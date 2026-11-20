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
    targets.qt.platform = "qtct";
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
