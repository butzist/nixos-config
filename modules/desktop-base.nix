{
  config,
  pkgs,
  isDarwin,
  ...
}: {
  imports = [
  ];

  # Packages that should be installed to the user profile.
  home.packages = with pkgs; [
    jq
    yq-go

    lazygit
    btop
    killall

    ripgrep
    fd
    eza

    evince
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
      };
    };

    alacritty = {
      enable = true;
      settings = {
        env.TERM = "xterm-256color";
        scrolling.multiplier = 5;
        selection.save_to_clipboard = true;
      };
    };

    ghostty = {
      enable = !isDarwin;
    };

    neovide = {
      enable = true;
      settings = {
        font = with config.stylix.fonts; {
          normal = [monospace.name];
          size = sizes.terminal;
        };
      };
    };

    lazygit.enable = true;
    btop.enable = true;
    yazi.enable = true;
    fzf.enable = true;
    bat.enable = true;
  };

  fonts.fontconfig.enable = true;

  # Let home Manager install and manage itself.
  programs.home-manager.enable = true;
}
