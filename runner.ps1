# java-runner - run Java exercises without an IDE (PowerShell)
# Usage: .\runner.ps1 [File.java] [-Watch] [-All] [-InputFile f] [-Classpath p] [-OutputFile f]

param(
    [string]$JavaFile = "",
    [switch]$Watch,
    [switch]$All,
    [string]$InputFile = "",
    [string]$Classpath = "",
    [string]$OutputFile = "",
    [switch]$Help
)

if ($Help) {
    Write-Host "Usage: .\runner.ps1 [File.java] [options]"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -Watch              Recompile and rerun on every file save (event-based)"
    Write-Host "  -All                Compile all .java files in the same directory together"
    Write-Host "  -InputFile <file>   Pipe file contents into stdin when running"
    Write-Host "  -Classpath <path>   Append to the compile and run classpath"
    Write-Host "  -OutputFile <file>  Save program output to file (also prints to terminal)"
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
    $fileDir   = [System.IO.Path]::GetDirectoryName($JavaFile)
    $tmpDir    = Join-Path $env:TEMP ("java-runner-" + [System.IO.Path]::GetRandomFileName())
    New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null

    # Build classpath
    $cp = $tmpDir
    if ($Classpath) { $cp = "$tmpDir;$Classpath" }

    Write-Host ""
    Write-Host "[....] Compiling $className.java..." -ForegroundColor Cyan

    # Choose sources: -All compiles every .java in the same directory
    $errFile = Join-Path $tmpDir "errors.txt"
    if ($All) {
        $sources = (Get-ChildItem -Path $fileDir -Filter "*.java" -File | ForEach-Object { $_.FullName })
        $cpArgs  = if ($Classpath) { @("-cp", $Classpath) } else { @() }
        & javac @cpArgs -d $tmpDir @sources 2>$errFile
    } else {
        $cpArgs = if ($Classpath) { @("-cp", $Classpath) } else { @() }
        & javac @cpArgs -d $tmpDir $JavaFile 2>$errFile
    }
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

    # Run with optional input/output redirection
    if ($InputFile -and $OutputFile) {
        & java -cp $cp $className < $InputFile | Tee-Object -FilePath $OutputFile
        $javaExit = $LASTEXITCODE
    } elseif ($InputFile) {
        & java -cp $cp $className < $InputFile
        $javaExit = $LASTEXITCODE
    } elseif ($OutputFile) {
        & java -cp $cp $className | Tee-Object -FilePath $OutputFile
        $javaExit = $LASTEXITCODE
    } else {
        & java -cp $cp $className
        $javaExit = $LASTEXITCODE
    }

    $sw.Stop()
    $elapsed = $sw.ElapsedMilliseconds

    Write-Host "───────────────────────────────────────────────────────────" -ForegroundColor Cyan
    if ($javaExit -ne 0) {
        Write-Host "[FAIL] Finished in ${elapsed}ms (exit code $javaExit)" -ForegroundColor Red
    } else {
        Write-Host "[ OK ] Finished in ${elapsed}ms" -ForegroundColor Green
        if ($OutputFile) { Write-Host "   Output saved to: $OutputFile" -ForegroundColor Cyan }
    }
    Write-Host ""

    Remove-Item -Recurse -Force $tmpDir
    return $javaExit
}

if ($Watch) {
    Write-Host "[WATCH] Watch mode enabled - save the file to rerun" -ForegroundColor Yellow

    $dir      = Split-Path $JavaFile -Parent
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
