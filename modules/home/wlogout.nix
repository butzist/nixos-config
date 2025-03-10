{
  config,
  pkgs,
  ...
}: {
  programs.wlogout.enable = true;
  programs.wlogout.style = let
    colors = config.lib.stylix.colors;
  in ''
    * {
    	background-image: none;
    	box-shadow: none;
    }

    window {
    	background-color: #${colors.base00};
      opacity: 0.9;
    }

    button {
      margin: 20;
      border-radius: 20;
      border-color: #${colors.base0D};
    	text-decoration-color: #${colors.base05};
      color: #${colors.base05};
    	background-color: #${colors.base01};
    	border-style: solid;
    	border-width: 1px;
    	background-repeat: no-repeat;
    	background-position: center;
    	background-size: 25%;
    }

    button:focus, button:active, button:hover {
    	background-color: #${colors.base02};
      border-color: #${colors.base0D};
    	outline-style: none;
    }

    #lock {
        background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/lock.png"), url("/usr/local/share/wlogout/icons/lock.png"));
    }

    #logout {
        background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/logout.png"), url("/usr/local/share/wlogout/icons/logout.png"));
    }

    #suspend {
        background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/suspend.png"), url("/usr/local/share/wlogout/icons/suspend.png"));
    }

    #hibernate {
        background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/hibernate.png"), url("/usr/local/share/wlogout/icons/hibernate.png"));
    }

    #shutdown {
        background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/shutdown.png"), url("/usr/local/share/wlogout/icons/shutdown.png"));
    }

    #reboot {
        background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/reboot.png"), url("/usr/local/share/wlogout/icons/reboot.png"));
    }
  '';
}
