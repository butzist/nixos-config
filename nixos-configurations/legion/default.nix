# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  pkgs,
  ezModules,
  ...
}: let
  # Qwen3.5-9B Q4_K_M baked into the store, so llama-server never downloads
  # at runtime (the on-demand fetch in router mode hangs silently under the
  # service sandbox).
  qwenModel = pkgs.fetchurl {
    name = "Qwen3.5-9B-Q4_K_M.gguf";
    url = "https://huggingface.co/unsloth/Qwen3.5-9B-GGUF/resolve/main/Qwen3.5-9B-Q4_K_M.gguf";
    hash = "sha256-A7dHJ6hgpWM44ELEQguz8Esv7Fc0F19MufqFPa9St+g=";
  };
in {
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
  boot.kernelPackages = pkgs.linuxPackages_latest;
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
  # Allow access to I2C bus for display configuration
  hardware.i2c.enable = true;

  # Local LLM server for opencode, accelerated with the NVIDIA GPU.
  # Serves Qwen3.5-9B Q4_K_M via llama.cpp (llama-server).
  services.llama-cpp = {
    enable = true;
    package = pkgs.llama-cpp-cuda;
    # Move llama-server off the default 8080; nginx listens on 11434 instead
    # (see below) and proxies to this backend port.
    settings = {
      host = "127.0.0.1";
      port = 11435;
      # Router mode only exposes models defined in a preset INI; a bare
      # --model-url/--alias would register zero models and `/v1/models`
      # returns an empty list (breaking opencode's model discovery).
      models-preset =
        (pkgs.formats.ini {}).generate
        "llama-cpp-models.ini"
        {
          "qwen3.5-9b" = {
            model = "${qwenModel}";
            # Present the API model name as this so opencode's provider id matches.
            alias = "qwen3.5-9b";
            # 64k context window. opencode's tokenizer estimate routinely undercounts
            # vs the model's real tokenizer, so it used to ship prompts of 55-69k
            # real tokens that got rejected against a 48k window. The model
            # natively supports 262k, but the 8GB VRAM cap (this hybrid
            # Mamba/attention model has a cheap ~16kB/token KV cache at
            # head_dim 64, GQA x4) keeps us conservative at 64k.
            ctx-size = 64 * 1024;
            # Offload all 28 layers to the GPU.
            n-gpu-layers = 99;
            # Model parameters recommended for Qwen3.5 family (agentic coding).
            temp = 1.0;
            top-p = 0.95;
            top-k = 64;
          };
        };
    };
  };

  # Browsers (Chrome/Brave) block public HTTPS pages from talking to
  # localhost unless the server answers the Private Network Access (PNA)
  # preflight with `Access-Control-Allow-Private-Network`. llama-server does
  # not emit that header, so proxy it here on the port the OnlyOffice page
  # uses and add the header ourselves.
  services.nginx = {
    enable = true;
    virtualHosts."localhost" = {
      listen = [
        {
          addr = "127.0.0.1";
          port = 11434;
        }
      ];
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
    extraGroups = ["networkmanager" "wheel" "docker" "video" "kvm" "i2c"];
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
