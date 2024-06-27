{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs; [
    fira-code-nerdfont
    ubuntu_font_family
    liberation_ttf
  ];

  fonts = {
    fontconfig = {
      enable = true;
      defaultFonts = {
        serif = [ "Liberation Serif" ];
        sansSerif = [ "Ubuntu" ];
        monospace = [ "FiraCode Nerd Font" ];
      };
    };
  };
}
