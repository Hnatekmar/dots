#!/bin/bash

cd dotfiles/

stow -t $HOME -R crush

CRUSH_VERSION=v0.87.0

go install github.com/charmbracelet/crush@latest
