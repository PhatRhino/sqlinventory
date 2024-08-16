DECLARE @MachineGuid NVARCHAR(50)
DECLARE @DomainName SYSNAME

EXEC master.sys.xp_instance_regread
    @rootkey = 'HKEY_LOCAL_MACHINE',
    @key = 'SOFTWARE\\Microsoft\\Cryptography',
    @value_name = 'MachineGuid',
    @value = @MachineGuid OUTPUT

EXEC master.sys.xp_regread
    @rootkey = 'HKEY_LOCAL_MACHINE',
    @key = 'SYSTEM\\CurrentControlSet\\Services\\Tcpip\\Parameters',
    @value_name = 'Domain',
    @value = @DomainName OUTPUT

-- Select host information to be inserted or updated
MERGE INTO Host AS target
USING (
    SELECT 
          @MachineGuid AS HostGUID,
          CAST(SERVERPROPERTY('MachineName') AS NVARCHAR(128)) AS Hostname,
          DEFAULT_DOMAIN() as Domain,
          @DomainName AS Subdomain,
          'Production' AS Environment, -- This can be adjusted based on your environment
          sys.dm_os_host_info.host_platform AS Platform,
          sys.dm_os_host_info.host_distribution AS Distribution,
          sys.dm_os_host_info.host_release AS Release,
          sys.dm_os_sys_info.cpu_count AS CPUCount,
          sys.dm_os_sys_info.physical_memory_kb/1024 as PhysicalMemory,
          (SELECT TOP 1 local_net_address FROM sys.dm_exec_connections WHERE session_id = @@SPID) AS IPAddress,
          GETDATE() AS CaptureDate
) AS source
ON target.HostGUID = source.HostGUID
WHEN MATCHED THEN
    UPDATE SET
          target.Hostname = source.Hostname,
          target.Domain = source.Domain,
          target.Subdomain = source.Subdomain,
          target.Environment = source.Environment,
          target.Platform = source.Platform,
          target.Distribution = source.Distribution,
          target.Release = source.Release,
          target.CPUCount = source.CPUCount,
          target.PhysicalMemory = source.PhysicalMemory,
          target.IPAddress = source.IPAddress,
          target.CaptureDate = source.CaptureDate
WHEN NOT MATCHED THEN
    INSERT (
          HostGUID,
          Hostname,
          Domain,
          Subdomain,
          Environment,
          Platform,
          Distribution,
          Release,
          CPUCount,
          PhysicalMemory,
          IPAddress,
          CaptureDate
    )
    VALUES (
          source.HostGUID,
          source.Hostname,
          source.Domain,
          source.Subdomain,
          source.Environment,
          source.Platform,
          source.Distribution,
          source.Release,
          source.CPUCount,
          source.PhysicalMemory,
          source.IPAddress,
          source.CaptureDate
    );
