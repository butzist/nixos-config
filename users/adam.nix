{pkgs, ...}: let
  sensitive = import ../secrets/users/adam/sensitive.nix;
in {
  home.username = "adam";
  home.homeDirectory = "/home/adam";

  imports = [
    ../modules/home/base.nix
    ../modules/home/nushell.nix
    ../modules/home/neovim
    ../modules/home/hyprland.nix
    ../modules/home/waybar
    ../modules/home/development.nix
    ../themes/everforest-kingdoms.nix
  ];

  # Packages that should be installed to the user profile.
  home.packages = with pkgs; [
    androidStudioPackages.beta
    android-tools
    _security.brave
    _security.firefox
    _stable.freecad
    kicad
    kicadAddons.kikit
    easyeda2kicad
    _stable.inkscape
    orca-slicer
    gimp3-with-plugins
    _stable.pulseview
    sigrok-cli
    sigrok-firmware-fx2lafw
  ];

  # basic configuration of git, please change to your own
  programs = {
    git = {
      settings = {
        user = {
          inherit (sensitive) name;
          inherit (sensitive) email;
        };
      };
    };

    bash = {
      enable = true;
    };
  };

  # This value determines the home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update home Manager without changing this value. See
  # the home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "24.05";
}
