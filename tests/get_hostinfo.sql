DECLARE @MachineGuid NVARCHAR(50)
DECLARE @DomainName SYSNAME

EXEC master.sys.xp_instance_regread
    @rootkey = 'HKEY_LOCAL_MACHINE',
    @key = 'SOFTWARE\Microsoft\Cryptography',
    @value_name = 'MachineGuid',
    @value = @MachineGuid OUTPUT

EXEC master.sys.xp_regread
    @rootkey = 'HKEY_LOCAL_MACHINE',
    @key = 'SYSTEM\CurrentControlSet\Services\Tcpip\Parameters',
    @value_name = 'Domain',
    @value = @DomainName OUTPUT

SELECT 
      @MachineGuid AS [guid]
    , CAST(SERVERPROPERTY('MachineName') AS NVARCHAR(128)) AS [hostname]
    , DEFAULT_DOMAIN() as [domain]
    , @DomainName AS [subdomain]
    --, TODO: Environment (environment variable, network stage/service now stage)
    , sys.dm_os_host_info.host_platform AS [platform]
    , sys.dm_os_host_info.host_distribution AS [distribution]
    , sys.dm_os_host_info.host_release AS [release]
    , sys.dm_os_sys_info.cpu_count AS [cpu_count]
    , sys.dm_os_sys_info.physical_memory_kb/1024 as [physical_memory]
    , CONNECTIONPROPERTY('local_net_address') as [ipaddress]
    , GETDATE() as [lastscan]
FROM sys.dm_os_host_info, sys.dm_os_sys_info