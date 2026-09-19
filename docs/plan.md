# Análise do Projeto LÖVE2D Timer

A base do projeto está boa: a lógica do contador já está separada do `main.lua`, e os arquivos `theme.lua`, `button.lua` e `layout.lua` formam uma estrutura fácil de evoluir.

O principal problema agora não é falta de funcionalidade, e sim **densidade visual + concentração de responsabilidades no `main.lua`**.

---

## 1. Interface: reduzir a quantidade de elementos visíveis

Hoje cada timer apresenta:

```text
20 min | 10 min | 5 min | SET | START | CLR
```

Isso funciona, mas seis botões competem com o elemento mais importante da interface: **o display**.

Eu seguiria uma hierarquia mais parecida com um timer físico:

```text
┌─────────────────────────────────────────────┐
│ T1                              ● READY     │
│                                             │
│             88:88                           │
│            12:35                            │
│                                             │
│  5m     10m     20m     SET       START     │
└─────────────────────────────────────────────┘
```

### Mudança principal
Manteria os presets porque eles são úteis, mas mudaria a importância visual:

* **Primário:** `START` / `PAUSE`
* **Secundários:** `5m`, `10m`, `20m`, `SET`
* **Terciário:** `RESET`

O `CLR` vermelho atualmente chama bastante atenção. Em um timer minimalista, eu faria o reset como um botão menor e discreto, por exemplo:

```text
5m  10m  20m  SET     ┌ START ┐   ↻
```

Ou até:

```text
5m  10m  20m  SET     START
                         ↻
```

> **Dica:** O botão de reset pode aparecer somente quando há tempo configurado.

---

## 2. Dar mais personalidade ao timer

A interface já tem uma inspiração clara em timers japoneses, mas falta um pouco de "produto físico".

Eu adicionaria:

### Identificação do timer
Hoje `T1`, `T2` e `T3` existem internamente, mas praticamente não são utilizados visualmente. No canto da célula:

```text
T1                         ● RUNNING
```

Sem precisar escrever frases grandes. Estados sugeridos:
* `● READY`
* `● RUN`
* `● PAUSED`
* `● DONE`

*Isso também evita depender somente da cor.*

---

## 3. Destaque do timer focado

Hoje o foco é representado por uma borda azul de 3 px. Funciona, mas eu usaria menos cor e mais contraste estrutural.

* **Timer normal:**
  ```text
  ────────────────────────────
  ```
* **Timer focado:**
  ```text
  ╔════════════════════════════╗
  ```

E principalmente:
* Borda um pouco mais espessa;
* LCD ligeiramente mais claro;
* Pequeno indicador discreto no título.

Assim o foco continua evidente sem parecer uma seleção de formulário.

---

## 4. O LCD deveria dominar a tela

Essa é provavelmente a melhoria visual mais importante. Atualmente o corpo do timer, LCD e botões têm pesos visuais relativamente próximos.

Eu faria algo como:

```text
┌─────────────────────────────────────┐
│ T1                                  │
│                                     │
│                                     │
│             12:35                   │
│                                     │
│                                     │
├─────────────────────────────────────┤
│ 5m  10m  20m  SET       START    ↻ │
└─────────────────────────────────────┘
```

O display deveria ocupar **60–70% da célula visualmente**. Isso também melhora bastante o modo com apenas um timer.

---

## 5. Evitar texto dentro do LCD durante edição

Hoje aparece: `digitando... (use o teclado numerico)`

Isso quebra um pouco a estética minimalista. No modo de edição, seria melhor mostrar o tempo direto com um indicador:

```text
T1                       SET
             12:34
```

O fato de estar editando já fica evidente pelo modal ou por uma pequena animação no LCD.

---

## 6. Teclado numérico mais compacto

O modal atual funciona, mas é bastante alto. Eu reduziria para algo mais semelhante a uma calculadora:

```text
┌───────────────────────┐
│      AJUSTAR TEMPO    │
│        12:34          │
│                       │
│   7     8     9       │
│   4     5     6       │
│   1     2     3       │
│   ←     0     C       │
│                       │
│      CANCELAR   OK    │
└───────────────────────┘
```

Mudaria `<x` para `←` e deixaria `C` exclusivamente para limpar (`Clear`).

---

## 7. START/STOP → START/PAUSE

No código você faz:

```lua
if t.state == "running" then
    b.startStopBtn.label = "STOP"
else
    b.startStopBtn.label = "START"
end
```

Mas o comportamento de `STOP` na prática é `self.state = "paused"`. Semanticamente o botão está fazendo **Pause**, não **Stop**.

Eu mudaria os rótulos para:
* `START`
* `PAUSE`

Isso deixa o modelo mental muito mais claro para o usuário.

---

## 8. Lógica baseada em tempo real (`endTime`)

Existe uma melhoria técnica importante em `timer.lua`. Hoje:

```lua
self.remaining = self.remaining - dt
```

Um timer baseado apenas em delta time (`dt`) pode acumular desvios quando a janela perde frames, o sistema fica ocupado ou o processo é pausado.

Para um timer, é mais preciso pensar em:

$$\text{hora de término} = \text{tempo atual} + \text{duração}$$

Conceitualmente:

```lua
self.endTime = love.timer.getTime() + seconds

-- No update:
self.remaining = self.endTime - love.timer.getTime()
```

Isso deixa o contador muito mais robusto.

---

## 9. Arquitetura: modularizando o `main.lua`

Atualmente `main.lua` controla timers, botões, teclado, mouse, keypad, layout, foco, renderização, estados e áudio. 

Eu migraria para uma estrutura de diretórios mais organizada:

