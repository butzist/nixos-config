{pkgs, ...}: {
  # GNOME is no longer the desktop session; Umbriel + Noctalia is the default.
  services.desktopManager.gnome = {
    enable = false;
  };

  services.gnome = {
    core-apps.enable = false;
    core-developer-tools.enable = false;
    games.enable = false;
  };
}
