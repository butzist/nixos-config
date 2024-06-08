{ config, lib, pkgs, ... }:

{
  imports = [
    ./fonts.nix
  ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Packages that should be installed to the user profile.
  home.packages = with pkgs; [
    alacritty
    firefox
    arandr

    jq
    yq-go
  ];

  # basic configuration of git, please change to your own
  programs = {
    bash.enable = true;

    alacritty = { enable = true;
      settings = {
        env.TERM = "xterm-256color";
        font = {
          size = 12;
        };
        scrolling.multiplier = 5;
        selection.save_to_clipboard = true;
      };
    };
  };

  # Let home Manager install and manage itself.
  programs.home-manager.enable = true;
}


