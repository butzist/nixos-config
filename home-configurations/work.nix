{
  config,
  inputs,
  pkgs,
  ezModules,
  ...
}: {
  home.username = "work";
  home.homeDirectory = "/home/work";

  imports =
    (with ezModules; [
      base
      kitty
      nushell
      zellij
      neovim
      development
      work
      hyprland
      wlogout
      walker
      waybar
    ])
    ++ [
      inputs.lassies-doghouse.homeManagerModules.default
      ../themes/everforest-kingdoms.nix
    ];

  # Packages that should be installed to the user profile.
  home.packages = with pkgs; [
    _stable.libreoffice
    kicad
    easyeda2kicad
  ];

  # ColliePWA: HTTP only, loopback only, no outbound network, no self-update.
  # The package and both modules live in the lassies-doghouse flake; this file
  # only selects them and sets the site-specific host. Pair from this shell with
  # `collie pair` after the service is up. The NixOS collie-serve module fronts
  # it with HTTPS on the tailnet via tailscale serve; the Host header it
  # forwards must be allowed explicitly.
  #
  # Web Push is the one exception to "no outbound": the bridge hands sends to
  # a host-side CONNECT proxy over a Unix socket, and that proxy only reaches
  # the push-service hosts in services.collie.pushProxy.allowHosts.
  #
  # OpenCode reports its live sessions to Collie through a plugin that talks to
  # a Unix socket in the Collie state dir. The plugin is installed for the host
  # OpenCode here; the agents module copies it into the jailed OpenCode, binds
  # the state dir read-only at the jail's ~/.local/state/collie and sets
  # COLLIE_STATE_DIR to that path.
  services.collie = {
    enable = true;
    publicHosts = ["legion.baboon-macaroni.ts.net"];
    pushProxy.enable = true;
    opencodePlugin.enable = true;
  };

  age.secrets = {
    gpg-private = {file = ../secrets/users/work/gpg-private.asc.age;};
    opencode-go-token = {
      file = ../secrets/users/work/opencode-go-token.txt.age;
      mode = "0400";
      path = "${config.home.homeDirectory}/.config/opencode/opencode-go-token";
    };
    greenpt-token = {
      file = ../secrets/users/work/greenpt-ai-token.txt.age;
      mode = "0400";
      path = "${config.home.homeDirectory}/.config/opencode/greenpt-ai-token";
    };
  };

  agents = {
    opencode = {
      envFromFile = {
        GREENPT_API_KEY = config.age.secrets.greenpt-token.path;
        OPENCODE_GO_API_KEY = config.age.secrets.opencode-go-token.path;
      };

      config.provider = {
        greenpt.options.apiKey = "{env:GREENPT_API_KEY}";
        "opencode-go".options.apiKey = "{env:OPENCODE_GO_API_KEY}";
      };
    };

    crush = {
      envFromFile.OPENCODE_API_KEY = config.age.secrets.opencode-go-token.path;
    };

    pi = {
      envFromFile.OPENCODE_API_KEY = config.age.secrets.opencode-go-token.path;
    };
  };

  programs = {
    # Chrome/Brave 142+ gates public -> loopback requests behind the Local
    # Network Access permission. The loopback-network permissions policy only
    # allows same-origin iframes by default, so the nested OnlyOffice engine
    # (onlyoffice.github.io) could never be delegated the permission. This
    # switch makes the LNA permissions policy default-enabled in ALL frames,
    # so no allow attribute is needed anywhere on the iframe chain.
    brave = {
      enable = true;
      commandLineArgs = [
        "--local-network-access-permissions-policy-default-enabled"
      ];
    };

    git = {
      settings = {
        credential.helper = "!f() { gh auth git-credential \"$@\"; }; f";

        user = {
          inherit (config.sensitive) name;
          inherit (config.sensitive) email;
          signingkey = "68C8B8A1A0A099640AC225E7F5B9095486E4F9FF";
        };

        commit = {
          gpgsign = true;
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

  systemd.user.services.import-gpg-key = {
    Unit = {
      Description = "Import GPG private key from agenix secret";
      After = ["agenix.service"];
      Requires = ["agenix.service"];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.gnupg}/bin/gpg --batch --import ${config.age.secrets.gpg-private.path}";
    };
    Install.WantedBy = ["default.target"];
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
