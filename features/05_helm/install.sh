#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/../utils.sh"

HELM_VERSION=4.3.1

if check_command_version helm "$HELM_VERSION"; then
    echo "==> helm $HELM_VERSION already installed, skipping"
    exit 0
fi

# Prebuilt static binary from Helm's official download host. Helm publishes a
# `.sha256sum` sidecar next to each tarball (the GitHub release only carries
# signed .asc copies), so verification uses the sidecar.
ARCH="$(map_arch amd64 arm64)"
CACHE_KEY="helm/${HELM_VERSION}"
BASE="https://get.helm.sh"
ASSET="helm-v${HELM_VERSION}-linux-${ARCH}.tar.gz"

TMP_FOLDER=$(mktemp -d)
trap 'rm -rf "$TMP_FOLDER"' EXIT

install_from_release() {
    fetch_cached "$BASE/${ASSET}.sha256sum" "$CACHE_KEY/${ASSET}.sha256sum" "$TMP_FOLDER/${ASSET}.sha256sum"
    local expected
    expected=$(awk -v f="$ASSET" '$2 == f {print $1}' "$TMP_FOLDER/${ASSET}.sha256sum")
    [ -n "$expected" ] || { echo "ERROR: $ASSET missing from helm ${ASSET}.sha256sum" >&2; return 1; }

    fetch_cached "$BASE/$ASSET" "$CACHE_KEY/$ASSET" "$TMP_FOLDER/$ASSET" "$expected"

    tar -xzf "$TMP_FOLDER/$ASSET" -C "$TMP_FOLDER" --strip-components=1
    install_bin "$TMP_FOLDER/helm" helm
}

build_from_source() {
    if ! command -v go >/dev/null 2>&1; then
        bash "$(dirname "$0")/../00_go/install.sh"
    fi

    # get.helm.sh sits behind a CDN that some build networks cannot reach (the
    # dev-cluster dind bridge gets a connection timeout). The Go module proxy
    # uses different egress, so building the same tag keeps the bootstrap
    # working there. Set the version explicitly: `go install` does not inject
    # Helm's own ldflags and would otherwise report v4.3.
    mkdir -p "$TMP_FOLDER/bin"
    GOBIN="$TMP_FOLDER/bin" go install \
        -ldflags "-X helm.sh/helm/v4/internal/version.version=v${HELM_VERSION}" \
        "helm.sh/helm/v4/cmd/helm@v${HELM_VERSION}"
    install_bin "$TMP_FOLDER/bin/helm" helm
}

echo "==> Installing helm $HELM_VERSION..."

# A HEAD probe is cheaper than the retry ladder. Fall back to a source build
# when the host is unreachable, and also when the probe passes but the download
# still fails.
if curl -fsI --connect-timeout 5 --max-time 10 "$BASE/$ASSET" >/dev/null 2>&1 &&
    install_from_release; then
    :
else
    echo "WARN: $BASE is unreachable; building helm $HELM_VERSION from source" >&2
    build_from_source
fi

echo "==> helm $HELM_VERSION installed."
