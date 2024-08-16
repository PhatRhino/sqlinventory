DECLARE @DefaultBackupDirectory NVARCHAR(500);
DECLARE @InstanceGUID UNIQUEIDENTIFIER;
DECLARE @Hostname NVARCHAR(128);

-- Wechseln zum Kontext der master-Datenbank, um die service_broker_guid für msdb abzurufen
USE master;

-- Abrufen der service_broker_guid für die msdb-Datenbank
SELECT @InstanceGUID = service_broker_guid
FROM sys.databases
WHERE name = 'msdb';

-- Lesen des Standard-Backup-Verzeichnisses
EXEC master.dbo.xp_instance_regread
    @rootkey = 'HKEY_LOCAL_MACHINE'
    , @key = 'SOFTWARE\\Microsoft\\MSSQLServer\\MSSQLServer'
    , @value_name = 'BackupDirectory'
    , @value = @DefaultBackupDirectory OUTPUT;

-- Extrahieren des Hostnamens aus @@SERVERNAME (ohne Instanznamen)
SELECT @Hostname = LEFT(@@SERVERNAME, CHARINDEX('\', @@SERVERNAME + '\') - 1);

-- Zurückwechseln in die AdminDB-Datenbank
USE AdminDB;

-- Einfügen oder Aktualisieren der Instanzinformationen
MERGE INTO InstanceInfo AS target
USING (
    SELECT
          @InstanceGUID AS InstanceGUID
        , CONVERT(NVARCHAR(128), SERVERPROPERTY('InstanceName')) AS InstanceName
        , CONVERT(NVARCHAR(128), SERVERPROPERTY('Edition')) AS Edition
        , CONVERT(NVARCHAR(50), SERVERPROPERTY('ProductLevel')) AS Level
        , CONVERT(NVARCHAR(50), SERVERPROPERTY('ProductUpdateLevel')) AS UpdateLevel
        , CONVERT(NVARCHAR(128), SERVERPROPERTY('ProductVersion')) AS Version
        , CONVERT(NVARCHAR(10), SERVERPROPERTY('ProductMajorVersion')) AS MajorVersion
        , CONVERT(NVARCHAR(10), SERVERPROPERTY('ProductMinorVersion')) AS MinorVersion
        , CONVERT(BIGINT, (SELECT value_in_use FROM sys.configurations WHERE name = 'max server memory (MB)') * 1024) AS MaxMemory
        , CONVERT(BIGINT, (SELECT value_in_use FROM sys.configurations WHERE name = 'min server memory (MB)') * 1024) AS MinMemory
        , CONVERT(NVARCHAR(128), SERVERPROPERTY('Collation')) AS Collation
        , CONVERT(NVARCHAR(260), SERVERPROPERTY('InstanceDefaultDataPath')) AS DefaultDataDirectory
        , CONVERT(NVARCHAR(260), SERVERPROPERTY('InstanceDefaultLogPath')) AS DefaultLogDirectory
        , @DefaultBackupDirectory AS DefaultBackupDirectory
        , GETDATE() AS CaptureDate
        , (SELECT TOP 1 HostID FROM HostInfo WHERE Hostname = @Hostname) AS HostID
) AS source
ON target.InstanceGUID = source.InstanceGUID
WHEN MATCHED THEN
    UPDATE SET
          target.InstanceName = source.InstanceName
        , target.Edition = source.Edition
        , target.Level = source.Level
        , target.UpdateLevel = source.UpdateLevel
        , target.Version = source.Version
        , target.MajorVersion = source.MajorVersion
        , target.MinorVersion = source.MinorVersion
        , target.MaxMemory = source.MaxMemory
        , target.MinMemory = source.MinMemory
        , target.Collation = source.Collation
        , target.DefaultDataDirectory = source.DefaultDataDirectory
        , target.DefaultLogDirectory = source.DefaultLogDirectory
        , target.DefaultBackupDirectory = source.DefaultBackupDirectory
        , target.CaptureDate = source.CaptureDate
WHEN NOT MATCHED THEN
    INSERT (
          HostID
        , InstanceGUID
        , InstanceName
        , Edition
        , Level
        , UpdateLevel
        , Version
        , MajorVersion
        , MinorVersion
        , MaxMemory
        , MinMemory
        , Collation
        , DefaultDataDirectory
        , DefaultLogDirectory
        , DefaultBackupDirectory
        , CaptureDate
    )
    VALUES (
          source.HostID
        , source.InstanceGUID
        , source.InstanceName
        , source.Edition
        , source.Level
        , source.UpdateLevel
        , source.Version
        , source.MajorVersion
        , source.MinorVersion
        , source.MaxMemory
        , source.MinMemory
        , source.Collation
        , source.DefaultDataDirectory
        , source.DefaultLogDirectory
        , source.DefaultBackupDirectory
        , source.CaptureDate
    );
