_: {
  plugins.lualine = {
    enable = true;

    settings = {
      options = {
        globalstatus = true;
        disabledFiletypes = {
          statusline = ["startup" "alpha"];
        };
      };
      extensions = [
        "neo-tree"
      ];
      sections = {
        lualine_a = [
          {
            __unkeyed = "mode";
          }
        ];
        lualine_b = [
          {
            __unkeyed = "branch";
            icon = "";
          }
        ];
        lualine_c = [
          {
            __unkeyed = "diagnostics";
            sources = ["nvim_lsp"];
            symbols = {
              error = " ";
              warn = " ";
              info = " ";
              hint = "󰝶 ";
            };
          }
          {
            __unkeyed = "filetype";
            icon_only = true;
            separator = "";
            padding = {
              left = 1;
              right = 0;
            };
          }
          {
            __unkeyed = "filename";
            path = 1;
          }
        ];
        lualine_x = [
          {
            __unkeyed = "diff";
            symbos = {
              added = " ";
              modified = " ";
              removed = " ";
            };
            source = {
              __raw = ''
                function()
                  local gitsings = vim.b.gitsigns_status_dict
                  if gitsigns then
                    return {
                      added = gitigns.added,
                      modified = gitigns.changed,
                      removed = gitigns.removed
                    }
                  end
                end
              '';
            };
          }
        ];
        lualine_y = [
          {
            __unkeyed = "progress";
          }
        ];
        lualine_z = [
          {
            __unkeyed = "location";
          }
        ];
      };
    };
  };
}
