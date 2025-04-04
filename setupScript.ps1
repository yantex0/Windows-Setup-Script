Set-ItemProperty -Path HKCU:\software\microsoft\windows\currentversion\explorer\advanced -Name 'TaskbarAl' -Type 'DWord' -Value 0 #Start Menu to the left



# List of packages to install

$packages = @(

	"Microsoft.WindowsTerminal",

	"Mozilla.Firefox",

  "Google.GoogleDrive",

  "7zip.7zip",

  "Notepad++.Notepad+",

	"Dell.CommandUpdate.Universal",

	"Logitech.GHUB",

	"Valve.Steam",

	"Proton.ProtonVPN",

	"OpenWhisperSystems.Signal",

	"GlavSoft.TightVNC",

	"Microsoft.VisualStudioCode",

	"XPDM1ZW6815MQM", #VLC

	"9NT1R1C2HH7J" #ChatGPT

)



# Loop through each package and install it with necessary flags

foreach ($package in $packages) {

    Write-Output "Installing $package..."

    winget install -e --id $package --accept-source-agreements --silent

}



Write-Output "All installations completed!"

Read-Host -Prompt "Press Enter to exit"

