{ config, pkgs, ... }:

{
  home.username = "adam";
  home.homeDirectory = "/home/adam";

  stylix.enable = true;
  stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-hard.yaml";
  stylix.image = ../wallpapers/ubuntu.png;
  stylix.polarity = "dark";
  
  stylix.cursor = {
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 16;
  };

  stylix.fonts = {
    serif = {
      package = pkgs.liberation_ttf;
      name = "Liberation Serif";
    };

    sansSerif = {
      package = pkgs.ubuntu_font_family;
      name = "Ubuntu";
    };

    monospace = {
      package = pkgs.fira-code-nerdfont;
      name = "FiraCode Nerd Font";
    };
  };

  stylix.opacity = {
    terminal = 0.5;
  };
}