```text
timer/
├── main.lua
├── timer.lua
├── button.lua
├── layout.lua
├── theme.lua
├── sound.lua
│
├── ui/
│   ├── timer_view.lua
│   ├── keypad.lua
│   └── mode_selector.lua
│
└── input/
    └── controls.lua
```

---

## 10. Criar o componente `TimerView`

Hoje você tem `cellButtons[i]` e várias regras espalhadas em `main.lua`. Em vez disso:

```lua
views[i] = TimerView.new(timers[i])
```

O componente `TimerView` saberia gerenciar internamente:
* `display`
* `preset buttons`
* `set button`
* `start button`
* `reset button`

E o `main.lua` ficaria limpo:

```lua
for i = 1, mode do
    views[i]:updateLayout(cells[i])
    views[i]:draw()
end
```

---

## 11. Seletor de modo mais discreto

Os números 1 / 2 / 3 no topo parecem três comandos independentes. Seria melhor:

```text
TIMERS  [ 1 ] [ 2 ] [ 3 ]
```

Ou ainda mais discreto:

```text
1  [2]  3
```

Apenas o número ativo ganha destaque.

---

## 12. Layout responsivo inteligente

No `layout.lua`, os timers sempre são distribuídos verticalmente. Em telas *widescreen* (16:9), três timers verticais desperdiçam espaço lateral.

Eu consideraria alternar com base na proporção da tela (`aspectRatio = screenW / screenH`):

* **1 Timer:**
  ```text
  ┌─────────────────────────┐
  │                         │
  │          TIMER          │
  │                         │
  └─────────────────────────┘
  ```
* **2 Timers:**
  ```text
  ┌────────────┬────────────┐
  │    T1      │    T2      │
  │            │            │
  └────────────┴────────────┘
  ```
* **3 Timers:**
  ```text
  ┌───────────┬───────────┐
  │    T1     │    T2     │
  ├───────────┴───────────┤
  │          T3           │
  └───────────────────────┘
  ```

---

## 13. Redução e padronização da paleta de cores

Atualmente há muitas cores concorrendo (amarelo, azul, vermelho, verde, cinza, azul de foco, verde LCD, vermelho de terminado).

Reduziria para uma linguagem mais enxuta:

| Papel | Cor |
| :--- | :--- |
| **Neutro** | Cinza / Creme |
| **Ação** | Azul |
| **Confirmar** | Verde |
| **Perigo** | Vermelho |
| **Presets** | Amarelo (todos com a mesma aparência) |

---

## 14. Microanimações de estado

* **Running:** Um indicador discreto (`●`) piscando lentamente.
* **Paused:** Indicador estático diferente (sem piscar).
* **Finished:** Apenas o texto `00:00` pisca e o som toca (evitando fazer a célula inteira piscar).

---

## 15. Desacoplar áudio da lógica do Timer

Em vez do `main.lua` checar `t.beepAcc`, o timer pode produzir um evento ou retorno limpo:

```lua
local finished = t:update(dt)
if finished then
    sound.playBeep()
end
```

Ou via *callback*:

```lua
t:onFinished(function()
    sound.playAlarm()
end)
```

Assim o `Timer` sabe quando terminou, mas não se preocupa com *como* o som é produzido.

---

## 16. Correções pontuais no código

1. **Escopo local:** Mudar funções globais (`confirmEditingAndClose`, `startEditing`, `setMode`, etc.) para `local function` para evitar poluição do namespace global.
2. **Simplificar `theme.load()`:** Remover o `pcall` desnecessário na verificação da fonte e passar a chave direto para o `newFont()`.
3. **Uso de `duration`:** Com o timer baseado em `endTime`, o campo `self.duration` passa a ter utilidade real (permitindo criar uma barra de progresso no futuro).

---

## 17. Adicionar uma barra de progresso discreta

Uma linha fina de 3–4 px abaixo do display para mostrar o progresso sem poluir a tela:

```text
┌────────────────────────────────┐
│ T1                     ● RUN   │
│                                │
│             12:35              │
│                                │
│ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━   │
│                                │
│ 5m  10m  20m  SET    PAUSE  ↻  │
└────────────────────────────────┘
```

---

## 18. Atalhos visíveis no rodapé

Um indicador discreto ao pressionar `?` ou com o mouse inativo:

```text
Space Start/Pause · T Set · Tab Next
```

---

## Planos de Execução por Fases

```text
FASE 1: UI
├── Reduzir peso visual dos 6 botões
├── Trocar STOP por PAUSE
├── Adicionar T1/T2/T3 e indicadores de estado
├── Aumentar destaque do LCD (60-70% da célula)
└── Compactar keypad e seletor de modo

FASE 2: Arquitetura
├── Criar ui/timer_view.lua
├── Isolar keypad do main.lua
├── Criar camada de input
└── Modularizar escopos globais para locais

FASE 3: Robustez
├── Implementar contagem por endTime
├── Evento/Callback de término
└── Isolar sistema de áudio

FASE 4: Acabamento
├── Barra de progresso discreta
├── Microanimações de estado
└── Atalhos de teclado no rodapé
```

---

## Visual Final Proposto

```text
┌─────────────────────────────────────┐
│ T1                        ● RUN     │
│              12:35                  │
│ 5m  10m  20m  SET        PAUSE  ↻   │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ T2                      ● PAUSED    │
│              04:20                  │
│ 5m  10m  20m  SET        START  ↻   │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ T3                       ● READY    │
│              00:00                  │
│ 5m  10m  20m  SET        START  ↻   │
└─────────────────────────────────────┘
```

> **Conclusão:** A primeira refatoração recomendada é criar o **`TimerView`**. Ela resolve a poluição do `main.lua` e deixa a base pronta para todas as melhorias visuais.