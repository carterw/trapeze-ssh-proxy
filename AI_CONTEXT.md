# trapeze-ssh-proxy — AI Context Document

> This document is intended for AI assistants. It provides a compact, structured
> description of the trapeze-ssh-proxy project so an AI can quickly understand
> its purpose, architecture, installation, and usage without reading every file.

## Project Identity

- **Name**: trapeze-ssh-proxy
- **Repository**: `github.com/carterw/trapeze-ssh-proxy`
- **License**: Proprietary (see LICENSE)
- **Version**: 0.1.0
- **Language**: JavaScript (Node.js 22 SEA — Single Executable Application)
- **Distribution**: GitHub Releases with SHA-256 checksum verification

## Purpose

A native OpenSSH `ProxyCommand` helper for the ioTrapeze reverse-proxy system.
It bridges standard OpenSSH to a device's SSH daemon over WebSocket Secure
(WSS) on port 443, allowing operators to SSH into devices behind CGNAT,
cellular networks, or restrictive firewalls without exposing inbound ports.

## Architecture

```
Operator's SSH client
  → trapeze-ssh-proxy (ProxyCommand)
  → WSS connection to controller on port 443 (/ws/ssh)
  → Controller validates operator token (HMAC, short-lived, device-scoped)
  → Controller forwards SSH stream through reverse tunnel to edge client
  → Edge client connects stream to device's local sshd on port 22
  → Device sshd performs normal key/password authentication
```

Key design points:
- The proxy speaks **plain SSH bytes** over a WebSocket Secure connection.
- The controller token is **not** the device SSH credential — it only
  authorizes the WSS upgrade. The device's `sshd` performs its own auth.
- The proxy stores **no tokens, keys, or credentials**. The token is read
  from an environment variable at connection time.

## Installation

### Linux (x64 / ARM64)

```bash
curl -sSL https://github.com/carterw/trapeze-ssh-proxy/raw/main/install.sh | bash -s -- --version 0.1.0
```

Installs to `/usr/local/bin/trapeze-ssh-proxy` (requires root or `--install-path`).

### Windows (PowerShell, as Administrator)

```powershell
& ([scriptblock]::Create((irm https://github.com/carterw/trapeze-ssh-proxy/raw/main/install.ps1))) -Version 0.1.0
```

Installs to `C:\Program Files\ioTrapeze\trapeze-ssh-proxy.exe`.

For user-writable install (no admin):

```powershell
& ([scriptblock]::Create((irm https://github.com/carterw/trapeze-ssh-proxy/raw/main/install.ps1))) -Version 0.1.0 -InstallPath "$env:LOCALAPPDATA\ioTrapeze\trapeze-ssh-proxy.exe"
```

### Supported Platforms

| Artifact | Platform |
| :--- | :--- |
| `trapeze-ssh-proxy-windows-x64.exe` | Windows x64 |
| `trapeze-ssh-proxy-linux-x64` | Linux x64 |
| `trapeze-ssh-proxy-linux-arm64` | Linux ARM64 |

## Usage

### 1. Configure OpenSSH

Add to `~/.ssh/config` (Linux/Cygwin) or `C:\Users\<user>\.ssh\config` (Windows OpenSSH):

```sshconfig
Host *.morphites.com
    ProxyCommand /usr/local/bin/trapeze-ssh-proxy wss://%h/ws/ssh --token-env TRAPEZE_SSH_TOKEN
```

Windows path variant:

```sshconfig
Host *.morphites.com
    ProxyCommand "C:/Program Files/ioTrapeze/trapeze-ssh-proxy.exe" wss://%h/ws/ssh --token-env TRAPEZE_SSH_TOKEN
```

Replace `*.morphites.com` with the device domain suffix for your deployment.

### 2. Generate a temporary token

From the controller dashboard (e.g. `https://controller.morphites.com/admin/`),
open **Devices**, select **SSH token** for the target device. Tokens expire
after 15 minutes by default and are scoped to a single device.

Export in the terminal that will launch OpenSSH:

```bash
export TRAPEZE_SSH_TOKEN='copied-token'
```

PowerShell:

```powershell
$env:TRAPEZE_SSH_TOKEN = 'copied-token'
```

### 3. Connect

```bash
ssh bill@pi5A.morphites.com
```

## CLI Reference

```text
trapeze-ssh-proxy wss://<device>.<domain>/ws/ssh --token-env TRAPEZE_SSH_TOKEN
trapeze-ssh-proxy --version
trapeze-ssh-proxy --help
```

| Flag | Description |
| :--- | :--- |
| `wss://<url>` | WebSocket Secure endpoint (required for proxy mode) |
| `--token-env <VAR>` | Environment variable name containing the SSH token |
| `--version` | Print version and exit |
| `--help` | Print help and exit |

## Prerequisites

- An ioTrapeze controller running at a public HTTPS hostname.
- A device registered with the controller and connected via reverse tunnel.
- An operator account on the controller dashboard (admin role to issue SSH tokens).
- OpenSSH installed on the operator's machine.

## Troubleshooting

| Symptom | Cause | Fix |
| :--- | :--- | :--- |
| `Permission denied (publickey)` + `ssh -v` shows `Connecting to <host> port 22` | ProxyCommand not configured; connecting directly to controller host sshd | Add ProxyCommand entry to the correct `~/.ssh/config` file |
| `upgrade rejected with HTTP 401 Unauthorized` | Token missing, expired, or not exported | Generate fresh token and `export TRAPEZE_SSH_TOKEN=...` |
| `upgrade rejected with HTTP 404 Not Found` | Device ID typo or device not registered | Verify device ID and controller database |
| `Permission denied (publickey)` through tunnel but works on LAN | Device sshd doesn't recognize operator's key | Add operator's public key to device `~/.ssh/authorized_keys` |
| Windows OpenSSH ignores Cygwin config | Separate config files | Add ProxyCommand to `C:\Users\<user>\.ssh\config` separately |

## Security Model

- Operator token: HMAC-signed, short-lived (15 min default), device-scoped.
- The proxy does not store or persist any credentials.
- The device's `sshd` performs its own authentication independently.
- Windows release artifacts are Authenticode-signed; the installer refuses
  unsigned releases.
- SHA-256 checksum verification on every install.

## Relationship to Other Projects

- **proxycontroller** (private repo): The controller server that manages
  devices, operator accounts, reverse tunnels, nginx config, and the WSS
  `/ws/ssh` endpoint. This proxy is a client of that controller.
- **ioTrapeze ecosystem**: The broader IoT reverse-proxy system providing
  stable public hostnames (`device.domain.com`) for devices behind CGNAT,
  cellular, or restrictive networks.

## File Layout

```
trapeze-ssh-proxy/
├── .github/workflows/release.yml   # CI: build native artifacts on tag push
├── .gitattributes                   # LFS tracking for binaries
├── .gitignore
├── LICENSE                          # Proprietary
├── README.md                        # User-facing documentation
├── AI_CONTEXT.md                    # This file
├── install.sh                       # Linux installer (curl | bash)
├── install.ps1                      # Windows installer (PowerShell)
├── SHA256SUMS                       # Release checksums
└── trapeze-ssh-proxy-windows-x64.exe  # Windows binary (Git LFS)
```
