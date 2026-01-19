{pkgs, ...}: {
  # Login
  services.displayManager.gdm.enable = true;

  # Style
  stylix.enable = true;
  stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/everforest.yaml";

  # Enable networking
  networking.networkmanager.enable = true;
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Enable automatic switching to network mode for some USB WLAN adapters
  hardware.usb-modeswitch.enable = true;

  # Enable bluetooth
  hardware.bluetooth.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Zurich";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "de_CH.UTF-8";
    LC_IDENTIFICATION = "de_CH.UTF-8";
    LC_MEASUREMENT = "de_CH.UTF-8";
    LC_MONETARY = "de_CH.UTF-8";
    LC_NAME = "de_CH.UTF-8";
    LC_NUMERIC = "de_CH.UTF-8";
    LC_PAPER = "de_CH.UTF-8";
    LC_TELEPHONE = "de_CH.UTF-8";
    LC_TIME = "de_CH.UTF-8";
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Disable screen reader
  services.orca.enable = false;

  # Enable CUPS to print documents.
  services.printing = {
    enable = true;
    drivers = with pkgs; [
    ];
  };

  hardware.printers = {
    ensurePrinters = [
      {
        name = "Brother_MFC_L8390DCW";
        location = "Home";
        deviceUri = "dnssd://Brother%20MFC-L8390CDW%20series._ipp._tcp.local/?uuid=e3248000-80ce-11db-8000-94ddf83cc8fc";
        model = "everywhere";
        ppdOptions = {
          PageSize = "A4";
        };
      }
    ];
    ensureDefaultPrinter = "Brother_MFC_L8390DCW";
  };

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.polkit.enable = true;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  services.pipewire.wireplumber.extraConfig.bluetoothEnhancements = {
    "monitor.bluez.properties" = {
      "bluez5.enable-sbc-xq" = true;
      "bluez5.enable-msbc" = true;
      "bluez5.enable-hw-volume" = true;
      "bluez5.roles" = ["hsp_hs" "hsp_ag" "hfp_hf" "hfp_ag"];
    };
  };

  # Firewall settings
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [];
    allowedUDPPorts = [];
  };

  programs = {
    neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
    };

    nix-ld.enable = true;
    light.enable = true;
    dconf.enable = true;
  };

  # File manager
  programs.thunar = {
    enable = true;
    plugins = with pkgs; [
      thunar-archive-plugin
    ];
  };
  services.gvfs.enable = true;
  services.tumbler.enable = true;

  services.udev.packages = with pkgs; [
    via
    vial
  ];

  services.openssh = {
    enable = true;
    ports = [];
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  services.pcscd.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  services.fwupd.enable = true;

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
    lm_sensors
    ethtool
    pciutils
    usbutils
    usb-modeswitch

    # hardware
    vial
  ];

  nix = {
    settings = {
      experimental-features = ["nix-command" "flakes"];
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
