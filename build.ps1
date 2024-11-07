
$OutputFolder = "./content/docs"
$ModuleName = "Devolutions.PowerShell"

Remove-Item $OutputFolder -Recurse -ErrorAction SilentlyContinue -Force | Out-Null

Import-Module $ModuleName

Get-Command -Module $ModuleName -CommandType Cmdlet | ForEach-Object {
	$CommandHelp = New-CommandHelp $_
    #$CommandHelp.Metadata['date'] = (Get-Date $CommandHelp.Metadata['ms.date'] -Format 'yyyy-MM-dd').ToString()
    $CommandHelp.Metadata['date'] = (Get-Date -Format 'yyyy-MM-dd').ToString()
    $CommandHelp.RelatedLinks | ForEach-Object { $_.Uri = "/docs/$($_.LinkText)" }
    #$CommandHelp.RelatedLinks | ForEach-Object { $_.Uri = "@/docs/$($_.LinkText).md" }
    #$CommandHelp.RelatedLinks += [PSCustomObject]@{ Uri = $ModuleName; LinkText = $ModuleName }
    $CommandHelp.Inputs | Where-Object { $_.Description.Contains("{{ Fill") } | ForEach-Object { $_.Description = "" }
    $CommandHelp.Outputs | Where-Object { $_.Description.Contains("{{ Fill") } | ForEach-Object { $_.Description = "" }
    if ($CommandHelp.Synopsis -and $CommandHelp.Synopsis.Contains('Fill ')) {
        $CommandHelp.Synopsis = ""
    }
	Export-MarkdownCommandHelp -CommandHelp $CommandHelp -OutputFolder $OutputFolder -Force
}

Get-Item "$OutputFolder/$ModuleName/*.md" | ForEach-Object {
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
Set-Content -Path "$OutputFolder/$ModuleName/_index.md" -Value $content -Force

Move-Item ".\$OutputFolder\$ModuleName\*" $OutputFolder
Remove-Item ".\$OutputFolder\$ModuleName"
