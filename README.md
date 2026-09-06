# trapeze-ssh-proxy

A native OpenSSH `ProxyCommand` helper for [ioTrapeze](https://github.com/carterw/proxycontroller) reverse-proxy tunnels. It bridges standard OpenSSH to a device's SSH daemon over WebSocket Secure (WSS) on port 443, so operators can SSH into devices behind CGNAT, cellular networks, or restrictive firewalls without exposing inbound ports.

## Single-line install

### Linux (x64 / ARM64)

```bash
curl -sSL https://github.com/carterw/trapeze-ssh-proxy/raw/main/install.sh | bash -s -- --version 0.1.0
```

### Windows (PowerShell, as Administrator)

```powershell
irm https://github.com/carterw/trapeze-ssh-proxy/raw/main/install.ps1 | iex -Version 0.1.0
```

The installer downloads the native executable for your platform, verifies its SHA-256 checksum, installs it, and prints the `~/.ssh/config` snippet.

## What it does

```
OpenSSH -> trapeze-ssh-proxy -> WSS /ws/ssh on controller -> reverse tunnel -> device sshd:22
```

The proxy speaks plain SSH bytes over a WebSocket Secure connection. The controller validates a short-lived operator token before opening the tunnel, then the device's `sshd` performs normal key or password authentication.

## Prerequisites

- An ioTrapeze controller running and accessible at a public HTTPS hostname.
- A device registered with the controller and connected via reverse tunnel.
- An operator account on the controller dashboard (admin role required to issue SSH tokens).

## Usage

### 1. Configure OpenSSH

Add this to `~/.ssh/config`:

**Linux:**

```sshconfig
Host *.morphites.com
    ProxyCommand /usr/local/bin/trapeze-ssh-proxy wss://%h/ws/ssh --token-env TRAPEZE_SSH_TOKEN
```

**Windows:**

```sshconfig
Host *.morphites.com
    ProxyCommand "C:/Program Files/ioTrapeze/trapeze-ssh-proxy.exe" wss://%h/ws/ssh --token-env TRAPEZE_SSH_TOKEN
```

**Cygwin on Windows (locally-built executable):**

```sshconfig
Host *.morphites.com
    ProxyCommand X:/ioTrapeze/proxycontroller/dist/native/trapeze-ssh-proxy-windows-x64.exe wss://%h/ws/ssh --token-env TRAPEZE_SSH_TOKEN
```

Replace `*.morphites.com` with your device domain suffix if different.

### 2. Generate a temporary token

Sign into your controller dashboard (e.g. `https://controller.morphites.com/admin/`), open **Devices**, and select **SSH token** for the target device. Tokens expire after 15 minutes by default and are scoped to a single device.

Export the token in the terminal that will launch OpenSSH:

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

The controller validates the operator token and active device tunnel, then the edge client connects the stream to the local SSH daemon on port 22. The temporary controller token does not replace the device account's SSH key or password.

## Supported platforms

| Artifact | Platform |
| :--- | :--- |
| `trapeze-ssh-proxy-windows-x64.exe` | Windows x64 |
| `trapeze-ssh-proxy-linux-x64` | Linux x64 |
| `trapeze-ssh-proxy-linux-arm64` | Linux ARM64 |

## CLI options

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

## Security

- The proxy does not store tokens, keys, or credentials.
- The operator token is short-lived (15 minutes default), HMAC-signed, and device-scoped.
- The device's `sshd` performs its own authentication independently.
- Windows release artifacts are Authenticode-signed; the installer refuses unsigned releases.

## License

Proprietary. See [LICENSE](LICENSE).
