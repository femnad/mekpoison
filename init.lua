local application = require "mjolnir.application"
local hotkey = require "mjolnir.hotkey"
local window = require "mjolnir.window"
local fnutils = require "mjolnir.fnutils"
local modal_hotkey = require "mjolnir._asm.modal_hotkey"
local alert = require "mjolnir.alert"
local screen = require "mjolnir.screen"
local notify = require "mjolnir._asm.notify"
local hints = require "mjolnir.th.hints"
local spotify = require "mjolnir.lb.spotify"
require("mjolnir._asm.ipc")

modal_hotkey.inject()

function reload()
    mjolnir:reload()
end

function exit_modal()
end

function next_window()
    window.focus(window.orderedwindows()[2])
end

function fn_run_and_exit(modal_key, modal_fn)
    return function()
        modal_fn()
        modal_key:exit()
    end
end

function fn_run_and_exit_non_fs(modal_key, modal_fn)
    return function()
        local focused_window = window.focusedwindow()
        if not focused_window:isfullscreen() then
            modal_fn()
        end
        modal_key:exit()
    end
end

function maximize()
  local focused_window = window.focusedwindow()
  local main_frame = screen.mainscreen():frame()
  focused_window:setframe(main_frame)
end

function next_app_window()
    local fw = window.focusedwindow()
    local app = fw:application()
    local app_wins = app:allwindows()
    local main_win = app:mainwindow()
    for i=1,#app_wins do
        if app_wins[i] ~= main_win then
            app_wins[i]:focus()
        end
    end
end

function full_screen()
    local fw = window.focusedwindow()
    fw:setfullscreen(not fw:isfullscreen())
end

function bind_modal_key(modal_key, sub_key, wrapper, modal_fn)
    modal_key:bind({}, sub_key, wrapper(modal_key, modal_fn))
end

function show_window_hints()
    hints.windowHints()
end

function show_app_hints()
    local fw = window.focusedwindow()
    local app = fw:application()
    hints.appHints(app)
end

function spotify_current_track()
    spotify.displayCurrentTrack()
end

function bind_modal_keys(modal_key, modal_ops)
    bind_modal_key(modal_key, 'escape', fn_run_and_exit, exit_modal)
    for i, v in ipairs(modal_ops) do
        key, fn, is_fs_safe = v[1], v[2], v[3]
        if is_fs_safe then
            bind_modal_key(modal_key, key, fn_run_and_exit, fn)
        else
            bind_modal_key(modal_key, key, fn_run_and_exit_non_fs, fn)
        end
    end
end

function fn_app_launch_or_focus(app)
    return function()
        application.launchorfocus(app)
    end
end

function tile(transformer)
    local focused_window = window.focusedwindow()
    local screen_frame = screen.mainscreen():frame()
    local window_frame = focused_window:frame()
    transformer(window_frame, screen_frame)
    focused_window:setframe(window_frame)
end

function _div(a, b)
    return a / b
end

function _div_by_2(a)
    return _div(a, 2)
end

function _nop(a)
    return a
end

function _zero(a)
    return 0
end

function _fn_tile_tr(xt, yt, wt, ht)
    return function(f, s)
        f.x = xt(s.w)
        f.y = yt(s.h)
        f.w = wt(s.w)
        f.h = ht(s.h)
    end
end

function wrap_tile(xt, yt, wt, ht)
    tile(_fn_tile_tr(xt, yt, wt, ht))
end

function tile_left()
    wrap_tile(_zero, _zero, _div_by_2, _nop)
end

function tile_right()
    wrap_tile(_div_by_2, _zero, _div_by_2, _nop)
end

function tile_top()
    wrap_tile(_zero, _zero, _nop, _div_by_2)
end

function tile_bottom()
    wrap_tile(_zero, _div_by_2, _nop, _div_by_2)
end

function tile_right_top()
    wrap_tile(_div_by_2, _zero, _div_by_2, _div_by_2)
end

function tile_right_bottom()
    wrap_tile(_div_by_2, _div_by_2, _div_by_2, _div_by_2)
end

function tile_left_top()
    wrap_tile(_zero, _zero, _div_by_2, _div_by_2)
end

function tile_left_bottom()
    wrap_tile(_zero, _div_by_2, _div_by_2, _div_by_2)
end

function tile_left_and_right()
    local ordered_windows = window.orderedwindows()
    tile_left()
    window.focus(ordered_windows[2])
    tile_right()
    window.focus(ordered_windows[1])
end

modifier = {"ctrl", "alt"}

keybindings = {
    ['m'] = {
        {'g', tile_left_top},
        {'c', tile_left_bottom},
        {'l', tile_right_bottom},
        {'r', tile_right_top},
        {'d', tile_left_and_right},
        {'h', tile_left},
        {'t', tile_bottom},
        {'n', tile_top},
        {'s', tile_right},
        {'m', maximize}
    },
    ['h'] = {
        {'f', full_screen, true},
        {'g', next_app_window},
        {'w', show_app_hints},
        {'p', spotify_current_track},
        {'r', reload, true},
        {'h', next_window},
        {'d', show_window_hints}
    },
    ['space'] = {
        {'d', fn_app_launch_or_focus('Dash'), true},
        {'g', fn_app_launch_or_focus('HipChat'), true},
        {'h', fn_app_launch_or_focus('iTerm'), true},
        {'m', fn_app_launch_or_focus('Airmail 3'), true},
        {'n', fn_app_launch_or_focus('Emacs'), true},
        {'s', fn_app_launch_or_focus('Firefox-ESR'), true},
        {'t', fn_app_launch_or_focus('Intellij IDEA CE'), true}
    }
}

for key, chain_bindings in pairs(keybindings) do
    local modal_start = modal_hotkey.new(modifier, key)
    bind_modal_keys(modal_start, chain_bindings)
end
