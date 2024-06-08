{ config, pkgs, ... }:

{
  home.username = "adam";
  home.homeDirectory = "/home/adam";

  imports = [
    ./modules/neovim/neovim.nix
  ];

  # set cursor size and dpi for 4k monitor
  xresources.properties = {
    "Xcursor.size" = 16;
    "Xft.dpi" = 172;
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Packages that should be installed to the user profile.
  home.packages = with pkgs; [
    neovim
    vscode

    ripgrep
    jq
    yq-go
    eza
    fzf

    alacritty
    nushell
    zellij

    kubectl
    terraform
    terragrunt
    helm

    firefox
    microsoft-edge

    arandr

    nodejs_20
    fnm
    go

    rustc
    rustc-wasm32
    wasm-pack
    wasm-bindgen-cli
    cargo
    rust-analyzer
    clippy
    rustfmt
    clang
    mold
  ];

  # basic configuration of git, please change to your own
  programs = {
    git = {
      enable = true;
      userName = "Adam";
      userEmail = "adam";
    };

    bash.enable = true;

    nushell = { enable = true;
      extraConfig = ''
       let carapace_completer = {|spans|
       carapace $spans.0 nushell $spans | from json
       }
       $env.config = {
        show_banner: false,
        completions: {
        case_sensitive: false # case-sensitive completions
        quick: true    # set to false to prevent auto-selecting completions
        partial: true    # set to false to prevent partial filling of the prompt
        algorithm: "fuzzy"    # prefix or fuzzy
        external: {
        # set to false to prevent nushell looking into $env.PATH to find more suggestions
            enable: true 
        # set to lower can improve completion performance at the cost of omitting some options
            max_results: 100 
            completer: $carapace_completer # check 'carapace_completer' 
          }
        }
       } 
       $env.PATH = ($env.PATH | 
       split row (char esep) |
       prepend /home/adam/.apps |
       append /usr/bin/env
       )
       '';
       shellAliases = {
         vi = "nvim";
         vim = "nvim";
       };
    };  

    carapace = { enable = true;
      enableNushellIntegration = true;
    };

    starship = { enable = true;
      settings = {
        add_newline = true;
        character = { 
          success_symbol = "[➜](bold green)";
          error_symbol = "[➜](bold red)";
        };
      };
    };

    zoxide = { enable = true;
      enableNushellIntegration = true;
    };

    alacritty = { enable = true;
      settings = {
        env.TERM = "xterm-256color";
        font = {
          size = 12;
        };
        scrolling.multiplier = 5;
        selection.save_to_clipboard = true;
      };
    };

    go = { enable = true;
      goPath = "go";
      goPrivate = [ "gitlab.com/datahow" ];
    };
  };

  home.file = {
    ".cargo/config.toml" = { source = dotfiles/cargo/config.toml; };
  };

  # This value determines the home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update home Manager without changing this value. See
  # the home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "24.05";

  # Let home Manager install and manage itself.
  programs.home-manager.enable = true;
}

