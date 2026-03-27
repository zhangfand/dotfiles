local log = hs.logger.new('window')

local function move_window(direction)
    local window = hs.window.focusedWindow()
    if not window then return end
    local screen = window:screen():frame()
    log.d("screen", hs.inspect(screen))
    local multipliers = {
        west = { x = 0, y = 0, w = 0.5, h = 1 },
        east = { x = 0.5, y = 0, w = 0.5, h = 1 },
        north = { x = 0, y = 0, w = 1, h = 0.5 },
        south = { x = 0, y = 0.5, w = 1, h = 0.5 },
        full = { x = 0, y = 0, w = 1, h = 1 },
    }
    local multiplier = multipliers[direction]
    log.d(direction)
    local new_frame = {
        x = screen.x + screen.w * multiplier.x,
        y = screen.y + screen.h * multiplier.y,
        w = screen.w * multiplier.w,
        h = screen.h * multiplier.h,
    }
    log.d(direction, hs.inspect(new_frame))
    window:setFrame(new_frame)
end

local command_funcs = {
    move = move_window,
}

local keymaps = {
    window = {
        move = {
            south = { { 'ctrl', 'alt' }, 'j' },
            north = { { 'ctrl', 'alt' }, 'k' },
            east = { { 'ctrl', 'alt' }, 'l' },
            west = { { 'ctrl', 'alt' }, 'h' },
            full = { { 'ctrl', 'alt' }, 'return' },
        }
        -- focus = {
        --     west           = { { 'alt' }, 'h' },
        --     -- south = {{'alt'}, 'j'},
        --     north          = { { 'alt' }, 'k' },
        --     east           = { { 'alt' }, 'l' },

        --     recent         = { { 'alt' }, 'b' },

        --     ['stack.next'] = { { 'alt' }, 'n' },
        --     ['stack.prev'] = { { 'alt' }, 'p' },
        -- },
        -- swap = {
        --     west  = { { 'alt', 'shift' }, 'h' },
        --     south = { { 'alt', 'shift' }, 'j' },
        --     north = { { 'alt', 'shift' }, 'k' },
        --     east  = { { 'alt', 'shift' }, 'l' },
        -- },
        -- space = {
        --     ['1'] = { { 'alt', 'shift' }, '1' },
        --     ['2'] = { { 'alt', 'shift' }, '2' },
        --     ['3'] = { { 'alt', 'shift' }, '3' },
        --     ['4'] = { { 'alt', 'shift' }, '4' },
        -- }
    },
    space = {
        layout = {
            stack = { { 'alt', 'shift' }, 's' },
            float = { { 'alt', 'shift' }, 'f' },
            bsp   = { { 'alt', 'shift' }, 'e' },
        },
        focus = {
            ['1'] = { { 'cmd', 'shift' }, '1' },
            ['2'] = { { 'cmd', 'shift' }, '2' },
            ['3'] = { { 'cmd', 'shift' }, '3' },
            ['4'] = { { 'cmd', 'shift' }, '4' },
        },
    },
}

for domain, commands in pairs(keymaps) do
    -- domain = window,
    for command, actions in pairs(commands) do
        -- command = focus
        local command_func = command_funcs[command]
        if not command_func then
            log.w("no handler for command: " .. domain .. "." .. command)
            goto continue
        end
        for action, binding in pairs(actions) do
            -- action = west, binding = {{'alt'}, 'h'}
            local local_action = action
            hs.hotkey.bind(binding[1], binding[2], function()
                log.d("triggered", domain, command, local_action)
                command_func(local_action)
            end)
        end
        ::continue::
    end
end
