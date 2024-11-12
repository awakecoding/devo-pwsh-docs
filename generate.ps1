
$ModuleName = "Devolutions.PowerShell"

$VersionList = @("2024.3.5", "2024.3.4", "2024.3.3")
$LatestVersion = $VersionList[0]

function Build-ZolaVersionedDocs {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string[]] $VersionList,

        [Parameter(Mandatory = $true)]
        [string] $ModuleName
    )

    foreach ($Version in $VersionList) {
        Remove-Item -Path "./content" -Recurse -ErrorAction SilentlyContinue -Force | Out-Null

        Write-Host "Generating content for $ModuleName version $Version"
        pwsh .\build.ps1 -Version $Version -OutputPath "./content/cmdlet"

        $VersionOutputPath = "$StaticOutputPath/$ModuleName/$Version"
        Remove-Item -Path $VersionOutputPath -Recurse -ErrorAction SilentlyContinue -Force | Out-Null

        Write-Host "Generating Zola site for $ModuleName version $Version"
        zola build -o $VersionOutputPath -u "/$ModuleName/$Version/"
    }
}

function Build-ZolaTopLevelSite {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $LatestVersion,

        [Parameter(Mandatory = $true)]
        [string[]] $VersionList,

        [Parameter(Mandatory = $true)]
        [string] $ModuleName,

        [string] $ConfigFilePath = ".\top-level\config.toml"
    )

    Copy-Item -Path "$ConfigFilePath.bak" -Destination $ConfigFilePath -Force | Out-Null

    $versionArray = ($VersionList | ForEach-Object { '    "' + $_ + '"' }) -join ",`n"

    $extraSection = @"
[extra]
module = "$ModuleName"
latest = "$LatestVersion"
versions = [
$versionArray
]
"@.Trim()

    $configContent = (Get-Content -Path $ConfigFilePath -Raw).TrimEnd()
    $configContent = $configContent -replace '\[extra\][\s\S]*?(?=^\[|\Z)', ''
    $configContent += $extraSection
    Set-Content -Path $ConfigFilePath -Value $configContent

	Write-Host "Generating top-level Zola site for $ModuleName"
	Remove-Item -Path "./www" -Recurse -ErrorAction SilentlyContinue -Force | Out-Null
    Set-Location "top-level"
    zola build -o "../www" -u "/"
    Set-Location ".."
}

#Build-ZolaVersionedDocs -VersionList $VersionList -ModuleName $ModuleName
Build-ZolaTopLevelSite -LatestVersion $LatestVersion -VersionList $VersionList -ModuleName $ModuleName
