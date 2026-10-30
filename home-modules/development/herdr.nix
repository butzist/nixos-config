{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  colors = config.lib.stylix.colors;
  hex = name: "#${colors.${name}}";

  herdr = inputs.nix-ai-tools.packages.${pkgs.stdenv.hostPlatform.system}.herdr;
  herdrAuthProxy = inputs.herdr-auth-proxy.packages.${pkgs.stdenv.hostPlatform.system}.default;

  # Herdr's socket API has no authentication. Start the auth proxy alongside
  # the server and keep the real socket private; jailed agents are pointed at
  # the proxy's JWT-gated auth socket by the agent policy. The proxy resolves
  # its upstream socket before herdr runs, so mirror --session into the env it
  # reads (HERDR_SESSION).
  #
  # `wrap` always exports a usable HERDR_AUTH_JWT itself: fresh from the proxy
  # it starts, re-adopted from the running server (verified with auth.hello), or
  # after replacing a stale proxy when no server is running. A running server
  # without a usable token cannot be repaired from outside, so `wrap` fails
  # closed and tells the user to restart it; do not restart the server behind
  # their back here.
  herdrWrapped = pkgs.writeShellScriptBin "herdr" ''
    set -euo pipefail

    realHerdr=${lib.getExe herdr}
    proxy=${herdrAuthProxy}/bin/herdr-auth-proxy

    session=""
    prev=""
    for arg in "$@"; do
      if [ "$prev" = "--session" ]; then
        session="$arg"
      fi
      case "$arg" in
        --session=*) session="''${arg#--session=}" ;;
      esac
      prev="$arg"
    done
    # `herdr session attach <name>` is rewritten by herdr into a default launch.
    if [ "''${1:-}" = "session" ] && [ "''${2:-}" = "attach" ] && [ -n "''${3:-}" ]; then
      session="$3"
    fi
    # herdr omits HERDR_SESSION from the default session's environment.
    if [ "$session" = "default" ]; then
      session=""
      unset HERDR_SESSION
    fi
    if [ -n "$session" ]; then
      export HERDR_SESSION="$session"
    fi

    # CLI subcommands are the operator talking to herdr's real socket; only the
    # TUI launcher (and the hidden client mode) need the proxy-wrapped env. In
    # particular `herdr server stop` must pass through even when `wrap` would
    # otherwise refuse to run because the running server has no usable token.
    for arg in "$@"; do
      case "$arg" in
        --remote | --remote=* | --machine | --machine=* | --help | -h | --version | -V | --default-config | --skill)
          exec "$realHerdr" "$@"
          ;;
      esac
    done
    case "''${1:-}" in
      "" | client | --session | --session=* | --handoff) ;;
      session)
        if [ "''${2:-}" != "attach" ]; then
          exec "$realHerdr" "$@"
        fi
        ;;
      *)
        exec "$realHerdr" "$@"
        ;;
    esac

    exec "$proxy" wrap -- "$realHerdr" "$@"
  '';

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

    # Mirror the zellij keymap (home-modules/zellij.nix): Super+Alt is the Herdr
    # layer, j/k step through workspaces, h/l through tabs, t/w open a new
    # tab/workspace and q detaches (exits the TUI, leaving the server running).
    # Super+Alt+g takes over from ctrl+b as the prefix.
    keys = {
      prefix = "super+alt+g";

      detach = ["prefix+q" "super+alt+q"];

      previous_workspace = "super+alt+k";
      next_workspace = "super+alt+j";

      previous_tab = ["prefix+p" "super+alt+h"];
      next_tab = ["prefix+n" "super+alt+l"];

      new_tab = ["prefix+c" "super+alt+t"];
      new_workspace = ["prefix+shift+n" "super+alt+w"];
    };

    # Background agents report through the desktop notification service
    # (dunst here; Herdr shells out to notify-send on Linux) instead of
    # covering pane output with in-app toasts.
    ui.toast.delivery = "system";
  };
in {
  # notify-send is what `delivery = "system"` executes on Linux. The proxy
  # package also provides the `herdr-auth` client used to drive gated agents.
  home.packages =
    [herdrWrapped herdrAuthProxy]
    ++ lib.optionals (!pkgs.stdenv.hostPlatform.isDarwin) [pkgs.libnotify];

  xdg.configFile."herdr/config.toml".source =
    (pkgs.formats.toml {}).generate "herdr-config.toml" herdrConfig;

  # Herdr writes its bundled plugins itself; let the binary install the one
  # matching its version instead of vendoring the JS in this repo.
  home.activation.herdr-opencode-integration = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [ -x ${herdr}/bin/herdr ]; then
      run mkdir -p "$HOME/.config/opencode"
      run ${herdr}/bin/herdr integration install opencode
    fi
  '';
}
