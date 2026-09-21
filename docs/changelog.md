# Changelog

Todas as mudanças notáveis do projeto serão documentadas aqui.
Formato baseado em [Keep a Changelog](https://keepachangelog.com/).

## [Unreleased]
### Added
- `timeutil.lua` — fonte única `TimeUtil.now()` (elimina duplicação `love.timer.getTime or os.clock` em `main.lua:95,208`).
- Persistência fullscreen: `Store.collect/apply` + `config` agora salvam `fullscreen:boolean` (`main.lua:135` `toggleFullscreen` + `love.load` restaura).
- `web/index.html` `fixCanvasDPR()` (buffer `devicePixelRatio`) + `aria-live` `#live` para leitor de tela (poll `document.title` com `TEMPO`).
- `README.md` seção `Teclado (PT-BR)` espelhando atalhos em português.
### Fixed
- `main.lua:190` `highdpi=true` + `getDimensions` pontos lógicos, `love.resize` debounce 30ms (evita jank em drag).
- `theme.lua:102` `setFilter nearest` (LCD) / `linear` (UI) + log fallback fonte; `store.lua` `pcall` em save/load + versionamento `Store.VERSION=1` com sanitização `presets/sound/theme`.
- `ui/timer_view.lua:13` lerp `lcdBg` (~150ms) + scale pop `0.96→1` ao trocar `1↔2↔3`, sombra case + gradiente LCD + pulso `finished`, `button.lua:107` `setLineJoin bevel`.
- `ui/timer_view.lua:37` bug `theme` global `nil` em `new()` corrigido (fonte só em `refresh()` após `theme.load`).

### Changed
- `docs/todo.md` Fase A (validação HiDPI) executada, Fase B (touch mobile) como lembrete adiado a pedido.

## [1.0.4] - 2026-09-19
### Fixed
- `store.lua`: `Store.apply` limita o restante ao último valor salvo
  (`min(left, saved.remaining, saved.duration`) — no navegador a base de
  `love.timer.getTime()` pode recomeçar do zero a cada carregamento e o
  timer "ganhava" segundos após F5.
- Rename aceita acentos: novo `strutil.lua` (`upperLabel` com tabela manual
  à–ý + `stripLastChar` UTF-8), usado por `app.lua:renameInput` e
  `timer.lua:setLabel`; exemplo do README (`CAFÉ`) agora funciona de fato.
### Added
- Testes de regressão: acentos em `test_app.lua`, `test_timer.lua` e
  `smoke_love.lua`; teto pós-reload em `test_store.lua`.
- `web/og-image.png` (1200×630) + `og:image` (preview ao compartilhar o link).
### Changed
- README: seção `Web/publicação` (fluxo real via `gh-pages`, nota IDBFS);
  limitação documentada (título da aba só pisca com a aba visível —
  throttling do navegador); `web/index.html` marcado como rascunho
  alternativo não-publicado (harness Davidobot, incompatível com o bundle
  atual que usa 2dengine/love.js).

## [1.0.3] - 2026-09-19
### Fixed
- Web: `gh-pages/style.css` com `object-fit: contain` (não distorce em
  celular retrato) + fundo `#e6e6e0`; `main.lua` com `minwidth/minheight`
  menor na Web (320×240) para o layout empilhado ativar de verdade.
### Added
- SEO/acessibilidade da página: `meta description`, tags OG, `role="img"` +
  `aria-label` no canvas, `<noscript>` (em `web/index.html` e no `gh-pages`).

## [1.0.2] - 2026-09-19
### Fixed
- Settings: botão CLOSE; menu em inglês.

## [1.0.1] - 2026-09-19
### Changed
- Ícones vetoriais, foco único, removido SOM do top-bar.

## [1.0.0] - 2026-09-19
### Fixed - refatoração Fases 1–4 (ver `docs/plan.md`, itens #1–#19)
- `timer.lua`: contagem por tempo real (`endTime = now() + remaining`); `pause()` congela `remaining`, `start()` recalcula `endTime`, `addPreset` em execução desloca `endTime`; novo `getProgress()` para futura barra; `duration` com utilidade real; `update()` retorna `true` no frame de término e dispara `onFinished` (`setOnFinished`)
- `main.lua`: funções internas + repetição do bip (1x/seg) movida de `t.beepAcc` para tabela local `beepAcc[i]`; `Timer` sem estado de áudio
- Arquitetura (#9/#10): novos `ui/timer_view.lua` (botões + layout + desenho da célula), `ui/keypad.lua` (modal numérico), `input/controls.lua` (teclado + `cellAt`); `main.lua` (~495→~230 linhas) só orquestra
- UI (#7): rótulo `STOP` → `PAUSE` (comportamento real é `paused`); README atualizado
- UI (#1): hierarquia de botões — START/PAUSE primário largo (peso 1.6x), presets+SET secundários, reset ↻ terciário pequeno (≤46px, cinza) visível só com tempo configurado
- UI (#2): cabeçalho da célula com `T1/T2/T3` à esquerda e `● READY/RUN/PAUSED/DONE` à direita (texto + cor, sem depender só da cor)
- UI (#4): LCD ampliado (faixa de botões 24%→18% da célula, máx 70→56px); dígitos centralizados abaixo do cabeçalho; LCD ~64% (célula 150px) a ~85% (modo 1 timer)
- UI (#3): foco estrutural — borda neutra espessa (4px, cor `label`) em vez do anel azul, `lcdBgFocus` mais claro (0.60/0.68/0.60), indicador `▸` no título
- UI (#5): removida frase `digitando...` do LCD; em edição o cabeçalho mostra `● SET` e o tempo digitado aparece direto (o modal já indica a edição)
- P3 (#18): rodapé discreto de atalhos (faixa 24px reservada no layout)
- P3 (#14): microanimações — ● pulsante em RUN (dotAlpha/sin), estático em PAUSED, só 00:00 pisca + som em DONE
- P3 (#17): barra de progresso discreta 4px abaixo do LCD (usa getProgress do #8)
- P3 (#12): layout responsivo — wide (aspect>=1.0): 2 lado a lado, 3 em grade 2+1; retrato mantém vertical
- UI (#13): paleta padronizada — presets só amarelo, ação azul (SET, modo ativo, dot PAUSED), confirmar verde, perigo só C do keypad, neutro cinza (reset ↻, CANCELAR)
- UI (#11): seletor de modo discreto — botões 32→26px, rótulo TIMERS, só ativo em destaque
- UI (#6): keypad estilo calculadora — grade `← 0 C` (C só limpa), linha final `CANCELAR | OK`; modal 448→402px
- `main.lua`: funções internas (`confirmEditingAndClose`, `cancelEditingAndClose`, `startEditing`, `setMode`, `repositionAll`, `refreshAllButtons`) agora `local` com forward-declares; só callbacks `love.*` permanecem globais
- `theme.lua`: removido `pcall` desnecessário em `theme.load()`

## [0.1.0] - 2026-09-19
### Added
- Estrutura inicial: `main.lua`, `timer.lua`, `button.lua`, `layout.lua`, `theme.lua`, `sound.lua`
- Contador com presets 5m/10m/20m, SET via keypad modal, START/STOP, CLR
- Suporte a 1/2/3 timers, LCD, indicador de foco, seletor de modo
