{pkgs, ...}: let
  sensitive = import ../secrets/users/adam/sensitive.nix;
in {
  home.username = "adam";
  home.homeDirectory = "/home/adam";

  imports = [
    ../modules/desktop-base.nix
    ../modules/nushell.nix
    ../modules/neovim.nix
    ../modules/hyprland.nix
    ../modules/waybar/default.nix
    ../modules/development.nix
    ../themes/ubuntu-catppuccin.nix
  ];

  # Packages that should be installed to the user profile.
  home.packages = with pkgs; [
    freecad
    orca-slicer
  ];

  sops = {
    defaultSopsFile = ../secrets/users/adam/default.yaml;
    age.sshKeyPaths = ["/home/adam/.ssh/id_ed25519"];
    secrets = {};
  };

  # basic configuration of git, please change to your own
  programs = {
    git = {
      enable = true;
      userName = sensitive.name;
      userEmail = sensitive.email;

      extraConfig = {
        init = {
          defaultBranch = "main";
        };
        pull = {
          rebase = true;
        };
        submodule = {
          recurse = true;
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
