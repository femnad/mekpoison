local application = hs.application
local alert = hs.alert
local chooser = hs.chooser
local fnutils = hs.fnutils
local screen = hs.screen
local window = hs.window

require('hs.ipc')

hs.hints.hintChars = {'h', 't', 'n', 's', 'd', 'u', 'e', 'o', 'a', 'i'}
window.animationDuration = 0

local expose = hs.expose.new()
local switcher = window.switcher.new()

function reload()
    hs.reload()
end

function toggle_expose()
    expose:toggleShow()
end

function getFocusedWindow()
    return window.focusedWindow()
end

function getMainScreenFrame()
    local mainScreen = screen.mainScreen()
    return mainScreen:frame()
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

function showHints()
    hs.hints.windowHints()
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

function _noop(a)
    return a
end

function _zero(a)
    return 0
end

function _quarter(a)
    return a / 4
end

function _half(a)
    return a / 2
end

function _3quarters(a)
    return a * 3 / 4
end

function _oneEighth(a)
    return a / 8
end

function transform_window(transformer)
    local focusedWindow = window.focusedWindow()
    local mainScreen = screen.mainScreen()
    local mainFrame = mainScreen:frame()
    local focusedWindow = window.focusedWindow()
    local transformedFrame = transformer(mainFrame)
    focusedWindow:setFrame(transformedFrame)
end

function _tile(frame, tr_x, tr_y, tr_w, tr_h)
    frame.x = tr_x(frame.w)
    frame.y = tr_y(frame.h)
    frame.w = tr_w(frame.w)
    frame.h = tr_h(frame.h)
    return frame
end

function _tile_left_top(mainFrame)
    return _tile(mainFrame, _zero, _zero, _half, _half)
end

function _tile_left_bottom(mainFrame)
    return _tile(mainFrame, _zero, _half, _half, _half)
end

function _tile_right_top(mainFrame)
    return _tile(mainFrame, _half, _zero, _half, _half)
end

function _tile_right_bottom(mainFrame)
    return _tile(mainFrame, _half, _half, _half, _half)
end

function _tile_left(mainFrame)
    return _tile(mainFrame, _zero, _zero, _half, _noop)
end

function _tile_right(mainFrame)
    return _tile(mainFrame, _half, _zero, _half, _noop)
end

function _tile_top(mainFrame)
    return _tile(mainFrame, _zero, _zero, _noop, _half)
end

function _tile_bottom(mainFrame)
    return _tile(mainFrame, _zero, _half, _noop, _half)
end

function tile_left_top()
    transform_window(_tile_left_top)
end

function tile_left_bottom()
    transform_window(_tile_left_bottom)
end

function tile_right_top()
    transform_window(_tile_right_top)
end

function tile_right_bottom()
    transform_window(_tile_right_bottom)
end

function tile_left()
    transform_window(_tile_left)
end

function tile_right()
    transform_window(_tile_right)
end

function tile_top()
    transform_window(_tile_top)
end

function tile_bottom()
    transform_window(_tile_bottom)
end

function toggle_fullscreen()
    local fw = window.focusedWindow()
    fw:toggleFullScreen()
end

function tile_double()
    local orderedWindows = window.orderedWindows()
    if #orderedWindows >= 2 then
        tile_right()
        next_window()
        tile_left()
        next_window()
    end
end

function _frontAndCenter(mainFrame)
    return _tile(mainFrame, _oneEighth, _oneEighth, _3quarters, _3quarters)
end

function frontAndCenter()
    transform_window(_frontAndCenter)
end

function showCurrentTimeAndDate()
    local currentTimeAndDate = os.date("%F %T", os.time())
    alert.show(currentTimeAndDate, {['radius']=0})
end

function getOrderedWindowsWithNonEmptyTitles()
    return fnutils.filter(
        window.orderedWindows(), function(w)
            return #w:title() > 0
        end)
end

function showWindowChooser()
    local orderedWindows = getOrderedWindowsWithNonEmptyTitles()
    local windowNames = fnutils.imap(
        orderedWindows, function(window)
            local application = window:application()
            return {
                subText = window:title(),
                text = application:title(),
                image = hs.image.imageFromAppBundle(application:bundleID())
            }
        end)
    local windowChooser = chooser.new(
        function(chosen)
            if chosen ~= nil then
                local chosenWindow = fnutils.find(orderedWindows, function(window)
                    return window:title() == chosen.subText
                end)
                chosenWindow:focus()
            end
        end)
    windowChooser:choices(windowNames)
    windowChooser:searchSubText(true)
    windowChooser:show()
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


local base_modifier = 'ctrl-alt'
local modal_keybindings = {
    ['h'] = {
        {'a', showCurrentTimeAndDate},
        {'f', showHints},
        {'g', prev_window},
        {'r', reload},
        {'c', focus_prev_app_window},
        {'d', show_app_window_hints},
        {'h', next_window},
        {'t', focus_next_app_window},
        {'b', toggle_expose},
        {'z', close_application}
    },
    ['m'] = {
        {'g', tile_left_top},
        {'c', tile_left_bottom},
        {'r', tile_right_top},
        {'l', tile_right_bottom},
        {'d', tile_double},
        {'h', tile_left},
        {'t', tile_bottom},
        {'n', tile_top},
        {'s', tile_right},
        {'b', toggle_fullscreen},
        {'m', maximize},
        {'w', frontAndCenter}
    },
    ['space'] = {
        {'g', fn_launch_or_focus('HipChat')},
        {'d', fn_launch_or_focus('Dash')},
        {'h', fn_launch_or_focus('iTerm')},
        {'t', fn_launch_or_focus('Intellij IDEA CE')},
        {'n', fn_launch_or_focus('Firefox')},
        {'s', fn_launch_or_focus('Emacs')},
        {'m', fn_launch_or_focus('Airmail 3')},
        {'space', showWindowChooser}
    }
}

for mod_key, bindings in pairs(modal_keybindings) do
    local modal = hs.hotkey.modal.new(base_modifier, mod_key)
    bind_modal(modal, '', 'escape', fn_exit_modal)
    for _i, binding in ipairs(bindings) do
        modal_key, modal_function = binding[1], binding[2]
        bind_modal(modal, '', modal_key, modal_function)
    end
end

local hotkeys = {
    t = switch_next,
    n = switch_prev,
    p = run_choosepass
}

for key, fn in pairs(hotkeys) do
    hs.hotkey.bind(base_modifier, key, nil, fn)
end
