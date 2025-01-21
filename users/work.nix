{pkgs, ...}: let
  sensitive = import ../secrets/users/work/sensitive.nix;
in {
  home.username = "work";
  home.homeDirectory = "/home/work";

  imports = [
    ../modules/desktop-base.nix
    ../modules/nushell.nix
    ../modules/nixvim/default.nix
    ../modules/hyprland.nix
    ../modules/waybar/default.nix
    ../modules/development.nix
    ../modules/work/default.nix
    ../themes/datahow-dark.nix
  ];

  # Packages that should be installed to the user profile.
  home.packages = with pkgs; [
    freecad
  ];

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
        url = {
          "git@gitlab.com:" = {
            insteadOf = "https://gitlab.com/";
          };
        };
      };
    };

    bash = {
      enable = true;
      profileExtra = ''
        export GITLAB_AUTH_TOKEN=$(cat ~/Desktop/yarn-token.txt | head -n1 -c-1)
        export POETRY_HTTP_BASIC_PYDHL_USERNAME=${sensitive.email}
        export POETRY_HTTP_BASIC_PYDHL_PASSWORD=$(cat ~/Desktop/yarn-token.txt | head -n1 -c-1)
      '';
    };
  };

  systemd.user.sessionVariables.SSH_AUTH_SOCK = "/run/user/1000/keyring/ssh";

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
