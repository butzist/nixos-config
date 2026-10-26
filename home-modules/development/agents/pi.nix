{
  pkgs,
  rtkShell,
}: {
  defaultSettings = {
    "$schema" = "https://pi.dev/schemas/settings.schema.json";
    defaultProvider = "opencode-go";
    defaultModel = "deepseek-v4.1-flash";
    defaultThinkingLevel = "medium";
    # Custom theme generated from the Stylix base16 palette below.
    theme = "stylix";
    # Pi's shell tool goes through rtk like opencode's.
    shellPath = "${rtkShell}/bin/rtk-shell";
    enableInstallTelemetry = false;
  };

  # Pi's catalog may lag behind the models served by OpenCode Go, so declare
  # the model explicitly (with env-interpolated credentials).
  defaultModels = {
    "$schema" = "https://pi.dev/schemas/models.schema.json";
    providers."opencode-go" = {
      baseUrl = "https://opencode.ai/zen/go/v1";
      api = "openai-completions";
      apiKey = "$OPENCODE_API_KEY";
      models = [
        {
          id = "deepseek-v4.1-flash";
          name = "DeepSeek V4.1 Flash";
          reasoning = true;
          contextWindow = 1000000;
          maxTokens = 384000;
        }
      ];
    };
  };

  mkPackage = {
    name ? "pi",
    settings ? {},
    models ? {},
    colors ? null,
    polarity ? "dark",
    package ? pkgs.pi-coding-agent,
    extraPackages ? [],
    herdr ? true,
    herdrPackage ? pkgs.herdr,
  }: let
    inherit (pkgs) lib;
    json = pkgs.formats.json {};

    # Base16 palette for Pi's custom theme format. Optional colors are set too,
    # so every surface follows the Stylix scheme. `colors` is
    # config.lib.stylix.colors.
    theme =
      if colors == null
      then null
      else let
        c = key: colors.withHashtag.${key};
      in {
        "$schema" = "https://pi.dev/schemas/theme.schema.json";
        name = "stylix";
        appearance = polarity;

        colors = {
          accent = c "base0D";
          border = c "base02";
          borderAccent = c "base0D";
          borderMuted = c "base01";
          success = c "base0B";
          error = c "base08";
          warning = c "base09";
          muted = c "base04";
          dim = c "base03";
          text = c "base05";
          thinkingText = c "base04";

          scrollbarTrack = c "base01";
          scrollbarThumb = c "base03";
          selectedBg = c "base02";
          searchMatchBg = c "base02";
          searchMatchText = c "base05";

          userMessageBg = c "base01";
          userMessageText = c "base05";
          customMessageBg = c "base01";
          customMessageText = c "base05";
          customMessageLabel = c "base0E";

          toolPendingBg = c "base01";
          toolSuccessBg = c "base01";
          toolErrorBg = c "base01";
          toolTitle = c "base0D";
          toolOutput = c "base05";

          mdHeading = c "base0E";
          mdLink = c "base0D";
          mdLinkUrl = c "base0C";
          mdCode = c "base0B";
          mdCodeBlock = c "base0B";
          mdCodeBlockBorder = c "base02";
          mdQuote = c "base04";
          mdQuoteBorder = c "base02";
          mdHr = c "base03";
          mdListBullet = c "base0D";

          toolDiffAdded = c "base0B";
          toolDiffRemoved = c "base08";
          toolDiffContext = c "base03";

          syntaxComment = c "base03";
          syntaxKeyword = c "base0E";
          syntaxFunction = c "base0D";
          syntaxVariable = c "base05";
          syntaxString = c "base0B";
          syntaxNumber = c "base09";
          syntaxType = c "base0A";
          syntaxOperator = c "base0C";
          syntaxPunctuation = c "base04";

          thinkingOff = c "base03";
          thinkingMinimal = c "base0C";
          thinkingLow = c "base0B";
          thinkingMedium = c "base0A";
          thinkingHigh = c "base09";
          thinkingXhigh = c "base08";
          thinkingMax = c "base08";
          bashMode = c "base0B";
        };

        export = {
          pageBg = c "base00";
          cardBg = c "base01";
          infoBg = c "base01";
        };
      };

    # Herdr's Pi integration is a TypeScript extension it writes into the agent
    # directory. Generate it at build time so a jailed Pi gets it without
    # running the installer.
    herdrExtension =
      pkgs.runCommand "herdr-pi-extension" {
        nativeBuildInputs = [herdrPackage];
      } ''
        mkdir -p home/.pi/agent
        HOME=$TMPDIR/home XDG_CONFIG_HOME=$TMPDIR/home/.config \
          ${lib.getExe herdrPackage} integration install pi >/dev/null
        mkdir -p $out
        cp -a home/.pi/agent/extensions/. $out/
      '';

    configDir = pkgs.runCommand "pi-config" {} ''
      mkdir -p $out
      ${lib.optionalString (settings != {}) ''
        cp ${json.generate "settings.json" settings} $out/settings.json
      ''}
      ${lib.optionalString (models != {}) ''
        cp ${json.generate "models.json" models} $out/models.json
      ''}
      ${lib.optionalString (theme != null) ''
        mkdir -p $out/themes
        cp ${json.generate "stylix-theme.json" theme} $out/themes/stylix.json
      ''}
      ${lib.optionalString herdr ''
        mkdir -p $out/extensions
        cp -a ${herdrExtension}/. $out/extensions/
      ''}
    '';

    wrapper = pkgs.writeShellScriptBin name ''
      ${lib.optionalString (extraPackages != []) ''
        export PATH=${lib.makeBinPath extraPackages}''${PATH:+:$PATH}
      ''}
      # Pi has no config-file flag. It reads settings/models/extensions from its
      # agent directory, so point that at the (jail) home and refresh the
      # Nix-managed files on every launch. Sessions and auth.json are untouched.
      agent_dir="''${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}"
      mkdir -p "$agent_dir"
      # Drop the managed files first: they may be previous copies or symlinks
      # into an immutable store path from a home-manager module.
      ${lib.optionalString (settings != {}) ''
        rm -f "$agent_dir/settings.json"
      ''}
      ${lib.optionalString (models != {}) ''
        rm -f "$agent_dir/models.json"
      ''}
      ${lib.optionalString (theme != null) ''
        rm -f "$agent_dir/themes/stylix.json"
      ''}
      ${lib.optionalString herdr ''
        rm -f "$agent_dir/extensions/herdr-agent-state.ts"
      ''}
      cp -R --no-preserve=mode,ownership ${configDir}/. "$agent_dir/"
      chmod -R u+w "$agent_dir"
      export PI_CODING_AGENT_DIR="$agent_dir"
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
