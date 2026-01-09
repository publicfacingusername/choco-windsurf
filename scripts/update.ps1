$ErrorActionPreference = 'Stop'

$packageId = 'Codeium.Windsurf'
$repoRoot = Split-Path -Parent $PSScriptRoot

Write-Host "Checking latest release via winget package $packageId..."
$wingetData = winget show --id $packageId --exact --output json | ConvertFrom-Json
if (-not $wingetData.Versions) {
  throw "No versions found for $packageId."
}

$latest = $wingetData.Versions | Sort-Object { [version]$_.Version } -Descending | Select-Object -First 1
if (-not $latest) {
  throw "Unable to determine latest version for $packageId."
}

$installer = $latest.Installers | Where-Object { $_.Architecture -eq 'x64' -and $_.Scope -match 'user' } | Select-Object -First 1
if (-not $installer) {
  $installer = $latest.Installers | Where-Object { $_.Architecture -eq 'x64' } | Select-Object -First 1
}
if (-not $installer) {
  $installer = $latest.Installers | Select-Object -First 1
}
if (-not $installer) {
  throw "No installer found for version $($latest.Version)."
}

$version = $latest.Version
$url = $installer.InstallerUrl
if (-not $url) {
  throw "Installer URL missing for version $version."
}

$tempFile = Join-Path $env:TEMP "windsurf-$version.exe"
Write-Host "Downloading installer to compute checksum: $url"
$webHeaders = @{ 'User-Agent' = 'Mozilla/5.0' }
Invoke-WebRequest -Uri $url -OutFile $tempFile -Headers $webHeaders
$checksum = (Get-FileHash -Path $tempFile -Algorithm SHA256).Hash.ToUpperInvariant()
Remove-Item -Path $tempFile -ErrorAction SilentlyContinue

$nuspec = Get-ChildItem -Path $repoRoot -Filter 'windsurf.*.nuspec' | Select-Object -First 1
if (-not $nuspec) {
  throw 'No nuspec found to update.'
}

[xml]$nuspecXml = Get-Content -Path $nuspec.FullName
$nuspecXml.package.metadata.version = $version
$nuspecXml.Save($nuspec.FullName)

$newNuspecName = "windsurf.$version.nuspec"
$newNuspecPath = Join-Path $repoRoot $newNuspecName
if ($nuspec.Name -ne $newNuspecName) {
  Move-Item -Path $nuspec.FullName -Destination $newNuspecPath -Force
}

$installScriptPath = Join-Path $repoRoot 'tools/chocolateyinstall.ps1'
$installContent = Get-Content -Path $installScriptPath -Raw
$installContent = $installContent -replace "(?m)^\$url\s*=\s*'.*'\s*$", "\$url        = '$url'"
$installContent = $installContent -replace "(?m)^\s*checksum\s*=\s*'.*'\s*$", "  checksum      = '$checksum'"
Set-Content -Path $installScriptPath -Value $installContent -Encoding UTF8
