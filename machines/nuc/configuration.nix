# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{pkgs, ...}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ../../modules/system/nixos/base.nix
    ../../modules/system/nixos/gnome.nix
    ../../modules/system/nixos/gaming.nix
    ../../modules/system/containers
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "nuc"; # Define your hostname.

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

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "euro";
  };

  # Enable buetooth manager.
  services.blueman.enable = true;

  # Android development
  programs.adb.enable = true;

  # Extra udev packages
  services.udev.packages = with pkgs; [
    android-udev-rules
  ];

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.work = {
    isNormalUser = true;
    description = "Work";
    extraGroups = ["networkmanager" "wheel" "docker" "video" "kvm"];
    uid = 1000;
    shell = pkgs.bash;
  };

  users.users.games = {
    isNormalUser = true;
    description = "Gaming";
    extraGroups = ["networkmanager" "video" "gamemode"];
    uid = 1001;
    shell = pkgs.bash;
  };

  users.users.adam = {
    isNormalUser = true;
    description = "Adam";
    extraGroups = ["networkmanager" "wheel" "docker" "video" "kvm" "adbusers"];
    uid = 1002;
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
  system.stateVersion = "24.05"; # Did you read the comment?
}
