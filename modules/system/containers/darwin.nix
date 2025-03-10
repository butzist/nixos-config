{pkgs, ...}: {
  # Useful other development tools
  environment.systemPackages = with pkgs; [
    colima
    docker
  ];
  environment.variables = {
    DOCKER_CONTEXT = "colima";
  };
}
