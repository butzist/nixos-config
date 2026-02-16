{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./wezterm.nix
  ];

  # Packages that should be installed to the user profile.
  home.packages = with pkgs; [
    jq
    yq-go

    mdcat
    figlet

    lazygit
    btop
    killall

    ripgrep
    fd
    eza

    evince
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
      };
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

    yazi = {
      enable = true;
      shellWrapperName = "y";
    };

    lazygit.enable = true;
    btop.enable = true;
    fzf.enable = true;
    bat.enable = true;
  };

  fonts.fontconfig.enable = true;

  # Let home Manager install and manage itself.
  programs.home-manager.enable = true;
}
