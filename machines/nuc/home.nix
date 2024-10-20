{...}: {
  wayland.windowManager.hyprland.settings = {
    monitor = [
      "desc:Samsung Electric Company S27F350 H4ZMA14287, 1920x1080, 0x194, 1"
      "desc:Samsung Electric Company LS27A600U H4ZT400506, 2560x1440, 1920x0, 1"
    ];
  };

  wayland.windowManager.sway.config = {
    output = {
      "Samsung Electric Company S27F350 H4ZMA14287" = {
        pos = "0 720";
        res = "1920x1080";
        scale = "1";
      };

      "Samsung Electric Company LS27A600U H4ZT400506" = {
        pos = "1920 360";
        res = "2560x1440";
        scale = "1";
      };
    };
  };
}
