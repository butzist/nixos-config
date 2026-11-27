{tack, ...}: {
  imports = [
    ../shared-modules/sources.nix
    tack.home-manager.darwinModules.home-manager
    tack.agenix.darwinModules.default
    tack.determinate.darwinModules.default
    ../shared-modules/ssh-keys.nix
  ];

  nix.enable = false; # nix is managed by determinate
}
