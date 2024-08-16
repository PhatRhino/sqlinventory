DECLARE @MachineGuid NVARCHAR(50);
DECLARE @DomainName SYSNAME;

-- Wechseln zum Kontext der master-Datenbank, um auf systemweite DMVs zugreifen zu können
USE master;

-- Lesen der MachineGuid aus der Registry
EXEC master.sys.xp_instance_regread
    @rootkey = 'HKEY_LOCAL_MACHINE'
    , @key = 'SOFTWARE\\Microsoft\\Cryptography'
    , @value_name = 'MachineGuid'
    , @value = @MachineGuid OUTPUT;

-- Lesen der Domain aus der Registry
EXEC master.sys.xp_regread
    @rootkey = 'HKEY_LOCAL_MACHINE'
    , @key = 'SYSTEM\\CurrentControlSet\\Services\\Tcpip\\Parameters'
    , @value_name = 'Domain'
    , @value = @DomainName OUTPUT;

-- Erfassen der Hostinformationen aus den System-DMVs
DECLARE @Platform NVARCHAR(50);
DECLARE @Distribution NVARCHAR(50);
DECLARE @Release NVARCHAR(50);
DECLARE @CPUCount INT;
DECLARE @PhysicalMemoryKB BIGINT;
DECLARE @IPAddress NVARCHAR(50);

SELECT @Platform = host_platform
    , @Distribution = host_distribution
    , @Release = host_release
FROM sys.dm_os_host_info;

SELECT @CPUCount = cpu_count
    , @PhysicalMemoryKB = physical_memory_kb
FROM sys.dm_os_sys_info;

SELECT @IPAddress = local_net_address
FROM sys.dm_exec_connections
WHERE session_id = @@SPID;

-- Wechseln zurück zum Kontext der AdminDB-Datenbank
USE AdminDB;

-- Einfügen oder Aktualisieren der Host-Informationen in der HostInfo-Tabelle
MERGE INTO HostInfo AS target
USING (
    SELECT 
          @MachineGuid AS HostGUID
        , CAST(SERVERPROPERTY('MachineName') AS NVARCHAR(128)) AS Hostname
        , DEFAULT_DOMAIN() AS Domain
        , @DomainName AS Subdomain
        , 'Production' AS Environment -- This can be adjusted based on your environment
        , @Platform AS Platform
        , @Distribution AS Distribution
        , @Release AS Release
        , @CPUCount AS CPUCount
        , @PhysicalMemoryKB AS PhysicalMemoryKB
        , @IPAddress AS IPAddress
        , GETDATE() AS CaptureDate
) AS source
ON target.HostGUID = source.HostGUID
WHEN MATCHED THEN
    UPDATE SET
          target.Hostname = source.Hostname
        , target.Domain = source.Domain
        , target.Subdomain = source.Subdomain
        , target.Environment = source.Environment
        , target.Platform = source.Platform
        , target.Distribution = source.Distribution
        , target.Release = source.Release
        , target.CPUCount = source.CPUCount
        , target.PhysicalMemory = source.PhysicalMemoryKB
        , target.IPAddress = source.IPAddress
        , target.CaptureDate = source.CaptureDate
WHEN NOT MATCHED THEN
    INSERT (
          HostGUID
        , Hostname
        , Domain
        , Subdomain
        , Environment
        , Platform
        , Distribution
        , Release
        , CPUCount
        , PhysicalMemory
        , IPAddress
        , CaptureDate
    )
    VALUES (
          source.HostGUID
        , source.Hostname
        , source.Domain
        , source.Subdomain
        , source.Environment
        , source.Platform
        , source.Distribution
        , source.Release
        , source.CPUCount
        , source.PhysicalMemoryKB
        , source.IPAddress
        , source.CaptureDate
    );
