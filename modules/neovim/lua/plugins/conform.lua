return {
	{
		"stevearc/conform.nvim",
		opts = {
			formatters_by_ft = {
				go = { "goimports", "gofumpt" },
				nix = { "alejandra" },
				sh = { "shfmt" },
			},
		},
	},
}
