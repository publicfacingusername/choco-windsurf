$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$releaseBaseUrl = 'https://windsurf-stable.codeiumdata.com/win32-x64-user/stable'
$latestManifestUrl = "$releaseBaseUrl/latest.yml"

Write-Host "Fetching latest release manifest: $latestManifestUrl"
$webHeaders = @{ 'User-Agent' = 'Mozilla/5.0' }
$manifestResponse = Invoke-WebRequest -Uri $latestManifestUrl -Headers $webHeaders
$manifestContent = $manifestResponse.Content

$versionMatch = [regex]::Match($manifestContent, "(?m)^version:\\s*(.+)$")
if (-not $versionMatch.Success) {
  throw 'Unable to determine latest version from latest.yml.'
}
$version = $versionMatch.Groups[1].Value.Trim()

$pathMatch = [regex]::Match($manifestContent, "(?m)^\\s*(path|url):\\s*(.+)$")
if (-not $pathMatch.Success) {
  throw 'Unable to determine installer path from latest.yml.'
}
$pathValue = $pathMatch.Groups[2].Value.Trim()
$url = if ($pathValue -match '^https?://') {
  $pathValue
} else {
  "$releaseBaseUrl/$pathValue"
}

if (-not $url) {
  throw "Installer URL missing for version $version."
}

$tempFile = Join-Path $env:TEMP "windsurf-$version.exe"
Write-Host "Downloading installer to compute checksum: $url"
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
