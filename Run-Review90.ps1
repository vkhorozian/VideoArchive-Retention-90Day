# ==================================================
# Video Archive 90-Day Review Script (Drive-Aware)
# With Live Output, Progress, and Disk Reporting
# ==================================================

# ---------------- TEST MODE ----------------
# $true  = TEST MODE (no data moved)
# $false = LIVE MODE (folders moved)
$WhatIfMode = $false   # CHANGE TO $true FOR TEST RUNS

# ---------------- RETENTION ----------------
$RetentionDays = 90
$CutoffDate    = (Get-Date).AddDays(-$RetentionDays)

# ---------------- AUTO PATH DETECTION ----------------
$BasePath   = $PSScriptRoot
$SourceRoot = Join-Path $BasePath "Archiver-01"
$ReviewRoot = Join-Path $BasePath "Archiver-01-Review90"
$LogRoot    = Join-Path $BasePath "Logs"

$Drive   = (Get-Item $BasePath).PSDrive.Name
$RunDate = Get-Date -Format "yyyy-MM-dd"
$LogFile = Join-Path $LogRoot "Archiver-01_Review90_Drive-$Drive`_$RunDate.log"

# ---------------- METRICS ----------------
$EvaluatedFolders  = 0
$MovedFolders      = 0
$SkippedFolders    = 0
$TotalBytesMoved   = 0

# ---------------- VALIDATION ----------------
if (-not (Test-Path $SourceRoot)) {
    Write-Error "Source path not found: $SourceRoot"
    exit 1
}

# ---------------- ENSURE FOLDERS EXIST ----------------
foreach ($Path in @($ReviewRoot, $LogRoot)) {
    if (-not (Test-Path $Path)) {
        New-Item -Path $Path -ItemType Directory | Out-Null
    }
}

# ---------------- LOG HEADER ----------------
"==================================================" | Out-File $LogFile -Append
"Run Start : $(Get-Date)"                            | Out-File $LogFile -Append
"Drive     : $Drive"                                 | Out-File $LogFile -Append
"Mode      : $(if ($WhatIfMode) {'TEST (WhatIf)'} else {'LIVE'})" | Out-File $LogFile -Append
"Retention : $RetentionDays days"                    | Out-File $LogFile -Append
"==================================================" | Out-File $LogFile -Append
"" | Out-File $LogFile -Append

Write-Host "Starting archive review on drive $Drive..."
Write-Host "Retention cutoff: $CutoffDate"
Write-Host ""

# ---------------- PROCESS CAMERA FOLDERS ----------------
Get-ChildItem -Path $SourceRoot -Directory | ForEach-Object {

    $CameraFolder = $_
    $CameraName   = $CameraFolder.Name
    $ReviewCameraPath = Join-Path $ReviewRoot $CameraName

    if (-not (Test-Path $ReviewCameraPath)) {
        New-Item -Path $ReviewCameraPath -ItemType Directory | Out-Null
        Write-Host "Created review folder: $ReviewCameraPath"
    }

    Get-ChildItem -Path $CameraFolder.FullName -Directory | ForEach-Object {

        $EvaluatedFolders++
        $DateFolder = $_

        Write-Progress `
            -Activity "Processing Camera: $CameraName" `
            -Status "Evaluating: $($DateFolder.Name)" `
            -PercentComplete (($EvaluatedFolders % 100))

        if ($DateFolder.LastWriteTime -ge $CutoffDate) {
            $SkippedFolders++
            Write-Host "SKIP | $CameraName | $($DateFolder.Name) | LastWriteTime=$($DateFolder.LastWriteTime)"
            "$(Get-Date) | SKIP | $CameraName | $($DateFolder.Name) | LastWriteTime=$($DateFolder.LastWriteTime)" |
                Out-File $LogFile -Append
            return
        }

        # Calculate folder size
        $FolderSizeBytes = (
            Get-ChildItem $DateFolder.FullName -Recurse -File -ErrorAction SilentlyContinue |
            Measure-Object Length -Sum
        ).Sum

        $SourcePath = $DateFolder.FullName
        $DestPath   = Join-Path $ReviewCameraPath $DateFolder.Name

        try {
            if ($WhatIfMode) {
                Move-Item -Path $SourcePath -Destination $DestPath -WhatIf
                Write-Host "TEST | WOULD MOVE | $CameraName | $($DateFolder.Name)"
            }
            else {
                Move-Item -Path $SourcePath -Destination $DestPath
                Write-Host "MOVE | $CameraName | $($DateFolder.Name)"
            }

            $MovedFolders++
            $TotalBytesMoved += $FolderSizeBytes

            "$(Get-Date) | $(if ($WhatIfMode) {'TEST'} else {'LIVE'}) | MOVE | $CameraName | $($DateFolder.Name) | SIZE=$FolderSizeBytes bytes" |
                Out-File $LogFile -Append
        }
        catch {
            Write-Host "ERROR | $CameraName | $($DateFolder.Name) | $($_.Exception.Message)" -ForegroundColor Red
            "$(Get-Date) | ERROR | $CameraName | $($DateFolder.Name) | $($_.Exception.Message)" |
                Out-File $LogFile -Append
        }
    }
}

# ---------------- SUMMARY ----------------
$TotalGB = [Math]::Round($TotalBytesMoved / 1GB, 2)

Write-Host ""
Write-Host "================ SUMMARY ================"
Write-Host "Folders evaluated : $EvaluatedFolders"
Write-Host "Folders moved     : $MovedFolders"
Write-Host "Folders skipped   : $SkippedFolders"
Write-Host "Disk reclaimed    : $TotalGB GB"
Write-Host "========================================="

"" | Out-File $LogFile -Append
"---------------- SUMMARY ----------------" | Out-File $LogFile -Append
"Folders evaluated : $EvaluatedFolders"   | Out-File $LogFile -Append
"Folders moved     : $MovedFolders"       | Out-File $LogFile -Append
"Folders skipped   : $SkippedFolders"     | Out-File $LogFile -Append
"Disk reclaimed    : $TotalGB GB"          | Out-File $LogFile -Append
"------------------------------------------" | Out-File $LogFile -Append
"Run End : $(Get-Date)" | Out-File $LogFile -Append
