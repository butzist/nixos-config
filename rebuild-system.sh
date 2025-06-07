#! /usr/bin/env bash

sudo nixos-rebuild switch --show-trace --flake '.?submodules=1'
