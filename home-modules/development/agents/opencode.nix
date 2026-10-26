{
  pkgs,
  rtkShell,
}: {
  # System-wide defaults layered under per-user and explicit agent config.
  defaultConfig = {
    "$schema" = "https://opencode.ai/config.json";
    lsp = true;
    # Route agent shell calls through rtk.
    shell = "${rtkShell}/bin/rtk-shell";
    model = "qwen3.6-35b-a3b";
    compaction = {
      auto = true;
      prune = true;
      reserved = 10000;
    };
    mcp.serena = {
      type = "local";
      command = ["${pkgs.serena}/bin/serena" "start-mcp-server" "--context" "agent"];
      enabled = true;
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
  };

  mkPackage = {
    name ? "opencode",
    config ? {},
    package ? pkgs.opencode,
    extraPackages ? [],
  }: let
    inherit (pkgs) lib;

    configFile = (pkgs.formats.json {}).generate "opencode-config.json" config;

    wrapper = pkgs.writeShellScriptBin name ''
      ${lib.optionalString (extraPackages != []) ''
        export PATH=${lib.makeBinPath extraPackages}''${PATH:+:$PATH}
      ''}
      export OPENCODE_CONFIG=${configFile}
      # A background server would escape the jail's lifecycle and could be
      # shared across projects; keep opencode's server private to this run.
      # Utility subcommands reject --standalone, so only add it to the TUI,
      # run/mini, and TUI flags.
      standalone=0
      case "''${1:-}" in
        ""|run|mini|-*) standalone=1 ;;
        upgrade|update|acp|debug|auth|mcp|plugin|session|service|pair|serve) ;;
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
