{
  config,
  lib,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    sway-contrib.grimshot
    swayidle
  ];

  wayland.windowManager.sway.enable = true;
  wayland.windowManager.sway.package = null;
  wayland.windowManager.sway.checkConfig = true;
  wayland.windowManager.sway.config = {
    modifier = "Mod4";
    terminal = "${pkgs.alacritty}/bin/alacritty";
    menu = "${pkgs.wofi}/bin/wofi -I --show drun | xargs swaymsg exec --";

    output = {
      "Samsung Electric Company S27F350 H4ZMA14287" = {
        pos = "0 720";
        res = "1920x1080";
        scale = "1";
      };

      "Samsung Electric Company LS27A600U H4ZT400506" = {
        pos = "1920 360";
        res = "2560x1440";
        scale = "1";
      };
    };

    input = {
      "1267:12693:ELAN0676:00_04F3:3195_Touchpad" = {
        dwt = "enabled";
        tap = "enabled";
        natural_scroll = "enabled";
        middle_emulation = "disabled";
      };

      "*" = {
        xkb_options = "compose:menu";
      };
    };

    bars = [];

    gaps = {
      outer = 15;
      inner = 10;
    };
  };

  wayland.windowManager.sway.systemd.enable = true;
  wayland.windowManager.sway.wrapperFeatures.gtk = true;
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
      set $lock_command swaylock --daemonize --ignore-empty-password --show-failed-attempts -c000000
      exec swayidle -w \
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
      "${modifier}+Shift+e" = "exec ${pkgs.wlogout}/bin/wlogout";
      "${modifier}+Shift+d" = "exec ${pkgs.wdisplays}/bin/wdisplays";
      Print = "exec grimshot copy anything";
      XF86AudioRaiseVolume = "exec pactl set-sink-volume @DEFAULT_SINK@ +5%";
      XF86AudioLowerVolume = "exec pactl set-sink-volume @DEFAULT_SINK@ -5%";
      XF86AudioMute = "exec pactl set-sink-mute @DEFAULT_SINK@ toggle";
      XF86AudioMicMute = "exec pactl set-source-mute @DEFAULT_SOURCE@ toggle";
      XF86MonBrightnessDown = "exec light -U 10";
      XF86MonBrightnessUp = "exec light -A 10";
    };

  gtk = {
    enable = true;
    iconTheme = {
      package = pkgs.gnome.adwaita-icon-theme;
      name = "Adwaita";
    };
  };

  programs.wofi.enable = true;
  programs.wlogout.enable = true;
  programs.swaylock.enable = true;

  # Enable the gnome-keyring secrets vault.
  # Will be exposed through DBus to programs willing to store secrets.
  services.gnome-keyring.enable = true;
}
