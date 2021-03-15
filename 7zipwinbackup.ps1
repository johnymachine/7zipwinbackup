param (
    [Parameter(
        Mandatory = $true,
        HelpMessage = "Source directory for backup."
    )]
    [ValidateScript( { Test-Path -Path $_ })]
    [string]$sourceDirectory,
    [Parameter(
        Mandatory = $true,
        HelpMessage = "Destination directory for archive."
    )]
    [ValidateScript( { Test-Path -Path $_ })]
    [string]$destinationDirectory,
    [Parameter(
        Mandatory = $true,
        HelpMessage = "Base name for backup archive."
    )]   
    [string]$archiveName,
    [Parameter(
        HelpMessage = "File containing the password."
    )]
    [ValidateScript( { Test-Path -Path $_ })]
    [string]$secretFile,
    [Parameter(
        HelpMessage = "Number of days between full backups."
    )]   
    [int]$dayBetweenFulls = 7,
    [Parameter(
        HelpMessage = "Number of full backups to keep in rotation."
    )]   
    [int]$fullsToKeep = 4,
    [Parameter(
        HelpMessage = "Mode of differential backup."
    )]
    [ValidateSet("incemental", "decremental", IgnoreCase = $false)]  
    [string]$backupMode = "incremental"
)
Write-Host ("=== 7ZipWinBackup ===")
Write-Host ("Backup: {0} to: {1}" -f $sourceDirectory, $destinationDirectory)
$fileDateTime = Get-Date -Format FileDateTime
$backupRegex = "^$archiveName-[0-9]{8}T[0-9]{10}"
$fullBackupExtension = ".full"
$incrementalBackupExtension = ".incr"
$decrementalBackupExtension = ".decr"
$archiveExtension = ".7z"

$backups = Get-ChildItem -File -Path $destinationDirectory
$fullBackups = $backups | Where-Object { $_.Name -match $backupRegex + $fullBackupExtension + $archiveExtension } | Sort-Object -Property LastWriteTime -Descending
$lastFullBackup = $fullBackups | Select-Object -First 1

if (!$lastFullBackup) {
    # first run, create full backup
    $archivePath = Join-Path -Path $destinationDirectory -ChildPath ($archiveName + "-" + $fileDateTime + $fullBackupExtension + $archiveExtension)
    Write-Host ("=== FullBackup ===")
    $7zipArgs = @(
        "a"; # add to archive
        "-mx=9"; # ultra compresion
        "-mhe"; # encrypt filenames
        "-t7z"; # use 7z format
        $archivePath;
        $sourceDirectory;
    )
    if ($secretFile) { $7zipArgs = $7zipArgs + ("-p{0}" -f (Get-Content -Path $secretFile)) };
    $output = 7z @7zipArgs
    $output
}
elseif ($lastFullBackup.LastWriteTime -lt (Get-Date).AddDays(-$dayBetweenFulls)) {
    # last full run is too old, create full backup
    $archivePath = Join-Path -Path $destinationDirectory -ChildPath ($archiveName + "-" + $fileDateTime + $fullBackupExtension + $archiveExtension)
    Write-Host ("=== FullBackup ===")
    $7zipArgs = @(
        "a"; # add to archive
        "-mx=9"; # ultra compresion
        "-mhe"; # encrypt filenames
        "-t7z"; # use 7z format
        $archivePath;
        $sourceDirectory;
    )
    if ($secretFile) { $7zipArgs = $7zipArgs + ("-p{0}" -f (Get-Content -Path $secretFile)) };
    $output = 7z @7zipArgs
    $output

    # delete backups older than fullsToKeep
    if ($fullBackups.Count -gt ($fullsToKeep - 2)) {
        $deleteFrom = ($fullBackups | Select-Object -Skip ($fullsToKeep - 2))[0].LastWriteTime
        $filestoDelete = Get-ChildItem -Path $destinationDirectory -File | Where-Object { $_.Name -match $backupRegex -and $_.LastWriteTime -lt $deleteFrom }
        $null = $filestoDelete | Remove-Item -Force
    }
}
elseif ($backupMode.Equals("incremental")) {
    # create differential backup in incremental mode
    # create the differential step into the future
    $archivePath = Join-Path -Path $destinationDirectory -ChildPath ($archiveName + "-" + $fileDateTime + $incrementalBackupExtension + $archiveExtension)
    Write-Host ("=== IncrementalBackup ===")
    $7zipArgs = @(
        "u"; # add to archive
        $lastFullBackup.FullName;
        "-u-";
        "-up0q3r2x2y2z0w2!{0}" -f $archivePath
        "-mx=9"; # ultra compresion
        "-mhe"; # encrypt filenames
        "-t7z"; # use 7z format
        $sourceDirectory;
    )
    if ($secretFile) { $7zipArgs = $7zipArgs + ("-p{0}" -f (Get-Content -Path $secretFile)) };
    $incrementalOutput = 7z @7zipArgs
    $incrementalOutput
}
elseif ($backupMode.Equals("decremental")) {
    # create differential backup in decremental mode
    # create the differential step into the past
    $archivePath = Join-Path -Path $destinationDirectory -ChildPath ($archiveName + "-" + $fileDateTime + $decrementalBackupExtension + $archiveExtension)
    Write-Host ("=== DecrementalBackup ===")
    $7zipArgs = @(
        "u"; # add to archive
        $lastFullBackup.FullName;
        "-u-";
        "-up1q1r3x1y1z0w1!{0}" -f $archivePath
        "-mx=9"; # ultra compresion
        "-mhe"; # encrypt filenames
        "-t7z"; # use 7z format
        $sourceDirectory;
    )
    if ($secretFile) { $7zipArgs = $7zipArgs + ("-p{0}" -f (Get-Content -Path $secretFile)) };
    $decrementalOutput = 7z @7zipArgs
    $decrementalOutput

    # update the archive to the latest files
    $archivePath = Join-Path -Path $destinationDirectory -ChildPath ($archiveName + "-" + $fileDateTime + $decrementalBackupExtension + $archiveExtension)
    $7zipArgs = @(
        "u"; # add to archive
        $lastFullBackup.FullName;
        "-mx=9"; # ultra compresion
        "-mhe"; # encrypt filenames
        "-t7z"; # use 7z format
        $sourceDirectory;
    )
    if ($secretFile) { $7zipArgs = $7zipArgs + ("-p{0}" -f (Get-Content -Path $secretFile)) };
    $output = 7z @7zipArgs
    $output
}

