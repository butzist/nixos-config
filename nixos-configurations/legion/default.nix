# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  lib,
  pkgs,
  ezModules,
  ...
}: let
  # Every file is a separate fetchurl, pinned by the sha256 Hugging Face
  # reports for it (the git-lfs etag for the LFS-tracked ones), symlinked into
  # one directory by linkFarm. Symlinks rather than copies: the shards are
  # 21.8 GiB between them and the store already has them.
  #
  # `model` is given this path rather than the `nvidia/Qwen3.6-35B-A3B-NVFP4`
  # repo id, so the unit serves a fixed set of weights instead of whatever the
  # remote branch points at, and a first start does not have to download 21.8
  # GiB under the service sandbox. Nothing here needs to be writable, so the
  # read-only store is fine.
  freetokenRepo = "nvidia/Qwen3.6-35B-A3B-NVFP4";
  freetokenModel = pkgs.linkFarm "qwen3.6-35b-a3b-nvfp4" (
    lib.mapAttrs
    (
      name: hash:
        pkgs.fetchurl {
          inherit name hash;
          url = "https://huggingface.co/${freetokenRepo}/resolve/main/${name}";
        }
    )
    {
      "config.json" = "sha256-WK76HJ7/eYn0MddI8t3sOURssf0qaazEbihcajewzsw=";
      "configuration.json" = "sha256-wbCdtBkRlRMkfpuLkSxLmJcQbJsgxsrafhB9mTxUNes=";
      "generation_config.json" = "sha256-5wwTbBt43cH7CQW6yOczpNxEjU+FKl3XUUP//HC+VQ4=";
      "hf_quant_config.json" = "sha256-df58yNWDa1hzTgXuZ0I6TOkdYCqq1FyBc6G3WXzVdmM=";
      "model.safetensors.index.json" = "sha256-1nQDpOl5PAuooTa68Us7dux7MsgiJnl4CEiV4H69ij4=";
      "preprocessor_config.json" = "sha256-JyJUUKycZSmHLuGST8sJYv9WNINPgXBA9EQRgRb05RY=";
      "tokenizer.json" = "sha256-X55NSQGpK5l+RjwfRgVQiLbMpcphplItG59kxLuBy0I=";
      "tokenizer_config.json" = "sha256-UYbw3vzX8jI4LH8K680iUtBzu5IaskDkB7euh0XSsps=";
      "video_preprocessor_config.json" = "sha256-d2ivJ8H6+pzJARwdwgBn4D+JFeA7Y1BFUOEdUGaYbRM=";
      "vocab.json" = "sha256-zpm0yymD0RiAbOCot3ejWwk+IAClA+veJYUyhMnfoAM=";
      "chat_template.jinja" = "sha256-6E8yoj/donaJ+GiqShpWIfQRM+UaSNfz78vqKDlXQlk=";
      "model-00001-of-00003.safetensors" = "sha256-BxQcLbkuR7wId3EyzRoDI/rzAOqzp9fBEbwr8HX9oFA=";
      "model-00002-of-00003.safetensors" = "sha256-beqcdZoPlBz54cwVASFrDhB5ZqZskEJQUOIS770FPwI=";
      "model-00003-of-00003.safetensors" = "sha256-l1iHX8VeSVYRZfSkQ0K2VMEjw+JcaBGzSruDVT+xoWQ=";
    }
  );
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

  services.xserver.videoDrivers = [
    "amdgpu"
    "nvidia"
  ];

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

  zramSwap = {
    enable = true;
    memoryPercent = 53;
    memoryMax = 16 * 1024 * 1024 * 1024;

    # in compressed RAM first and only spill to disk under real pressure.
    priority = 5;
  };

  services.freetoken = {
    enable = true;
    model = "${freetokenModel}";
    settings = {
      "served-model-name" = "qwen3.6-35b-a3b";
      "text-model-only" = true;

      # An 8 GiB card serving a 35B-A3B MoE leaves very little slack: the
      # default 0.9 reserved under a GiB for CUDA graphs and activations. KV is
      # cheap here (~20 KiB/token), so 64k costs ~1.25 GiB total.
      "memory-ratio" = 0.80;
      "kv-reserve-tokens" = 65536;

      # One decode buffer, and only a batch-1 graph capture, instead of two.
      # OpenCode never has more than one request in flight here.
      "max-running-requests" = 1;

      # Prints the real cache/weight breakdown, which is the only way to tell
      # whether a given setting actually landed.
      "enable-cache-report" = true;
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
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
      "video"
      "kvm"
      "i2c"
    ];
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
