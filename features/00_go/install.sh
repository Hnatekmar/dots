#!/bin/bash

source "$(dirname "$0")/../utils.sh"

GO_VERSION=1.26.5

if check_command_version go "$GO_VERSION"; then
    echo "==> go $GO_VERSION already installed, skipping"
    exit 0
fi

rm -rf /usr/local/go

TMP_FOLDER=$(mktemp -d)

cd $TMP_FOLDER

curl -LO https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz

tar -xzf go${GO_VERSION}.linux-amd64.tar.gz -C /usr/local
