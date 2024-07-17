{pkgs, ...}: {
  home.username = "adam";
  home.homeDirectory = "/home/adam";

  imports = [
    ../modules/desktop-base.nix
    ../modules/nushell.nix
    ../modules/nixvim/default.nix
    ../modules/sway.nix
    ../modules/hyprland.nix
    ../modules/waybar/default.nix
    ../modules/development.nix
    ../modules/work/default.nix
    ../themes/ubuntu-catppuccin.nix
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

    bash = {
      enable = true;
      profileExtra = ''
        export GITLAB_AUTH_TOKEN=$(cat ~/Desktop/yarn-token.txt | head -n1 -c-1)
      '';
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
