{pkgs, ...}: {
  imports = [
    ../../modules/system/darwin/base.nix
    ../../modules/system/darwin/aerospace.nix
    ../../modules/system/containers
  ];

  users.users.work = {
    home = "/Users/work";
    shell = pkgs.bashInteractive;
    uid = 503;
  };

  # allow nixdarwin to manage the user
  users.knownUsers = ["work"];

  ## Set Git commit hash for darwin-version.
  #system.configurationRevision = self.rev or self.dirtyRev or null;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 6;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";
}
