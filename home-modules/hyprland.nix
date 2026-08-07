{
  pkgs,
  config,
  lib,
  ...
}: {
  home.packages = with pkgs; [
    hyprland-qtutils
    pix
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = true;
    configType = "lua";
    plugins = [];
  };

  wayland.windowManager.hyprland.settings = let
    inline = lib.generators.mkLuaInline;

    # Concatenate modifiers and key into a Lua expression. The token `mod`
    # expands to the Lua local defined by the `mod` variable below.
    keys = mods: key:
      inline (
        builtins.concatStringsSep " .. \" + \" .. " (
          map (m:
            if m == "mod"
            then "mod"
            else "\"${m}\"")
          mods
          ++ ["\"${key}\""]
        )
      );

    exec = cmd: inline "hl.dsp.exec_cmd(\"${cmd}\")";
    focusMonitor = mon: inline "hl.dsp.focus({ monitor = \"${mon}\" })";
    focusWorkspace = ws:
      inline "hl.dsp.focus({ workspace = ${
        if builtins.isInt ws
        then toString ws
        else "\"${ws}\""
      } })";
    moveToWorkspace = ws:
      inline "hl.dsp.window.move({ workspace = ${
        if builtins.isInt ws
        then toString ws
        else "\"${ws}\""
      } })";
    layout = msg: inline "hl.dsp.layout(\"${msg}\")";
    moveWindowOrGroup = dir: inline "hl.dsp.window.move({ direction = \"${dir}\", group_aware = true })";
    groupActive = next:
      inline (
        if next
        then "hl.dsp.group.next()"
        else "hl.dsp.group.prev()"
      );

    mkBind = mods: key: dispatch: {
      _args = [
        (keys mods key)
        dispatch
      ];
    };

    mkBindMouse = mods: key: dispatch: {
      _args = [
        (keys mods key)
        dispatch
        {mouse = true;}
      ];
    };
  in {
    mod = {
      _var = "SUPER";
    };

    config = {
      ecosystem = {
        no_update_news = true;
        no_donation_nag = true;
      };

      general = {
        layout = "scrolling";
      };

      input = {
        kb_options = "compose:menu,caps:escape";
      };

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
          range = 20;
          offset = [0 2];
          render_power = 4;
        };
      };

      scrolling = {
        fullscreen_on_one_column = true;
        column_width = 0.95;
        direction = "right";
      };
    };

    bind =
      [
        (mkBind ["mod"] "Space" (exec "walker"))
        (mkBind ["mod"] "Return" (exec (lib.getExe pkgs.kitty)))
        (mkBind ["mod" "CTRL"] "L" (exec "loginctl lock-session"))
        (mkBind ["mod"] "E" (exec "thunar"))
        (mkBind ["mod" "SHIFT"] "Q" (exec (lib.getExe pkgs.wlogout)))
        (mkBind ["mod"] "D" (exec (lib.getExe pkgs.wdisplays)))
        (mkBind [] "Print" (exec "${lib.getExe pkgs.hyprshot} -m region --freeze --clipboard-only"))
        (mkBind ["SHIFT"] "Print" (exec "${lib.getExe pkgs.hyprshot} -m region --freeze"))
        (mkBind ["mod"] "Print" (exec (lib.getExe pkgs.kooha)))
        (mkBind [] "XF86AudioRaiseVolume" (exec "${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ +5%"))
        (mkBind [] "XF86AudioLowerVolume" (exec "${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ -5%"))
        (mkBind [] "XF86AudioMute" (exec "${pkgs.pulseaudio}/bin/pactl set-sink-mute @DEFAULT_SINK@ toggle"))
        (mkBind [] "XF86AudioMicMute" (exec "${pkgs.pulseaudio}/bin/pactl set-source-mute @DEFAULT_SOURCE@ toggle"))
        (mkBind [] "XF86MonBrightnessDown" (exec "${lib.getExe pkgs.brightnessctl} set 10%-"))
        (mkBind [] "XF86MonBrightnessUp" (exec "${lib.getExe pkgs.brightnessctl} set +10%"))
        (mkBind ["mod"] "Left" (focusMonitor "l"))
        (mkBind ["mod"] "Up" (layout "move -col"))
        (mkBind ["mod"] "Down" (layout "move +col"))
        (mkBind ["mod"] "Right" (focusMonitor "r"))
        (mkBind ["mod"] "H" (focusMonitor "l"))
        (mkBind ["mod"] "J" (layout "move -col"))
        (mkBind ["mod"] "K" (layout "move +col"))
        (mkBind ["mod"] "L" (focusMonitor "r"))
        (mkBind ["mod"] "I" (groupActive true))
        (mkBind ["mod"] "U" (groupActive false))
        (mkBind ["mod" "SHIFT"] "Left" (moveWindowOrGroup "left"))
        (mkBind ["mod" "SHIFT"] "Up" (layout "swapcol l"))
        (mkBind ["mod" "SHIFT"] "Down" (layout "swapcol r"))
        (mkBind ["mod" "SHIFT"] "Right" (moveWindowOrGroup "right"))
        (mkBind ["mod" "SHIFT"] "H" (moveWindowOrGroup "left"))
        (mkBind ["mod" "SHIFT"] "J" (layout "swapcol u"))
        (mkBind ["mod" "SHIFT"] "K" (layout "swapcol d"))
        (mkBind ["mod" "SHIFT"] "L" (moveWindowOrGroup "right"))
        (mkBind ["mod"] "W" (inline "hl.dsp.group.toggle()"))
        (mkBind ["mod"] "mouse_down" (focusWorkspace "e+1"))
        (mkBind ["mod"] "mouse_up" (focusWorkspace "e-1"))
        (mkBind ["mod"] "C" (inline "hl.dsp.window.close()"))
        (mkBind ["mod"] "F" (inline "hl.dsp.window.fullscreen({ action = \"toggle\" })"))
        (mkBind ["mod" "SHIFT"] "F" (inline "hl.dsp.window.float({ action = \"toggle\" })"))
        (mkBindMouse ["mod"] "mouse:272" (inline "hl.dsp.window.drag()"))
        (mkBindMouse ["mod"] "mouse:273" (inline "hl.dsp.window.resize()"))
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
              (mkBind ["mod"] ws (focusWorkspace (x + 1)))
              (mkBind ["mod" "SHIFT"] ws (moveToWorkspace (x + 1)))
            ]
          )
          10)
      );

    window_rule = {
      name = "tool windows";
      match = {
        class = "^()$";
        title = "^()$";
      };

      no_blur = true;
    };

    on = {
      _args = [
        "hyprland.start"
        (inline "function()\n  hl.exec_cmd(\"waybar\")\nend")
      ];
    };
  };

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
