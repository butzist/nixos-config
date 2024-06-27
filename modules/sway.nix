{
  config,
  lib,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
  ];

  wayland.windowManager.sway.enable = true;
  wayland.windowManager.sway.package = null;
  wayland.windowManager.sway.checkConfig = false;
  wayland.windowManager.sway.config = {
    modifier = "Mod4";
    terminal = "/usr/bin/alacritty";
    menu = "rofi -show drun -show-icons | xargs swaymsg exec --";

    output = {
      "Samsung Electric Company S27F350 H4ZMA14287" =  {
        pos = "0 720";
        res = "1920x1080";
        scale = "1";
      };

      "Samsung Electric Company LS27A600U H4ZT400506" = {
        pos  = "1920 360";
        res = "2560x1440";
        scale = "1";
      }; 

      eDP-1  = {
        pos = "4480 0";
        res = "2880x1800";
        scale = "1.5";
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
      } ;
    };

    bars = [
      { command = "waybar"; }
    ];

    gaps = {
      outer = 20;
      inner = 10;
    };
  };

  wayland.windowManager.sway.systemd.enable = false;
  wayland.windowManager.sway.wrapperFeatures.gtk = true;
  wayland.windowManager.sway.extraConfig = ''
  # Screen lock
    set $lock_command swaylock --daemonize --ignore-empty-password --show-failed-attempts -c000000
    exec swayidle -w \
    timeout 5 'if pgrep -x swaylock; then swaymsg "output * dpms off"; fi' \
    resume 'swaymsg "output * dpms on"' \
    before-sleep "$lock_command"

  # Apply GTK theme
  exec_always ~/bin/import-gsettings
    
  include /etc/sway/config.d/*
  '';
#    Lock after timeout
#    timeout 300 'swaymsg "output * dpms off"' \
#    timeout 305 "$lock_command" \

  wayland.windowManager.sway.config.keybindings = let
    modifier = config.wayland.windowManager.sway.config.modifier;
  in lib.mkOptionDefault {
    "${modifier}+l" = "exec $lock_command";
    "${modifier}+Shift+e" = "exec wlogout";
    Print = "exec grimshot copy anything";
    XF86AudioRaiseVolume = "exec pactl set-sink-volume @DEFAULT_SINK@ +5%";
    XF86AudioLowerVolume = "exec pactl set-sink-volume @DEFAULT_SINK@ -5%";
    XF86AudioMute = "exec pactl set-sink-mute @DEFAULT_SINK@ toggle";
    XF86AudioMicMute = "exec pactl set-source-mute @DEFAULT_SOURCE@ toggle";
    XF86MonBrightnessDown = "exec brightnessctl set 5%-";
    XF86MonBrightnessUp = "exec brightnessctl set 5%+";
  };

  gtk = {
    enable = true;
    iconTheme = {
      package = pkgs.gnome.adwaita-icon-theme;
      name = "Adwaita";
    };
  };

  programs.wlogout.enable = true;
  programs.rofi.enable = true;
  programs.swaylock.enable = true;
}

