{...}: {
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
