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
      ../modules/home/base.nix
      ../modules/home/nushell.nix
      ../modules/home/neovim
      ../modules/home/development.nix
      ../modules/home/work
      ../themes/datahow-dark.nix
    ]
    ++ (
      if isDarwin
      then [
      ]
      else [
        ../modules/home/hyprland.nix
        ../modules/home/waybar
      ]
    );

  # Packages that should be installed to the user profile.
  home.packages = with pkgs; [
    brave
  ];

  age.secrets = {
    dockerConfig = {
      file = ../secrets/users/work/dockerConfig.age;
      path = "${config.home.homeDirectory}/.docker/config.json";
    };
    kubeConfig = {
      file = ../secrets/users/work/kubeConfig.age;
      path = "${config.home.homeDirectory}/.kube/config";
    };
    yarnToken = {
      file = ../secrets/users/work/yarnToken.age;
    };
    anthropicApiKey = {
      file = ../secrets/users/work/anthropicApiKey.age;
    };
  };

  programs = {
    git = {
      settings = {
        user = {
          inherit (sensitive) name;
          inherit (sensitive) email;
        };

        init = {
          defaultBranch = "main";
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
      bashrcExtra = ''
        export ANTHROPIC_API_KEY=$(cat ${config.age.secrets.anthropicApiKey.path})
        export GITLAB_AUTH_TOKEN=$(cat ${config.age.secrets.yarnToken.path})
        export POETRY_HTTP_BASIC_PYDHL_USERNAME=${sensitive.email}
        export POETRY_HTTP_BASIC_PYDHL_PASSWORD=$(cat ${config.age.secrets.yarnToken.path})
        export POETRY_HTTP_BASIC_PROCESS_FORMAT_VALIDATION_PASSWORD=$(cat ${config.age.secrets.yarnToken.path})
        export POETRY_HTTP_BASIC_PROCESS_FORMAT_VALIDATION_USERNAME=${sensitive.email}
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
