# TODO — ordem de prioridade (fonte: docs/plan.md, 2026-09-19)

Ordem: base técnica primeiro (evita retrabalho), depois UI de alto impacto, refinamentos e acabamento.

## P0 - Base técnica (desbloqueia o resto)
- [x] #16 Correções pontuais: funções globais (`confirmEditingAndClose`, `startEditing`, `setMode`, etc.) → `local function`; simplificar `theme.load()` (remover `pcall` desnecessário)
- [x] #8 Migrar `timer.lua` para `endTime = love.timer.getTime() + seconds`; `remaining = endTime - now`; dar utilidade real a `self.duration`
- [x] #15 Desacoplar áudio: callback/evento `onFinished`, `main.lua` só chama `sound.playBeep()`; `Timer` não conhece som
- [x] #9/#10 Criar `ui/timer_view.lua` (`TimerView.new(timer)` gerencia display + presets + set/start/reset), `ui/keypad.lua`, `input/controls.lua`; `main.lua` só orquestra (sem `ui/mode_selector.lua` separado — botões de modo seguem no `main.lua`, discreto o bastante)

## P1 - UI principal (alto impacto)
- [x] #7 Renomear STOP → PAUSE (comportamento real é `paused`)
- [x] #1 Hierarquia visual: primário START/PAUSE, secundários 5m/10m/20m/SET, terciário reset ↻ discreto e condicional (só com tempo configurado)
- [x] #2 Identificação T1/T2/T3 + estados `READY / RUN / PAUSED / DONE` (não só cor)
- [x] #4 LCD dominando 60–70% da célula
- [x] #3 Foco por contraste estrutural (borda mais espessa + LCD mais claro + indicador no título)

## P2 - Refinamentos
- [x] #5 Edição sem texto dentro do LCD (mostrar tempo + indicador SET/modal)
- [x] #6 Keypad compacto estilo calculadora (`←` backspace, `C` clear, CANCELAR/OK)
- [x] #11 Seletor de modo discreto (só ativo em destaque)
- [x] #13 Padronizar paleta: neutro cinza/creme, ação azul, confirmar verde, perigo vermelho, presets amarelo uniforme

## P3 - Acabamento
- [x] #12 Layout responsivo por `aspectRatio`: 1 full, 2 lado-a-lado, 3 em grade (2+1)
- [x] #17 Barra de progresso discreta 3–4px abaixo do display (depende do #8 `duration`)
- [x] #14 Microanimações: ● piscando em RUN, estático em PAUSED, só 00:00 pisca + som em DONE
- [x] #18 Rodapé de atalhos: `Space Start/Pause · T Set · Tab Next`
- [x] #19 Alarme somente visual (sem bipe): removido caminho de áudio
  (`sound.playBeep`, repetição 1x/seg, `mute`); DONE = X vermelho + `00:00` piscando

## Parte 2 — backlog pós-1.0.4 (fonte: rodadas de revisão web, 2026-09-19)

- [ ] Touch mobile: `love.touchpressed/released` (hoje só mouse/teclado); alvos ≥44px; testar em celular real
- [ ] Áudio web: confirmar bipe no primeiro término no site (autoplay policy; Space de início conta como gesto na maioria dos browsers)
- [ ] Decisão harness web: manter 2dengine/love.js no `gh-pages` ou migrar p/ Davidobot (`web/index.html` tem botão Iniciar que resolve autoplay) — ver README "Web/publicação"
- [x] `og:image` dedicado (`web/og-image.png` 1200×630 + publicado no `gh-pages`)
- [ ] PWA/manifest (ícone, tema, offline além do cache love.js)
