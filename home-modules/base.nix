{pkgs, ...}: {
  # Packages that should be installed to the user profile.
  home.packages = with pkgs; [
    jq
    yq-go

    mdcat
    figlet
    fastfetch

    lazygit
    btop
    killall
    codex

    ripgrep
    fd
    eza

    evince
    pdftk
    bc
  ];

  # basic configuration of git, please change to your own
  programs = {
    bash = {
      enable = true;
      shellAliases = {
        la = "eza -la";
        ll = "eza -l";
        ls = "eza";
        cat = "bat";
        gg = "lazygit";
        zz = "zellij";
        chatgpt = "codex --sandbox read-only --ask-for-approval never";
      };
    };

    yazi = {
      enable = true;
      shellWrapperName = "y";
    };

    lazygit = {
      enable = true;
      settings = {
        git = {
          overrideGpg = true;
        };
      };
    };

    btop.enable = true;
    fzf.enable = true;
    bat.enable = true;
  };

  fonts.fontconfig.enable = true;
  home.pointerCursor.enable = true;

  # Let home Manager install and manage itself.
  programs.home-manager.enable = true;

  # One secret service for every user and every session: gnome-keyring owns
  # org.freedesktop.secrets. The daemon is started at graphical-session-pre by
  # this module's systemd user service (Plasma, Umbriel and Hyprland all reach
  # that target); the system side adds D-Bus activation and PAM unlock at login
  # (see services.gnome.gnome-keyring in nixos-modules/base.nix).
  services.gnome-keyring.enable = true;

  # Since kwallet 6.32 kwalletd6 is only a compat wrapper. With the ksecretd
  # backend disabled it forwards KWallet clients to org.freedesktop.secrets,
  # i.e. gnome-keyring above. That matters because the plasma6 module sets
  # SSH_ASKPASS=ksshaskpass for every user, so SSH passphrases land in the same
  # keyring whether the session is Plasma or not.
  xdg.configFile."kwalletrc".text = ''
    [KSecretD]
    Enabled=false
  '';
}
