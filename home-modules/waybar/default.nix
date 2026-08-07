{
  config,
  pkgs,
  lib,
  ...
}: {
  home.packages = with pkgs; [
    pavucontrol
  ];

  programs.waybar.enable = true;
  stylix.targets.waybar.enable = false;
  programs.waybar.style = ./style.css;
  programs.waybar.settings = {
    "mainBar" = {
      "output" = [
        "*"
      ];
      "modules-left" = [
        "hyprland/workspaces"
        "sway/workspaces"
        "sway/mode"
      ];
      "modules-center" = [
        "hyprland/window"
        "sway/window"
      ];
      "modules-right" = [
        "tray"
        "group/internet"
        "bluetooth"
        "pulseaudio"
        "battery"
        "group/hardware"
        "clock"
        "custom/power"
      ];
      "group/internet" = {
        "orientation" = "horizontal";
        "modules" = [
          "custom/internet"
          "network"
        ];
      };
      "group/hardware" = {
        "orientation" = "horizontal";
        "modules" = [
          "cpu"
          "memory"
        ];
      };
      "sway/workspaces" = {
        "disable-scroll" = true;
        "all-outputs" = false;
        "format" = "{name}";
      };
      "sway/mode" = {
        "format" = "<span style=\"italic\">{}</span>";
      };
      "sway/window" = {
        "format" = "{}";
        "max-length" = 50;
      };
      "custom/internet" = {
        "exec" = let
          script = pkgs.writeShellScript "internet-check" ''
            if ping -c 1 -W 1 1.1.1.1 > /dev/null 2>&1; then
              echo '{"text":"","class":"connected"}'
            else
              echo '{"text":"","class":"disconnected"}'
            fi
          '';
        in "${script}";
        "interval" = 10;
        "return-type" = "json";
      };
      "network" = {
        "format-wifi" = "  {signalStrength}% ({essid})";
        "format-ethernet" = "{ifname} ";
        "format-disconnected" = "";
        "max-length" = 50;
        "on-click" = "${lib.getExe pkgs.kitty} nmtui";
      };
      "tray" = {
        "icon-size" = 15;
        "spacing" = 1;
      };
      "clock" = {
        "tooltip-format" = "<big>{:%d %B %Y}</big>\n<tt><small>{calendar}</small></tt>";
        "on-click" = "gnome-calendar";
      };
      "pulseaudio" = {
        "format" = "{icon}{volume}%";
        "format-bluetooth" = "{icon}{volume}% {format_source}";
        "format-bluetooth-muted" = "{icon}0% {format_source}";
        "format-muted" = "{icon}0%";
        "format-source" = "{volume}% ";
        "format-source-muted" = "";
        "format-icons" = {
          "headphone" = " ";
          "hands-free" = " ";
          "headset" = " ";
          "phone" = " ";
          "portable" = " ";
          "car" = " ";
          "default" = [
            ""
            " "
            " "
          ];
        };
        "on-click" = "pavucontrol";
      };
      "memory" = {
        "interval" = 5;
        "format" = " {}%";
        "on-click" = "${lib.getExe pkgs.kitty} btop";
      };
      "cpu" = {
        "interval" = 5;
        "format" = " {usage}%";
        "on-click" = "${lib.getExe pkgs.kitty} btop";
      };
      "battery" = {
        "states" = {
          "good" = 80;
          "warning" = 30;
          "critical" = 15;
        };
        "format" = "{icon} {capacity}%";
        "format-icons" = [
          " "
          " "
          " "
          " "
          " "
        ];
      };
      "bluetooth" = {
        "format" = " ";
        "tooltip-format" = "{status}";
        "interval" = 30;
        "on-click" = "blueman-manager";
        "format-no-controller" = "";
      };
      "custom/power" = {
        "format" = " ";
        "on-click" = "wlogout";
      };
    };
  };

  home.file.".config/waybar/colors.css".text = let
    colors = config.lib.stylix.colors;
  in ''
    @define-color background #${colors.base00};
    @define-color altbackground #${colors.base01};
    @define-color selbackground #${colors.base02};
    @define-color text #${colors.base05};
    @define-color alttext #${colors.base04};
    @define-color warning #${colors.base0A};
    @define-color error #${colors.base08};
    @define-color urgent #${colors.base09};
    @define-color border #${colors.base03};
    @define-color active #${colors.base0D};
  '';
}
