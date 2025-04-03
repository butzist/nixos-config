{pkgs, ...}: {
  services.aerospace.enable = true;

  environment.systemPackages = with pkgs; [
  ];

  homebrew.casks = [];

  system.defaults = {
    WindowManager = {
      AutoHide = false;
      EnableStandardClickToShowDesktop = false;
      EnableTiledWindowMargins = false;
      EnableTilingByEdgeDrag = false;
      EnableTilingOptionAccelerator = false;
      EnableTopTilingByEdgeDrag = false;
      GloballyEnabled = false;
      StandardHideDesktopIcons = true;
      StandardHideWidgets = true;
    };
    spaces.spans-displays = true;
    dock.autohide = true;

    CustomSystemPreferences = {
      NSGlobalDomain = {
        NSWindowShouldDragOnGesture = true;
      };

      # use alt-space for Spotlight
      "com.apple.symbolichotkeys" = {
        "64" = {
          enabled = 1;
          value = {
            parameters = [
              32
              49
              524288
            ];
            type = "standard";
          };
        };
      };
    };
  };

  services.aerospace.settings = {
    "after-login-command" = [];
    "after-startup-command" = [
      "exec-and-forget ${pkgs.jankyborders}/bin/borders active_color=0xffe1e3e4 inactive_color=0xff494d64 width=5.0"
      "exec-and-forget ${pkgs.autoraise}/bin/autoraise -delay 3"
    ];

    "automatically-unhide-macos-hidden-apps" = false;
    "default-root-container-layout" = "accordion";
    "default-root-container-orientation" = "auto";
    "enable-normalization-flatten-containers" = true;
    "enable-normalization-opposite-orientation-for-nested-containers" = true;

    "accordion-padding" = 30;
    "gaps" = {
      "inner" = {
        "horizontal" = 10;
        "vertical" = 10;
      };
      "outer" = {
        "bottom" = 10;
        "left" = 10;
        "right" = 10;
        "top" = 10;
      };
    };
    "key-mapping" = {
      "preset" = "qwerty";
    };
    "mode" = {
      "main" = {
        "binding" = {
          "alt-1" = "workspace 1";
          "alt-2" = "workspace 2";
          "alt-3" = "workspace 3";
          "alt-4" = "workspace 4";
          "alt-5" = "workspace 5";
          "alt-6" = "workspace 6";
          "alt-7" = "workspace 7";
          "alt-8" = "workspace 8";
          "alt-9" = "workspace 9";
          "alt-0" = "workspace 10";
          "alt-comma" = "layout accordion horizontal vertical";
          "alt-slash" = "layout tiles horizontal vertical";
          "alt-f" = [
            "layout floating tiling"
            "mode main"
          ];
          "alt-equal" = "resize smart +50";
          "alt-minus" = "resize smart -50";
          "alt-h" = "focus --boundaries all-monitors-outer-frame --boundaries-action wrap-around-all-monitors --ignore-floating left";
          "alt-j" = "focus --boundaries all-monitors-outer-frame --boundaries-action wrap-around-all-monitors --ignore-floating down";
          "alt-k" = "focus --boundaries all-monitors-outer-frame --boundaries-action wrap-around-all-monitors --ignore-floating up";
          "alt-l" = "focus --boundaries all-monitors-outer-frame --boundaries-action wrap-around-all-monitors --ignore-floating right";
          "alt-shift-1" = "move-node-to-workspace 1";
          "alt-shift-2" = "move-node-to-workspace 2";
          "alt-shift-3" = "move-node-to-workspace 3";
          "alt-shift-4" = "move-node-to-workspace 4";
          "alt-shift-5" = "move-node-to-workspace 5";
          "alt-shift-6" = "move-node-to-workspace 6";
          "alt-shift-7" = "move-node-to-workspace 7";
          "alt-shift-8" = "move-node-to-workspace 8";
          "alt-shift-9" = "move-node-to-workspace 9";
          "alt-shift-0" = "move-node-to-workspace 10";
          "alt-shift-h" = "move left";
          "alt-shift-j" = "move down";
          "alt-shift-k" = "move up";
          "alt-shift-l" = "move right";
          "alt-shift-semicolon" = "mode service";
          "alt-shift-tab" = "move-workspace-to-monitor --wrap-around next";
          "alt-tab" = "workspace-back-and-forth";

          "alt-enter" = "exec-and-forget ${pkgs.wezterm}/bin/wezterm";
        };
      };

      "service" = {
        "binding" = {
          "alt-shift-h" = [
            "join-with left"
            "mode main"
          ];
          "alt-shift-j" = [
            "join-with down"
            "mode main"
          ];
          "alt-shift-k" = [
            "join-with up"
            "mode main"
          ];
          "alt-shift-l" = [
            "join-with right"
            "mode main"
          ];
          "backspace" = [
            "close-all-windows-but-current"
            "mode main"
          ];
          "down" = "volume down";
          "esc" = [
            "reload-config"
            "mode main"
          ];
          "r" = [
            "flatten-workspace-tree"
            "mode main"
          ];
          "shift-down" = [
            "volume set 0"
            "mode main"
          ];
          "up" = "volume up";
        };
      };
    };
    "on-focused-monitor-changed" = [
      "move-mouse monitor-lazy-center"
    ];
    "on-focus-changed" = [
      "move-mouse window-lazy-center"
    ];
    "workspace-to-monitor-force-assignment" = {
      "1" = ["1" "main"];
      "2" = ["2" "main"];
      "3" = ["3" "main"];
      "10" = ["3" "main"];
    };
  };
}
