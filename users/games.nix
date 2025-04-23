{pkgs, ...}: {
  home.username = "games";
  home.homeDirectory = "/home/games";

  imports = [
    ../modules/home/base.nix
    ../modules/home/waybar
    ../modules/home/gaming.nix
    ../themes/ubuntu-catppuccin.nix
  ];

  # Packages that should be installed to the user profile.
  home.packages = with pkgs; [
    firefox
    starsector
  ];

  # basic configuration of git, please change to your own
  programs = {
    bash = {
      enable = true;
    };
  };

  home.file.".config/autostart/steam.desktop" = {
    text = ''
      [Desktop Entry]
      Name=Steam Autostart
      Exec=${pkgs.steam}/bin/steam -silent
      Type=Application
      Terminal=false
    '';
    executable = false;
  };

  # This value determines the home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update home Manager without changing this value. See
  # the home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "24.05";
}
