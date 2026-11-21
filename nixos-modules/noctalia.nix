{
  config,
  lib,
  ...
}: let
  colors = config.lib.stylix.colors.withHashtag;
  cursor = config.stylix.cursor;
  cursorName =
    if cursor == null || cursor.name == null
    then "Adwaita"
    else cursor.name;
  fontFamily = config.stylix.fonts.sansSerif.name;
  wallpaper = config.stylix.image;
  themeMode =
    if config.stylix.polarity == "dark"
    then "dark"
    else "light";
in {
  # Install the shell binary for Umbriel's declarative autostart. The systemd
  # unit stays off: Umbriel owns session startup and starts Noctalia once.
  programs.noctalia = {
    enable = true;
    systemd.enable = false;
    # The battery widget reads UPower's DisplayDevice and hides itself when it
    # is absent. NetworkManager and Bluetooth are already on in base.nix, and
    # laptop.nix's explicit false keeps TLP's PPD-compatible interface in charge.
    recommendedServices.enable = true;
  };

  programs.umbriel.enable = true;

  # Keep the display manager and GNOME shell out of the way on every host.
  services.displayManager.gdm.enable = lib.mkForce false;
  services.desktopManager.gnome.enable = lib.mkForce false;

  services.displayManager.noctalia-greeter = {
    enable = true;

    # Cursor comes from the dual-purpose theme imported by base.nix.
    cursorTheme = {
      package =
        if cursor == null
        then null
        else cursor.package;
      name = cursorName;
    };

    settings = {
      session.default = "Umbriel";

      appearance = {
        scheme = "Synced";
        password_style = "random";
        hide_logo = false;
        power_buttons_position = "bottom-right";
        scheme_selector_position = "top-right";
        theme_mode = themeMode;
        corner_radius_scale = 1.15;
        font_family = fontFamily;

        # Same base16 mapping stylix uses for Noctalia, in the greeter's schema.
        palette = {
          primary = colors.base0D;
          on_primary = colors.base00;
          secondary = colors.base0E;
          on_secondary = colors.base00;
          tertiary = colors.base0C;
          on_tertiary = colors.base00;
          error = colors.base08;
          on_error = colors.base00;
          surface = colors.base00;
          on_surface = colors.base05;
          surface_variant = colors.base01;
          on_surface_variant = colors.base04;
          outline = colors.base03;
          shadow = colors.base00;
          hover = colors.base0C;
          on_hover = colors.base00;
        };

        wallpaper =
          {
            fill_mode = "crop";
            blur = 0.35;
            tint = 0.15;
          }
          // lib.optionalAttrs (wallpaper != null) {path = wallpaper;};
      };

      clock = {
        enabled = true;
        position = "above-panel";
      };

      keyboard = {
        layout = "us";
        options = "compose:menu,caps:escape";
        numlock = true;
      };

      cursor.size =
        if cursor == null || cursor.size == null
        then 24
        else cursor.size;
    };
  };
}
