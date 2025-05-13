$ErrorActionPreference = 'Stop'
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$url        = 'https://windsurf-stable.codeiumdata.com/win32-x64-user/stable/059f29a353ceb14e3fdd2012438042e67a7dde5b/WindsurfUserSetup-x64-1.6.4.exe'

$packageArgs = @{
  packageName   = $env:ChocolateyPackageName
  unzipLocation = $toolsDir
  fileType      = 'exe'
  url           = $url
  softwareName  = 'Windsurf*' #part or all of the Display Name as you see it in Programs and Features. It should be enough to be unique
  checksum      = 'F9D0965BBEC507ACF99D4F037374E96D19CBD679263ED3E6DF485BF0A3B2C2B5'
  checksumType  = 'sha256' #default is md5, can also be sha1, sha256 or sha512
  silentArgs    = "/VERYSILENT" # ALLUSERS=1 DISABLEDESKTOPSHORTCUT=1 ADDDESKTOPICON=0 ADDSTARTMENU=0
  validExitCodes= @(0, 3010, 1641)
}

Install-ChocolateyPackage @packageArgs # https://docs.chocolatey.org/en-us/create/functions/install-chocolateypackage
