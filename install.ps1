param(
  [Parameter(Mandatory = $true)]
  [string]$Version,
  [string]$Repository = 'carterw/trapeze-ssh-proxy',
  [string]$InstallPath = "$env:ProgramFiles\ioTrapeze\trapeze-ssh-proxy.exe"
)

$ErrorActionPreference = 'Stop'
$versionNumber = $Version.TrimStart('v')
$artifact = 'trapeze-ssh-proxy-windows-x64.exe'
$baseUrl = "https://github.com/$Repository/releases/download/v$versionNumber"
$tempDirectory = Join-Path ([IO.Path]::GetTempPath()) "trapeze-ssh-proxy-$([guid]::NewGuid())"

try {
  New-Item -ItemType Directory -Path $tempDirectory | Out-Null
  $artifactPath = Join-Path $tempDirectory $artifact
  $checksumPath = Join-Path $tempDirectory 'SHA256SUMS'

  Write-Output "Downloading trapeze-ssh-proxy $versionNumber ($artifact)..."
  Invoke-WebRequest "$baseUrl/$artifact" -OutFile $artifactPath
  Invoke-WebRequest "$baseUrl/SHA256SUMS" -OutFile $checksumPath

  Write-Output "Verifying checksum..."
  $checksumLine = Get-Content $checksumPath | Where-Object { $_ -match "  $([regex]::Escape($artifact))$" }
  if (-not $checksumLine) { throw "Checksum for $artifact was not found." }
  $expected = ($checksumLine -split '\s+')[0].ToLowerInvariant()
  $actual = (Get-FileHash $artifactPath -Algorithm SHA256).Hash.ToLowerInvariant()
  if ($actual -ne $expected) { throw 'SSH proxy checksum verification failed.' }

  $installDirectory = Split-Path $InstallPath -Parent
  New-Item -ItemType Directory -Force -Path $installDirectory | Out-Null
  $stagedPath = "$InstallPath.new"
  Copy-Item $artifactPath $stagedPath -Force
  Move-Item $stagedPath $InstallPath -Force
  & $InstallPath --version

  Write-Output ""
  Write-Output "Installed trapeze-ssh-proxy $versionNumber at $InstallPath"
  Write-Output ""
  Write-Output "Add this to ~/.ssh/config:"
  Write-Output ""
  Write-Output "    Host *.morphites.com"
  Write-Output "        ProxyCommand `"$InstallPath`" wss://%h/ws/ssh --token-env TRAPEZE_SSH_TOKEN"
  Write-Output ""
  Write-Output "Then generate a token from your controller dashboard and:"
  Write-Output '    $env:TRAPEZE_SSH_TOKEN = "your-token"'
  Write-Output "    ssh user@device.morphites.com"
} finally {
  Remove-Item $tempDirectory -Recurse -Force -ErrorAction SilentlyContinue
}
