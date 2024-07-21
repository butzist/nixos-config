{
  lib,
  pkgs,
  ...
}: {
  plugins.lsp.servers = {
    lua-ls = {enable = true;};
    nil-ls = {enable = true;};
    marksman = {enable = true;};
    jsonls = {enable = true;};
    yamlls = {enable = true;};
  };

  plugins.conform-nvim = {
    formattersByFt = {
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

  plugins.markdown-preview = {
    enable = true;
    settings = {
      browser = "firefox";
      echo_preview_url = true;
      port = "6969";
      preview_options = {
        disable_filename = true;
        disable_sync_scroll = true;
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
