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

function list_windows()
    local windows = window.orderedwindows()
    for n, w in next, windows, nil do
        local window_title = window.title(w)
        if #window_title > 0 then
            alert.show(n .. ": " .. window_title, 3)
        end
    end
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

function spotify_current_track()
    spotify.displayCurrentTrack()
end

function bind_modal_keys(modal_key, modal_ops)
    bind_modal_key(modal_key, 'escape', fn_run_and_exit, exit_modal)
    for i, v in ipairs(modal_ops) do
        key, wrapper, fn = v[1], v[2], v[3]
        bind_modal_key(modal_key, key, wrapper, fn)
    end
end

local winops = {
    {'f', fn_run_and_exit, full_screen},
    {'g', fn_run_and_exit_non_fs, next_app_window},
    {'h', fn_run_and_exit_non_fs, show_window_hints},
    {'m', fn_run_and_exit_non_fs, maximize},
    {'p', fn_run_and_exit_non_fs, spotify_current_track},
    {'r', fn_run_and_exit, reload},
    {'t', fn_run_and_exit_non_fs, next_window},
    {'w', fn_run_and_exit_non_fs, list_windows}
}

kbd_t = modal_hotkey.new({"ctrl", "alt"}, "t")
bind_modal_keys(kbd_t, winops)

function fn_app_launch_or_focus(app)
    return function()
        application.launchorfocus(app)
    end
end

-- Launch or focus operations
local lofops = {
    {'d', fn_run_and_exit, fn_app_launch_or_focus('Dash')},
    {'g', fn_run_and_exit, fn_app_launch_or_focus('HipChat')},
    {'h', fn_run_and_exit, fn_app_launch_or_focus('iTerm')},
    {'m', fn_run_and_exit, fn_app_launch_or_focus('Mail')},
    {'n', fn_run_and_exit, fn_app_launch_or_focus('Emacs')},
    {'s', fn_run_and_exit, fn_app_launch_or_focus('Firefox-ESR')},
    {'t', fn_run_and_exit, fn_app_launch_or_focus('Intellij IDEA CE')}
}

kbd_h = modal_hotkey.new({"ctrl", "alt"}, "h")
bind_modal_keys(kbd_h, lofops)

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

function tile_right_top()
    wrap_tile(_div_by_2, _zero, _div_by_2, _div_by_2)
end

function tile_right_bottom()
    wrap_tile(_div_by_2, _div_by_2, _div_by_2, _div_by_2)
end

function tile_left_and_right()
    local ordered_windows = window.orderedwindows()
    tile_left()
    window.focus(ordered_windows[2])
    tile_right()
    window.focus(ordered_windows[1])
end

local tileops = {
    {'d', fn_run_and_exit_non_fs, tile_left_and_right},
    {'h', fn_run_and_exit_non_fs, tile_left},
    {'l', fn_run_and_exit_non_fs, tile_right_bottom},
    {'r', fn_run_and_exit_non_fs, tile_right_top},
    {'s', fn_run_and_exit_non_fs, tile_right}
}

kbd_m = modal_hotkey.new({"ctrl", "alt"}, "m")
bind_modal_keys(kbd_m, tileops)
