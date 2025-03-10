_: {
  virtualisation = {
    # Enable common container config files in /etc/containers
    containers.enable = true;

    docker = {
      enable = true;
      rootless.enable = false;
    };
  };

  networking.firewall.trustedInterfaces = ["docker0"];
}
