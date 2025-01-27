{pkgs, ...}: {
  virtualisation = {
    # Enable common container config files in /etc/containers
    containers.enable = true;

    docker = {
      enable = true;
      rootless.enable = false;
    };
  };

  networking.firewall.trustedInterfaces = ["docker0"];

  # Useful other development tools
  environment.systemPackages = with pkgs; [
    dive # look into docker image layers
  ];
}
