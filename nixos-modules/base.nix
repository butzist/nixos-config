{pkgs, ...}: {
  # The Stylix system theme is selected per host in nixos-configurations/*/default.nix;
  # the greeter reads those values from config.stylix in ./noctalia.nix.

  # Login: GDM is replaced by noctalia-greeter in ./noctalia.nix.
  services.displayManager.gdm.enable = false;

  # Enable networking
  networking.networkmanager.enable = true;
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Enable automatic switching to network mode for some USB WLAN adapters
  hardware.usb-modeswitch.enable = true;

  # Enable bluetooth
  hardware.bluetooth.enable = true;

  # blueman ships an XDG autostart entry that would start its applet in every
  # session, including Umbriel where Noctalia owns Bluetooth. /etc/xdg comes
  # before the system-packages path in XDG_CONFIG_DIRS, so this shadows the
  # shipped file. The applet is started from hyprland-session.target instead
  # (see home-modules/hyprland.nix); blueman-manager stays available for Waybar.
  environment.etc."xdg/autostart/blueman.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Blueman Applet
    Exec=blueman-applet
    Hidden=true
  '';

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

  # PipeWire does not restore a card's hardware mixer controls (e.g. a USB
  # DAC's Master switch), which some devices default to muted on power-up.
  # enablePersistence installs alsa-store + the udev restore rule; it does not
  # enable hardware.alsa, which would disable PipeWire.
  hardware.alsa.enablePersistence = true;

  services.pipewire.wireplumber.extraConfig.bluetoothEnhancements = {
    "monitor.bluez.properties" = {
      "bluez5.enable-sbc-xq" = true;
      "bluez5.enable-msbc" = true;
      "bluez5.enable-hw-volume" = true;
      # a2dp_source must be included, otherwise the adapter never registers
      # A2DP codecs and bluetooth headsets only expose (broken) HFP profiles.
      "bluez5.roles" = ["a2dp_sink" "a2dp_source" "bap_sink" "bap_source" "hfp_hf" "hfp_ag"];
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
    dconf.enable = true;

    localsend = {
      enable = true;
      openFirewall = true;
    };
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

  # gnome-keyring is the secret service for every user and session (the daemon
  # itself is started per-user by home-modules/base.nix). This system module
  # adds the org.freedesktop.secrets D-Bus activation, the cap_ipc_lock wrapper
  # and PAM unlock at login: greetd's PAM stack includes `login`, so the
  # enableGnomeKeyring hook this sets on `login` unlocks the keyring on greetd
  # logins too.
  services.gnome.gnome-keyring.enable = true;

  # Route the portal Secret interface (flatpak/sandboxed apps) to gnome-keyring
  # in every session. The shipped preferences are UseIn=gnome (gnome-keyring)
  # vs UseIn=kde (kwallet), and kwallet's ksecretd portal no longer starts now
  # that the ksecretd backend is disabled, so pin it explicitly.
  xdg.portal.config.common."org.freedesktop.impl.portal.Secret" = "gnome-keyring";

  services.udev = {
    enable = true;
    packages = with pkgs; [
      libsigrok
      openocd
      via
      vial
    ];
  };

  users.extraGroups.plugdev = {};

  # SSH over the tailnet only: with openFirewall off, the trusted tailscale0
  # interface is the sole path in (no LAN fallback). `ports` is explicit because
  # an empty list does not mean "no listener" - sshd just falls back to 22 and
  # only the firewall rule is skipped.
  services.openssh = {
    enable = true;
    ports = [22];
    openFirewall = false;
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
    net-tools
    dnsutils
    iproute2
    wget
    socat
    nmap
    iw

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
    _stable.ltrace
    lsof

    # system tools
    alsa-utils
    brightnessctl
    ethtool
    lm_sensors
    pciutils
    sysstat
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
  #    flake = ".?submodules=1";
  #    flags = [
  #      "-L"
  #    ];
  #    dates = "09:00";
  #    randomizedDelaySec = "45min";
  #  };
}
