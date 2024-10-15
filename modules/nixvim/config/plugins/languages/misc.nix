{
  lib,
  pkgs,
  ...
}: {
  plugins.lsp.servers = {
    lua_ls = {enable = true;};
    nil_ls = {enable = true;};
    marksman = {enable = true;};
    jsonls = {enable = true;};
    yamlls = {enable = true;};
  };

  plugins.conform-nvim = {
    settings = {
      formatters_by_ft = {
        lua = ["stylua"];
        nix = ["alejandra"];
        markdown = [
          ["prettierd" "prettier"]
        ];
        yaml = [
          ["prettierd" "prettier"]
        ];
        bash = [
          "shellcheck"
          "shellharden"
          "shfmt"
        ];
        json = ["jq"];
        "_" = ["trim_whitespace"];
      };

      formatters = {
        alejandra = {
          command = "${lib.getExe pkgs.alejandra}";
        };
        jq = {
          command = "${lib.getExe pkgs.jq}";
        };
        prettierd = {
          command = "${lib.getExe pkgs.prettierd}";
        };
        stylua = {
          command = "${lib.getExe pkgs.stylua}";
        };
        shellcheck = {
          command = "${lib.getExe pkgs.shellcheck}";
        };
        shfmt = {
          command = "${lib.getExe pkgs.shfmt}";
        };
        shellharden = {
          command = "${lib.getExe pkgs.shellharden}";
        };
      };
    };
  };

  plugins.lint = {
    lintersByFt = {
      markdown = [
        "vale"
      ];
    };

    linters = {
      vale = {
        cmd = "${lib.getExe (pkgs.vale.withStyles (s: [s.google]))}";
      };
    };
  };

  plugins.markdown-preview = {
    enable = true;
    settings = {
      browser = "firefox";
      echo_preview_url = 1;
      port = "6969";
      preview_options = {
        disable_filename = 1;
        disable_sync_scroll = 1;
        sync_scroll_type = "middle";
      };
    };
  };

  plugins.schemastore = {
    enable = true;
    yaml.enable = true;
    json.enable = false;
  };
}
