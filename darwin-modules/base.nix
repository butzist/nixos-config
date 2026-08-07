{pkgs, ...}: {
  # Set your time zone.
  time.timeZone = "Europe/Zurich";

  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
    };

    brews = [];
    casks = [
      "claude"
      "microsoft-edge"
      "microsoft-teams"
      "microsoft-outlook"
      "microsoft-word"
      "microsoft-powerpoint"
    ];
  };

  security.pam.services.sudo_local.touchIdAuth = true;
  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToEscape = true;
  };
  system.startup.chime = false;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    git
    agenix
    nix-tree

    # archives
    zip
    xz
    unzip
    p7zip

    # networking tools
    dnsutils
    wget
    curl
    socat
    nmap

    # performance monitoring
    btop

    # toolchain
    libiconv

    # libraries
    darwin.libresolv
  ];

  programs = {
    bash.enable = true;
  };
}
