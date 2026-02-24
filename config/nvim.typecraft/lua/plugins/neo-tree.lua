-- Install neo-tree to plugin to browse the file system
return {
	"nvim-neo-tree/neo-tree.nvim",
	branch = "v3.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons",
		"MunifTanjim/nui.nvim",
	},

	-- Configure keymaps for neo-tree
	config = function()
		vim.keymap.set("n", "<C-n>", ":Neotree filesystem reveal left<CR>", {})
	end,
}
