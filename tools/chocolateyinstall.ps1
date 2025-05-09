﻿$ErrorActionPreference = 'Stop'
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$url        = 'https://windsurf-stable.codeiumdata.com/win32-x64-user/stable/71eeb18eeed7897bea630fcaba7d37c49c78b05e/WindsurfUserSetup-x64-1.7.3.exe'

$packageArgs = @{
  packageName   = $env:ChocolateyPackageName
  unzipLocation = $toolsDir
  fileType      = 'exe'
  url           = $url
  softwareName  = 'Windsurf*' #part or all of the Display Name as you see it in Programs and Features. It should be enough to be unique
  checksum      = 'FB8649E59605153514D0FB4ECEA6B85F3BBF4D6A9D0975551AE352EEABEB5306'
  checksumType  = 'sha256' #default is md5, can also be sha1, sha256 or sha512
  silentArgs    = "/VERYSILENT" # ALLUSERS=1 DISABLEDESKTOPSHORTCUT=1 ADDDESKTOPICON=0 ADDSTARTMENU=0
  validExitCodes= @(0, 3010, 1641)
}

Install-ChocolateyPackage @packageArgs # https://docs.chocolatey.org/en-us/create/functions/install-chocolateypackage
