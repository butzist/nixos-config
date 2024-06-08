{ config, lib, pkgs, ... }:

{
  boot.kernelModules = [ "ecryptfs" ];

  # Login
  security.pam.enableEcryptfs = true;
  services.xserver.displayManager.gdm.enable = true;

  # Enable networking
  networking.networkmanager.enable = true;
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Enable bluetooth
  hardware.bluetooth.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Zurich";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  # Enable Docker
  virtualisation.docker = {
    enable = true;
    storageDriver = "btrfs";
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  programs = {
    firefox.enable = true;

    neovim = { enable = true;
      defaultEditor = true;
    };
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    ecryptfs

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

    # misc
    file
    which
    tree
    gnused
    gnutar
    gawk
    gnupg

    # performance monitoring
    btop
    iotop
    iftop

    # system call monitoring
    strace
    ltrace
    lsof

    # system tools
    sysstat
    lm_sensors # for `sensors` command
    ethtool
    pciutils
    usbutils
  ];

  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 15d";
    };
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
