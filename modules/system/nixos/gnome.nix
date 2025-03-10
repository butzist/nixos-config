{pkgs, ...}: {
  services.xserver.desktopManager.gnome = {
    enable = true;
  };

  environment.gnome.excludePackages = with pkgs; [
    gnome-photos
    gnome-tour
    gedit
    cheese
    gnome-music
    gnome-terminal
    epiphany
    geary
    evince
    gnome-characters
    totem
    tali
    iagno
    hitori
    atomix
  ];
}
