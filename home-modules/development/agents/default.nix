{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  permissionType =
    lib.types.either
    (lib.types.listOf lib.types.anything)
    (lib.types.functionTo (lib.types.listOf lib.types.anything));

  defaults = import ./defaults.nix;

  agents = import ./policy.nix {
    inherit pkgs;
    agent-toolbox = inputs.agent-toolbox;

    extraPackages = config.agents.extraPackages;
    env = config.agents.env;
    fwdEnv =
      config.agents.fwdEnv
      ++ lib.optionals (config.agents.goose.sessionVariables != {}) [
        "GOOSE_PROVIDER"
        "GOOSE_MODEL"
      ];
    sharedPermissions = config.agents.sharedPermissions;
    nvidia = config.agents.nvidia.enable;
    ghToken = config.agents.ghToken.enable;
    flakeRoot = config.agents.flakeRoot.enable;
    herdr = config.agents.herdr.enable;
    direnv = config.agents.direnv.enable;
    persistHome = config.agents.persistHome.enable;

    opencode = {
      package = config.agents.opencode.package;
      config = lib.recursiveUpdate defaults.opencodeConfig config.agents.opencode.config;
      envFromFile = config.agents.opencode.envFromFile;
      extraPackages = config.agents.opencode.extraPackages;
      permissions = config.agents.opencode.permissions;
      allowAllReads = config.agents.opencode.allowAllReads;
    };

    goose = {
      package = config.agents.goose.package;
      config = config.agents.goose.config;
      envFromFile = config.agents.goose.envFromFile;
      extraPackages = config.agents.goose.extraPackages;
      permissions = config.agents.goose.permissions;
    };
  };

  # Run through the project's direnv/dev shell when ${FLAKE_ROOT:-$PWD}/.envrc
  # exists; the dev shell's PATH/env are forwarded into the jail. Without one,
  # the prebuilt system package runs directly.
  launcher = name: defaultPackage:
    import ./launcher.nix {
      inherit pkgs name defaultPackage;
      direnv = config.agents.direnv.enable;
    };

  packages = [
    (launcher "opencode" agents.opencode)
    (launcher "opencode-free" agents."opencode-free")
    (launcher "goose" agents.goose)
    (launcher "goose-free" agents."goose-free")
  ];
in {
  options.agents = {
    extraPackages = lib.mkOption {
      description = "Extra packages made available to both agents and their jails.";
      type = lib.types.listOf lib.types.package;
      default = [pkgs.nixd pkgs.gh];
    };

    env = lib.mkOption {
      description = "Literal environment variables set inside the agent jails.";
      type = lib.types.attrsOf lib.types.str;
      default = {};
    };

    fwdEnv = lib.mkOption {
      description = "Host environment variables forwarded into the agent jails when set.";
      type = lib.types.listOf lib.types.str;
      default = [];
    };

    sharedPermissions = lib.mkOption {
      description = "Extra jail.nix permissions appended to the defaults shared by both agents.";
      type = permissionType;
      default = [];
    };

    nvidia = {
      enable = lib.mkOption {
        description = "Expose CUDA devices (/dev/nvidia*, /proc/driver/nvidia, ...) to the jailed agents.";
        type = lib.types.bool;
        default = true;
      };
    };

    ghToken = {
      enable = lib.mkOption {
        description = "Run `gh auth token` on the host and forward the result to the agents as GH_TOKEN.";
        type = lib.types.bool;
        default = true;
      };
    };

    flakeRoot = {
      enable = lib.mkOption {
        description = "Bind $FLAKE_ROOT (or the cwd when unset) read-write into the agent jails.";
        type = lib.types.bool;
        default = true;
      };
    };

    herdr = {
      enable = lib.mkOption {
        description = "Bind the Herdr socket and OpenCode plugin into the agent jails.";
        type = lib.types.bool;
        default = true;
      };
    };

    direnv = {
      enable = lib.mkOption {
        description = "Run the agent through the project's direnv/dev shell when <root>/.envrc exists, and forward the dev-shell environment into the jail. Also activates in a plain nix develop shell.";
        type = lib.types.bool;
        default = true;
      };
    };

    persistHome = {
      enable = lib.mkOption {
        description = "Persist the jail home at $FLAKE_ROOT/.home when FLAKE_ROOT is set; otherwise use a tmpfs home.";
        type = lib.types.bool;
        default = true;
      };
    };

    opencode = {
      package = lib.mkOption {
        description = "opencode package to wrap. Defaults to the system opencode.";
        type = lib.types.package;
        default = pkgs.opencode;
      };

      config = lib.mkOption {
        description = "opencode config recursively merged over the default FreeToken configuration.";
        type = lib.types.attrs;
        default = {};
      };

      permissions = lib.mkOption {
        description = "Extra jail permissions appended to the jailed opencode defaults.";
        type = permissionType;
        default = [];
      };

      allowAllReads = lib.mkOption {
        description = "Auto-approve reads of everything visible inside the jail. This does not widen the jail's mounts; the free variant still asks.";
        type = lib.types.bool;
        default = true;
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
      package = lib.mkOption {
        description = "goose package to wrap (null keeps agent-toolbox's default).";
        type = lib.types.nullOr lib.types.package;
        default = null;
      };

      config = lib.mkOption {
        description = "goose config recursively merged over the default configuration.";
        type = lib.types.attrs;
        default = {};
      };

      permissions = lib.mkOption {
        description = "Extra jail permissions appended to the jailed goose defaults.";
        type = permissionType;
        default = [];
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
    home.packages = packages;
    home.sessionVariables = config.agents.goose.sessionVariables;
  };
}
