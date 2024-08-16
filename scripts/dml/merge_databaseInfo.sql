IF OBJECT_ID('tempdb.dbo.#space') IS NOT NULL
    DROP TABLE #space;

CREATE TABLE #space (
      DatabaseID INT PRIMARY KEY
    , DataUsedSizeKB BIGINT
    , LogUsedSizeKB BIGINT
);

DECLARE @SQL NVARCHAR(MAX);

SELECT @SQL = STUFF((
    SELECT '
    USE [' + d.name + ']
    INSERT INTO #space (DatabaseID, DataUsedSizeKB, LogUsedSizeKB)
    SELECT
          DB_ID()
        , SUM(CASE WHEN [type] = 0 THEN space_used END)
        , SUM(CASE WHEN [type] = 1 THEN space_used END)
    FROM (
        SELECT s.[type], space_used = SUM(FILEPROPERTY(s.name, ''SpaceUsed'') * 8)
        FROM sys.database_files s
        GROUP BY s.[type]
    ) t;'
    FROM sys.databases d
    WHERE d.[state] = 0
    FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, '');

EXEC sys.sp_executesql @SQL;

-- Insert or update the data into the DatabaseInfo table
MERGE INTO DatabaseInfo AS target
USING (
    SELECT
          d.database_id AS LocalID
        , d.service_broker_guid AS DatabaseGUID
        , d.name
        , d.create_date
        , d.compatibility_level
        , d.collation_name
        , d.state_desc
        , r.recovery_model_desc
        , (SELECT SUM(size * 8) FROM sys.master_files WHERE type = 0 AND database_id = d.database_id) AS DataSizeKB
        , s.DataUsedSizeKB
        , (SELECT SUM(size * 8) FROM sys.master_files WHERE type = 1 AND database_id = d.database_id) AS LogSizeKB
        , s.LogUsedSizeKB
        , GETDATE() AS CaptureDate
    FROM sys.databases d
    JOIN sys.database_recovery_status r ON d.database_id = r.database_id
    LEFT JOIN #space s ON d.database_id = s.database_id
) AS source
ON target.DatabaseGUID = source.DatabaseGUID
WHEN MATCHED THEN
    UPDATE SET
          target.Name = source.name
        , target.CreateDate = source.create_date
        , target.CompatibilityLevel = source.compatibility_level
        , target.CollationName = source.collation_name
        , target.RecoveryModelDesc = source.recovery_model_desc
        , target.DataSizeKB = source.DataSizeKB
        , target.DataUsedSizeKB = source.DataUsedSizeKB
        , target.LogSizeKB = source.LogSizeKB
        , target.LogUsedSizeKB = source.LogUsedSizeKB
        , target.CaptureDate = source.CaptureDate
WHEN NOT MATCHED THEN
    INSERT (
          InstanceID
        , DatabaseGUID
        , Name
        , CreateDate
        , CompatibilityLevel
        , CollationName
        , RecoveryModelDesc
        , DataSizeKB
        , DataUsedSizeKB
        , LogSizeKB
        , LogUsedSizeKB
        , CaptureDate
    )
    VALUES (
          (SELECT TOP 1 InstanceID FROM InstanceInfo WHERE HostID = (SELECT HostID FROM HostInfo WHERE Hostname = @@SERVERNAME))
        , source.DatabaseGUID
        , source.name
        , source.create_date
        , source.compatibility_level
        , source.collation_name
        , source.recovery_model_desc
        , source.DataSizeKB
        , source.DataUsedSizeKB
        , source.LogSizeKB
        , source.LogUsedSizeKB
        , source.CaptureDate
    );