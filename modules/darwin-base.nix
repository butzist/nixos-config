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
      "microsoft-edge"
      "microsoft-teams"
      "microsoft-outlook"
      "microsoft-word"
      "microsoft-powerpoint"
    ];
  };

  security.pam.enableSudoTouchIdAuth = true;
  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToEscape = true;
  };
  system.startup.chime = false;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    git
    sops

    # archives
    zip
    xz
    unzip
    p7zip

    # networking tools
    dnsutils
    wget
    socat
    nmap

    # performance monitoring
    btop
  ];

  nix = {
    settings = {
      experimental-features = ["nix-command" "flakes"];
    };
    optimise = {automatic = true;};
    gc = {
      automatic = true;
      interval = {
        Hour = 3;
        Minute = 15;
        Weekday = 7;
      };
      options = "--delete-older-than 15d";
    };
  };

  programs = {
    bash.enable = true;
  };

  #  system.autoUpgrade = {
  #    enable = true;
  #    flake = inputs.self.ourPath;
  #    flags = [
  #      "--update-input"
  #      "nixpkgs"
  #      "-L"
  #    ];
  #    dates = "09:00";
  #    randomizedDelaySec = "45min";
  #  };
}
