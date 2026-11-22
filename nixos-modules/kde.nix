{lib, ...}: {
  # Plasma is available as a session, but the login manager stays the greetd
  # greeter configured in ./noctalia.nix. Plasma's own SDDM and GDM are kept
  # off so there is still a single display manager on KDE hosts.
  services = {
    desktopManager.plasma6.enable = true;
    displayManager = {
      sddm.enable = lib.mkForce false;
      gdm.enable = lib.mkForce false;
    };
  };
}
