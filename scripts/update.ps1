$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$platform = 'win32-x64-user'
$channel = 'stable'
$api = "https://windsurf-stable.codeium.com/api/update/$platform/$channel/latest"

Write-Host "Fetching latest release metadata: $api"
$meta = Invoke-RestMethod -Uri $api
$url = $meta.url
$version = $meta.windsurfVersion
$expectedSha = $meta.sha256hash
if (-not $version) {
  $version = $meta.productVersion
}
if (-not $url) {
  throw 'Installer URL missing from update metadata.'
}
if (-not $version) {
  throw 'Version missing from update metadata.'
}
if (-not $expectedSha) {
  throw 'SHA256 checksum missing from update metadata.'
}
Write-Host "Found Windows installer URL: $url"
Write-Host "Latest version detected: $version"

$out = Join-Path $env:TEMP ("WindsurfUserSetup-x64-$version.exe")
Write-Host "Downloading installer to compute checksum: $url"
Invoke-WebRequest -Uri $url -OutFile $out
$actualSha = (Get-FileHash -Algorithm SHA256 -Path $out).Hash.ToLowerInvariant()
if ($actualSha -ne $expectedSha.ToLowerInvariant()) {
  throw "SHA256 mismatch. Expected $expectedSha got $actualSha"
}
Remove-Item -Path $out -ErrorAction SilentlyContinue

$checksum = $expectedSha.ToUpperInvariant()

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
$installContent = $installContent -replace '(?m)^\$url\s*=\s*''.*''\s*$', "\$url        = '$url'"
$installContent = $installContent -replace '(?m)^\s*checksum\s*=\s*''.*''\s*$', "  checksum      = '$checksum'"
Set-Content -Path $installScriptPath -Value $installContent -Encoding UTF8
