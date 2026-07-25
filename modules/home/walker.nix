{config, ...}: {
  services.elephant = {
    enable = true;
    settings = {
      providers = {
        default = [
          "desktopapplications"
        ];
      };
    };
  };

  xdg.configFile."elephant/desktopapplications.toml".text = ''
    show_actions = true
  '';

  services.walker = {
    enable = true;
    systemd.enable = true;
    enableElephantIntegration = true;

    settings = {
      theme = "stylix";

      providers = {
        default = [
          "desktopapplications"
        ];
        empty = ["desktopapplications"];
      };

      placeholders = {
        default = {
          input = "Search...";
          list = "No Results";
        };
        desktopapplications = {
          input = "Launch App";
          list = "No Applications";
        };
      };

      keybinds = {
        close = ["Escape"];
        next = ["Down" "ctrl j"];
        previous = ["Up" "ctrl k"];
        toggle_exact = ["ctrl e"];
        quick_activate = [];
      };
    };

    theme = let
      colors = config.lib.stylix.colors;
    in {
      name = "stylix";
      style = ''
        @define-color window_bg_color #${colors.base00};
        @define-color accent_bg_color #${colors.base02};
        @define-color theme_fg_color #${colors.base05};
        @define-color error_bg_color #${colors.base08};
        @define-color error_fg_color #${colors.base05};

        * {
          all: unset;
        }

        .box-wrapper {
          box-shadow:
            0 19px 38px rgba(0, 0, 0, 0.3),
            0 15px 12px rgba(0, 0, 0, 0.22);
          background: @window_bg_color;
          padding: 20px;
          border-radius: 20px;
          border: 1px solid alpha(@accent_bg_color, 0.5);
        }

        .input {
          caret-color: @theme_fg_color;
          background: lighter(@window_bg_color);
          padding: 10px;
          color: @theme_fg_color;
          border-radius: 10px;
        }

        .input placeholder {
          opacity: 0.5;
        }

        .list {
          color: @theme_fg_color;
        }

        .item-box {
          border-radius: 10px;
          padding: 10px;
        }

        child:hover .item-box,
        child:selected .item-box {
          background: alpha(@accent_bg_color, 0.25);
        }

        .item-text {
          font-size: 14px;
        }

        .item-subtext {
          font-size: 12px;
          opacity: 0.5;
        }

        .item-image,
        .item-image-text {
          margin-right: 10px;
        }

        .placeholder,
        .elephant-hint {
          color: @theme_fg_color;
          opacity: 0.5;
        }

        .error {
          padding: 10px;
          background: @error_bg_color;
          color: @error_fg_color;
          border-radius: 5px;
        }

        .normal-icons {
          -gtk-icon-size: 16px;
        }

        .large-icons {
          -gtk-icon-size: 32px;
        }

        scrollbar {
          opacity: 0;
        }
      '';
    };
  };
}
