-- "gc" to comment visual regions/lines
-- return {
--	"numToStr/Comment.nvim",
--	opts = {},
--}

return {
	"numToStr/Comment.nvim",
	opts = {
		-- Add a pre_hook to intercept the "nil" state
		pre_hook = function(ctx)
			-- If Neovim doesn't know the comment string, provide the Rust default
			if vim.bo.filetype == "rust" then
				return "// %s"
			end
		end,
	},
	config = function(_, opts)
		-- Ensure the plugin sets up correctly with our options
		require("Comment").setup(opts)
	end,
}
