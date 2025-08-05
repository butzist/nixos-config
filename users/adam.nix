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
    ../themes/ubuntu-catppuccin.nix
  ];

  # Packages that should be installed to the user profile.
  home.packages = with pkgs; [
    androidStudioPackages.beta
    brave
    firefox
    freecad
    inkscape
    stable.orca-slicer
    gimp3-with-plugins
  ];

  # basic configuration of git, please change to your own
  programs = {
    git = {
      userName = sensitive.name;
      userEmail = sensitive.email;
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
