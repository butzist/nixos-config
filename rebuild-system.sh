#! /usr/bin/env bash

sudo nixos-rebuild switch --flake '.?submodules=1'
