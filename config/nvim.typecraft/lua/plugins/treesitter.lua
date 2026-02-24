-- Install treesitter, a parser generator tool
return {
	"nvim-treesitter/nvim-treesitter",
	build = ":TSUpdate",

	-- configure treesitter
	config = function()
		local config = require("nvim-treesitter.configs")
		config.setup({
			auto_install = true,
			highlight = { enable = true },
			indent = { enable = true },
		})
	end,
}
