{
  config,
  pkgs,
  ezModules,
  ...
}: {
  home.username = "adam";
  home.homeDirectory = "/home/adam";

  imports =
    (with ezModules; [
      base
      kitty
      nushell
      neovim
      hyprland
      wlogout
      walker
      waybar
      development
    ])
    ++ [
      ../themes/everforest-kingdoms.nix
    ];

  # Packages that should be installed to the user profile.
  home.packages = with pkgs; [
    androidStudioPackages.beta
    android-tools
    _security.brave
    _security.firefox
    blender
    freecad
    kicad
    easyeda2kicad
    _stable.inkscape
    orca-slicer
    gimp3-with-plugins
    pulseview
    sigrok-cli
    sigrok-firmware-fx2lafw
    audacity
    ffmpeg
    shotcut
    obs-studio
    obs-cmd
  ];

  # basic configuration of git, please change to your own
  programs = {
    git = {
      settings = {
        user = {
          inherit (config.sensitive) name;
          inherit (config.sensitive) email;
        };
      };
    };

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
  home.stateVersion = "26.05";
}
