# java-runner - run Java exercises without an IDE (PowerShell)
# Usage: .\runner.ps1 [File.java] [-Watch]

param(
    [string]$JavaFile = "",
    [switch]$Watch,
    [switch]$Help
)

if ($Help) {
    Write-Host "Usage: .\runner.ps1 [File.java] [-Watch]"
    Write-Host "  File.java   Java file to compile and run (optional if only one .java exists)"
    Write-Host "  -Watch      Recompile and rerun on every file save (event-based)"
    exit 0
}

# Auto-detect .java file
if (-not $JavaFile) {
    $found = @(Get-ChildItem -Path . -Filter "*.java" -File)

    if ($found.Count -eq 0 -and (Test-Path ".\examples")) {
        $found = @(Get-ChildItem -Path ".\examples" -Filter "*.java" -File)
        if ($found.Count -gt 0) {
            Write-Host "[INFO] No .java in current dir, searching examples\" -ForegroundColor Yellow
        }
    }

    if ($found.Count -eq 1) {
        $JavaFile = $found[0].FullName
    } elseif ($found.Count -eq 0) {
        Write-Host "[ERROR] No .java file found in current directory or examples\" -ForegroundColor Red
        exit 1
    } else {
        Write-Host "[WARNING] Multiple .java files found. Please specify one:" -ForegroundColor Yellow
        $found | ForEach-Object { Write-Host "  $($_.Name)" }
        exit 1
    }
}

if (-not (Test-Path $JavaFile)) {
    Write-Host "[ERROR] File not found: $JavaFile" -ForegroundColor Red
    exit 1
}

$JavaFile = (Resolve-Path $JavaFile).Path

function Invoke-Run {
    $className = [System.IO.Path]::GetFileNameWithoutExtension($JavaFile)
    $tmpDir = Join-Path $env:TEMP ("java-runner-" + [System.IO.Path]::GetRandomFileName())
    New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null

    Write-Host ""
    Write-Host "[....] Compiling $className.java..." -ForegroundColor Cyan

    $errFile = Join-Path $tmpDir "errors.txt"
    & javac -d $tmpDir $JavaFile 2>$errFile
    $compileExit = $LASTEXITCODE

    if ($compileExit -ne 0) {
        Write-Host "[FAIL] Compilation failed:" -ForegroundColor Red
        Write-Host ""
        Get-Content $errFile | ForEach-Object { Write-Host $_ }
        Remove-Item -Recurse -Force $tmpDir
        return $compileExit
    }

    Write-Host "[ OK ] Compiled successfully" -ForegroundColor Green
    Write-Host "───────────────────────── output ─────────────────────────" -ForegroundColor Cyan

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    & java -cp $tmpDir $className
    $javaExit = $LASTEXITCODE
    $sw.Stop()
    $elapsed = $sw.ElapsedMilliseconds

    Write-Host "───────────────────────────────────────────────────────────" -ForegroundColor Cyan
    if ($javaExit -ne 0) {
        Write-Host "[FAIL] Finished in ${elapsed}ms (exit code $javaExit)" -ForegroundColor Red
    } else {
        Write-Host "[ OK ] Finished in ${elapsed}ms" -ForegroundColor Green
    }
    Write-Host ""

    Remove-Item -Recurse -Force $tmpDir
    return $javaExit
}

if ($Watch) {
    Write-Host "[WATCH] Watch mode enabled - save the file to rerun" -ForegroundColor Yellow

    $dir = Split-Path $JavaFile -Parent
    $filename = Split-Path $JavaFile -Leaf

    Clear-Host
    Invoke-Run | Out-Null

    $watcher = New-Object System.IO.FileSystemWatcher($dir, $filename)
    $watcher.NotifyFilter = [System.IO.NotifyFilters]::LastWrite
    $watcher.EnableRaisingEvents = $true

    try {
        while ($true) {
            $result = $watcher.WaitForChanged([System.IO.WatcherChangeTypes]::Changed, 5000)
            if (-not $result.TimedOut) {
                Start-Sleep -Milliseconds 100
                Clear-Host
                Invoke-Run | Out-Null
            }
        }
    } finally {
        $watcher.Dispose()
    }
} else {
    $exitCode = Invoke-Run
    exit $exitCode
}
