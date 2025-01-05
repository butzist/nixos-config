{
  pkgs,
  config,
  ...
}: {
  imports = [
    ./wlogout.nix
  ];

  home.packages = with pkgs; [
    hyprshot
    hypridle
    hyprland-qtutils
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    plugins = [pkgs.hyprlandPlugins.hy3];
  };

  wayland.windowManager.hyprland.settings = {
    "$mod" = "SUPER";

    input = {
      kb_options = "compose:menu,caps:escape";
    };

    bind =
      [
        "$mod, Space, exec, ${pkgs.wofi}/bin/wofi -I --show drun"
        "$mod, Return, exec, ${pkgs.ghostty}/bin/ghostty"
        "$mod&Ctrl, L, exec, loginctl lock-session"
        "$mod, E, exec, thunar"
        "$mod&Shift, Q, exec, ${pkgs.wlogout}/bin/wlogout"
        "$mod, D, exec, ${pkgs.wdisplays}/bin/wdisplays"
        ", Print, exec, ${pkgs.hyprshot}/bin/hyprshot -m region --freeze --clipboard-only"
        "Shift, Print, exec, ${pkgs.hyprshot}/bin/hyprshot -m region --freeze"
        "$mod, Print, exec, ${pkgs.kooha}/bin/kooha"
        ", XF86AudioRaiseVolume, exec, pactl set-sink-volume @DEFAULT_SINK@ +5%"
        ", XF86AudioLowerVolume, exec, pactl set-sink-volume @DEFAULT_SINK@ -5%"
        ", XF86AudioMute, exec, pactl set-sink-mute @DEFAULT_SINK@ toggle"
        ", XF86AudioMicMute, exec, pactl set-source-mute @DEFAULT_SOURCE@ toggle"
        ", XF86MonBrightnessDown, exec, light -U 10"
        ", XF86MonBrightnessUp, exec, light -A 10"
        "$mod, Left, hy3:movefocus, l"
        "$mod, Up, hy3:movefocus, u"
        "$mod, Down, hy3:movefocus, d"
        "$mod, Right, hy3:movefocus, r"
        "$mod, H, hy3:movefocus, l"
        "$mod, K, hy3:movefocus, u"
        "$mod, J, hy3:movefocus, d"
        "$mod, L, hy3:movefocus, r"
        "$mod&Shift, Left, hy3:movewindow, l"
        "$mod&Shift, Up, hy3:movewindow, u"
        "$mod&Shift, Down, hy3:movewindow, d"
        "$mod&Shift, Right, hy3:movewindow, r"
        "$mod&Shift, H, hy3:movewindow, l"
        "$mod&Shift, K, hy3:movewindow, u"
        "$mod&Shift, J, hy3:movewindow, d"
        "$mod&Shift, L, hy3:movewindow, r"
        "$mod, mouse_down, workspace, e+1"
        "$mod, mouse_up, workspace, e-1"
        "$mod, C, killactive"
        "$mod, W, hy3:makegroup, tab"
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

    windowrulev2 = [
      "noblur,class:^()$,title:^()$"
    ];

    general = {
      layout = "hy3";
    };

    plugin = {
      hy3 = {
        tabs = with config.lib.stylix.colors; let
          rgba = color: alpha: "rgba(${color}${alpha})";
        in {
          rounding = 5;

          "col.text.active" = rgba base05 "ff";
          "col.text.inactive" = rgba base05 "ff";
          "col.active" = rgba base0D "ff";
          "col.inactive" = rgba base03 "80";
        };

        autotile = {
          enable = true;
        };
      };
    };

    exec-once = [
      "waybar"
    ];
  };

  wayland.windowManager.hyprland.systemd = {
    enable = true;
    variables = ["--all"];
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
