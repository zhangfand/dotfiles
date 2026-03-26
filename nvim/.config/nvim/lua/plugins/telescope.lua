-- Enable telescope fzf native, if installed
-- pcall(require('telescope').load_extension, 'fzf')

-- See `:help telescope.builtin`

local function _builtin (name)
  return function()
    require'telescope.builtin'[name]()
  end
end

return {
  {
    'nvim-telescope/telescope.nvim',
    branch = '0.1.x',
    dependencies = {
      'nvim-lua/plenary.nvim',
      -- Fuzzy Finder Algorithm which requires local dependencies to be built.
      -- Only load if `make` is available. Make sure you have the system
      -- requirements installed.
      {
        'nvim-telescope/telescope-fzf-native.nvim',
        -- NOTE: If you are having trouble with this installation,
        --       refer to the README for telescope-fzf-native for more instructions.
        build = 'make',
        cond = function()
          return vim.fn.executable 'make' == 1
        end,
      },
    },
    cmd = { 'Telescope' },
    keys = {
      {'<leader>fg', _builtin'git_files',  desc = 'Search [G]it [F]iles' },
      {'<leader>ff', _builtin'find_files',  desc = '[S]earch [F]iles' },
      {'<leader>fh', _builtin'help_tags',  desc = '[S]earch [H]elp' },
      {'<leader>fs', _builtin'grep_string',  desc = '[S]earch current [W]ord' },
      {'<leader>fd', _builtin'diagnostics',  desc = '[S]earch [D]iagnostics' },
      {'<leader>sr', _builtin'resume',  desc = '[S]earch [R]esume' },
    }
  }
}
