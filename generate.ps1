$ModuleName = "Devolutions.PowerShell"
@('2024.3.5','2024.3.4','2024.3.3') | ForEach-Object {
	$Version = $_
	Remove-Item "./content" -Recurse -ErrorAction SilentlyContinue -Force | Out-Null
	pwsh .\build.ps1 -Version $Version -OutputPath "./content/cmdlet"
	Remove-Item "www/$ModuleName/$Version" -Recurse -ErrorAction SilentlyContinue -Force | Out-Null
	zola build -o "www/$ModuleName/$Version" -u "/$ModuleName/$Version/"
}
