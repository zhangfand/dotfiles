-- Generate annotations for Spoons.
-- Run it once in a while rather than everytime hammerspoon load configs
-- because it takes a while to generate.
-- hs.loadSpoon('EmmyLua')

-- Reload config when files in $HOME/.hammerspoon are updated.
local function reloadConfig(files)
    local doReload = false
    for _,file in pairs(files) do
        if file:sub(-4) == ".lua" then
            doReload = true
            break
        end
    end
    if doReload then
        hs.reload()
        hs.notify.new({title="Hammerspoon", informativeText="Config reloaded."}):send()
    end
end

hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", reloadConfig):start()

require'yabai'

