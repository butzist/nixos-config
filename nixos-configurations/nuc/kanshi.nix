{...}: let
  # kanshi is the single output manager here: it uses wlr-output-management,
  # so Hyprland, sway and Umbriel all pick up the same profile. The offsets are
  # the ones Hyprland used; sway's old block centred the pair differently.
  profile = name: outputs: {
    profile = {inherit name outputs;};
  };
in {
  services.kanshi = {
    enable = true;
    systemdTarget = "graphical-session.target";

    settings = [
      (profile "desk" [
        {
          criteria = "Samsung Electric Company S27F350 H4ZMA14287";
          mode = "1920x1080";
          position = "0,194";
          scale = 1.0;
        }
        {
          criteria = "Samsung Electric Company LS27A600U H4ZT400506";
          mode = "2560x1440";
          position = "1920,0";
          scale = 1.0;
        }
      ])
    ];
  };
}
