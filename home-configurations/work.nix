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
    libreoffice
    kicad
    easyeda2kicad
  ];

  age.secrets = {};

  programs = {
    # Chrome/Brave 142+ gates public -> loopback requests behind the Local
    # Network Access permission. The loopback-network permissions policy only
    # allows same-origin iframes by default, so the nested OnlyOffice engine
    # (onlyoffice.github.io) could never be delegated the permission. This
    # switch makes the LNA permissions policy default-enabled in ALL frames,
    # so no allow attribute is needed anywhere on the iframe chain.
    brave = {
      enable = true;
      commandLineArgs = [
        "--local-network-access-permissions-policy-default-enabled"
      ];
    };

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
