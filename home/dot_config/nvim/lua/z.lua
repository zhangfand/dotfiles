-- Add a command to use z to switch pwd.
local function z(query)
    local z_path = vim.fn.system{'zoxide', 'query', query}
    if vim.v.shell_error ~= 0 then
        return
    end
    -- Remove the trailing newline(s)
    z_path = string.gsub(z_path, '\n', '')
    vim.cmd.cd(z_path)
end

vim.api.nvim_create_user_command(
    'Z',
    function (opts)
        local query = opts.fargs[1]
        z(query)
    end,
    { nargs = 1 }
)
