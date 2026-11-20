# Everforest theme. One settings attrset feeds both the NixOS system module
# (used by the greeter) and the home-manager module (used by the shell).
{pkgs, ...}: let
  mkTheme = import ./mk-theme.nix;
in
  mkTheme {
    base16Scheme = "${pkgs.base16-schemes}/share/themes/everforest.yaml";
    image = ../wallpapers/everforest-2.png;
    polarity = "dark";

    cursor = {
      package = pkgs.banana-cursor;
      name = "Banana";
      size = 28;
    };

    fonts = {
      serif = {
        package = pkgs.liberation_ttf;
        name = "Liberation Serif";
      };

      sansSerif = {
        package = pkgs.ubuntu-classic;
        name = "Ubuntu";
      };

      monospace = {
        package = pkgs.nerd-fonts.fira-code;
        name = "FiraCode Nerd Font";
      };
    };

    opacity = {
      terminal = 0.9;
      applications = 0.9;
    };

    iconTheme = {
      package = pkgs.adwaita-icon-theme;
      name = "Adwaita";
    };
  }
