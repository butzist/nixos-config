# Kispi staircase theme: the fetched wallpaper paired with rose-pine-moon.
# Kept separate from Bosque so hosts that still use Bosque are unaffected.
{pkgs, ...}: let
  mkTheme = import ./mk-theme.nix;
  kispiWallpaper = import ../wallpapers/kispi-staircase.nix {inherit pkgs;};
in
  mkTheme {
    base16Scheme = "${pkgs.base16-schemes}/share/themes/rose-pine-moon.yaml";
    image = "${kispiWallpaper}";
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
      desktop = 0.7;
    };

    iconTheme = {
      package = pkgs.adwaita-icon-theme;
      name = "Adwaita";
    };
  }
