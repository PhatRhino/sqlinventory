DECLARE @DefaultBackupDirectory NVARCHAR(500)

EXEC master.dbo.xp_instance_regread
    @rootkey = 'HKEY_LOCAL_MACHINE',
    @key = 'SOFTWARE\\Microsoft\\MSSQLServer\\MSSQLServer',
    @value_name = 'BackupDirectory',
    @value = @DefaultBackupDirectory OUTPUT

-- Insert or update the instance information
MERGE INTO InstanceInfo AS target
USING (
    SELECT
        LOWER([service_broker_guid]) AS InstanceGUID,
        SERVERPROPERTY('InstanceName') AS InstanceName,
        SERVERPROPERTY('Edition') AS Edition,
        SERVERPROPERTY('ProductLevel') AS [Level],
        SERVERPROPERTY('ProductUpdateLevel') AS UpdateLevel,
        SERVERPROPERTY('ProductVersion') AS Version,
        SERVERPROPERTY('ProductMajorVersion') AS MajorVersion,
        SERVERPROPERTY('ProductMinorVersion') AS MinorVersion,
          (SELECT value_in_use FROM sys.configurations WHERE name = 'max server memory (MB)') * 1024 AS MaxMemoryKB,
          (SELECT value_in_use FROM sys.configurations WHERE name = 'min server memory (MB)') * 1024 AS MinMemoryKB,
        SERVERPROPERTY('Collation') AS Collation,
        SERVERPROPERTY('InstanceDefaultDataPath') AS DefaultDataDirectory,
        SERVERPROPERTY('InstanceDefaultLogPath') AS DefaultLogDirectory,
        @DefaultBackupDirectory AS DefaultBackupDirectory,
        GETDATE() AS CaptureDate,
        (SELECT TOP 1 HostID FROM Host WHERE Hostname = @@SERVERNAME) AS HostID
) AS source
ON target.InstanceGUID = source.InstanceGUID
WHEN MATCHED THEN
    UPDATE SET
          target.InstanceName = source.InstanceName,
          target.Edition = source.Edition,
          target.Level = source.Level,
          target.UpdateLevel = source.UpdateLevel,
          target.Version = source.Version,
          target.MajorVersion = source.MajorVersion,
          target.MinorVersion = source.MinorVersion,
          target.MaxMemoryKB = source.MaxMemoryKB,
          target.MinMemoryKB = source.MinMemoryKB,
          target.Collation = source.Collation,
          target.DefaultDataDirectory = source.DefaultDataDirectory,
          target.DefaultLogDirectory = source.DefaultLogDirectory,
          target.DefaultBackupDirectory = source.DefaultBackupDirectory,
          target.CaptureDate = source.CaptureDate
WHEN NOT MATCHED THEN
    INSERT (
          HostID,
          InstanceGUID,
          InstanceName,
          Edition,
          [Level],
          UpdateLevel,
          Version,
          MajorVersion,
          MinorVersion,
          MaxMemoryKB,
          MinMemoryKB,
          Collation,
          DefaultDataDirectory,
          DefaultLogDirectory,
          DefaultBackupDirectory,
          CaptureDate
    )
    VALUES (
          source.HostID,
          source.InstanceGUID,
          source.InstanceName,
          source.Edition,
          source.Level,
          source.UpdateLevel,
          source.Version,
          source.MajorVersion,
          source.MinorVersion,
          source.MaxMemoryKB,
          source.MinMemoryKB,
          source.Collation,
          source.DefaultDataDirectory,
          source.DefaultLogDirectory,
          source.DefaultBackupDirectory,
          source.CaptureDate
    );
