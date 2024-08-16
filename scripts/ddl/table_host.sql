USE AdminDB;
GO

-- Tabelle für Host-Informationen
CREATE TABLE Host (
    HostID INT IDENTITY(1,1) PRIMARY KEY, -- Auto-increment Primärschlüssel
    HostGUID UNIQUEIDENTIFIER NOT NULL, -- GUID für den Host, ermittelt aus msdb
    Hostname NVARCHAR(128) NOT NULL, -- Hostname des Servers
    Domain NVARCHAR(128), -- Domäne, zu der der Server gehört (AD Domain)
    Subdomain NVARCHAR(128), -- Subdomäne, um den FQDN zu ermitteln (DNS Subdomain)
    Environment NVARCHAR(50), -- Umgebung (z.B. 'Production', 'Development', 'Test')
    Platform NVARCHAR(50), -- Plattform des Servers (Windows/Linux)
    Distribution NVARCHAR(50), -- Betriebssystem-Distribution (Beschreibung des OS)
    Release NVARCHAR(50), -- Betriebssystem-Version (Versionsnummer)
    CPUCount INT, -- Anzahl der CPUs auf dem Server
    PhysicalMemory BIGINT, -- Physischer Speicher in MB, angepasst für zukünftige Anforderungen
    IPAddress NVARCHAR(50), -- IP-Adresse des Servers
    Status NVARCHAR(50) DEFAULT 'Active', -- Status des Datensatzes (z.B. 'Active', 'Inactive')
    Version INT NOT NULL DEFAULT 1, -- Version des Datensatzes
    ValidFrom DATETIME NOT NULL DEFAULT GETDATE(), -- Gültig ab Datum
    ValidTo DATETIME NULL, -- Gültig bis Datum (NULL bedeutet aktuell gültig)
    CaptureDate DATETIME DEFAULT GETDATE(), -- Zeitpunkt der Datenerfassung
    CONSTRAINT UQ_Host_Hostname UNIQUE (Hostname, Domain, Subdomain) -- Eindeutiger Index auf Hostname, Domain und Subdomain
);

-- Indexe hinzufügen
CREATE INDEX IDX_Host_Hostname ON Host (Hostname);
GO
