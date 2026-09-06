#!/usr/bin/env bash
set -euo pipefail

VERSION=""
REPOSITORY="${GITHUB_REPOSITORY:-carterw/trapeze-ssh-proxy}"
INSTALL_PATH="${INSTALL_PATH:-/usr/local/bin/trapeze-ssh-proxy}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version|-v)
      VERSION="${2#v}"
      shift 2
      ;;
    --repository)
      REPOSITORY="$2"
      shift 2
      ;;
    --install-path)
      INSTALL_PATH="$2"
      shift 2
      ;;
    --help|-h)
      echo "Usage: install.sh --version <version> [--repository owner/repo] [--install-path path]"
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

if [ -z "$VERSION" ]; then
  echo "Error: --version is required." >&2
  exit 1
fi

case "$(uname -m)" in
  x86_64|amd64) ARTIFACT="trapeze-ssh-proxy-linux-x64" ;;
  aarch64|arm64) ARTIFACT="trapeze-ssh-proxy-linux-arm64" ;;
  *)
    echo "Error: unsupported architecture $(uname -m)." >&2
    exit 1
    ;;
esac

TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT
BASE_URL="https://github.com/${REPOSITORY}/releases/download/v${VERSION}"

echo "Downloading trapeze-ssh-proxy ${VERSION} (${ARTIFACT})..."
curl --fail --silent --show-error --location "${BASE_URL}/${ARTIFACT}" --output "${TEMP_DIR}/${ARTIFACT}"
curl --fail --silent --show-error --location "${BASE_URL}/SHA256SUMS" --output "${TEMP_DIR}/SHA256SUMS"

echo "Verifying checksum..."
(
  cd "$TEMP_DIR"
  grep "  ${ARTIFACT}$" SHA256SUMS | sha256sum --check --strict
)

install -m 0755 "${TEMP_DIR}/${ARTIFACT}" "${INSTALL_PATH}.new"
mv -f "${INSTALL_PATH}.new" "$INSTALL_PATH"
"$INSTALL_PATH" --version

echo ""
echo "Installed trapeze-ssh-proxy ${VERSION} at ${INSTALL_PATH}"
echo ""
echo "Add this to ~/.ssh/config:"
echo ""
echo "    Host *.morphites.com"
echo "        ProxyCommand ${INSTALL_PATH} wss://%h/ws/ssh --token-env TRAPEZE_SSH_TOKEN"
echo ""
echo "Then generate a token from your controller dashboard and:"
echo "    export TRAPEZE_SSH_TOKEN='your-token'"
echo "    ssh user@device.morphites.com"
