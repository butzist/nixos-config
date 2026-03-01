{pkgs, ...}: let
in {
  home.username = "mirj";
  home.homeDirectory = "/home/mirj";

  imports = [
    ../modules/home/base.nix
    ../modules/home/nushell.nix
    ../themes/ubuntu-catppuccin.nix
  ];

  # Packages that should be installed to the user profile.
  home.packages = with pkgs; [
    _security.brave
    _security.firefox
    _stable.freecad
    _stable.inkscape
    orca-slicer
    gimp3-with-plugins
    _stable.libreoffice
    hunspell
    hunspellDicts.de_CH
    hunspellDicts.de_DE
    hunspellDicts.en_US
  ];

  programs = {
    bash = {
      enable = true;
    };
  };

  # This value determines the home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update home Manager without changing this value. See
  # the home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "25.11";
}
