-- Highlight, edit, and navigate code
-- NOTE: this is the nvim-treesitter `main` branch (rewrite). It does NOT use the old
-- `ensure_installed` / `highlight = { enable = true }` options. Instead:
--   * parsers are installed with require("nvim-treesitter").install({...})
--   * highlighting is enabled with vim.treesitter.start() (built into Neovim)
-- Requirements: `tree-sitter` CLI (pacman -S tree-sitter-cli), a C compiler, tar, curl.
return {
	"nvim-treesitter/nvim-treesitter",
	branch = "main",
	lazy = false, -- this plugin does not support lazy-loading
	build = ":TSUpdate",
	config = function()
		local ts = require("nvim-treesitter")

		-- Parsers to always have installed (no-op if already installed; runs in the background)
		ts.install({
			"lua",
			"python",
			"javascript",
			"typescript",
			"vimdoc",
			"vim",
			"regex",
			"terraform",
			"hcl",
			"sql",
			"dockerfile",
			"toml",
			"json",
			"java",
			"groovy",
			"go",
			"gitignore",
			"graphql",
			"yaml",
			"make",
			"cmake",
			"markdown",
			"markdown_inline",
			"bash",
			"tsx",
			"css",
			"html",
		})

		local function start(buf, lang)
			if pcall(vim.treesitter.start, buf, lang) then
				-- Optional, experimental treesitter indentation:
				-- vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
				return true
			end
			return false
		end

		-- Enable highlighting for every filetype that has a parser,
		-- and auto-install missing parsers (replaces the old `auto_install = true`)
		vim.api.nvim_create_autocmd("FileType", {
			group = vim.api.nvim_create_augroup("user-treesitter", { clear = true }),
			callback = function(args)
				local lang = vim.treesitter.language.get_lang(args.match)
				if not lang or start(args.buf, lang) then
					return
				end
				if vim.tbl_contains(ts.get_available(), lang) then
					ts.install({ lang }):await(function()
						vim.schedule(function()
							if vim.api.nvim_buf_is_valid(args.buf) then
								start(args.buf, lang)
							end
						end)
					end)
				end
			end,
		})
	end,
}
