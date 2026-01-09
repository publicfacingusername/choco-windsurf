$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$downloadsPageUrl = 'https://windsurf.com/download/editor#all-download-options'

Write-Host "Fetching download options page: $downloadsPageUrl"
$webHeaders = @{ 'User-Agent' = 'Mozilla/5.0' }
$pageResponse = Invoke-WebRequest -Uri $downloadsPageUrl -Headers $webHeaders
$pageContent = $pageResponse.Content

$urlMatch = [regex]::Match($pageContent, '(?i)https?://[^\"\\s>]+WindsurfUserSetup[^\"\\s>]*\\.exe')
if (-not $urlMatch.Success) {
  $urlMatch = [regex]::Match($pageContent, '(?i)https?://[^\"\\s>]+win32[^\"\\s>]+\\.exe')
}
if (-not $urlMatch.Success) {
  throw 'Unable to determine Windows installer URL from download options page.'
}
$url = $urlMatch.Value

$versionMatch = [regex]::Match($url, '(?i)-(?<version>\\d+\\.\\d+\\.\\d+(?:\\.\\d+)?)\\.exe')
if (-not $versionMatch.Success) {
  throw 'Unable to determine version from installer URL.'
}
$version = $versionMatch.Groups['version'].Value

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
