{ config, pkgs, ... }:

{
  home.username = "adam";
  home.homeDirectory = "/home/adam";

  imports = [
    ../modules/desktop-base.nix
    ../modules/nushell.nix
    ../modules/nixvim/nixvim.nix
    ../modules/sway.nix
    ../modules/development.nix
    ../modules/work.nix
    ../themes/ubuntu-dark.nix
  ];

  # Packages that should be installed to the user profile.
  home.packages = with pkgs; [
  ];

  # basic configuration of git, please change to your own
  programs = {
    git = {
      enable = true;
      userName = "Adam";
      userEmail = "adam";
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

