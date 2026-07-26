#!/bin/bash

GO_VERSION=1.26.5

CURRENT_FOLDER=$(pwd)
TMP_FOLDER=$(mktemp -d)

DNF_PACKAGES=(git stow)

# Base env + preparation
stow -R base

dnf install -y $DNF_PACKAGES

cd $TMP_FOLDER

curl -LO https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz

rm -rf /usr/local/go
tar -xzf go${GO_VERSION}.linux-amd64.tar.gz -C /usr/local

rm -rf $TMP_FOLDER

export PATH=$PATH:/usr/local/go/bin:~/go/bin

# Install go software
go install github.com/charmbracelet/gum@latest
go install github.com/charmbracelet/crush@latest
