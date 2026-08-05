{pkgs, ...}: let
  sensitive = import ../secrets/users/work/sensitive.nix;
in {
  home.username = "work";
  home.homeDirectory = "/home/work";

  # compliance crap
  services.hypridle = {
    settings = {
      listener = [
        {
          timeout = 900; # 15 min
          on-timeout = "loginctl lock-session"; # lock screen when timeout has passed
        }
      ];
    };
  };
  imports = [
    ../modules/home/base.nix
    ../modules/home/nushell.nix
    ../modules/home/neovim
    ../modules/home/development.nix
    ../modules/home/work
    ../themes/everforest-kingdoms.nix
    ../modules/home/hyprland.nix
    ../modules/home/waybar
  ];

  # Packages that should be installed to the user profile.
  home.packages = with pkgs; [
    brave
  ];

  age.secrets = {};

  programs = {
    git = {
      settings = {
        credential.helper = "!f() { gh auth git-credential \"$@\"; }; f";

        user = {
          inherit (sensitive) name;
          inherit (sensitive) email;
        };

        init = {
          defaultBranch = "main";
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
  home.stateVersion = "26.05";
}
