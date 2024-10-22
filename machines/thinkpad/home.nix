{...}: {
  wayland.windowManager.hyprland.settings = {
    monitor = [
      "eDP-1, preferred, auto-right, 1.5"
    ];
  };

  wayland.windowManager.sway.config = {
    output = {
      "*" = {
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
    };
  };
}
