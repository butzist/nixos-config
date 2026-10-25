{
  config,
  lib,
  pkgs,
  ...
}: let
  colors = config.lib.stylix.colors;
  hex = name: "#${colors.${name}}";

  # Herdr's "terminal" base theme already follows the terminal palette; the
  # custom tokens pin the remaining UI surfaces to Stylix's base16 scheme.
  herdrConfig = {
    # Notification setup is chosen below, so never show the first-run wizard.
    onboarding = false;

    theme = {
      name = "terminal";
      custom = {
        panel_bg = hex "base00";
        sidebar_bg = hex "base01";
        active_row_bg = hex "base02";
        selection_bg = hex "base02";
        surface0 = hex "base01";
        surface1 = hex "base02";
        surface_dim = hex "base03";
        overlay0 = hex "base03";
        overlay1 = hex "base04";
        text = hex "base05";
        subtext0 = hex "base04";
        accent = hex "base0D";
        red = hex "base08";
        green = hex "base0B";
        yellow = hex "base0A";
        blue = hex "base0D";
        teal = hex "base0C";
        peach = hex "base09";
        mauve = hex "base0E";
      };
    };

    # Background agents report through the desktop notification service
    # (dunst here; Herdr shells out to notify-send on Linux) instead of
    # covering pane output with in-app toasts.
    ui.toast.delivery = "system";
  };
in {
  # notify-send is what `delivery = "system"` executes on Linux.
  home.packages =
    [pkgs.herdr]
    ++ lib.optionals (!pkgs.stdenv.hostPlatform.isDarwin) [pkgs.libnotify];

  xdg.configFile."herdr/config.toml".source =
    (pkgs.formats.toml {}).generate "herdr-config.toml" herdrConfig;

  # Herdr writes its bundled plugins itself; let the binary install the one
  # matching its version instead of vendoring the JS in this repo.
  home.activation.herdr-opencode-integration = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [ -x ${pkgs.herdr}/bin/herdr ]; then
      run mkdir -p "$HOME/.config/opencode"
      run ${pkgs.herdr}/bin/herdr integration install opencode
    fi
  '';
}
