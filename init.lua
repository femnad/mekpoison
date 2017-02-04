local alert = hs.alert.show
local application = hs.application
local fnutils = hs.fnutils
local window = hs.window

hs.hints.hintChars = {'h', 't', 'n', 's', 'd', 'u', 'e', 'o', 'a', 'i'}
window.animationDuration = 0

local expose = hs.expose.new()
local switcher = window.switcher.new(nil, {showThumbnails=false})

function reload()
    hs.reload()
end

function toggle_expose()
    expose:toggleShow()
end

function focus_other_window(relative_order)
    local ordered_windows = window.orderedWindows()
    local nw = ordered_windows[1 + relative_order]
    if nw ~= nil then
        nw:focus()
    else
        ordered_windows[#ordered_windows]:focus()
    end
end

function next_window()
    focus_other_window(1)
end

function prev_window()
    focus_other_window(-1)
end

function focus_other_app_window(relative_order)
    local fw = window.focusedWindow()
    local app_wins = fw:application():allWindows()
    local other_wins = fnutils.filter(app_wins, function(w) return w ~= fw end)
    local nw = other_wins[1 + relative_order]
    if nw ~= nil then
        nw:focus()
    else
        other_wins[#other_wins]:focus()
    end
end

function focus_next_app_window()
    focus_other_app_window(1)
end

function focus_prev_app_window()
    focus_other_app_window(-1)
end

function show_app_window_hints()
    hs.hints.windowHints(hs.window.focusedWindow():application():allWindows())
end

function close_application()
    window.focusedWindow():close()
end

function bind_modal(modal, modifier, modal_key, fn)
    modal:bind(modifier, modal_key, function()
        fn()
        modal:exit()
    end)
end

function fn_exit_modal(modal)
    return function()
        modal:exit()
    end
end

function maximize()
    local fw = window.focusedWindow()
    fw:maximize()
end

function toggle_fullscreen()
    local fw = window.focusedWindow()
    fw:toggleFullScreen()
end

function fn_launch_or_focus(app_name)
    return function()
        application.launchOrFocus(app_name)
    end
end

function run_choosepass()
    hs.execute('choosepass', true)
end

function switch_next()
    switcher:next()
end

function switch_prev()
    switcher:previous()
end

hs.hotkey.bind('ctrl-alt', 't', nil, switch_next)
hs.hotkey.bind('ctrl-alt', 'n', nil, switch_prev)

local modal_modifier = 'ctrl-alt'
local modal_keybindings = {
    ['h'] = {
        {'g', focus_next_app_window},
        {'c', focus_prev_app_window},
        {'d', show_app_window_hints},
        {'r', reload},
        {'h', next_window},
        {'t', prev_window},
        {'b', toggle_expose},
        {'z', close_application}
    },
    ['m'] = {
        {'b', toggle_fullscreen},
        {'m', maximize}
    },
    ['p'] = {
        {'c', run_choosepass}
    },
    ['space'] = {
        {'g', fn_launch_or_focus('HipChat')},
        {'d', fn_launch_or_focus('Dash')},
        {'h', fn_launch_or_focus('iTerm')},
        {'t', fn_launch_or_focus('Intellij IDEA CE')},
        {'n', fn_launch_or_focus('Firefox')},
        {'s', fn_launch_or_focus('Emacs')},
        {'m', fn_launch_or_focus('Airmail 3')}
    }
}

for mod_key, bindings in pairs(modal_keybindings) do
    local modal = hs.hotkey.modal.new(modal_modifier, mod_key)
    bind_modal(modal, '', 'escape', fn_exit_modal)
    for _i, binding in ipairs(bindings) do
        modal_key, modal_function = binding[1], binding[2]
        bind_modal(modal, '', modal_key, modal_function)
    end
end
