{ config, lib, pkgs, ... }:

{
  imports = [
    ./fonts.nix
  ];

  # Packages that should be installed to the user profile.
  home.packages = with pkgs; [
    jq
    yq-go

    lazygit
    btop

    ripgrep
    fd
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
	window.opacity = 0.5;
      };
    };
  };

  # Let home Manager install and manage itself.
  programs.home-manager.enable = true;
}


