local application = hs.application
local alert = hs.alert
local battery = hs.battery
local caffeinate = hs.caffeinate
local chooser = hs.chooser
local eventtap = hs.eventtap
local execute = hs.execute
local fnutils = hs.fnutils
local notify = hs.notify
local keycodes = hs.keycodes
local pasteboard = hs.pasteboard
local screen = hs.screen
local timer = hs.timer
local usb = hs.usb
local window = hs.window

require('hs.ipc')

hs.hints.style = "vimperator"
hs.hints.showTitleThresh = 10

window.animationDuration = 0

local expose = hs.expose.new()
local switcher = window.switcher.new()

local CREDENTIAL_SCRIPT = 'getcred'
local MODAL_TIMEOUT = 5
local OLKB_KEYBOARDS_VENDOR_ID = 65261
local OLKB_KEYBOARD_IDS_TO_WATCH_FOR = {24672, 24673}
local PASTE_TIMEOUT = 20
local REMINDER_PERIOD = 60 * 30
local TERMINAL = 'iTerm'

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
    if #other_wins < 1 then
        return
    end
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

function modalTimeout(modal)
    return timer.doAfter(MODAL_TIMEOUT, function()
        modal:exit()
    end)
end

function bind_modal(modal, modifier, modal_key, fn)
    local canceler = nil

    function modal:entered()
        canceler = modalTimeout(modal)
    end

    function modal:exited()
        canceler:stop()
    end

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

function _frontAndCenter50(mainFrame)
    return _tile(mainFrame, _quarter, _quarter, _half, _half)
end

function frontAndCenter50()
    transform_window(_frontAndCenter50)
end

function _alert(message)
    alert.show(message, {['radius']=0})
end

function showCurrentTimeAndDate()
    local currentTimeAndDate = os.date("%F %T", os.time())
    _alert(currentTimeAndDate)
end

function getShowableWindows()
    return fnutils.filter(
        window.orderedWindows(), function(w)
            return #w:title() > 0
        end)
end

function getAppImage(window)
    local application = window:application()
    local appBundleID = application:bundleID()
    if appBundleID == nil then
        return hs.image.imageFromName('NSInfo')
    else
        return hs.image.imageFromAppBundle(appBundleID)
    end
end

function showWindowChooser()
    local orderedWindows = getShowableWindows()
    local windowNames = fnutils.imap(
        orderedWindows, function(window)
            return {
                subText = window:title(),
                text = window:application():title(),
                image = getAppImage(window)
            }
        end)
    local windowChooser = chooser.new(
        function(chosen)
            if chosen ~= nil then
                local chosenWindow = fnutils.find(orderedWindows, function(window)
                    return window:title() == chosen.subText
                end)
                if chosenWindow ~= nil then
                    chosenWindow:focus()
                end
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

function switch_next()
    switcher:next()
end

function switch_prev()
    switcher:previous()
end

function showBatteryStats()
    local charge = battery.percentage()
    local remaining = battery.timeRemaining()
    local alertText = 'Battery: Charge ' .. charge .. '%\nRemaining: ' .. remaining .. ' minutes'
    _alert(alertText)
end

function executeCommand(command)
    return execute(command, true)
end

function runGetCred(arguments)
    local command = CREDENTIAL_SCRIPT .. ' ' .. arguments
    local response, successful = executeCommand(command)
    if successful then
        return response
    end
end

function typeCredential(credentialType, typeEnter, notify)
    local credential = runGetCred(credentialType)
    if credential then
        eventtap.keyStrokes(credential)
        if typeEnter then
            eventtap.keyStroke({}, 'return')
        end
        if notify then
            _alert('Go Ahead, TACCOM')
        end
    end
end

function _getPassword()
    return runGetCred('password')
end

function copyPassword()
    local password = _getPassword()
    pasteboard.setContents(password)
    _alert('You have ' .. PASTE_TIMEOUT .. ' seconds to comply')
    timer.doAfter(PASTE_TIMEOUT, function()
        pasteboard.setContents('')
    end)
end

function typeLogin()
    typeCredential('login', false, false)
end

function typePassword()
    typeCredential('password')
end

function typePasswordAndEnter()
    typeCredential('password', true)
end

function _typeBoth(endWithReturn)
    local loginAndPassword = runGetCred('both')
    local _split = fnutils.split(loginAndPassword, '\n')
    local login, password = _split[1], _split[2]
    eventtap.keyStrokes(login)
    eventtap.keyStroke({}, 'tab')
    eventtap.keyStrokes(password)
    if endWithReturn then
        eventtap.keyStroke({}, 'return')
    end
end

function typeLoginTabPassword()
    _typeBoth(false)
end

function typeLoginTabPasswordEnter()
    _typeBoth(true)
end

function typePasswordTwice()
    local password = _getPassword()
    eventtap.keyStrokes(password)
    eventtap.keyStroke({}, 'tab')
    eventtap.keyStrokes(password)
end

function startScreensaver()
    caffeinate.startScreensaver()
end

function runAlfred()
    application.launchOrFocus('Alfred 3')
end

function runTerminal()
    application.launchOrFocus(TERMINAL)
end

local ctrl_alt_modifier = 'ctrl-alt'

local ctrl_alt_modal_keybindings = {
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
        {'q', startScreensaver},
        {'w', frontAndCenter},
        {'v', frontAndCenter50}
    },
    ['p'] = {
        {'o', typeLogin, 'ctrl'},
        {'e', typePasswordAndEnter, 'ctrl'},
        {'c', copyPassword, 'ctrl'},
        {'l', typeLoginTabPasswordEnter, 'ctrl'},
        {'t', typePassword, 'ctrl'},
        {'u', typePasswordTwice, 'ctrl'},
        {'s', typeLoginTabPassword, 'ctrl'}
    }
}

