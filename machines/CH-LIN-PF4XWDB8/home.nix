{...}: {
  wayland.windowManager.hyprland.settings = {
    monitor = [
      "eDP-1, preferred, 5120x240, 1.5"
      "desc:Dell Inc. DELL P2720DC 3CPVL93, preferred, 0x0, 1"
      "desc:Dell Inc. DELL P2720DC 30GSL93, preferred, 2560x0, 1"
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
