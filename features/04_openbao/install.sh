#!/bin/bash

source "$(dirname "$0")/../utils.sh"

OPENBAO_VERSION=2.6.1

if check_command_version bao "$OPENBAO_VERSION"; then
    echo "==> openbao $OPENBAO_VERSION already installed, skipping"
    exit 0
fi

TMP_FOLDER=$(mktemp -d)
cd "$TMP_FOLDER"

curl -LO "https://github.com/openbao/openbao/releases/download/v${OPENBAO_VERSION}/openbao_${OPENBAO_VERSION}_linux_amd64.tar.gz"
curl -LO "https://github.com/openbao/openbao/releases/download/v${OPENBAO_VERSION}/checksums.txt"

sha256sum --ignore-missing --check checksums.txt

tar -xzf "openbao_${OPENBAO_VERSION}_linux_amd64.tar.gz"

cp bao /usr/local/bin/

rm -rf "$TMP_FOLDER"