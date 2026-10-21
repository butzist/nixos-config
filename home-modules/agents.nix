{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  atb = inputs.agent-toolbox;

  permissionType =
    lib.types.either
    (lib.types.listOf lib.types.anything)
    (lib.types.functionTo (lib.types.listOf lib.types.anything));

  # Sandbox permissions as jail.nix combinators. We bind /nix read-only so
  # every package's store path is available; mkJailedAgent puts the agent
  # package's bin (including extraPackages) on PATH. The NixOS system profile is
  # exposed too. envFromFile secrets are exported by the toolbox host wrapper
  # and forwarded into the jail automatically (mkJailedAgent adds try-fwd-env
  # per var); GOOSE_PROVIDER/MODEL are no envFromFile vars, so they need
  # explicit entries.
  defaultSharedPermissions = c: [
    (c.readonly "/nix")
    (c.try-readonly (c.noescape "~/.config/git/config"))
    (c.try-readonly (c.noescape "~/.config/.gh"))
    (c.try-readwrite (c.noescape "~/.cargo"))
    (c.readonly "/run/current-system")
    (c.add-path "/run/current-system/sw/bin")
  ];

  defaultOpencodeConfig = pkgs.lib.recursiveUpdate atb.lib.defaultOpencodeConfig {
    model = "qwen3.6-35b-a3b";
    compaction = {
      auto = true;
      prune = true;
      reserved = 10000;
    };
    provider.FreeToken = {
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

    # external_directory defaults to "ask"; these trees are bound
    # into the jail so opencode may read them without prompting.
    permission = {
      external_directory = {
        "/nix/store/**" = "allow";
        "~/.cargo/**" = "allow";
        "/etc/**" = "allow";
      };
      read = {
        "/nix/store/**" = "allow";
        "~/.cargo/**" = "allow";
        "/etc/**" = "allow";
      };
    };
  };

  opencode = atb.lib.mkAgent {
    name = "opencode";
    package = atb.lib.mkOpencode {
      config = pkgs.lib.recursiveUpdate defaultOpencodeConfig config.agents.opencode.config;
      extraPackages = config.agents.extraPackages ++ config.agents.opencode.extraPackages;
    };
    envFromFile = config.agents.opencode.envFromFile;
  };

  goose = atb.lib.mkAgent {
    name = "goose";
    package = atb.lib.mkGoose {
      config = pkgs.lib.recursiveUpdate atb.lib.defaultGooseConfig config.agents.goose.config;
      extraPackages = config.agents.extraPackages ++ config.agents.goose.extraPackages;
    };
    envFromFile = config.agents.goose.envFromFile;
  };
in {
  options.agents = {
    extraPackages = lib.mkOption {
      description = "Extra packages made available to both agents and their jails.";
      type = lib.types.listOf lib.types.package;
      default = [pkgs.nixd];
    };

    sharedPermissions = lib.mkOption {
      description = "jail.nix permission combinator function shared by the default agent policies.";
      type = lib.types.functionTo (lib.types.listOf lib.types.anything);
      default = defaultSharedPermissions;
    };

    opencode = {
      config = lib.mkOption {
        description = "opencode config recursively merged over the default FreeToken configuration.";
        type = lib.types.attrs;
        default = {};
      };

      permissions = lib.mkOption {
        description = "Jail permissions as a list or a jail.nix combinators function.";
        type = permissionType;
        default = c:
          atb.lib.defaultOpencodePermissions c
          ++ config.agents.sharedPermissions c;
      };

      envFromFile = lib.mkOption {
        description = "Environment variables exported on the host from files, then forwarded into the jail.";
        type = lib.types.attrsOf (lib.types.either lib.types.path lib.types.str);
        default = {};
      };

      extraPackages = lib.mkOption {
        description = "Extra packages made available to opencode only.";
        type = lib.types.listOf lib.types.package;
        default = [];
      };
    };

    goose = {
      config = lib.mkOption {
        description = "goose config recursively merged over the default configuration.";
        type = lib.types.attrs;
        default = {};
      };

      permissions = lib.mkOption {
        description = "Jail permissions as a list or a jail.nix combinators function.";
        type = permissionType;
        default = c:
          atb.lib.defaultGoosePermissions c
          ++ config.agents.sharedPermissions c
          ++ [
            (c.try-fwd-env "GOOSE_PROVIDER")
            (c.try-fwd-env "GOOSE_MODEL")
          ];
      };

      envFromFile = lib.mkOption {
        description = "Environment variables exported on the host from files, then forwarded into the jail.";
        type = lib.types.attrsOf (lib.types.either lib.types.path lib.types.str);
        default = {};
      };

      extraPackages = lib.mkOption {
        description = "Extra packages made available to goose only.";
        type = lib.types.listOf lib.types.package;
        default = [];
      };

      sessionVariables = lib.mkOption {
        description = "Non-secret session variables for goose, e.g. its provider and model.";
        type = lib.types.attrsOf lib.types.str;
        default = {};
      };
    };
  };

  config = {
    home.packages = [
      (opencode.makeJailedWith {inherit (config.agents.opencode) permissions;})
      (goose.makeJailedWith {inherit (config.agents.goose) permissions;})
      opencode.free
      goose.free
    ];

    home.sessionVariables = config.agents.goose.sessionVariables;
  };
}
