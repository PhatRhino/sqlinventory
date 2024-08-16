IF OBJECT_ID('tempdb.dbo.#space') IS NOT NULL
    DROP TABLE #space;

CREATE TABLE #space (
      database_id INT PRIMARY KEY,
      data_used_size DECIMAL(18,2),
      log_used_size DECIMAL(18,2)
);

DECLARE @SQL NVARCHAR(MAX);

SELECT @SQL = STUFF((
    SELECT '
    USE [' + d.name + ']
    INSERT INTO #space (database_id, data_used_size, log_used_size)
    SELECT
          DB_ID(),
          SUM(CASE WHEN [type] = 0 THEN space_used END),
          SUM(CASE WHEN [type] = 1 THEN space_used END)
    FROM (
        SELECT s.[type], space_used = SUM(FILEPROPERTY(s.name, ''SpaceUsed'') * 8. / 1024)
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
          d.database_id as local_id,
          d.service_broker_guid as DatabaseGUID,
          d.name,
          d.create_date,
          d.compatibility_level,
          d.collation_name,
          d.state_desc,
          r.recovery_model_desc,
          (SELECT SUM(size * 8. / 1024) FROM sys.master_files WHERE type = 0 AND database_id = d.database_id) AS Total_Size,
          s.data_used_size,
          (SELECT SUM(size * 8. / 1024) FROM sys.master_files WHERE type = 1 AND database_id = d.database_id) AS Log_Size,
          s.log_used_size,
          GETDATE() as CaptureDate
    FROM sys.databases d
    JOIN sys.database_recovery_status r ON d.database_id = r.database_id
    LEFT JOIN #space s ON d.database_id = s.database_id
) AS source
ON target.DatabaseGUID = source.DatabaseGUID
WHEN MATCHED THEN
    UPDATE SET
          target.Name = source.name,
          target.CreateDate = source.create_date,
          target.Compatibility_Level = source.compatibility_level,
          target.Collation_Name = source.collation_name,
          target.RecoveryModelDesc = source.recovery_model_desc,
          target.Total_Size = source.Total_Size,
          target.Data_Used_Size = source.data_used_size,
          target.Log_Size = source.Log_Size,
          target.Log_Used_Size = source.log_used_size,
          target.CaptureDate = source.CaptureDate
WHEN NOT MATCHED THEN
    INSERT (
          InstanceID,
          DatabaseGUID,
          Name,
          CreateDate,
          Compatibility_Level,
          Collation_Name,
          RecoveryModelDesc,
          Total_Size,
          Data_Size,
          Data_Used_Size,
          Log_Size,
          Log_Used_Size,
          CaptureDate
    )
    VALUES (
          (SELECT TOP 1 InstanceID FROM InstanceInfo WHERE HostID = (SELECT HostID FROM Host WHERE Hostname = @@SERVERNAME)),
          source.DatabaseGUID,
          source.name,
          source.create_date,
          source.compatibility_level,
          source.collation_name,
          source.recovery_model_desc,
          source.Total_Size,
          source.Total_Size, -- Assuming Total_Size = Data_Size for simplicity
          source.data_used_size,
          source.Log_Size,
          source.log_used_size,
          source.CaptureDate
    );
