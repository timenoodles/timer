# Multi Timer — Japanese Style (LÖVE2D / Lua)

▶ **Try it in your browser: https://timenoodles.github.io/timer**

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
- Click the preset buttons (default `20m / 10m / 5m`, configured in
  `config.lua` → `config.presets`) to add minutes. Presets add up even
  while running and can be changed without touching `ui/timer_view.lua`.
- Click the **✎** button on the focused timer (or press `N`) to rename it
  (short names, max 6 chars, e.g. `FORNO`, `CAFÉ`).
- **SET** opens a numeric keypad to type the exact time (microwave-style:
  digits enter from the right — seconds, then minutes, then hours).
- **START/PAUSE** starts or pauses the countdown. Pressing START on a
  finished timer restarts it and dismisses the alarm.
- **Reset icon** (subtle, only shown when a time is set) clears the timer.
- When a timer finishes: blinking `00:00` + red X marker, window title
  flashes, and a beep sounds per `config.sound` (`off`/`beep`/`repeat3`/`repeat`).
  Press `S` to cycle the sound mode. `repeat` rings until you press
  `Space`/START/`R` (dismiss).
- State autosaves (remaining, duration, state, labels, mode, presets, sound);
  a running timer resumes via end-timestamp after reload. Press `Y` to clear
  the saved state.
- Click anywhere inside a cell to focus that timer (thicker border +
  brighter LCD + triangle marker + highlighted label). `Tab`/`Shift+Tab`
  moves focus the same way.
- Buttons **1 / 2 / 3** in the top-right corner switch the layout (how many
  timers are shown on screen). The colored dot shows the state
  (gray = ready, green = running, blue = paused, red = finished).

### Keyboard
| Key              | Action                                         |
|------------------|-------------------------------------------------|
| `Tab` / `Shift+Tab` | Move focus between timers                    |
| `Space`          | Start/Pause (or restart, if finished) the focused timer |
| `R`              | Clear (reset) the focused timer                 |
| `T`              | Open the numeric keypad to type a time (focused timer) |
| `N`              | Rename the focused timer (`Enter` ok, `Esc` cancels) |
| `S`              | Cycle alarm sound (`off`→`beep`→`repeat3`→`repeat`) |
| `P`              | Open settings (sound, theme, autosave, presets, clear save) |
| `Y`              | Clear saved state (autosave file)              |
| `F11`            | Toggle fullscreen (dedicated panel mode)        |
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
app.lua         -- app controller (mode, focus, rename, sound; no drawing)
timer.lua       -- pure countdown logic (no drawing, no audio; injectable clock)
config.lua      -- central config: presets, sound mode, autosave, label limit
notification.lua -- finish alarm (beeps + title flash), wired via setOnFinished
store.lua       -- save/restore state via love.filesystem (endTimestamp)
button.lua      -- reusable button component
layout.lua      -- cell layout for each mode (1/2/3 timers)
theme.lua       -- colors and fonts
assets/fonts/   -- DSEG7 + M PLUS Rounded fonts (OFL license, free)
ui/timer_view.lua -- per-timer cell drawing and buttons
ui/keypad.lua     -- modal numeric keypad
ui/settings.lua   -- settings modal (sound, theme, autosave, presets)
input/controls.lua -- keyboard/cell-click handling (no drawing)
tests/           -- logic tests (`lua tests/test_timer.lua`, `test_controls.lua`,
                   `test_layout.lua`, `test_store.lua`, `test_app.lua`,
                   `test_settings.lua`, `smoke_love.lua` headless)
web/index.html   -- love.js container template (title, favicon, loading/error)
```

## Settings & themes

- Press `P` (or the `⚙` button) for settings: alarm sound, theme
  (`classic`/`dark`/`contrast`), autosave on/off, the 3 presets (±1 min),
  and clearing the saved state. `↑`/`↓` select, `←`/`→` change,
  `Enter` activates, `Esc` closes.
- Themes only change the palette — layout, fonts and geometry stay the
  same, with the Japanese light theme as default.

> History (execution log) was deliberately left out: it conflicts with the
> minimalist timers-physical-device proposal and there is no real demand
> signal yet.

## Quick customization

- **Colors**: edit `theme.lua` (`theme.colors`).
- **Time presets**: edit `config.lua` (`config.presets = { 20, 10, 5 }`).
- **Alarm sound**: edit `config.lua` (`config.sound`) or press `S` in-app.

## Web/publicação

- O site no ar (`https://timenoodles.github.io/timer`, branch `gh-pages`)
  usa o harness **2dengine/love.js** (`player.js` + `index.html` +
  `style.css` próprios). Fluxo: rebuild de `game.love` a partir do `main`
  (`zip -9 -r timer-japones.love main.lua app.lua button.lua config.lua
  layout.lua notification.lua store.lua strutil.lua theme.lua timer.lua
  ui input assets`), copiar para `game.love` no `gh-pages`, commitar e
  pushear.
- Após regenerar o bundle, reaplicar em `style.css`: `object-fit: contain`
  (não `fill`, que distorce em celular retrato) + fundo `#e6e6e0` — o
  template padrão volta com `fill`.
- `web/index.html` no `main` é um **rascunho alternativo** (harness
  Davidobot/love.js, incompatível com o bundle atual) — não é publicado,
  editar lá não muda o site. Guardado como referência p/ eventual migração.
- Autosave no navegador depende do `love.wasm` persistir `love.filesystem`
  em IndexedDB (IDBFS); se um F5 real resetar o estado, o problema é no
  build wasm, não em `store.lua`.
