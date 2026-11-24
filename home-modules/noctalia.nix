{
  config,
  pkgs,
  lib,
  ...
}: let
  toml = pkgs.formats.toml {};

  colors = config.lib.stylix.colors.withHashtag;
  solid = color: "${color}FF";
  translucent = color: alpha: "${color}${alpha}";
  uiFont = "${config.stylix.fonts.sansSerif.name} ${toString config.stylix.fonts.sizes.desktop}";

  noctalia = "${lib.getExe pkgs.noctalia} msg";

  workspaceBinds = builtins.listToAttrs (
    builtins.concatLists (
      builtins.genList (
        i: let
          workspace = i + 1;
          key =
            if workspace == 10
            then "0"
            else toString workspace;
        in [
          {
            name = "Mod+${key}";
            value = "workspace-switch ${toString workspace}";
          }
          {
            name = "Mod+Shift+${key}";
            value = "window-move-to-workspace ${toString workspace}";
          }
        ]
      )
      10
    )
  );

  umbrielSettings = {
    general = {
      autostart = ["noctalia"];
      mod_key = "Super";
      # The startup keybind cheatsheet is noise; the binds are configured here.
      show_cheatsheet = false;
      xwayland = true;
      xwayland_xsettings = true;
      nvidia_sync_workaround = true;
    };

    input = {
      keyboard.options = "compose:menu,caps:escape";
      cursor = {
        theme = config.stylix.cursor.name;
        size = config.stylix.cursor.size;
      };
      # Sloppy focus: pointer motion focuses the window under the cursor, while
      # keyboard-driven focus stays put until the pointer actually moves onto
      # another window. `always` would also refocus under a stationary pointer.
      focus.follows_mouse = "sloppy";
    };

    appearance = {
      prefer_no_csd = true;
      border_width = 2;
      outer_border_width = 0;
      corner_radius = 10;
      drag_opacity = 0.85;
      opaque_fullscreen = true;

      # The active window title lives in the bar's center lane, so the window
      # frame keeps only its border. Floating windows still resize from their
      # edges, and Mod+C / Mod+F remain the close and maximize controls.
      title_bar = {
        mode = "off";
        height = 28;
        font = uiFont;
        title_align = "left";
        button_position = "right";
        buttons = ["minimize" "maximize" "close"];
        button_corner_radius = 6;
      };

      tab_bar = {
        style = "titles";
        height = 26;
        font = uiFont;
        corner_radius = 8;
        hide_when_single = true;
        max_tabs = 6;
      };

      blur = {
        enabled = true;
        optimized = true;
        passes = 2;
        radius = 3;
        noise = 0.01;
        brightness = 1.0;
        contrast = 1.0;
        saturation = 1.0;
      };

      shadow = {
        enabled = true;
        softness = 12;
        offset_x = 0;
        offset_y = 4;
      };
    };

    colors = {
      background = solid colors.base00;
      text_primary = solid colors.base05;
      text_muted = solid colors.base04;
      accent_primary = solid colors.base0D;
      accent_secondary = solid colors.base0E;
      warning = solid colors.base0A;
      error = solid colors.base08;
      insert_hint = translucent colors.base0D "80";
      backdrop = "#000000FF";
      shadow = "#0000007F";

      border = {
        focused = solid colors.base0D;
        unfocused = solid colors.base03;
        outer = solid colors.base00;
      };

      overview = {
        background_tint = translucent colors.base00 "30";
        workspace_background = "#00000044";
        badge = solid colors.base0D;
      };

      title_bar = {
        background = solid colors.base01;
        background_unfocused = solid colors.base00;
        text = solid colors.base05;
        text_unfocused = solid colors.base04;
        close = solid colors.base08;
        close_glyph = solid colors.base00;
        close_glyph_hover = solid colors.base00;
        maximize = solid colors.base0D;
        maximize_glyph = solid colors.base00;
        maximize_glyph_hover = solid colors.base00;
        minimize = solid colors.base0A;
        minimize_glyph = solid colors.base00;
        minimize_glyph_hover = solid colors.base00;
      };

      tab_bar = {
        background = solid colors.base01;
        text = solid colors.base04;
        active = solid colors.base0D;
        active_text = solid colors.base00;
        active_unfocused = solid colors.base03;
        active_unfocused_text = solid colors.base05;
        urgent = solid colors.base08;
        urgent_text = solid colors.base00;
      };
    };

    layout = {
      mode = "scrolling";
      extent_presets = [0.5 0.75 0.95];
      scrolling.default_extent_fraction = 0.95;
    };

    keybinds =
      {
        # Applications and shell surfaces.
        "Mod+Space" = {
          action = "spawn ${noctalia} panel-toggle launcher";
          repeat = false;
        };
        "Mod+Return" = {
          action = "spawn ${lib.getExe pkgs.kitty}";
          repeat = false;
        };
        "Mod+E" = {
          action = "spawn ${lib.getExe pkgs.thunar}";
          repeat = false;
        };
        "Mod+D" = {
          action = "spawn ${lib.getExe pkgs.wdisplays}";
          repeat = false;
        };
        "Mod+S" = {
          action = "spawn ${noctalia} panel-toggle control-center";
          repeat = false;
        };
        "Mod+Comma" = {
          action = "spawn ${noctalia} settings-toggle";
          repeat = false;
        };
        "Mod+Ctrl+L" = {
          action = "spawn ${noctalia} session lock";
          repeat = false;
        };
        "Mod+Shift+Q" = {
          action = "spawn ${noctalia} panel-toggle session";
          repeat = false;
        };
        "Mod+Escape" = {
          action = "session-quit";
          repeat = false;
        };

        # Focus, tabs and monitors. H/L cross outputs, J/K step between windows
        # on the current workspace; arrows keep the layout-level window controls.
        "Mod+Left" = "window-focus-left";
        "Mod+Right" = "window-focus-right";
        "Mod+Up" = "window-focus-up";
        "Mod+Down" = "window-focus-down";
        "Mod+H" = "output-focus-left";
        "Mod+L" = "output-focus-right";
        "Mod+J" = "window-focus-left";
        "Mod+K" = "window-focus-right";
        "Mod+I" = "column-focus-tab-next";
        "Mod+U" = "column-focus-tab-previous";
        "Mod+Shift+Left" = "column-move-left";
        "Mod+Shift+Right" = "column-move-right";
        "Mod+Shift+Up" = "window-move-up";
        "Mod+Shift+Down" = "window-move-down";
        "Mod+Shift+H" = "window-move-to-output-left";
        "Mod+Shift+L" = "window-move-to-output-right";
        "Mod+Shift+J" = "window-move-left";
        "Mod+Shift+K" = "window-move-right";
        "Mod+WheelUp" = "workspace-previous";
        "Mod+WheelDown" = "workspace-next";
        "Mod+MouseBack" = "workspace-previous";
        "Mod+MouseForward" = "workspace-next";
        "Mod+MouseMiddle" = "layout-scroll-drag";
        "Mod+O" = {
          action = "overview-toggle";
          repeat = false;
        };

        # Window state.
        "Mod+C" = {
          action = "window-close";
          repeat = false;
        };
        "Mod+F" = {
          action = "window-toggle-fullscreen";
          repeat = false;
        };
        "Mod+Shift+F" = {
          action = "window-toggle-floating";
          repeat = false;
        };
        "Mod+W" = {
          action = "column-toggle-tabbed";
          repeat = false;
        };
        "Alt+Tab" = "spawn ${noctalia} window-switcher hold";
        "Alt+Shift+Tab" = "spawn ${noctalia} window-switcher hold reverse";

        # Screenshots and recording.
        "Print" = {
          action = "spawn ${noctalia} screenshot-region";
          repeat = false;
        };
        "Shift+Print" = {
          action = "spawn ${noctalia} screenshot-region --no-copy-to-clipboard";
          repeat = false;
        };
        "Mod+Print" = {
          action = "spawn ${lib.getExe pkgs.kooha}";
          repeat = false;
        };

        # Multimedia and display keys, routed through Noctalia for its OSDs.
        "XF86AudioRaiseVolume" = {
          action = "spawn ${noctalia} volume-up 5";
          allow_when_locked = true;
        };
        "XF86AudioLowerVolume" = {
          action = "spawn ${noctalia} volume-down 5";
          allow_when_locked = true;
        };
        "XF86AudioMute" = {
          action = "spawn ${noctalia} volume-mute";
          allow_when_locked = true;
          repeat = false;
        };
        "XF86AudioMicMute" = {
          action = "spawn ${noctalia} mic-mute";
          allow_when_locked = true;
          repeat = false;
        };
        "XF86AudioPlay" = {
          action = "spawn ${noctalia} media toggle";
          allow_when_locked = true;
          repeat = false;
        };
        "XF86AudioNext" = {
          action = "spawn ${noctalia} media next";
          allow_when_locked = true;
        };
        "XF86AudioPrev" = {
          action = "spawn ${noctalia} media previous";
          allow_when_locked = true;
        };
        "XF86MonBrightnessUp" = {
          action = "spawn ${noctalia} brightness-up 10";
          allow_when_locked = true;
        };
        "XF86MonBrightnessDown" = {
          action = "spawn ${noctalia} brightness-down 10";
          allow_when_locked = true;
        };
      }
      // workspaceBinds;

    window_rule = [
      {
        blur = true;
        blur_optimized = true;
      }
      {
        match.app_id = "^dev[.]noctalia[.]Noctalia$";
        default_floating = true;
        default_floating_size_px = {
          width = 1020;
          height = 900;
        };
      }
      {
        match.title = "^(Picture-in-Picture|Picture in picture)$";
        default_floating = true;
        default_maximize = false;
      }
    ];

    layer_rule = [
      {
        match.namespace = "^noctalia-(bar-[^\"]+|notification|dock|panel|attached-panel|osd)$";
        blur = true;
        blur_ignore_alpha = 0.6;
        blur_popups = true;
        blur_optimized = false;
      }
    ];

    animation = {
      enabled = true;
      duration_ms = 220;
      curve = "easeout";

      windows_in = {
        enabled = true;
        curve = "spring:1,900";
        style = "popin";
        scale = 0.6;
      };
      windows_out = {
        enabled = true;
        curve = "spring:1,1400";
        style = "popin";
        scale = 0.8;
      };
      windows_move = {
        enabled = true;
        curve = "spring:1,800";
      };
      windows_resize = {
        enabled = true;
        curve = "spring:1,900";
      };
      windows_opacity = {
        enabled = true;
        curve = "spring:1,900";
      };
      workspaces = {
        enabled = true;
        style = "slide";
        curve = "spring:1,800";
      };
      overview = {
        enabled = true;
        curve = "spring:1,800";
        workspace_curve = "spring:1,1000";
      };
      border = {
        enabled = true;
        curve = "spring:1,900";
      };
      # Noctalia animates its own layer-shell surfaces.
      layers.enabled = false;
    };
  };

  umbrielConfig = toml.generate "umbriel-config.toml" umbrielSettings;
