# Elevate if needed
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

# Define where to save the main installer script
$publicDesktopPath = "C:\Users\Public\Desktop"
$installerScriptPath = Join-Path $publicDesktopPath "setupScript.ps1"

# Define the script content
$installerScriptContent = 
@'
########################################
# Auto-elevate the script as Administrator
########################################

If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Script not running as administrator. Relaunching elevated..."
    Start-Process powershell "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

########################################
# Wait for explorer.exe to start
########################################

Write-Output "Waiting for Explorer (desktop) to fully load..."

$timeoutSeconds = 300  # Max total wait time (5 minutes)
$timer = [Diagnostics.Stopwatch]::StartNew()

while (-not (Get-Process explorer -ErrorAction SilentlyContinue)) {
    Start-Sleep -Seconds 2
    if ($timer.Elapsed.TotalSeconds -ge $timeoutSeconds) {
        Write-Warning "Timeout waiting for Explorer to load."
        break
    }
}

Write-Output "Explorer is running."

########################################
# Wait for network connectivity
########################################

Write-Output "Waiting for network connectivity..."

$timer.Restart()

while (-not (Test-Connection -ComputerName 8.8.8.8 -Count 1 -Quiet -ErrorAction SilentlyContinue)) {
    Start-Sleep -Seconds 3
    if ($timer.Elapsed.TotalSeconds -ge $timeoutSeconds) {
        Write-Warning "Timeout waiting for network. Proceeding anyway."
        break
    }
}

Write-Output "Network is available."

########################################
# Remove Microsoft Edge shortcut from Public Desktop
########################################

Write-Output "Checking for Microsoft Edge shortcut on Public Desktop..."

$edgeShortcutPath = "C:\Users\Public\Desktop\Microsoft Edge.lnk"

if (Test-Path $edgeShortcutPath) {
    Remove-Item -Path $edgeShortcutPath -Force
    Write-Output "Microsoft Edge shortcut removed from Public Desktop."
} else {
    Write-Output "Microsoft Edge shortcut not found. Nothing to remove."
}

Write-Output "##########################"
Write-Output ""

########################################
# Clean Taskbar Pins
########################################

Write-Output "Cleaning Taskbar Pins..."

function Unpin-AppFromTaskbar {
    param ([string]$AppName)

    $shell = New-Object -ComObject Shell.Application
    $folder = $shell.Namespace('shell:::{4234d49b-0245-4df3-b780-3893943456e1}')
    $item = $folder.Items() | Where-Object { $_.Name -eq $AppName }

    if ($item) {
        $verbs = $item.Verbs()
        foreach ($verb in $verbs) {
            if ($verb.Name.Replace('&amp;', '') -match 'Unpin from taskbar') {
                $verb.DoIt()
                Write-Output "Unpinned $AppName from Taskbar."
            }
        }
    } else {
        Write-Warning "$AppName not found on Taskbar."
    }
}

Start-Sleep -Seconds 5  # Give time for Taskbar to fully load

Unpin-AppFromTaskbar "Microsoft Edge"
Unpin-AppFromTaskbar "Microsoft Store"

Write-Output "Taskbar cleaned."
Write-Output "##########################"
Write-Output ""

########################################
# Install Applications
########################################

Write-Output "Starting application installation..."

# Define path to install log
$installLogPath = Join-Path -Path ([Environment]::GetFolderPath('Desktop')) -ChildPath 'install_log.txt'

# Clear existing log if it exists
if (Test-Path $installLogPath) {
    Remove-Item $installLogPath -Force
}

function Install-App {
    param (
        [string]$PackageId,
        [int]$Current,
        [int]$Total
    )

    Write-Output "[$Current/$Total] Installing $PackageId..."
    try {
        winget install --id $PackageId -e --accept-package-agreements --accept-source-agreements --silent
        Add-Content -Path $installLogPath -Value "SUCCESS - $PackageId"
        $global:successCount++
    } catch {
        Write-Warning "Failed to install $PackageId"
        Add-Content -Path $installLogPath -Value "FAILURE - $PackageId"
        $global:failureCount++
    }
}

$packages = @(
    "Microsoft.WindowsTerminal",
    "Brave.Brave",
	"Microsoft.PowerShell",
	"Git.Git",
    "Google.GoogleDrive",
    "7zip.7zip",
    "Notepad++.Notepad++",
    "Dell.CommandUpdate.Universal",
    "Logitech.GHUB",
    "Valve.Steam",
    "Proton.ProtonVPN",
    "OpenWhisperSystems.Signal",
    "Microsoft.VisualStudioCode",
    "9NT1R1C2HH7J",  # ChatGPT Desktop
    "GitHub.GitHubDesktop",
    "Bitvise.SSH.Client",
	"Debian.Debian"
)

# Start timing
$installStart = Get-Date

# Track success/failure counts
$successCount = 0
$failureCount = 0


$totalPackages = $packages.Count
$currentPackage = 1

foreach ($package in $packages) {
    Install-App -PackageId $package -Current $currentPackage -Total $totalPackages
    $currentPackage++
}

# End timing
$installEnd = Get-Date
$installDuration = $installEnd - $installStart

Write-Output ""
Write-Output "##########################"
Write-Output "Installation Summary:"
Write-Output "Successful installs: $successCount"
Write-Output "Failed installs: $failureCount"
Write-Output "Total install time: $($installDuration.ToString())"
Write-Output "##########################"

# Write summary to a second file
$summaryPath = Join-Path -Path ([Environment]::GetFolderPath('Desktop')) -ChildPath 'install_summary.txt'

$summaryContent = @"
Installation Summary:
Successful installs: $successCount
Failed installs: $failureCount
Total install time: $($installDuration.ToString())
"@

Set-Content -Path $summaryPath -Value $summaryContent -Force

########################################
# Disable Local Admin
########################################

Disable-LocalUser -Name "Administrator"

########################################
# Creating Outputs
########################################

Write-Output "Restarting Explorer..."
Stop-Process -Name explorer -Force
Start-Process explorer

# Open the install log
Start-Process notepad.exe $installLogPath

# Open the summary
Start-Process notepad.exe $summaryPath
'@
# Save the installer script
$null = $installerScriptContent
Set-Content -Path $installerScriptPath -Value $installerScriptContent -Force -Encoding UTF8

Write-Output "Installer script created at: $installerScriptPath"

# Run the installer script
Start-Process powershell "-ExecutionPolicy Bypass -File `"$installerScriptPath`"" -Verb RunAs
