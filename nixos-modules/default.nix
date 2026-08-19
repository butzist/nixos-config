{
  inputs,
  ...
}: {
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.agenix.nixosModules.default
    inputs.stylix.nixosModules.stylix
    ../overlays
    ../shared-modules/ssh-keys.nix
  ];

  home-manager = {
    useUserPackages = true;
    backupFileExtension = "backup";
  };

  # The stylix home module is imported for every user via home-modules/default.nix.
  # Without this, the NixOS module would inject it again through home-manager.sharedModules.
  stylix.homeManagerIntegration.autoImport = false;
}
