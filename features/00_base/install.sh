#!/bin/bash

rm -rf ~/.bash_profile

cd dotfiles
stow -t $HOME -R base
