# Multi Timer — Japanese Style (LÖVE2D / Lua)

A countdown timer inspired by Japanese kitchen timers
(LCD display, round buttons, minimalist design). Shows **1, 2, or 3
independent timers** on screen, each running on its own.

## How to run

1. Install LÖVE2D (https://love2d.org) — version 11.x.
2. Two ways to run:
   - **`.love` file**: double-click `timer-japones.love`
     (or drag it onto the LÖVE icon), **or**
   - **Folder**: `love .` inside the project folder (from a terminal), **or**
     drag the whole folder onto the LÖVE icon.

## Controls

### Mouse
- Click the **20m / 10m / 5m** buttons to add that many minutes to the timer.
  Presets add up even while the timer is running (e.g. +5m on the fly).
- **SET** opens a numeric keypad to type the exact time (microwave-style:
  digits enter from the right — seconds, then minutes, then hours).
- **START/PAUSE** starts or pauses the countdown. Pressing START on a
  finished timer restarts it with the last configured duration.
- **Reset icon** (subtle, only shown when a time is set) clears the timer.
- When a timer finishes there is **no sound** — only a visual warning
  (red X marker + blinking `00:00`). Press `Space`/click to restart
  or clear it.
- Click anywhere inside a cell to focus that timer (thicker border +
  triangle marker).
- Buttons **1 / 2 / 3** in the top-right corner switch the layout (how many
  timers are shown on screen). The colored dot shows the state
  (gray = ready, green = running, blue = paused, red = finished).

### Keyboard
| Key              | Action                                         |
|------------------|-------------------------------------------------|
| `Tab` / `Shift+Tab` | Move focus between timers                    |
| `Space`          | Start/Pause (or restart, if finished) the focused timer |
| `R`              | Clear (reset) the focused timer                 |
| `T`              | Open the numeric keypad to type a time          |
| `1`, `2`, `3`    | Switch layout (1, 2, or 3 timers on screen)     |
| *(while editing)* digits `0-9` | Type the time (HH MM SS)          |
| *(while editing)* arrows/`Tab` | Move selection between keypad buttons |
| *(while editing)* `Space`/`Enter` | Press the selected button (or confirm, if none selected) |
| `Enter`          | Confirm the typed time                          |
| `Backspace`      | Delete the last typed digit                     |
| `Esc`            | Cancel editing                                  |

Timers keep running in the background — switching layouts (e.g. from
3 to 1 timer) does not pause the hidden ones.

## Project structure

```
main.lua        -- entry point, LÖVE callbacks, mouse/keyboard input
timer.lua       -- pure countdown logic (no drawing)
button.lua      -- reusable button component
layout.lua      -- cell layout for each mode (1/2/3 timers)
theme.lua       -- colors and fonts
assets/fonts/   -- DSEG7 + M PLUS Rounded fonts (OFL license, free)
ui/timer_view.lua -- per-timer cell drawing and buttons
ui/keypad.lua     -- modal numeric keypad
input/controls.lua -- keyboard/cell-click handling (no drawing)
tests/test_timer.lua -- logic tests (`lua tests/test_timer.lua`)
```

## Quick customization

- **Colors**: edit `theme.lua` (`theme.colors`).
- **Time presets**: edit the `t:addPreset(20)` calls etc. in
  `ui/timer_view.lua` (`TimerView.new`).
