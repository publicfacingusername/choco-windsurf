$ErrorActionPreference = 'Stop'
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$url        = 'https://windsurf-stable.codeiumdata.com/win32-x64-user/stable/b21eedafd0e27ae3d0a6e454346f7b02178f0949/WindsurfUserSetup-x64-1.7.1.exe'

$packageArgs = @{
  packageName   = $env:ChocolateyPackageName
  unzipLocation = $toolsDir
  fileType      = 'exe'
  url           = $url
  softwareName  = 'Windsurf*' #part or all of the Display Name as you see it in Programs and Features. It should be enough to be unique
  checksum      = 'FFB462C95818CC34503EB42AB094479501008AD6474CB2D5C6D2D757CB7CA661'
  checksumType  = 'sha256' #default is md5, can also be sha1, sha256 or sha512
  silentArgs    = "/VERYSILENT" # ALLUSERS=1 DISABLEDESKTOPSHORTCUT=1 ADDDESKTOPICON=0 ADDSTARTMENU=0
  validExitCodes= @(0, 3010, 1641)
}

Install-ChocolateyPackage @packageArgs # https://docs.chocolatey.org/en-us/create/functions/install-chocolateypackage
