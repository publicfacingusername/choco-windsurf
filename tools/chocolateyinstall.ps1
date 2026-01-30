$ErrorActionPreference = 'Stop'
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$url        = 'https://windsurf-stable.codeiumdata.com/win32-x64-user/stable/5c2968103bdb09ce4f81ebbeacebb15ed409feed/WindsurfUserSetup-x64-1.13.14.exe'
$packageArgs = @{
  packageName   = $env:ChocolateyPackageName
  unzipLocation = $toolsDir
  fileType      = 'exe'
  url           = $url
  softwareName  = 'Windsurf*'
  checksum      = 'B43EBFB48BB136EA1BC22D191AA74C49847D48EBB9ACCDD7F8AF574F3C00DB5E'
  checksumType  = 'sha256'
  silentArgs    = "/VERYSILENT"
  validExitCodes= @(0, 3010, 1641)
}

Install-ChocolateyPackage @packageArgs # https://docs.chocolatey.org/en-us/create/functions/install-chocolateypackage



































































