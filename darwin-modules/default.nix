{
  inputs,
  ...
}: {
  imports = [
    inputs.home-manager.darwinModules.home-manager
    inputs.agenix.darwinModules.default
    inputs.determinate.darwinModules.default
    ../overlays
  ];

  nix.enable = false; # nix is managed by determinate
}
