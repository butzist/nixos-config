{pkgs, ...}: {
  home.username = "games";
  home.homeDirectory = "/home/games";

  imports = [
    ../modules/desktop-base.nix
    ../modules/sway.nix
    ../modules/waybar/default.nix
    ../themes/ubuntu-catppuccin.nix
  ];

  # Packages that should be installed to the user profile.
  home.packages = with pkgs; [
    steam
  ];

  # basic configuration of git, please change to your own
  programs = {
    bash = {
      enable = true;
    };
  };

  wayland.windowManager.sway.config.startup = [
    {command = "${pkgs.steam}/bin/steam -silent";}
  ];

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
