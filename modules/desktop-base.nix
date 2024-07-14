{pkgs, ...}: {
  imports = [
  ];

  # Packages that should be installed to the user profile.
  home.packages = with pkgs; [
    jq
    yq-go

    lazygit
    btop

    ripgrep
    fd

    evince
  ];

  # basic configuration of git, please change to your own
  programs = {
    bash.enable = true;

    alacritty = {
      enable = true;
      settings = {
        env.TERM = "xterm-256color";
        font = {
          size = 12;
        };
        scrolling.multiplier = 5;
        selection.save_to_clipboard = true;
      };
    };

    lazygit.enable = true;
    btop.enable = true;
    fzf.enable = true;
  };

  fonts.fontconfig.enable = true;

  # Let home Manager install and manage itself.
  programs.home-manager.enable = true;
}
