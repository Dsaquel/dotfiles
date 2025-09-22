return {
	{ "nvim-treesitter/playground", cmd = "TSPlaygroundToggle" },

	{
		"nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ':TSUpdate',
	},
}
