{...}: let
  # One output config for the whole machine: kanshi talks to the standard
  # wlr-output-management protocol, which Umbriel, Hyprland and sway all
  # implement, so the same profiles apply in every session.
  #
  # The laptop panel was 1.3333334 in the old Hyprland monitors.lua and 1.0
  # under Umbriel. 1.2 sits between them; 2560 / 1.2 = 2133 logical pixels,
  # which gives integral offsets for the 1920-wide HP panels in office A.
  laptopWidth = 2133;
  hpWidth = 1920;

  laptop = {
    # Hyprland saw no serial for this panel; the wildcard also matches an
    # Umbriel identity that includes one.
    criteria = "Samsung Display Corp. ATNA60HS03-0*";
    mode = "2560x1600";
    scale = 1.2;
  };

  hp = serial: {
    criteria = "HP Inc. HP E24i G4 ${serial}";
    mode = "1920x1200";
    scale = 1.0;
  };

  # Home Manager takes a tagged union here, so each entry needs the `profile`
  # wrapper rather than a bare { name, outputs } attrset.
  profile = name: outputs: {
    profile = {inherit name outputs;};
  };
in {
  services.kanshi = {
    enable = true;

    # Umbriel queues the graphical session targets; being explicit avoids
    # depending on home-manager's generic wayland target default.
    systemdTarget = "graphical-session.target";

    # kanshi activates the first profile whose outputs are all connected,
    # so the complete office layouts must precede the laptop-only fallback.
    settings = [
      (profile "office-a" [
        (laptop // {position = "0,0";})
        (hp "6CM406371S" // {position = "${toString laptopWidth},0";})
        (hp "6CM40635HR" // {position = "${toString (laptopWidth + hpWidth)},0";})
      ])
      (profile "office-b" [
        (hp "6CM40635X7" // {position = "0,0";})
        (hp "6CM406358B" // {position = "${toString hpWidth},0";})
        (laptop // {position = "${toString (2 * hpWidth)},0";})
      ])
      (profile "laptop-only" [
        (laptop // {position = "0,0";})
      ])
    ];
  };
}
