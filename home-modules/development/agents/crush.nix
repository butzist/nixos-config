{pkgs}: {
  # Crush's bundled Catwalk catalog already knows the OpenCode Go provider
  # (api_key = $OPENCODE_API_KEY), so only the model choice and the shared MCP
  # toolchain have to be pinned here. Crush runs commands through its embedded
  # bash, so the rtk shell cannot be injected.
  defaultConfig = {
    "$schema" = "https://charm.land/crush.json";
    models = {
      large = {
        provider = "opencode-go";
        model = "deepseek-v4.1-flash";
      };
      small = {
        provider = "opencode-go";
        model = "deepseek-v4.1-flash";
      };
    };
    mcp.serena = {
      type = "stdio";
      command = "${pkgs.serena}/bin/serena";
      args = ["start-mcp-server" "--context" "agent"];
    };
    options = {
      disable_metrics = true;
      tui.active_theme = "stylix";
    };
  };

  mkPackage = {
    name ? "crush",
    config ? {},
    colors ? null,
    package ? pkgs.crush,
    extraPackages ? [],
  }: let
    inherit (pkgs) lib;

    # Base16 palette for Crush's custom theme format. Every Palette field is
    # mapped so the TUI follows the Stylix scheme instead of its bundled
    # charm/gruvbox palettes. `colors` is config.lib.stylix.colors.
    theme =
      if colors == null
      then null
      else let
        c = key: colors.withHashtag.${key};
      in {
        base = "charmtone-panther";

        primary = c "base0D";
        secondary = c "base0E";
        accent = c "base0C";
        keyword = c "base0E";

        fg_base = c "base05";
        fg_subtle = c "base04";
        fg_more_subtle = c "base03";
        fg_most_subtle = c "base03";

        bg_base = c "base00";
        bg_least_visible = c "base01";
        bg_less_visible = c "base02";
        bg_most_visible = c "base02";

        on_primary = c "base00";
        separator = c "base02";

        destructive = c "base08";
        error = c "base08";
        warning = c "base09";
        warning_subtle = c "base0A";
        attention = c "base09";
        busy = c "base0A";
        info = c "base0D";
        info_more_subtle = c "base0D";
        info_most_subtle = c "base0C";
        success = c "base0B";
        success_more_subtle = c "base0B";
        success_most_subtle = c "base0C";

        diff_insert_fg = c "base0B";
        diff_insert_code_bg = c "base01";
        diff_insert_gutter_bg = c "base02";
        diff_delete_fg = c "base08";
        diff_delete_code_bg = c "base01";
        diff_delete_gutter_bg = c "base02";

        yolo = c "base0A";
        plan = c "base0E";
        plan_more_subtle = c "base01";

        button = c "base0D";
        button_subtle = c "base01";
        button_inactive = c "base02";
        button_hovered = c "base03";

        ansi_black = c "base00";
        ansi_red = c "base08";
        ansi_green = c "base0B";
        ansi_yellow = c "base0A";
        ansi_blue = c "base0D";
        ansi_magenta = c "base0E";
        ansi_cyan = c "base0C";
        ansi_white = c "base05";

        ansi_bright_black = c "base03";
        ansi_bright_red = c "base08";
        ansi_bright_green = c "base0B";
        ansi_bright_yellow = c "base0A";
        ansi_bright_blue = c "base0D";
        ansi_bright_magenta = c "base0E";
        ansi_bright_cyan = c "base0C";
        ansi_bright_white = c "base07";
      };

    configFile = (pkgs.formats.json {}).generate "crush.json" config;

    # CRUSH_GLOBAL_CONFIG points at a *directory*; crush reads <dir>/crush.json
    # from it and looks for custom themes in <dir>/themes. Keeping both in the
    # store makes the setup identical inside and outside the jail.
    configDir = pkgs.runCommand "crush-config" {} ''
      mkdir -p $out
      ln -s ${configFile} $out/crush.json
      ${lib.optionalString (theme != null) ''
        mkdir -p $out/themes
        ln -s ${(pkgs.formats.json {}).generate "stylix.json" theme} $out/themes/stylix.json
      ''}
    '';

    wrapper = pkgs.writeShellScriptBin name ''
      ${lib.optionalString (extraPackages != []) ''
        export PATH=${lib.makeBinPath extraPackages}''${PATH:+:$PATH}
      ''}
      export CRUSH_GLOBAL_CONFIG=${configDir}
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
