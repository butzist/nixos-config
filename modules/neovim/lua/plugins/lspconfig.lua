local lspconfig = require("lspconfig")
-- local null_ls = require("null-ls")

return {
	{
		"neovim/nvim-lspconfig",
		config = function()
			-- lspconfig.lua_ls.setup({})
			-- lspconfig.pyright.setup({})
			-- lspconfig.rust_analyzer.setup({})
			-- lspconfig.tsserver.setup({})
			-- lspconfig.volar.setup({})
		end,
	},
	-- {
	-- 	"jose-elias-alvarez/null-ls.nvim",
	-- 	sources = {
	-- 		null_ls.builtins.black.stylua,
	-- 		null_ls.builtins.ruff.stylua,
	-- 		null_ls.builtins.formatting.stylua,
	-- 		null_ls.builtins.diagnostics.eslint,
	-- 		null_ls.builtins.diagnostics.ruff,
	-- 	},
	-- },
}