function paste()
    eventtap.keyStrokes(executeCommand('pbpaste'))
end

local ctrl_alt_hotkeys = {
    v = paste,
    t = switch_next,
    n = switch_prev,
}

ctrl_t_modifier = 'ctrl'

local ctrl_t_modal_keybindings = {
    ['t'] = {
        {'a', showCurrentTimeAndDate},
        {'b', toggle_fullscreen},
        {'c', runTerminal},
        {'e', runAlfred},
        {'g', focus_next_app_window},
        {'m', maximize},
        {'t', next_window},
        {'u', showWindowChooser},
        {'v', showBatteryStats},
        {'z', close_application},
        {'space', showHints}
    }
}

function bind_modal_keybindings(modal_keybindings, base_modifier)
    for mod_key, bindings in pairs(modal_keybindings) do
        local modal = hs.hotkey.modal.new(base_modifier, mod_key)
        bind_modal(modal, '', 'escape', fn_exit_modal)
        for _i, binding in ipairs(bindings) do
            local modifier = binding[3]
            if not modifier then
                modifier = ''
            end
            modal_key, modal_function = binding[1], binding[2]
            bind_modal(modal, modifier, modal_key, modal_function)
        end
    end
end

function bind_hotkeys(hotkeys, base_modifier)
    for key, fn in pairs(hotkeys) do
        hs.hotkey.bind(base_modifier, key, nil, fn)
    end
end

bind_hotkeys(ctrl_alt_hotkeys, ctrl_alt_modifier)

bind_modal_keybindings(ctrl_t_modal_keybindings, ctrl_t_modifier)
bind_modal_keybindings(ctrl_alt_modal_keybindings, ctrl_alt_modifier)

function isOlkbKeyboardEvent(event)
    return event.vendorID == OLKB_KEYBOARDS_VENDOR_ID
        and fnutils.contains(OLKB_KEYBOARD_IDS_TO_WATCH_FOR, event.productID)
end

function olkbIn()
    keycodes.setLayout('U.S.')
    karabinerApp = application.find('karabiner')
    if karabinerApp ~= nil then
        karabinerApp:kill()
    end
    reload()
    notify.show('Bring', 'OLKB', 'on')
end

function olkbOut()
    keycodes.setLayout('Dvorak')
    executeCommand('open /Applications/Karabiner-Elements.app')
    reload()
    notify.show('Ready', 'for', 'No OLKB')
end

function getOlkbWatcher()
    return usb.watcher.new(function(event)
        if isOlkbKeyboardEvent(event) then
            if event.eventType == 'added' then
                olkbIn()
            elseif event.eventType == 'removed' then
                olkbOut()
            end
        end
    end)
end

olkbWatcher = getOlkbWatcher()
olkbWatcher:start()

function showReminder()
    notify.show('Yo', 'Gabba', 'Gabba!')
end

timer.doEvery(REMINDER_PERIOD, showReminder)
