param (
    [Parameter(
        Mandatory = $true,
        HelpMessage = "Source directory for backup."
    )]
    [string]$sourceDirectory,
    [Parameter(
        Mandatory = $true,
        HelpMessage = "Destination directory for archive."
    )]
    [string]$destinationDirectory,
    [Parameter(
        Mandatory = $true,
        HelpMessage = "Base name for backup archive."
    )]   
    [string]$archiveName,
    [Parameter(
        HelpMessage = "Number of days between full backups."
    )]   
    [int]$dayBetweenFulls = 7,
    [Parameter(
        HelpMessage = "Number of full backups to keep in rotation."
    )]   
    [int]$fullsToKeep = 7,
    [Parameter(
        HelpMessage = "Mode of differential backup."
    )]
    [ValidateSet("incemental", "decremental", IgnoreCase = $false)]  
    [int]$backupMode = "incemental"
)
$fileDateTime = Get-Date -Format FileDateTime
$backupRegex = "^$archiveName-[0-9]{8}T[0-9]{10}"
$fullBackupExtension = ".full"
$incrementalBackupExtension = ".incr"
$decrementalBackupExtension = ".incr"
$archiveExtension = ".7z"

$backups = Get-ChildItem -File -Path $destinationDirectory
$fullBackups = $backups | Where-Object { $_.Name -match $backupRegex + $fullBackupExtension + $archiveExtension }
$lastFullBackup = $fullBackups | Select-Object -Last 1

if (!$lastFullBackup) {
    # first run, create full backup
    $archivePath = Join-Path -Path $destinationDirectory -ChildPath ($archiveName + "-" + $fileDateTime + $fullBackupExtension + $archiveExtension)
    $7zipArgs = @(
        "a";        # add to archive
        "-mx=9";    # ultra compresion
        "-mhe";     # encrypt filenames
        "-t7z";     # use 7z format
        $archivePath;
        $sourceDirectory;
    )
    7z @7zipArgs
}
elseif ($lastFullBackup.LastWriteTime -lt (Get-Date).AddDays(-$dayBetweenFulls)) {
    # last full run is too old, create full backup
    $archivePath = Join-Path -Path $destinationDirectory -ChildPath ($archiveName + "-" + $fileDateTime + $fullBackupExtension + $archiveExtension)
    $7zipArgs = @(
        "a";        # add to archive
        "-mx=9";    # ultra compresion
        "-mhe";     # encrypt filenames
        "-t7z";     # use 7z format
        $archivePath;
        $sourceDirectory;
    )
    7z @7zipArgs
    # delete backups older that are N number(fullsToKeep) of full backups
    # code goes here
}
elseif ($backupMode.Equals("incemental")) {
    # create differential backup in decremental mode

    # This code does increment only on latest full not a chain to safe space full<-incremenal<-incremental
    # $archivePath = Join-Path -Path $destinationDirectory -ChildPath ($archiveName + "-" + $fileDateTime + $incrementalBackupExtension + $archiveExtension)
    # $7zipArgs = @(
    #     "u"; # add to archive
    #     "-mx=9"; # ultra compresion
    #     "-mhe"; # encrypt filenames
    #     "-t7z"; # use 7z format
    #     $lastFullBackup.FullName;
    #     $sourceDirectory;
    #     "-u-";
    #     "-up0q3r2x2y2z0w2!$archivePath";
    # )
    # 7z @7zipArgs
}
elseif ($backupMode.Equals("decremental")) {
    # create differential backup in decremental mode

    
}

