-- Standalone plugins with less than 10 lines of config go here
return {
	-- NOTE: vim-tmux-navigator removed (tmux is not installed and it overrode the
	-- <C-h/j/k/l> split-navigation maps in core/keymaps.lua). Re-add it if you start using tmux.
	{
		-- Detect tabstop and shiftwidth automatically
		"tpope/vim-sleuth",
	},
	{
		-- Powerful Git integration for Vim
		"tpope/vim-fugitive",
	},
	{
		-- GitHub integration for vim-fugitive
		"tpope/vim-rhubarb",
	},
	{
		-- Highlight todo, notes, etc in comments
		"folke/todo-comments.nvim",
		event = "VimEnter",
		dependencies = { "nvim-lua/plenary.nvim" },
		opts = { signs = false },
	},
	{
		-- High-performance color highlighter (maintained fork of norcalli/nvim-colorizer.lua)
		"catgoose/nvim-colorizer.lua",
		event = "BufReadPre",
		opts = {},
	},
	{
		-- Configures lua_ls for editing your Neovim config (vim.* API, plugin types),
		-- loading libraries on demand. Also provides the "lazydev" nvim-cmp source.
		"folke/lazydev.nvim",
		ft = "lua",
		opts = {
			library = {
				-- Load luvit types when the `vim.uv` word is found
				{ path = "${3rd}/luv/library", words = { "vim%.uv" } },
			},
		},
	},
}
