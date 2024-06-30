{
  config,
  lib,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
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
        "sway/workspaces"
        "sway/mode"
      ];
      "modules-center" = [
        "sway/window"
      ];
      "modules-right" = [
        "tray"
        "network"
        "bluetooth"
        "pulseaudio"
        "battery"
        "group/hardware"
        "clock"
        "custom/power"
      ];
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
      "network" = {
        "format-wifi" = "  {signalStrength}% ({essid})";
        "format-ethernet" = "{ifname} ";
        "format-disconnected" = "";
        "max-length" = 50;
        "on-click" = "alacritty -e 'nmtui'";
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
        "on-click" = "alacritty -e 'btop'";
      };
      "cpu" = {
        "interval" = 5;
        "format" = " {usage}%";
        "on-click" = "alacritty -e 'btop'";
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
  in
    ''
      @define-color base00 #''
    + colors.base00
    + ''      ;
          @define-color base01 #''
    + colors.base01
    + ''      ;
          @define-color base02 #''
    + colors.base02
    + ''      ;
          @define-color base03 #''
    + colors.base03
    + ''      ;
          @define-color base04 #''
    + colors.base04
    + ''      ;
          @define-color base05 #''
    + colors.base05
    + ''      ;
          @define-color base06 #''
    + colors.base06
    + ''      ;
          @define-color base07 #''
    + colors.base07
    + ''      ;
          @define-color base08 #''
    + colors.base08
    + ''      ;
          @define-color base09 #''
    + colors.base09
    + ''      ;
          @define-color base0A #''
    + colors.base0A
    + ''      ;
          @define-color base0B #''
    + colors.base0B
    + ''      ;
          @define-color base0C #''
    + colors.base0C
    + ''      ;
          @define-color base0D #''
    + colors.base0D
    + ''      ;
          @define-color base0E #''
    + colors.base0E
    + ''      ;
          @define-color base0F #''
    + colors.base0F
    + ''      ;
    '';
}
