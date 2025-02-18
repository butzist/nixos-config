{
  pkgs,
  isDarwin,
  ...
}: {
  imports =
    if isDarwin
    then [./darwin.nix]
    else [./linux.nix];

  # Common useful other development tools
  environment.systemPackages = with pkgs; [
    dive # look into docker image layers
    lazydocker
  ];
}
