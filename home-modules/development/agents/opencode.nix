{
  pkgs,
  rtkShell,
  herdrAuthProxy,
  herdr ? true,
}: {
  # OpenCode 2 defaults layered under per-user and explicit agent config. The
  # v2 schema differs from v1: providers/*permissions* use the new names, MCP
  # servers live under `mcp.servers`, and model references are `provider/model`.
  defaultConfig = {
    "$schema" = "https://opencode.ai/config.json";
    lsp = true;
    # Route agent shell calls through rtk.
    shell = "${rtkShell}/bin/rtk-shell";
    # The binary is Nix-managed; a self-update would try to replace a store path.
    update = "disable";
    # Keep sessions local and the agent tree flat: no sharing, no child agents,
    # no desktop-app browser control.
    share = "disabled";
    permissions = [
      {
        action = "subagent";
        resource = "*";
        effect = "deny";
      }
      {
        action = "browser";
        resource = "*";
        effect = "deny";
      }
    ];
    model = "freetoken/qwen3.6-35b-a3b";
    compaction = {
      auto = true;
      keep.tokens = 10000;
      # Preserve the v1 `reserved = 10000` (reserved compaction buffer).
      buffer = 10000;
    };
    mcp.servers.serena = {
      type = "local";
      command = ["${pkgs.serena}/bin/serena" "start-mcp-server" "--context" "agent"];
    };
    providers.freetoken = {
      name = "FreeToken (local)";
      package = "@opencode/ai/providers/openai-compatible";
      settings.baseURL = "http://localhost:1919/v1";
      models."qwen3.6-35b-a3b" = {
        name = "Qwen3.6-35B-A3B (local)";
        capabilities.tools = true;
        # Stay well under the server's window (opencode undercounts).
        limit = {
          context = 40 * 1024;
          output = 8 * 1024;
        };
        settings = {
          temperature = 1.0;
          top_p = 0.95;
          top_k = 64;
        };
      };
    };
  };

  # MCP servers that belong only in the jailed variant. REA drives analysis of
  # arbitrary binaries, so it stays out of the unconfined `opencode-free`.
  #
  # herdr's own socket API is unauthenticated; the jail only reaches the
  # JWT-gated proxy socket (HERDR_AUTH_SOCKET + HERDR_AUTH_JWT are set by the
  # jail run). `herdr-auth mcp` is the orchestration path there: spawn agents
  # and exchange durable messages instead of touching raw panes.
  jailedConfig = {
    mcp.servers =
      {
        rea = {
          type = "local";
          command = ["${pkgs.rea}/bin/rea" "mcp"];
        };
      }
      // pkgs.lib.optionalAttrs herdr {
        herdr = {
          type = "local";
          command = ["${herdrAuthProxy}/bin/herdr-auth" "mcp"];
        };
      };
  };

  mkPackage = {
    name ? "opencode",
    config ? {},
    package,
    extraPackages ? [],
  }: let
    inherit (pkgs) lib;

    configFile = (pkgs.formats.json {}).generate "opencode-config.json" config;

    wrapper = pkgs.writeShellScriptBin name ''
      ${lib.optionalString (extraPackages != []) ''
        export PATH=${lib.makeBinPath extraPackages}''${PATH:+:$PATH}
      ''}
      export OPENCODE_CONFIG=${configFile}
      # CLI settings are separate from the server config, so the tab strip
      # override cannot live in OPENCODE_CONFIG. Merge just that key over any
      # inline CLI config the user already provided.
      cli_config="''${OPENCODE_CLI_CONFIG_CONTENT:-}"
      if [ -z "$cli_config" ]; then cli_config='{}'; fi
      OPENCODE_CLI_CONFIG_CONTENT="$(${pkgs.jq}/bin/jq -cn --argjson base "$cli_config" '$base * {tabs: {mode: "off"}}')"
      export OPENCODE_CLI_CONFIG_CONTENT
      # The default TUI command has no --agent flag (run/mini do). Translate it
      # into OPENCODE_CONFIG_CONTENT (merged over any existing content) so
      # `opencode --agent build` works for the TUI too.
      case "''${1:-}" in
        run|mini) ;;
        upgrade|update|uninstall|acp|api|debug|auth|mcp|plugin|models|stats|session|service|reload|pair|serve) ;;
        *)
          agent=""
          args=()
          while [ "$#" -gt 0 ]; do
            case "$1" in
              --agent)
                if [ "$#" -lt 2 ]; then
                  echo "opencode: --agent requires a value" >&2
                  exit 2
                fi
                agent="$2"
                shift 2
                ;;
              --agent=*)
                agent="''${1#--agent=}"
                shift
                ;;
              *)
                args+=("$1")
                shift
                ;;
            esac
          done
          set -- "''${args[@]}"
          if [ -n "$agent" ]; then
            base="''${OPENCODE_CONFIG_CONTENT:-}"
            if [ -z "$base" ]; then base='{}'; fi
            OPENCODE_CONFIG_CONTENT="$(${pkgs.jq}/bin/jq -cn --argjson base "$base" --arg agent "$agent" '$base + {default_agent: $agent}')"
            export OPENCODE_CONFIG_CONTENT
          fi
          ;;
      esac
      # A background server would escape the jail's lifecycle and could be
      # shared across projects; keep opencode's server private to this run.
      # Utility subcommands reject --standalone, so only add it to the TUI,
      # run/mini, and TUI flags.
      standalone=0
      case "''${1:-}" in
        ""|run|mini|-*) standalone=1 ;;
        upgrade|update|uninstall|acp|api|debug|auth|mcp|plugin|models|stats|session|service|reload|pair|serve) ;;
        *) standalone=1 ;;
      esac
      if [ "$standalone" = 1 ]; then
        for arg in "$@"; do
          if [ "$arg" = "--standalone" ]; then
            standalone=0
            break
          fi
        done
      fi
      if [ "$standalone" = 1 ]; then
        set -- --standalone "$@"
      fi
      exec ${lib.getExe package} "$@"
    '';
  in
    (pkgs.symlinkJoin {
      inherit name;
      paths = [wrapper] ++ extraPackages;
    })
    .overrideAttrs (old: {
      meta = (old.meta or {}) // {mainProgram = name;};
    });
}
