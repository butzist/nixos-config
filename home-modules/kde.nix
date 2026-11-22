{
  # Stylix provides the Plasma-specific colours, fonts, window decorations and
  # wallpaper on top of the shared theme settings from themes/mk-theme.nix.
  # The Qt platform theme stays "qtct" there; this target applies the KDE part.
  stylix.targets.kde = {
    enable = true;
    useWallpaper = true;
  };

  # KDE Connect is part of the Plasma experience; the indicator keeps it
  # reachable from the system tray without starting the full settings app.
  services.kdeconnect = {
    enable = true;
    indicator = true;
  };
}
