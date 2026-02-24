return {
       "catppuccin/nvim",
	lazy = false,
	name = "catppuccin",
	priority = 1000,
	-- Set colorscheme to catppuccin
	config = function()
		vim.cmd.colorscheme("catppuccin")
	end,
}
