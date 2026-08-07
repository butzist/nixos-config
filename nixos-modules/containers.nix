{
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./containers-linux.nix
    ./containers-darwin.nix
  ];

  # Common useful other development tools
  environment.systemPackages = with pkgs; [
    dive # look into docker image layers
    lazydocker
  ];
}
