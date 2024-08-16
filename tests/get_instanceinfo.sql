DECLARE @DefaultBackupDirectory NVARCHAR(500)

EXEC master.dbo.xp_instance_regread
    @rootkey = 'HKEY_LOCAL_MACHINE',
    @key = 'SOFTWARE\Microsoft\MSSQLServer\MSSQLServer',
    @value_name = 'BackupDirectory',
    @value = @DefaultBackupDirectory OUTPUT

SELECT
      LOWER([service_broker_guid]) AS guid
    , SERVERPROPERTY('InstanceName') AS name
    , SERVERPROPERTY('Edition') AS edition
    , SERVERPROPERTY('ProductLevel') AS level
    , SERVERPROPERTY('ProductUpdateLevel') AS updatelevel
    , SERVERPROPERTY('ProductVersion') AS version
    , SERVERPROPERTY('ProductMajorVersion') AS majorversion
    , SERVERPROPERTY('ProductMinorVersion') AS minorversion
    , (SELECT value_in_use FROM sys.configurations WHERE name = 'max server memory (MB)') as [max_server_memory]
    , SERVERPROPERTY('Collation') AS collation
    , SERVERPROPERTY('InstanceDefaultDataPath') AS defaultfiledirectory
    , SERVERPROPERTY('InstanceDefaultLogPath') AS defaultlogdirectory
    , @DefaultBackupDirectory AS defaultbackupdirectory
    , GETDATE() as lastscan
FROM sys.databases
WHERE [name] = N'msdb';
GO