[
  # General Configuration
  ./settings.nix
  ./keymaps.nix
  ./auto_cmds.nix

  # Languages
  ./plugins/languages/rust.nix
  ./plugins/languages/go.nix
  ./plugins/languages/python.nix
  ./plugins/languages/webdev.nix
  ./plugins/languages/devops.nix
  ./plugins/languages/misc.nix

  # Completion
  ./plugins/cmp/cmp.nix
  ./plugins/cmp/lspkind.nix

  # Snippets
  ./plugins/snippets/luasnip.nix

  # Editor plugins and configurations
  ./plugins/editor/neo-tree.nix
  ./plugins/editor/treesitter.nix
  ./plugins/editor/undotree.nix
  ./plugins/editor/illuminate.nix
  ./plugins/editor/indent-blankline.nix
  ./plugins/editor/todo-comments.nix

  # UI plugins
  ./plugins/ui/bufferline.nix
  ./plugins/ui/lualine.nix

  # LSP and formatting
  ./plugins/lsp/lsp.nix
  ./plugins/lsp/conform.nix
  ./plugins/lsp/fidget.nix

  # Git
  ./plugins/git/lazygit.nix
  ./plugins/git/gitsigns.nix

  # Utils
  ./plugins/utils/telescope.nix
  ./plugins/utils/whichkey.nix
  ./plugins/utils/mini.nix
]
