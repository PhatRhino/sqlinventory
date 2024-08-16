USE AdminDB;
GO

-- Tabelle für Instanz-Informationen
CREATE TABLE InstanceInfo (
    InstanceID INT IDENTITY(1,1) PRIMARY KEY, -- Auto-increment Primärschlüssel
    HostID INT NOT NULL, -- Fremdschlüssel zur Host-Tabelle
    InstanceGUID UNIQUEIDENTIFIER NOT NULL, -- GUID für die Instanz, muss vom Nutzer gesetzt werden
    InstanceName NVARCHAR(128) NOT NULL, -- Name der Instanz
    Edition NVARCHAR(128), -- Edition des SQL Servers (z.B. 'Standard', 'Enterprise')
    Level NVARCHAR(50), -- SQL Server Produktlevel (z.B. 'SP1', 'RTM')
    UpdateLevel NVARCHAR(50), -- Update Level des SQL Servers (z.B. 'CU8')
    Version NVARCHAR(128), -- SQL Server-Version (z.B. '15.0.2000.5')
    MajorVersion NVARCHAR(10), -- Hauptversion (z.B. '15')
    MinorVersion NVARCHAR(10), -- Nebenversion (z.B. '0')
    MaxMemoryKB BIGINT NOT NULL, -- Maximale Speicherzuweisung in KB, angepasst für zukünftige Anforderungen
    MinMemoryKB BIGINT NOT NULL, -- Minimale Speicherzuweisung in KB
    Collation NVARCHAR(128), -- Kollation der Instanz
    DefaultDataDirectory NVARCHAR(260) NOT NULL, -- Standard-Datenverzeichnis
    DefaultLogDirectory NVARCHAR(260) NOT NULL, -- Standard-Protokollverzeichnis
    DefaultBackupDirectory NVARCHAR(260) NOT NULL, -- Standard-Sicherungsverzeichnis
    Status NVARCHAR(50) DEFAULT 'Active', -- Status des Datensatzes (z.B. 'Active', 'Inactive')
    VersionNo INT NOT NULL DEFAULT 1, -- Version des Datensatzes
    ValidFrom DATETIME NOT NULL DEFAULT GETDATE(), -- Gültig ab Datum
    ValidTo DATETIME NULL, -- Gültig bis Datum (NULL bedeutet aktuell gültig)
    CaptureDate DATETIME DEFAULT GETDATE(), -- Zeitpunkt der Datenerfassung
    CONSTRAINT UQ_Instance_Host_InstanceName UNIQUE (HostID, InstanceName), -- Eindeutiger Index auf HostID und InstanceName
    CONSTRAINT FK_Instance_Host FOREIGN KEY (HostID) REFERENCES Host(HostID) -- Fremdschlüssel zur Host-Tabelle
);

-- Index hinzufügen
CREATE INDEX IDX_Instance_InstanceName ON InstanceInfo (InstanceName);
GO
