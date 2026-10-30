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

  atb = inputs.agent-toolbox;
  system = pkgs.stdenv.hostPlatform.system;
  aiTools = inputs.nix-ai-tools.packages.${system};
  herdrAuthProxy = inputs.herdr-auth-proxy.packages.${system}.default;

  # One rtk shell for every agent that can be pointed at it (opencode via
  # `shell`, pi via `shellPath`). Crush uses its embedded bash.
  rtkShell = atb.lib.mkRtkShell {rtk = aiTools.rtk;};

  opencodeFile = import ./opencode.nix {inherit pkgs rtkShell;};
  crushFile = import ./crush.nix {inherit pkgs;};
  piFile = import ./pi.nix {inherit pkgs rtkShell;};

  # The jail binds /nix read-only, so the plugin can be copied straight from
  # the Collie package the service runs. Copy (rather than symlink) because the
  # jail home is a tmpfs/persisted dir: Herdr's `chmod -R u+w` on
  # ~/.config/opencode follows symlinks, and a link into the read-only store
  # would make it fail.
  colliePlugin = "${config.services.collie.package or inputs.lassies-doghouse.packages.${system}.collie}/lib/collie/plugins/opencode/collie-opencode-bridge.js";

  # Base16 palettes for the agents that Stylix has no target for.
  stylixColors = config.lib.stylix.colors;

  agents = import ./policy.nix {
    inherit pkgs rtkShell;
    inherit (inputs) agent-toolbox;
    herdrPackage = aiTools.herdr;
    inherit herdrAuthProxy;

    extraPackages = config.agents.extraPackages;
    env = config.agents.env;
    fwdEnv = config.agents.fwdEnv;
    sharedPermissions = config.agents.sharedPermissions;
    nvidia = config.agents.nvidia.enable;
    ghToken = config.agents.ghToken.enable;
    flakeRoot = config.agents.flakeRoot.enable;
    herdr = config.agents.herdr.enable;
    collie = config.agents.collie.enable;
    direnv = config.agents.direnv.enable;
    persistHome = config.agents.persistHome.enable;
    inherit colliePlugin;

    opencode = {
      package = config.agents.opencode.package;
      config = lib.recursiveUpdate opencodeFile.defaultConfig config.agents.opencode.config;
      envFromFile = config.agents.opencode.envFromFile;
      extraPackages = config.agents.opencode.extraPackages;
      permissions = config.agents.opencode.permissions;
      allowAllReads = config.agents.opencode.allowAllReads;
    };

    crush = {
      package = config.agents.crush.package;
      config = lib.recursiveUpdate crushFile.defaultConfig config.agents.crush.config;
      colors = stylixColors;
      envFromFile = config.agents.crush.envFromFile;
      extraPackages = config.agents.crush.extraPackages;
      permissions = config.agents.crush.permissions;
    };

    pi = {
      package = config.agents.pi.package;
      settings = lib.recursiveUpdate piFile.defaultSettings config.agents.pi.settings;
      models = lib.recursiveUpdate piFile.defaultModels config.agents.pi.models;
      colors = stylixColors;
      polarity = config.stylix.polarity;
      envFromFile = config.agents.pi.envFromFile;
      extraPackages = config.agents.pi.extraPackages;
      permissions = config.agents.pi.permissions;
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
    (launcher "crush" agents.crush)
    (launcher "crush-free" agents."crush-free")
    (launcher "pi" agents.pi)
    (launcher "pi-free" agents."pi-free")
  ];
in {
  options.agents = {
    extraPackages = lib.mkOption {
      description = "Packages made available to all agents (prepended to PATH) and their jails.";
      type = lib.types.listOf lib.types.package;
      default = with pkgs;
        [
          gh
          nixd
          fd
          jq
          python3
          ripgrep
          mcpls
          serena
        ]
        ++ [
          aiTools.rtk
          aiTools.herdr
          herdrAuthProxy
        ];
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
      description = "Extra jail.nix permissions appended to the defaults shared by all agents.";
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
        description = "Herdr auth socket/env (with a default orchestrator token), plus the OpenCode plugin and Pi extension used by the agent jails.";
        type = lib.types.bool;
        default = true;
      };
    };

    collie = {
      enable = lib.mkOption {
        description = "Install the Collie OpenCode plugin into the jail, expose the Collie socket directory at the jail's ~/.local/state/collie and set COLLIE_STATE_DIR to it.";
        type = lib.types.bool;
        # Follows the Collie service when lassies-doghouse is imported.
        default = config.services.collie.enable or false;
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

    crush = {
      package = lib.mkOption {
        description = "Crush package to wrap.";
        type = lib.types.package;
        default = aiTools.crush;
      };

      config = lib.mkOption {
        description = "Crush config (crush.json) recursively merged over the default configuration.";
        type = lib.types.attrs;
        default = {};
      };

      permissions = lib.mkOption {
        description = "Extra jail permissions appended to the jailed crush defaults.";
        type = permissionType;
        default = [];
      };

      envFromFile = lib.mkOption {
        description = "Environment variables exported on the host from files, then forwarded into the jail.";
        type = lib.types.attrsOf (lib.types.either lib.types.path lib.types.str);
        default = {};
      };

      extraPackages = lib.mkOption {
        description = "Extra packages made available to crush only.";
        type = lib.types.listOf lib.types.package;
        default = [];
      };
    };

    pi = {
      package = lib.mkOption {
        description = "Pi coding agent package to wrap.";
        type = lib.types.package;
        default = aiTools.pi;
      };

      settings = lib.mkOption {
        description = "Pi settings.json recursively merged over the default settings.";
        type = lib.types.attrs;
        default = {};
      };

      models = lib.mkOption {
        description = "Pi models.json recursively merged over the default provider/model.";
        type = lib.types.attrs;
        default = {};
      };

      permissions = lib.mkOption {
        description = "Extra jail permissions appended to the jailed pi defaults.";
        type = permissionType;
        default = [];
      };

      envFromFile = lib.mkOption {
        description = "Environment variables exported on the host from files, then forwarded into the jail.";
        type = lib.types.attrsOf (lib.types.either lib.types.path lib.types.str);
        default = {};
      };

      extraPackages = lib.mkOption {
        description = "Extra packages made available to pi only.";
        type = lib.types.listOf lib.types.package;
        default = [];
      };
    };
  };

  config = {
    home.packages = packages;
  };
}
