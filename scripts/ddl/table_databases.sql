USE AdminDB;
GO

-- Tabelle für Datenbank-Informationen
CREATE TABLE DatabaseInfo (
    DatabaseID INT IDENTITY(1,1) PRIMARY KEY, -- Auto-increment Primärschlüssel
    InstanceID INT NOT NULL, -- Fremdschlüssel zur Instanz-Tabelle
    DatabaseGUID UNIQUEIDENTIFIER DEFAULT NEWID(), -- GUID für die Datenbank
    Name NVARCHAR(128) NOT NULL, -- Name der Datenbank
    CreateDate DATETIME NOT NULL, -- Erstellungsdatum der Datenbank
    Compatibility_Level INT, -- Kompatibilitätslevel der Datenbank
    Collation_Name NVARCHAR(128), -- Kollation der Datenbank
    RecoveryModelDesc NVARCHAR(50), -- Recovery Model Beschreibung (z.B. 'FULL', 'SIMPLE')
    TotalSize BIGINT, -- Gesamte Größe der Datenbank in KB
    DataSize BIGINT, -- Größe der Datendateien in KB
    DataUsedSize BIGINT, -- Benutzte Größe der Datendateien in KB
    LogSize BIGINT, -- Größe der Protokolldatei in KB
    LogUsedSize BIGINT, -- Benutzte Größe der Protokolldatei in KB
    Status NVARCHAR(50) DEFAULT 'Active', -- Status des Datensatzes (z.B. 'Active', 'Deleted')
    Version INT NOT NULL DEFAULT 1, -- Version des Datensatzes
    ValidFrom DATETIME NOT NULL DEFAULT GETDATE(), -- Gültig ab Datum
    ValidTo DATETIME NULL, -- Gültig bis Datum
    CaptureDate DATETIME DEFAULT GETDATE(), -- Zeitpunkt der Datenerfassung
    CONSTRAINT FK_Database_Instance FOREIGN KEY (InstanceID) REFERENCES InstanceInfo(InstanceID) -- Fremdschlüssel zur Instanz-Tabelle
);

-- Index hinzufügen
CREATE INDEX IDX_Database_Name ON DatabaseInfo (Name);
GO
