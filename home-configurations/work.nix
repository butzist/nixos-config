{
  config,
  pkgs,
  ezModules,
  ...
}: {
  home.username = "work";
  home.homeDirectory = "/home/work";

  imports =
    (with ezModules; [
      base
      kitty
      nushell
      neovim
      development
      work
      hyprland
      wlogout
      walker
      waybar
    ])
    ++ [
      ../themes/everforest-kingdoms.nix
    ];

  # Packages that should be installed to the user profile.
  home.packages = with pkgs; [
    brave
    kicad
    easyeda2kicad
  ];

  age.secrets = {};

  programs = {
    git = {
      settings = {
        credential.helper = "!f() { gh auth git-credential \"$@\"; }; f";

        user = {
          inherit (config.sensitive) name;
          inherit (config.sensitive) email;
        };

        init = {
          defaultBranch = "main";
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
