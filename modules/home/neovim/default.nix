{pkgs, ...}: {
  imports = [
  ];

  home.packages = with pkgs; [
    wl-clipboard
  ];

  programs.nvf = {
    enable = true;

    settings.vim = {
      viAlias = true;
      vimAlias = true;

      options = {
        breakindent = true;
        expandtab = true;
        shiftwidth = 2;
        showtabline = 2;
        smartindent = true;
        softtabstop = 2;
        tabstop = 2;
      };

      debugMode = {
        enable = false;
        level = 16;
        logFile = "/tmp/nvim.log";
      };

      spellcheck = {
        enable = true;
      };

      diagnostics = {
        enable = true;
        config = {
          virtual_text = true;
        };
      };

      lsp = {
        enable = true;
        formatOnSave = true;
        lspkind.enable = false;
        lightbulb.enable = true;
        lspsaga.enable = false;
        trouble.enable = true;
        lspSignature.enable = true;
        otter-nvim.enable = true;
        nvim-docs-view.enable = true;
      };

      debugger = {
        nvim-dap = {
          enable = true;
          ui.enable = true;
        };
      };

      languages = {
        enableFormat = true;
        enableTreesitter = true;
        enableDAP = true;
        enableExtraDiagnostics = true;

        nix.enable = true;
        markdown = {
          enable = true;
          extensions.render-markdown-nvim.enable = true;
        };
        clang.enable = true;
        css.enable = true;
        html.enable = true;
        sql.enable = true;
        java.enable = true;
        kotlin.enable = true;
        ts.enable = true;
        go.enable = true;
        lua.enable = true;
        zig.enable = true;
        python = {
          enable = true;
          format.type = "ruff";
        };
        hcl.enable = true;
        terraform.enable = true;
        rust = {
          enable = true;
          crates.enable = true;
        };
        bash.enable = true;
        nu.enable = true;
        ruby.enable = true;
        yaml.enable = true;
        helm.enable = true;
      };

      visuals = {
        nvim-scrollbar.enable = true;
        nvim-web-devicons.enable = true;
        nvim-cursorline.enable = true;
        cinnamon-nvim.enable = true;
        fidget-nvim.enable = true;

        highlight-undo.enable = true;
        indent-blankline.enable = true;
      };

      statusline = {
        lualine = {
          enable = true;
        };
      };

      autopairs.nvim-autopairs.enable = true;
      autocomplete.nvim-cmp = {
        enable = true;
        mappings = {
          next = "<C-j>";
          previous = "<C-k>";
        };
      };
      snippets.luasnip.enable = true;

      filetree = {
        neo-tree = {
          enable = true;
        };
      };

      tabline = {
        nvimBufferline.enable = true;
      };

      treesitter = {
        context.enable = true;
        grammars = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
          ron
        ];
      };

      binds = {
        whichKey.enable = true;
        cheatsheet.enable = true;
      };

      telescope.enable = true;

      git = {
        enable = true;
        gitsigns.enable = true;
        gitsigns.codeActions.enable = false; # throws an annoying debug message
      };

      minimap = {
        minimap-vim.enable = false;
        codewindow.enable = true;
      };

      dashboard = {
        dashboard-nvim.enable = false;
        alpha.enable = true;
      };

      notify = {
        nvim-notify.enable = true;
      };

      projects = {
        project-nvim.enable = false;
      };

      utility = {
        ccc.enable = false;
        vim-wakatime.enable = false;
        diffview-nvim.enable = true;
        yanky-nvim.enable = false;
        icon-picker.enable = true;
        surround.enable = true;
        motion = {
          hop.enable = true;
          leap.enable = true;
          precognition.enable = true;
        };

        images = {
          image-nvim.enable = false;
        };
      };

      notes = {
        obsidian.enable = false;
        neorg.enable = false;
        orgmode.enable = false;
        mind-nvim.enable = false;
        todo-comments.enable = true;
      };

      terminal = {
        toggleterm = {
          enable = true;
          lazygit.enable = true;
        };
      };

      ui = {
        borders.enable = true;
        noice.enable = true;
        colorizer.enable = true;
        modes-nvim.enable = false;
        illuminate.enable = true;
        breadcrumbs = {
          enable = true;
          navbuddy.enable = true;
        };
        smartcolumn = {
          enable = true;
          setupOpts.custom_colorcolumn = {
            # this is a freeform module, it's `buftype = int;` for configuring column position
            nix = "110";
            ruby = "120";
            java = "130";
            go = ["90" "130"];
          };
        };
        fastaction.enable = true;
      };

      assistant = {
        chatgpt.enable = false;
        copilot = {
          enable = false;
          cmp.enable = true;
        };
      };

      session = {
        nvim-session-manager.enable = false;
      };

      gestures = {
        gesture-nvim.enable = false;
      };

      comments = {
        comment-nvim.enable = true;
      };

      presence = {
        neocord.enable = false;
      };

      keymaps = [
        {
          key = "<leader>e";
          mode = ["n"];
          action = "<cmd>Neotree<CR>";
          desc = "Open File Tree";
        }
        {
          key = "<leader>li";
          mode = ["n"];
          lua = true;
          action = "function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled(), { bufnr }) end";
          desc = "Toggle Inlay Hints";
        }
        {
          key = "<leader>la";
          mode = ["v"];
          lua = true;
          action = "function() vim.lsp.buf.range_code_action() end";
          desc = "Lsp Code Action";
        }
        {
          key = "H";
          mode = ["n"];
          action = "<cmd>BufferLineCyclePrev<CR>";
          desc = "Previous Tab";
        }
        {
          key = "L";
          mode = ["n"];
          action = "<cmd>BufferLineCycleNext<CR>";
          desc = "Next Tab";
        }
        {
          key = "<leader>qq";
          mode = ["n"];
          action = "<cmd>qall<CR>";
          desc = "Quit";
        }
        {
          key = "<leader>q!";
          mode = ["n"];
          action = "<cmd>qall!<CR>";
          desc = "Force Quit";
        }
        {
          key = "<esc>";
          mode = ["n" "i"];
          action = "<cmd>noh<CR><esc>";
          desc = "Escape and Clear hlsearch";
        }
      ];

      luaConfigRC.myconfig =
        /*
        lua
        */
        ''
          vim.api.nvim_create_autocmd({"TextYankPost"}, {
            pattern = {"*"},
            callback = function(ev)
              vim.highlight.on_yank()
            end
          })
        '';
    };
  };
}
