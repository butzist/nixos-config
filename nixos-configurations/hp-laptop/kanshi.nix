{...}: let
  # kanshi is the single output manager here: it uses wlr-output-management,
  # so Hyprland, sway and Umbriel all pick up the same profile.
  profile = name: outputs: {
    profile = {inherit name outputs;};
  };
in {
  services.kanshi = {
    enable = true;
    systemdTarget = "graphical-session.target";

    settings = [
      (profile "panel" [
        {
          criteria = "AU Optronics 0xFCAD";
          mode = "1920x1080";
          position = "0,0";
          scale = 1.0;
        }
      ])
    ];
  };
}
