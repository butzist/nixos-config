{pkgs, ...}: {
  stylix.enable = true;
  stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-frappe.yaml";
  stylix.image = ../wallpapers/ubuntu-catppuccin.png;
  stylix.polarity = "dark";

  stylix.cursor = {
    package = pkgs.banana-cursor;
    name = "Banana";
    size = 28;
  };

  stylix.fonts = {
    serif = {
      package = pkgs.liberation_ttf;
      name = "Liberation Serif";
    };

    sansSerif = {
      package = pkgs.ubuntu-classic;
      name = "Ubuntu";
    };

    monospace = {
      package = pkgs.nerd-fonts.fira-code;
      name = "FiraCode Nerd Font";
    };
  };

  stylix.opacity = {
    terminal = 0.9;
    applications = 0.9;
  };

  stylix.targets = {
    qt.platform = "qtct";
  };

  gtk = {
    enable = true;
    iconTheme = {
      package = pkgs.adwaita-icon-theme;
      name = "Adwaita";
    };
  };
}
