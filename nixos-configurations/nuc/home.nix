{...}: {
  wayland.windowManager.hyprland.settings = {
    monitor = [
      {
        output = "desc:Samsung Electric Company S27F350 H4ZMA14287";
        mode = "1920x1080";
        position = "0x194";
        scale = "1";
      }
      {
        output = "desc:Samsung Electric Company LS27A600U H4ZT400506";
        mode = "2560x1440";
        position = "1920x0";
        scale = "1";
      }
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
