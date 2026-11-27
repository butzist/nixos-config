{tack, ...}: {
  imports = [
    ../shared-modules/sources.nix
    ../todos
    tack.home-manager.nixosModules.home-manager
    tack.agenix.nixosModules.default
    tack.stylix.nixosModules.stylix
    tack.freetoken.nixosModules.freetoken
    ./boot.nix
    ./noctalia.nix
    ../shared-modules/ssh-keys.nix
    ../shared-modules/tailscale.nix
  ];

  home-manager = {
    useUserPackages = true;
    backupFileExtension = "backup";
  };

  # The stylix home module is imported for every user via home-modules/default.nix.
  # Without this, the NixOS module would inject it again through home-manager.sharedModules.
  stylix.homeManagerIntegration.autoImport = false;
}
