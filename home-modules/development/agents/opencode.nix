{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  system = pkgs.stdenv.hostPlatform.system;
  atb = inputs.agent-toolbox.lib pkgs;
  aiTools = inputs.llm-agents.packages.${system};
  rtkShell = atb.mkRtkShell {rtk = aiTools.rtk;};
  herdrAuthProxy = inputs.herdr-auth-proxy.packages.${system}.default;
  herdr = config.agents.herdr.enable;

  # Kitty already gets its blurred, translucent window from Stylix. When
  # Stylix says the terminal is opaque, paint base00 in the TUI instead; when
  # it is translucent, leave the chat background unset and let the terminal
  # provide the transparency (avoids stacking two alpha layers).
  colors = config.lib.stylix.colors;
  transparent = (config.stylix.opacity.terminal or 1) < 1;

  # Build a complete OpenCode V2 TUI theme from the active Stylix base16
  # palette. OpenCode wants a full `base` token tree plus at least one mode
  # palette; base16 only has 16 colours, so each hue is expanded into a
  # nine-step ramp by mixing the accent with the palette's fg/bg. Reading the
  # palette from config here gives every user the same mapping for their own
  # theme (Bosque, Catppuccin, ...).
  digits = lib.stringToCharacters "0123456789abcdef";

  digit = c:
    lib.lists.findFirstIndex (d: d == lib.toLower c) (builtins.throw "invalid hex digit: ${c}") digits;

  parse = hex: let
    c = lib.stringToCharacters (lib.toLower hex);
    byte = a: b: digit a * 16 + digit b;
  in {
    r = byte (lib.elemAt c 0) (lib.elemAt c 1);
    g = byte (lib.elemAt c 2) (lib.elemAt c 3);
    b = byte (lib.elemAt c 4) (lib.elemAt c 5);
  };

  hexByte = n: let
    hi = n / 16;
    lo = n - hi * 16;
  in "${lib.elemAt digits hi}${lib.elemAt digits lo}";

  # `t` percent of `to`, the rest `from`.
  mix = from: to: t: let
    a = parse from;
    b = parse to;
    channel = k: hexByte ((a.${k} * (100 - t) + b.${k} * t) / 100);
  in "#${channel "r"}${channel "g"}${channel "b"}";

  # Stylix exposes bare hex (no #); keep those where a plain hex is accepted.
  c = name: "#${colors.${name}}";
  tint = name: t: mix colors.base00 colors.${name} t;

  # OpenCode resolves `$hue.*` references but rejects references to other
  # semantic tokens, so repeat the base16 hex where a token would be handy.
  bgBase =
    if transparent
    then "transparent"
    else c "base00";
  surface = c "base01";
  surfaceHigh = c "base02";

  # Dark-mode ramps run from light (100) to dark (900), as OpenCode expects.
  ramp = name: {
    "100" = mix colors.base07 colors.${name} 18;
    "200" = mix colors.base06 colors.${name} 32;
    "300" = mix colors.base05 colors.${name} 60;
    "400" = c name;
    "500" = mix colors.base02 colors.${name} 55;
    "600" = mix colors.base01 colors.${name} 45;
    "700" = mix colors.base01 colors.${name} 28;
    "800" = mix colors.base00 colors.${name} 16;
    "900" = mix colors.base00 colors.${name} 8;
  };

  neutral = {
    "100" = mix colors.base07 "ffffff" 20;
    "200" = c "base07";
    "300" = c "base06";
    "400" = c "base05";
    "500" = c "base04";
    "600" = c "base03";
    "700" = c "base02";
    "800" = c "base01";
    "900" = mix colors.base00 "000000" 40;
  };

  hues = {
    gray = neutral;
    red = ramp "base08";
    orange = ramp "base09";
    yellow = ramp "base0A";
    green = ramp "base0B";
    cyan = ramp "base0C";
    blue = ramp "base0D";
    purple = ramp "base0E";
    # base0D is the accent in the other base16 consumers here (e.g. Herdr).
    accent = "$hue.blue";
    interactive = "$hue.blue";
    neutral = "$hue.gray";
  };

  theme = {
    "$schema" = "https://opencode.ai/theme.json";

    base = {
      categorical = ["blue" "cyan" "green" "purple" "yellow" "orange" "red"];

      text = {
        base = c "base05";
        muted = c "base04";

        action = {
          primary = {
            base = "$hue.interactive.300";
            "$hovered" = "$hue.interactive.200";
            "$focused" = "$hue.interactive.200";
            "$pressed" = "$hue.interactive.400";
            "$selected" = "$hue.interactive.300";
            "$disabled" = "$hue.neutral.500";
          };
          secondary = {
            base = c "base04";
            "$hovered" = c "base05";
            "$focused" = c "base05";
            "$pressed" = c "base05";
            "$selected" = c "base05";
            "$disabled" = "$hue.neutral.600";
          };
          destructive = {
            base = "$hue.red.300";
            "$hovered" = "$hue.red.200";
            "$focused" = "$hue.red.200";
            "$pressed" = "$hue.red.400";
            "$selected" = "$hue.red.300";
            "$disabled" = "$hue.neutral.500";
          };
        };

        formfield = {
          base = c "base05";
          "$hovered" = "$hue.interactive.200";
          "$focused" = "$hue.interactive.200";
          "$pressed" = "$hue.interactive.300";
          "$selected" = "$hue.interactive.200";
          "$disabled" = "$hue.neutral.500";
        };

        feedback = {
          error.base = "$hue.red.300";
          warning.base = "$hue.yellow.300";
          success.base = "$hue.green.300";
          info.base = "$hue.blue.300";
        };
      };

      background = {
        # Let kitty's blurred, translucent terminal show through the chat area.
        base = bgBase;
        raised = {
          base = surface;
          high = surfaceHigh;
          max = c "base03";
        };
        action = {
          primary = {
            base = "transparent";
            "$hovered" = surface;
            "$focused" = surface;
            "$pressed" = surfaceHigh;
            "$selected" = "transparent";
            "$disabled" = "transparent";
          };
          secondary = {
            base = "transparent";
            "$hovered" = surface;
            "$focused" = surface;
            "$pressed" = surfaceHigh;
            "$selected" = "transparent";
            "$disabled" = "transparent";
          };
          destructive = {
            base = "transparent";
            "$hovered" = "$hue.red.800";
            "$focused" = "$hue.red.800";
            "$pressed" = "$hue.red.700";
            "$selected" = "transparent";
            "$disabled" = "transparent";
          };
        };
        formfield = {
          base = bgBase;
          "$hovered" = surface;
          "$focused" = surface;
          "$pressed" = surfaceHigh;
          "$selected" = surface;
          "$disabled" = bgBase;
        };
        feedback = {
          error.base = bgBase;
          warning.base = bgBase;
          success.base = bgBase;
          info.base = bgBase;
        };
      };

      border.base = c "base02";
      scrollbar.base = c "base03";

      diff = {
        text = {
          added = "$hue.green.300";
          removed = "$hue.red.300";
          context = "$hue.neutral.400";
          hunkHeader = "$hue.blue.300";
        };
        background = {
          added = tint "base0B" 18;
          removed = tint "base08" 18;
          context = tint "base05" 6;
        };
        highlight = {
          added = tint "base0B" 34;
          removed = tint "base08" 34;
        };
        lineNumber = {
          text = c "base03";
          background = {
            added = tint "base0B" 12;
            removed = tint "base08" 12;
          };
        };
      };

      syntax = {
        comment = c "base03";
        keyword = c "base0E";
        function = c "base0D";
        variable = c "base05";
        string = c "base0B";
        number = c "base09";
        type = c "base0C";
        operator = c "base04";
        punctuation = c "base04";
      };

      markdown = {
        text = c "base05";
        heading = "$hue.blue.300";
        link = "$hue.cyan.300";
        linkText = "$hue.cyan.200";
        code = "$hue.green.300";
        blockQuote = "$hue.neutral.400";
        emphasis = "$hue.purple.300";
        strong = c "base06";
        horizontalRule = c "base02";
        listItem = "$hue.orange.300";
        listEnumeration = "$hue.orange.300";
        image = "$hue.blue.300";
        imageText = c "base04";
        codeBlock = "$hue.green.200";
      };

      # Dialogs are one surface above the transparent chat area.
      "@dialog" = {
        background = {
          base = surface;
          action.primary."$hovered" = surfaceHigh;
        };
      };
    };

    # Both themes in this repo are dark; requesting light mode still resolves.
    dark = {hue = hues;};
  };

  themeFile = (pkgs.formats.json {}).generate "opencode-stylix-theme.json" theme;

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
        # Nelson's MCP endpoint listens on the host's loopback. The jail's
        # default `c.network` shares the host net namespace, so localhost is
        # reachable without extra bwrap args. No OAuth on this local server.
        libreoffice = {
          type = "remote";
          url = "http://localhost:8766/mcp";
          oauth = false;
        };
      }
      // lib.optionalAttrs herdr {
        herdr = {
          type = "local";
          command = ["${herdrAuthProxy}/bin/herdr-auth" "mcp"];
        };
      };
  };

  mkPackage = {
    name ? "opencode",
    opencodeConfig ? {},
    package,
    extraPackages ? [],
  }: let
    configFile = (pkgs.formats.json {}).generate "opencode-config.json" opencodeConfig;

    # CLI settings are separate from the server config. The tab-strip override
    # and the generated theme selection both live here, merged over any inline
    # CLI config the user already provided. "stylix" is the theme file's name
    # without the .json suffix.
    cliOverrideFile = (pkgs.formats.json {}).generate "opencode-cli-overrides.json" {
      tabs.mode = "off";
      theme = {
        name = "stylix";
        mode = "dark";
      };
    };

    wrapper = pkgs.writeShellScriptBin name ''
      ${lib.optionalString (extraPackages != []) ''
        export PATH=${lib.makeBinPath extraPackages}''${PATH:+:$PATH}
      ''}
      export OPENCODE_CONFIG=${configFile}
      # Merge CLI overrides over any inline CLI config the user provided.
      cli_config="''${OPENCODE_CLI_CONFIG_CONTENT:-}"
      if [ -z "$cli_config" ]; then cli_config='{}'; fi
      OPENCODE_CLI_CONFIG_CONTENT="$(${pkgs.jq}/bin/jq -cn --argjson base "$cli_config" --slurpfile override ${cliOverrideFile} '$base * $override[0]')"
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
in {
  # Shared with the jail setup in policy.nix, which needs the generated theme
  # and the config/wrapper helpers. The module owns their generation so both
  # host and jailed agents read from the same Stylix palette.
  options.agents.opencode.internal = lib.mkOption {
    internal = true;
    description = "Generated theme file and OpenCode wrapper helpers used by the agent jails.";
    type = lib.types.attrs;
    default = {
      inherit themeFile defaultConfig jailedConfig mkPackage;
    };
  };

  config = {
    # The filename without .json is the theme name selected by the wrapper.
    xdg.configFile."opencode/themes/stylix.json".source = themeFile;
  };
}
