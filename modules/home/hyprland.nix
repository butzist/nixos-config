{
  pkgs,
  config,
  lib,
  ...
}: {
  imports = [
    ./wlogout.nix
  ];

  home.packages = with pkgs; [
    hyprland-qtutils
    pix
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = true;
    plugins = [];
  };

  wayland.windowManager.hyprland.settings = {
    "$mod" = "SUPER";

    ecosystem = {
      no_update_news = true;
      no_donation_nag = true;
    };

    input = {
      kb_options = "compose:menu,caps:escape";
    };

    bind =
      [
        "$mod, Space, exec, ${lib.getExe pkgs.wofi} -I --show drun"
        "$mod, Return, exec, ${lib.getExe pkgs.kitty}"
        "$mod&Ctrl, L, exec, loginctl lock-session"
        "$mod, E, exec, thunar"
        "$mod&Shift, Q, exec, ${lib.getExe pkgs.wlogout}"
        "$mod, D, exec, ${lib.getExe pkgs.wdisplays}"
        ", Print, exec, ${lib.getExe pkgs.hyprshot} -m region --freeze --clipboard-only"
        "Shift, Print, exec, ${lib.getExe pkgs.hyprshot} -m region --freeze"
        "$mod, Print, exec, ${lib.getExe pkgs.kooha}"
        ", XF86AudioRaiseVolume, exec, ${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ +5%"
        ", XF86AudioLowerVolume, exec, ${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ -5%"
        ", XF86AudioMute, exec, ${pkgs.pulseaudio}/bin/pactl set-sink-mute @DEFAULT_SINK@ toggle"
        ", XF86AudioMicMute, exec, ${pkgs.pulseaudio}/bin/pactl set-source-mute @DEFAULT_SOURCE@ toggle"
        ", XF86MonBrightnessDown, exec, ${lib.getExe pkgs.light} -U 10"
        ", XF86MonBrightnessUp, exec, ${lib.getExe pkgs.light} -A 10"
        "$mod, Left, movefocus, l"
        "$mod, Up, movefocus, u"
        "$mod, Down, movefocus, d"
        "$mod, Right, movefocus, r"
        "$mod, H, movefocus, l"
        "$mod, K, movefocus, u"
        "$mod, J, movefocus, d"
        "$mod, L, movefocus, r"
        "$mod, I, changegroupactive, f"
        "$mod, U, changegroupactive, b"
        "$mod&Shift, Left, movewindoworgroup, l"
        "$mod&Shift, Up, movewindoworgroup, u"
        "$mod&Shift, Down, movewindoworgroup, d"
        "$mod&Shift, Right, movewindoworgroup, r"
        "$mod&Shift, H, movewindoworgroup, l"
        "$mod&Shift, K, movewindoworgroup, u"
        "$mod&Shift, J, movewindoworgroup, d"
        "$mod&Shift, L, movewindoworgroup, r"
        "$mod, W, togglegroup, tab"
        "$mod, mouse_down, workspace, e+1"
        "$mod, mouse_up, workspace, e-1"
        "$mod, C, killactive"
        "$mod, F, fullscreen"
        "$mod&Shift, F, togglefloating"
      ]
      ++ (
        # workspaces
        # binds $mod + [shift +] {1..10} to [move to] workspace {1..10}
        builtins.concatLists (builtins.genList (
            x: let
              ws = let
                c = (x + 1) / 10;
              in
                builtins.toString (x + 1 - (c * 10));
            in [
              "$mod, ${ws}, workspace, ${toString (x + 1)}"
              "$mod SHIFT, ${ws}, movetoworkspace, ${toString (x + 1)}"
            ]
          )
          10)
      );

    bindm = [
      "$mod, mouse:272, movewindow"
      "$mod, mouse:273, resizewindow"
    ];

    decoration = {
      rounding = 20;

      blur = {
        enabled = true;
        xray = true;
        special = false;
        new_optimizations = true;
        size = 14;
        passes = 4;
        brightness = 1;
        noise = 0.01;
        contrast = 1;
        popups = true;
        popups_ignorealpha = 0.6;
      };

      shadow = {
        enabled = true;
        ignore_window = true;
        range = 20;
        offset = "0 2";
        render_power = 4;
      };
    };

    windowrule = {
      name = "tool windows";
      "match:class" = "^()$";
      "match:title" = "^()$";

      no_blur = true;
    };

    exec-once = [
      "waybar"
    ];
  };

  programs.wofi.enable = true;
  programs.hyprlock.enable = true;
  stylix.targets.hyprlock.enable = false;
  programs.hyprlock.settings = {
    general = {
      disable_loading_bar = true;
      grace = 0;
      hide_cursor = true;
      no_fade_in = false;
    };

    background = [
      {
        path = "screenshot";
        blur_passes = 3;
        blur_size = 8;
      }
    ];

    input-field = let
      colors = config.lib.stylix.colors;
    in [
      {
        size = "200, 50";
        position = "0, -80";
        monitor = "";
        dots_center = true;
        fade_on_empty = false;
        font_color = "rgb(${colors.base0E})";
        inner_color = "rgb(${colors.base02})";
        outer_color = "rgb(${colors.base01})";
        outline_thickness = 5;
        placeholder_text = "<span foreground=\"##${colors.base05}\">Password...</span>";
        shadow_passes = 2;
      }
    ];
  };

  services.hyprpaper.enable = true;

  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "pidof hyprlock || hyprlock"; # avoid starting multiple hyprlock instances.
        ignore_dbus_inhibit = false;
        before_sleep_cmd = "loginctl lock-session"; # lock before suspend.
        after_sleep_cmd = "hyprctl dispatch dpms on"; # to avoid having to press a key twice to turn on the display.
      };

      listener = [
        {
          timeout = 30;
          on-timeout = "pidof hyprlock && hyprctl dispatch dpms off"; # screen off when timeout has passed
          on-resume = "hyprctl dispatch dpms on"; # screen on when activity is detected after timeout has fired.
        }
      ];
    };
  };

  # Enable the gnome-keyring secrets vault.
  # Will be exposed through DBus to programs willing to store secrets.
  services.gnome-keyring.enable = true;

  services.dunst.enable = true;

  systemd.user.sessionVariables.NIXOS_OZONE_WL = "1";
}
