#!/usr/bin/env bash

home-manager expire-generations "0 days"
sudo nix-collect-garbage -d
nix-collect-garbage -d
