param (
    [string] $Version = "latest",
    [string] $ModuleName = "Devolutions.PowerShell",
    [string] $OutputPath = "./content/cmdlet"
)

$LatestVersion = (Find-Module -Name $ModuleName).Version

if ($Version -eq "latest") {
    $Version = $LatestVersion
}

$Module = Get-Module $ModuleName -ListAvailable | Where-Object { $_.Version -eq $Version }

if (-Not $Module) {
    Write-Host "Installing $ModuleName version $Version"
    Install-Module -Name $ModuleName -RequiredVersion $Version -Scope CurrentUser -Force
}

$ModuleInfo = Find-Module -Name $ModuleName -RequiredVersion $Version
$PublishedDate = $ModuleInfo.PublishedDate

Import-Module $ModuleName -RequiredVersion $Version -Force

Remove-Item $OutputPath -Recurse -ErrorAction SilentlyContinue -Force | Out-Null

Get-Command -Module $ModuleName -CommandType Cmdlet | ForEach-Object {
	$CommandHelp = New-CommandHelp $_
    $CommandHelp.Metadata['date'] = $PublishedDate.ToString("yyyy-MM-dd")
    $CommandHelp.RelatedLinks | ForEach-Object { $_.Uri = "/docs/$($_.LinkText)" }
    $CommandHelp.Inputs | Where-Object { $_.Description.Contains("{{ Fill") } | ForEach-Object { $_.Description = "" }
    $CommandHelp.Outputs | Where-Object { $_.Description.Contains("{{ Fill") } | ForEach-Object { $_.Description = "" }
    if ($CommandHelp.Synopsis -and $CommandHelp.Synopsis.Contains('Fill ')) {
        $CommandHelp.Synopsis = ""
    }
	Export-MarkdownCommandHelp -CommandHelp $CommandHelp -OutputFolder $OutputPath -Force | Out-Null
}

Get-Item "$OutputPath/$ModuleName/*.md" | ForEach-Object {
    $filePath = $_.FullName
    $content = Get-Content -Path $filePath -Raw
    $content = $content -replace '\{\{Insert list of aliases\}\}', ''
    $content = $content -replace '\{\{ Fill in the related links here \}\}', ''
    Set-Content -Path $filePath -Value $content
}

$content = @"
+++
title = "$ModuleName"
sort_by = "title"
template = "cmdlet.html"
page_template = "cmdlet-page.html"
+++
"@
Set-Content -Path "$OutputPath/$ModuleName/_index.md" -Value $content -Force

Move-Item ".\$OutputPath\$ModuleName\*" $OutputPath | Out-Null
Remove-Item ".\$OutputPath\$ModuleName" | Out-Null
