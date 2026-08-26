# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  pkgs,
  ezModules,
  ...
}: {
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ]
    ++ (with ezModules; [
      base
      gnome
      laptop
      containers
    ]);

  # Home-manager settings applied to every user on this machine.
  home-manager.sharedModules = [./home.nix];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_6_18;
  boot.initrd.luks.devices."luks-badc0975-bd8f-4323-a781-203aa39328fa".device = "/dev/disk/by-uuid/badc0975-bd8f-4323-a781-203aa39328fa";

  networking.hostName = "legion"; # Define your hostname.

  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
  };

  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
    };
  };

  services.xserver.videoDrivers = ["amdgpu" "nvidia"];

  hardware.nvidia = {
    open = true;
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = true;

    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };

      amdgpuBusId = "PCI:5:0:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "euro";
  };

  # Enable bluetooth manager.
  services.blueman.enable = true;
  # Power the adapter on at boot.
  hardware.bluetooth.powerOnBoot = true;

  # Local LLM server for opencode, accelerated with the NVIDIA GPU.
  services.ollama = {
    enable = true;
    package = pkgs.ollama-cuda;
    loadModels = ["gemma4:12b" "gemma4:e4b" "gemma4:e2b"];
    # Ollama's default context window is 4096 tokens, which opencode
    # (system prompt + tool definitions) exceeds in a single turn, so the
    # server silently truncates history and the model appears to "forget"
    # everything between prompts. Bump the server-wide default to 64k.
    # Allow the OnlyOffice GitHub page to call the local Ollama API from
    # the browser (CORS).
    environmentVariables = {
      OLLAMA_CONTEXT_LENGTH = "65536";
      OLLAMA_ORIGINS = "https://onlyoffice.github.io,http://localhost,http://localhost:*,https://localhost,https://localhost:*";
    };
    # Move Ollama off 11434; nginx listens there instead (see below).
    host = "127.0.0.1";
    port = 11435;
  };

  # Browsers (Chrome/Brave) block public HTTPS pages from talking to
  # localhost unless the server answers the Private Network Access (PNA)
  # preflight with `Access-Control-Allow-Private-Network`. Ollama does not
  # emit that header, so proxy it here on the port the OnlyOffice page uses
  # and add the header ourselves.
  services.nginx = {
    enable = true;
    virtualHosts."localhost" = {
      listen = [{ addr = "127.0.0.1"; port = 11434; }];
      locations."/" = {
        proxyPass = "http://127.0.0.1:11435";
        proxyWebsockets = true;
        extraConfig = ''
          proxy_set_header Host $host;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_buffering off;
          proxy_read_timeout 600s;
          add_header Access-Control-Allow-Private-Network true always;
        '';
      };
    };
  };

  # Binary cache for CUDA packages so ollama-cuda (and friends) don't have
  # to be built from source. See https://cache.nixos-cuda.org/
  nix.settings = {
    substituters = ["https://cache.nixos-cuda.org"];
    trusted-public-keys = ["cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="];
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.work = {
    isNormalUser = true;
    description = "Work";
    extraGroups = ["networkmanager" "wheel" "docker" "video" "kvm"];
    uid = 1000;
    shell = pkgs.bash;
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "26.05"; # Did you read the comment?
}