in {
  # Stylix owns Noctalia's palette, dark mode, font, and wallpaper.
  stylix.targets.noctalia.enable = true;

  programs.noctalia = {
    enable = true;
    # Umbriel's [general].autostart starts the shell once per session.
    systemd.enable = false;

    # theme.mode, shell.font_family and wallpaper.default.path come from the
    # stylix.targets.noctalia target above.
    settings = {
      shell = {
        corner_radius_scale = 1.25;
        button_borders = false;
        input_borders = false;
        popup_borders = true;
        card_borders = false;
        show_close_buttons = true;
        popup_shadows = true;

        animation = {
          enabled = true;
          speed = 1.1;
        };

        panel.transparency_mode = "glass";

        screenshot = {
          save_to_file = true;
          copy_to_clipboard = true;
          format = "png";
          freeze_screen = true;
          confirm_region = false;
        };
      };

      # Toast action buttons are app-supplied (e.g. a "Settings" shortcut), so
      # drop them; the notification panel and history remain the way in.
      notification.show_actions = false;

      # Turn monitors off 30 s after the session locks and goes idle. A zero
      # unlocked timeout keeps this lock-screen-only; Noctalia restores power
      # on activity/unlock. Defining a behavior replaces the disabled defaults.
      idle.behavior.screen-off = {
        enabled = true;
        timeout = 0;
        locked_timeout = 30;
        action = "screen_off";
      };

      bar.default = {
        position = "top";
        thickness = 38;
        background_opacity = 0.82;
        compositor_blur = true;
        capsule = true;
        capsule_fill = "surface_container";
        capsule_radius = 12.0;
        capsule_opacity = 0.92;

        start = ["workspaces"];
        center = ["clock" "active_window" "notifications"];
        end = [
          "media"
          "tray"
          "clipboard"
          "network"
          "bluetooth"
          "volume"
          "brightness"
          "battery"
          "session"
        ];
      };

      widget.active_window = {
        min_length = 160;
        max_length = 420;
        title_scroll = "on_hover";
      };

      wallpaper = {
        transition = ["fade" "wipe"];
        transition_duration = 1200;
        sync_transitions = true;
      };

      lockscreen = {
        enabled = true;
        lock_before_suspend = true;
        dnd = true;
      };
    };
  };

  # Noctalia's GUI-managed settings.toml in the state dir wins over the
  # Nix-generated config.toml. Keep the rest of the state dir (clipboard,
  # notification history, plugin data), but pin settings.toml to a read-only
  # empty store file so runtime writes fail and Nix stays the source of truth.
  xdg.stateFile."noctalia/settings.toml" = {
    source = pkgs.emptyFile;
    # Replace any stale runtime override file left by a previous session.
    force = true;
  };

  xdg.configFile."umbriel/config.toml".source =
    if config.programs.noctalia.checkConfig
    then
      pkgs.runCommand "umbriel-config.toml" {} ''
        ${lib.getExe pkgs.umbriel} config validate -c ${umbrielConfig}
        cp ${umbrielConfig} $out
      ''
    else umbrielConfig;

  # Carry over the useful session bits from the Hyprland module. Noctalia replaces
  # hyprpaper/hyprlock/hypridle/dunst and wlogout's job. The secret service
  # (gnome-keyring) is enabled for every user in ./base.nix.
  systemd.user.sessionVariables.NIXOS_OZONE_WL = "1";
}
