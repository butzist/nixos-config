{
  pkgs,
  ezModules,
  ...
}: {
  home.username = "mirj";
  home.homeDirectory = "/home/mirj";

  imports =
    (with ezModules; [
      base
      zen
      kde
      kitty
      nushell
      zellij
      office
    ])
    ++ [
      (import ../themes/ubuntu-catppuccin.nix {inherit pkgs;}).user
    ];

  # Packages that should be installed to the user profile.
  home.packages = with pkgs; [
    _security.brave-origin
    freecad
    orca-slicer
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
  home.stateVersion = "26.05";
}
