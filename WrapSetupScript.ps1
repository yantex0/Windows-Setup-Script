$SourceScriptPath = Join-Path $PSScriptRoot "setupScript.ps1"
$OutputScriptPath = Join-Path $PSScriptRoot "GeneratedFreshImage-ScriptCreation.ps1"

# Step 1: define header, carefully breaking up the nested here-string start delimiter
$header = @'
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

'@

# Step 2: read original content
$originalContent = Get-Content -Path $SourceScriptPath -Raw

# Step 3: define footer with nested here-string close and rest of code
$footer = @'

# Save the installer script
$null = $installerScriptContent
Set-Content -Path $installerScriptPath -Value $installerScriptContent -Force -Encoding UTF8

Write-Output "Installer script created at: $installerScriptPath"

# Run the installer script
Start-Process powershell "-ExecutionPolicy Bypass -File `"$installerScriptPath`"" -Verb RunAs
'@

# Step 4: combine all parts into one big string to create final wrapped script
$combinedContent = $header + "@'" + "`n" + $originalContent + "`n" + "'@" + $footer

# Step 5: save the combined script somewhere, for example:
Set-Content -Path $OutputScriptPath -Value $combinedContent -Force -Encoding UTF8
