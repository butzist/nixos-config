{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./wlogout.nix
  ];

  home.packages = with pkgs; [
    sway-contrib.grimshot
    swayidle
  ];

  wayland.windowManager.sway = {
    enable = true;
    checkConfig = true;

    systemd.enable = true;
    wrapperFeatures.gtk = true;
  };

  wayland.windowManager.sway.config = {
    modifier = "Mod4";
    terminal = "${lib.getExe pkgs.ghostty}";
    menu = "${lib.getExe pkgs.wofi} -I --show drun | xargs swaymsg exec --";

    input = {
      "*" = {
        xkb_options = "compose:menu,caps:escape";
      };
    };

    bars = [
      {
        command = "waybar";
      }
    ];

    gaps = {
      outer = 15;
      inner = 10;
    };
  };

  wayland.windowManager.sway.extraConfig = let
    script = pkgs.writeShellScript "import-gsettings.sh" ''
      config="''${XDG_CONFIG_HOME:-$HOME/.config}/gtk-3.0/settings.ini"
      if [ ! -f "$config" ]; then exit 1; fi

      gnome_schema="org.gnome.desktop.interface"
      gtk_theme="$(grep 'gtk-theme-name' "$config" | sed 's/.*\s*=\s*//')"
      icon_theme="$(grep 'gtk-icon-theme-name' "$config" | sed 's/.*\s*=\s*//')"
      cursor_theme="$(grep 'gtk-cursor-theme-name' "$config" | sed 's/.*\s*=\s*//')"
      font_name="$(grep 'gtk-font-name' "$config" | sed 's/.*\s*=\s*//')"
      gsettings set "$gnome_schema" gtk-theme "$gtk_theme"
      gsettings set "$gnome_schema" icon-theme "$icon_theme"
      gsettings set "$gnome_schema" cursor-theme "$cursor_theme"
      gsettings set "$gnome_schema" font-name "$font_name"
    '';
  in ''
    for_window [title="^.*"] border pixel 2, title_format "%title"

    # Screen lock
      set $lock_command ${lib.getExe pkgs.swaylock} --daemonize --ignore-empty-password --show-failed-attempts -c000000
      exec ${lib.getExe pkgs.swayidle} -w \
      timeout 5 'if pgrep -x swaylock; then swaymsg "output * dpms off"; fi' \
      resume 'swaymsg "output * dpms on"' \
      before-sleep "$lock_command"

    # Apply GTK theme
    exec ${script}
  '';
  #    Lock after timeout
  #    timeout 300 'swaymsg "output * dpms off"' \
  #    timeout 305 "$lock_command" \

  wayland.windowManager.sway.config.keybindings = let
    modifier = config.wayland.windowManager.sway.config.modifier;
  in
    lib.mkOptionDefault {
      "${modifier}+l" = "exec $lock_command";
      "${modifier}+Shift+e" = "exec ${lib.getExe pkgs.wlogout}";
      "${modifier}+Shift+d" = "exec ${lib.getExe pkgs.wdisplays}";
      Print = "exec ${lib.getExe pkgs.sway-contrib.grimshot} copy anything";
      XF86AudioRaiseVolume = "exec pactl set-sink-volume @DEFAULT_SINK@ +5%";
      XF86AudioLowerVolume = "exec pactl set-sink-volume @DEFAULT_SINK@ -5%";
      XF86AudioMute = "exec pactl set-sink-mute @DEFAULT_SINK@ toggle";
      XF86AudioMicMute = "exec pactl set-source-mute @DEFAULT_SOURCE@ toggle";
      XF86MonBrightnessDown = "exec light -U 10";
      XF86MonBrightnessUp = "exec light -A 10";
    };

  programs.wofi.enable = true;
  programs.swaylock.enable = true;

  # Enable the gnome-keyring secrets vault.
  # Will be exposed through DBus to programs willing to store secrets.
  services.gnome-keyring.enable = true;
}
