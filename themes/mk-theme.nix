# Build NixOS and home-manager Stylix modules from one settings attrset.
# Theme modules expose both variants so callers select them explicitly:
#
#   (import ./theme.nix { inherit pkgs; }).system
#   (import ./theme.nix { inherit pkgs; }).user
settings: let
  stylix = {
    enable = true;
    inherit
      (settings)
      base16Scheme
      image
      polarity
      cursor
      fonts
      opacity
      ;
    # The system Qt target already derives "kde"/"breeze" from Plasma, but
    # `stylix.homeManagerIntegration.autoImport = false` stops that from being
    # inherited by users. Set the platform here so the home-manager Qt target
    # uses Breeze instead of its qtct default (Kvantum), which breaks Plasma.
    targets.qt.platform = "kde";
  };

  system = {inherit stylix;};

  user =
    system
    // {
      gtk = {
        enable = true;
        iconTheme = settings.iconTheme;
      };
    };
in {
  inherit system user;
}
