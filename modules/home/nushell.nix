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

    zellij = {
      enable = true;
      enableBashIntegration = true;

      settings = {
        show_startup_tips = false;
        default_mode = "locked";
        keybinds = {
          locked = {
            _props = {clear-defaults = true;};

            "bind \"Ctrl g\"" = {SwitchToMode = "normal";};
            "bind \"Alt Super left\"" = {MoveFocusOrTab = "left";};
            "bind \"Alt Super down\"" = {MoveFocus = "down";};
            "bind \"Alt Super up\"" = {MoveFocus = "up";};
            "bind \"Alt Super right\"" = {MoveFocusOrTab = "right";};
            "bind \"Alt Super +\"" = {Resize = "Increase";};
            "bind \"Alt Super -\"" = {Resize = "Decrease";};
            "bind \"Alt Super =\"" = {Resize = "Increase";};
            "bind \"Alt Super [\"" = {PreviousSwapLayout = {};};
            "bind \"Alt Super ]\"" = {NextSwapLayout = {};};
            "bind \"Alt Super f\"" = {ToggleFloatingPanes = {};};
            "bind \"Alt Super h\"" = {MoveFocusOrTab = "left";};
            "bind \"Alt Super i\"" = {MoveTab = "left";};
            "bind \"Alt Super j\"" = {MoveFocus = "down";};
            "bind \"Alt Super k\"" = {MoveFocus = "up";};
            "bind \"Alt Super l\"" = {MoveFocusOrTab = "right";};
            "bind \"Alt Super p\"" = {NewPane = {};};
            "bind \"Alt Super t\"" = {NewTab = {};};
            "bind \"Alt Super o\"" = {MoveTab = "right";};
          };
          unbind = [
            "Alt left"
            "Alt down"
            "Alt up"
            "Alt right"
            "Alt +"
            "Alt -"
            "Alt ="
            "Alt ["
            "Alt ]"
            "Alt f"
            "Alt h"
            "Alt i"
            "Alt j"
            "Alt k"
            "Alt l"
            "Alt n"
            "Alt p"
            "Alt t"
            "Alt o"
          ];
        };
      };
    };
  };

  # disable zoxide diagnostics
  home.sessionVariables = {
    _ZO_DOCTOR = "0";
  };
}
