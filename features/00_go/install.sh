#!/bin/bash

rm -rf /usr/local/go
GO_VERSION=1.26.5

TMP_FOLDER=$(mktemp -d)

cd $TMP_FOLDER

curl -LO https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz

tar -xzf go${GO_VERSION}.linux-amd64.tar.gz -C /usr/local
