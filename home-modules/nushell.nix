_: {
  programs = {
    nushell = {
      enable = true;
      extraConfig = ''
        $env.config = {
         show_banner: false,
        }
        $env.PATH = ($env.PATH |
        split row (char esep) |
        append /usr/bin/env
        )
      '';
      shellAliases = {
        vi = "nvim";
        vim = "nvim";
        gg = "lazygit";
        zz = "zellij";
      };
    };

    carapace = {
      enable = true;
      enableBashIntegration = true;
      enableNushellIntegration = true;
    };

    starship = {
      enable = true;
      enableBashIntegration = true;
      enableNushellIntegration = true;

      settings = {
        add_newline = true;
        character = {
          success_symbol = "[➜](bold green)";
          error_symbol = "[➜](bold red)";
        };
      };
    };

    zoxide = {
      enable = true;
      enableBashIntegration = true;
      enableNushellIntegration = true;
    };
  };

  # disable zoxide diagnostics
  home.sessionVariables = {
    _ZO_DOCTOR = "0";
  };
}
