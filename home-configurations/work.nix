{
  config,
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
      ../themes/everforest-kingdoms.nix
    ];

  # Packages that should be installed to the user profile.
  home.packages = with pkgs; [
    libreoffice
    kicad
    easyeda2kicad
  ];

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

  xdg.configFile."opencode/opencode.jsonc".text = builtins.toJSON {
    "$schema" = "https://opencode.ai/config.json";
    lsp = true;
    model = "qwen3.6-35b-a3b";
    provider = {
      "greenpt" = {
        options.apiKey = "{file:${config.age.secrets.greenpt-token.path}}";
      };
      "opencode-go" = {
        options.apiKey = "{file:${config.age.secrets.opencode-go-token.path}}";
      };
      "FreeToken" = {
        npm = "@ai-sdk/openai-compatible";
        name = "FreeToken (local)";
        options.baseURL = "http://localhost:1919/v1";
        models = {
          # Must match `served-model-name` in default.nix, which is the id
          # FreeToken reports from /v1/models.
          "qwen3.6-35b-a3b" = {
            name = "Qwen3.6-35B-A3B (local)";
            tool_call = true;
            # Stay well under the server's window: opencode undercounts tokens,
            # so a smaller output leaves room for generation plus a
            # tokenizer-overshoot margin.
            limit = {
              context = 40 * 1024;
              output = 8 * 1024;
            };
            options = {
              temperature = 1.0;
              top_p = 0.95;
              top_k = 64;
            };
          };
        };
      };
    };

    compaction = {
      auto = true;
      prune = true;
      reserved = 10000;
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
