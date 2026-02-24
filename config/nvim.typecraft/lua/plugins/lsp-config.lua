-- install mason which allows you to easily manage external editor tooling such as LSP servers
return {
	{
		"williamboman/mason.nvim",
    lazy = false,
		config = function()
			require("mason").setup()
		end,
	},
	{
		"williamboman/mason-lspconfig.nvim",
    lazy = false,
    opts = {
      auto_install = true,
    }
	},
	{
		"neovim/nvim-lspconfig",
    lazy = false,
		config = function()
      local capabilities = require('cmp_nvim_lsp').default_capabilities()
 			local lspconfig = require("lspconfig")

			--lua
			lspconfig.lua_ls.setup({
        capabilities = capabilities
      })

			--terraform
			lspconfig.terraformls.setup({
        capabilities = capabilities
      })

			-- rust
			lspconfig.rust_analyzer.setup({
        capabilities = capabilities,
				-- Server-specific settings. See `:help lspconfig-setup`
				settings = {
					["rust-analyzer"] = {},
				},
			})

			-- configure keymaps
			vim.keymap.set("n", "K", vim.lsp.buf.hover, {})
			vim.keymap.set("n", "gD", vim.lsp.buf.definition, {})
			vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, {})
		end,
	},
}
