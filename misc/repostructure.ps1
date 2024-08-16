# Setze das Wurzelverzeichnis für das Projekt
$rootPath = "H:\UserData\Documents\00_SYNC\001_Business\repos_work\sqlinventory"

# Liste der Ordner, die erstellt werden sollen
$folders = @(
    "docs",
    "scripts",
    "scripts\ddl",
    "scripts\dml",
    "scripts\stored_procedures",
    "scripts\views",
    "scripts\functions",
    "scripts\triggers",
    "scripts\jobs",
    "scripts\migrations",
    "config",
    "tests",
    "backups"
)

# Erstellen der Ordnerstruktur und Hinzufügen der .gitkeep-Dateien
foreach ($folder in $folders) {
    $folderPath = Join-Path $rootPath $folder
    New-Item -ItemType Directory -Force -Path $folderPath
    New-Item -ItemType File -Force -Path (Join-Path $folderPath ".gitkeep")
}

Write-Host "Ordnerstruktur und .gitkeep-Dateien wurden erfolgreich erstellt."
