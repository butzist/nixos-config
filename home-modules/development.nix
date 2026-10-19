{
  config,
  inputs,
  pkgs,
  ...
}: let
  atb = inputs.agent-toolbox;

  # Only surface a credential-backed provider when its agenix secret is declared
  # for this user (development is shared by adam and work).
  hasGreenpt = config.age.secrets ? greenpt-token;
  hasOpencodeGo = config.age.secrets ? opencode-go-token;

  gooseConfig = atb.lib.defaultGooseConfig;

  # agent-toolbox pins its own nixpkgs; this host pkgs is only for extra
  # packages and for merging configs.
  agentExtraPackages = [pkgs.nixd];

  # Sandbox permissions as jail.nix combinators. We bind /nix/store read-only so
  # every package's store path is available; mkJailedAgent puts the agent
  # package's bin (including extraPackages) on PATH. The NixOS system profile is
  # exposed too. envFromFile secrets are exported by the toolbox host wrapper
  # and forwarded into the jail automatically (mkJailedAgent adds try-fwd-env
  # per var); GOOSE_PROVIDER/MODEL are no envFromFile vars, so they need
  # explicit entries.
  opencodePermissions = c:
    atb.lib.defaultOpencodePermissions c
    ++ [
      (c.readonly "/nix/store")
      (c.readonly "/run/current-system")
      (c.add-path "/run/current-system/sw/bin")
    ];
  goosePermissions = c:
    atb.lib.defaultGoosePermissions c
    ++ [
      (c.readonly "/nix/store")
      (c.readonly "/run/current-system")
      (c.add-path "/run/current-system/sw/bin")
      (c.try-fwd-env "GOOSE_PROVIDER")
      (c.try-fwd-env "GOOSE_MODEL")
    ];

  opencodeEnvFromFile =
    pkgs.lib.optionalAttrs hasGreenpt {
      GREENPT_API_KEY = config.age.secrets.greenpt-token.path;
    }
    // pkgs.lib.optionalAttrs hasOpencodeGo {
      OPENCODE_GO_API_KEY = config.age.secrets.opencode-go-token.path;
    };
  gooseEnvFromFile = pkgs.lib.optionalAttrs hasOpencodeGo {
    OPENCODE_API_KEY = config.age.secrets.opencode-go-token.path;
  };

  opencodeConfig = pkgs.lib.recursiveUpdate atb.lib.defaultOpencodeConfig {
    model = "qwen3.6-35b-a3b";
    compaction = {
      auto = true;
      prune = true;
      reserved = 10000;
    };
    provider =
      {
        FreeToken = {
          npm = "@ai-sdk/openai-compatible";
          name = "FreeToken (local)";
          options.baseURL = "http://localhost:1919/v1";
          models."qwen3.6-35b-a3b" = {
            name = "Qwen3.6-35B-A3B (local)";
            tool_call = true;
            # Stay well under the server's window (opencode undercounts).
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
      }
      // pkgs.lib.optionalAttrs hasGreenpt {
        greenpt.options.apiKey = "{env:GREENPT_API_KEY}";
      }
      // pkgs.lib.optionalAttrs hasOpencodeGo {
        "opencode-go".options.apiKey = "{env:OPENCODE_GO_API_KEY}";
      };
  };

  # One env-free package per agent; `withEnv` adds the envFromFile secrets on
  # the host, `free` exposes that as `<name>-free`, and `makeJailedWith`
  # forwards the same vars into the jail instead.
  opencode = atb.lib.mkAgent {
    name = "opencode";
    package = atb.lib.mkOpencode {
      config = opencodeConfig;
      extraPackages = agentExtraPackages;
    };
    envFromFile = opencodeEnvFromFile;
  };
  goose = atb.lib.mkAgent {
    name = "goose";
    package = atb.lib.mkGoose {
      config = gooseConfig;
      extraPackages = agentExtraPackages;
    };
    envFromFile = gooseEnvFromFile;
  };
in {
  imports = [
    ./rust-mold.nix
  ];

  home.packages = with pkgs; [
    # version control
    gh

    # js
    nodejs_24
    bun
    deno

    # python
    python314
    uv
    ruff
    python314Packages.pip
    python314Packages.virtualenv

    # go
    go-mockery
    gopls

    # rust
    # rust-analyzer comes from rustup's proxy to avoid a conflicting binary;
    # enable it with `rustup component add rust-analyzer`.
    rustup
    cargo-nextest
    cargo-watch
    cargo-binstall
    cargo-binutils
    cargo-flamegraph
    cargo-valgrind
    wasm-pack
    wasm-bindgen-cli
    lldb
    clang
    clang-tools

    # build
    gnumake
    just
    pre-commit
    watchexec

    # analytics
    flamegraph
    ghidra
    perf
    valgrind

    # agents: jailed by default, `-free` unjailed. serena/rtk config is baked
    # into the packages; secrets are read on the host (envFromFile) and forwarded
    # as env vars. Sandbox policy is the `permissions` combinator lists above.
    (opencode.makeJailedWith {permissions = opencodePermissions;})
    (goose.makeJailedWith {permissions = goosePermissions;})
    opencode.free
    goose.free
  ];

  # Default provider only where the opencode-go token exists.
  home.sessionVariables = pkgs.lib.optionalAttrs hasOpencodeGo {
    GOOSE_PROVIDER = "opencode_go";
    GOOSE_MODEL = "deepseek-v4.1-flash";
  };

  programs = {
    git = {
      enable = true;

      settings = {
        help = {
          autocorrect = "prompt";
        };
        branch = {
          sort = "-committerdate";
        };
        tag = {
          sort = "version:refname";
        };
        init = {
          defaultBranch = "main";
        };
        diff = {
          algorithm = "histogram";
          colorMoved = "plain";
          mnemonicPrefix = true;
          renames = true;
        };
        commit = {
          verbose = true;
        };
        fetch = {
          prune = true;
          pruneTags = true;
          all = true;
        };
        push = {
          default = "simple";
          autoSetupRemote = true;
          followTags = true;
        };
        pull = {
          rebase = true;
        };
        submodule = {
          recurse = true;
        };
        rebase = {
          autoSquash = true;
          autoStash = true;
          updateRefs = true;
        };
        rerere = {
          enabled = true;
          autoupdate = true;
        };
        merge = {
          conflictstyle = "zdiff3";
        };
      };
    };
    go = {
      enable = true;
    };
  };
}
