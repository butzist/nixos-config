{
  autoGroups = {
    startup = {};
    highlight_yank = {};
    indentscope = {};
  };

  autoCmd = [
    {
      group = "startup";
      event = ["VimEnter"];
      pattern = "*";
      callback = {
        __raw = ''
          function()
            vim.cmd[[highlight Normal guibg=NONE ctermbg=NONE]]
          end
        '';
      };
    }
    {
      group = "highlight_yank";
      event = ["TextYankPost"];
      pattern = "*";
      callback = {
        __raw = ''
          function()
            vim.highlight.on_yank()
          end
        '';
      };
    }
    {
      group = "indentscope";
      event = ["FileType"];
      pattern = [
        "help"
        "Startup"
        "startup"
        "neo-tree"
        "Trouble"
        "trouble"
        "notify"
      ];
      callback = {
        __raw = ''
          function()
            vim.b.miniindentscope_disable = true
          end
        '';
      };
    }
  ];
}
