{
  pkgs,
  config,
  isDarwin,
  ...
}: let
  sensitive = import ../secrets/users/work/sensitive.nix;
in {
  home.username = "work";
  home.homeDirectory =
    if isDarwin
    then "/Users/work"
    else "/home/work";

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
  imports =
    [
      ../modules/desktop-base.nix
      ../modules/nushell.nix
      ../modules/neovim.nix
      ../modules/development.nix
      ../modules/work
      ../themes/datahow-dark.nix
    ]
    ++ (
      if isDarwin
      then [
      ]
      else [
        ../modules/hyprland.nix
        ../modules/waybar
      ]
    );

  # Packages that should be installed to the user profile.
  home.packages = with pkgs; [
  ];

  sops = {
    defaultSopsFile = ../secrets/users/work/default.yaml;
    age.sshKeyPaths = ["${config.home.homeDirectory}/.ssh/id_ed25519"];
    secrets = {
      dockerConfig = {
        path = "${config.home.homeDirectory}/.docker/config.json";
      };
      yarnToken = {};
    };
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
        export GITLAB_AUTH_TOKEN=$(cat ${config.sops.secrets.yarnToken.path})
        export POETRY_HTTP_BASIC_PYDHL_USERNAME=${sensitive.email}
        export POETRY_HTTP_BASIC_PYDHL_PASSWORD=$(cat ${config.sops.secrets.yarnToken.path})
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
