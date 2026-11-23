-- Install neo-tree to plugin to browse the file system
return {
	"nvim-neo-tree/neo-tree.nvim",
	branch = "v3.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons",
		"MunifTanjim/nui.nvim",
	},

	keys = {
		{ "\\", ":Neotree reveal<CR>", { desc = "NeoTree reveal" } },
	},
	opts = {
		filesystem = {
			filtered_items = {
				-- terraform.tfvars is usually gitignored, so neo-tree hides it by default
				always_show_by_pattern = { "*.tfvars", "*.tfvars.json" },
			},
			window = {
				mappings = {
					["\\"] = "close_window",
				},
			},
		},
	},

	-- Configure keymaps for neo-tree
	-- config = function()
	-- 	vim.keymap.set("n", "<C-n>", ":Neotree filesystem reveal left<CR>", {})
	-- end,
}
