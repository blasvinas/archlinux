-- Install lualine plugin.  It is a status bar
return {
	"nvim-lualine/lualine.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },

	-- configure lualine with the dracula theme
	config = function()
		require("lualine").setup({
			options = {
				theme = "dracula",
			},
		})
	end,
}
