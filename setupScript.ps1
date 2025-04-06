Set-ItemProperty -Path HKCU:\software\microsoft\windows\currentversion\explorer\advanced -Name 'TaskbarAl' -Type 'DWord' -Value 0 #Start Menu to the left
New-Item -Path 'HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32' -Force | Out-Null
New-ItemProperty -Path 'HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32' -Name '(default)' -Value '' -PropertyType String -Force # Disable Windows 11 context menu


# List of packages to install

$packages = @(

	"Microsoft.WindowsTerminal",
	"Mozilla.Firefox",
	"Google.GoogleDrive",
	"7zip.7zip",
	"Notepad++.Notepad++",
	"Dell.CommandUpdate.Universal",
	"Logitech.GHUB",
	"Valve.Steam",
	"Proton.ProtonVPN",
	"OpenWhisperSystems.Signal",
	"Microsoft.VisualStudioCode",
	"9NT1R1C2HH7J" #ChatGPT
	"GitHub.GitHubDesktop"
	"Bitvise.SSH.Client"

)

# Loop through each package and install it with necessary flags

foreach ($package in $packages) {

	Write-Output "Installing $package..."

	winget install -e --id $package --accept-source-agreements --silent

}

Write-Output "All installations completed!"
Read-Host -Prompt "Press Enter to exit"

