# omarchy-macos

Deixa o macOS com a cara do [Omarchy](https://omarchy.org) — o setup Arch + Hyprland
do DHH — usando o tema **Tokyo Night**.

Só estética e janelas. Não mexe em nada do sistema que não seja reversível, e tudo
que é sobrescrito vai para `~/.omarchy-macos-backup/<timestamp>/`.

## O que isso instala

| Programa | Para quê |
|---|---|
| **Ghostty** | Terminal nativo e rápido, onde a paleta Tokyo Night aparece |
| **JetBrainsMono Nerd Font** | A fonte padrão do Omarchy. "Nerd Font" traz os ícones do prompt e dos TUIs |
| **starship** | O prompt: diretório, branch, status do git, duração de comandos lentos |
| **AeroSpace** | Tiling window manager estilo i3. **Não exige desativar o SIP** |
| **JankyBorders** | Borda colorida na janela focada (o AeroSpace não desenha bordas) |
| extensão `enkia.tokyo-night` | O tema dentro do Cursor / VS Code |

Além disso, aplica o tema Tokyo Night no `bat`, `btop`, `lazygit`, `zellij` e no Neovim —
mas **só nos que já estiverem instalados**. Os passos são condicionais.

## Uso

```bash
git clone <url-deste-repo> ~/code/omarchy-macos
cd ~/code/omarchy-macos

./scripts/tema.sh          # cores, fonte, prompt, Cursor, wallpaper
./scripts/aerospace.sh     # tiling + bordas  (opcional)

# utilitários de linha de comando
mkdir -p ~/.local/bin && cp bin/* ~/.local/bin/ && chmod +x ~/.local/bin/*
```

Os dois scripts são **idempotentes**: rodar de novo pula o que já está feito e
não duplica linhas no `.zshrc`.

### Opções úteis

```bash
./scripts/tema.sh --help              # lista todas
./scripts/tema.sh --no-install        # só configura, não instala nada
./scripts/tema.sh --no-ghostty        # mantém seu terminal atual
./scripts/tema.sh --vscode            # tematiza o VS Code também
./scripts/tema.sh --wallpaper 2-swirl-buck.webp
./scripts/tema.sh --dock              # esconde o Dock

./scripts/aerospace.sh --no-borders   # tiling sem o JankyBorders
```

### Utilitários

| Comando | O que faz |
|---|---|
| `aerokeys` | Mostra os atalhos lendo o **seu** `~/.aerospace.toml` — o equivalente do `Super+K` do Omarchy |
| `aerokeys workspace` | Filtra a lista |
| `aeroassign` | Define em qual workspace cada app abre, descobrindo os bundle IDs sozinho |

## Atalhos do AeroSpace

Onde o Omarchy diz `Super`, aqui é **`Alt`** (Option, `⌥`).

| Atalho | Ação |
|---|---|
| `Alt + ←↓↑→` ou `hjkl` | Mover o foco |
| `Alt + Shift + ←↓↑→` | Mover a janela |
| `Alt + 1..9` | Ir para o workspace |
| `Alt + Shift + 1..9` | Levar a janela junto |
| `Alt + Enter` | Terminal novo |
| `Alt + T` | **Soltar a janela do mosaico** — a válvula de escape |
| `Alt + F` | Tela cheia |
| `Alt + W` | Fechar |
| `Alt + Tab` | Workspace anterior |
| `Alt + /` | Inverter a orientação da divisão |
| `Alt + ,` | Modo acordeão |
| `Alt + Shift + ;` | Modo service (`esc` recarrega, `r` reseta o layout) |

Decore o `Alt + T` primeiro. Quando um app brigar com o tiling, é ele que resolve.

## Decisões e pegadinhas

Estas são as razões por trás de escolhas que não são óbvias no código.

**Por que `Alt` e não `Cmd`.** O Omarchy usa Super para tudo, e no Linux essa tecla
é praticamente livre. No macOS não há equivalente: `Cmd+1..9` troca abas, `Cmd+W`
fecha aba, `Cmd+F` busca. O AeroSpace captura o atalho antes do app, então mapear
em Cmd quebraria essas funções em todos os programas. Option é a única tecla
razoavelmente livre.

**Por que `macos-titlebar-style = tabs` e não `hidden`.** O `hidden` remove a
titlebar por completo — visualmente mais próximo do Omarchy, mas no macOS ele
**desativa as abas nativas** (abas exigem titlebar) e **impede arrastar a janela
com o mouse** desde o Ghostty 1.1.0. O `tabs` dá uma titlebar fina pintada com a
cor do terminal, sem perder nada. Para usar `hidden` mesmo assim:
`defaults write -g NSWindowShouldDragOnGesture -bool true` e mova qualquer janela
com `Ctrl + Cmd + arrastar`.

**Por que Ghostty, se o padrão do Omarchy é o Foot.** O Foot é Wayland-only e não
existe no macOS. Ghostty é uma das alternativas que o próprio Omarchy suporta
oficialmente, em *Install > Terminal*, junto de Alacritty e Kitty.

**A fonte é JetBrainsMono, não CaskaydiaMono.** O manual do Omarchy é explícito:
*"Omarchy uses JetBrainsMono Nerd Font as both the terminal and system font by
default"*. Cascadia Mono aparece no manual apenas como uma das fontes opcionais
instaláveis.

**AeroSpace não desenha bordas.** É o JankyBorders que faz isso, e ele exige
macOS 14+. O script pula essa parte automaticamente em versões anteriores.

**O `settings.json` do Cursor é alterado por merge.** Se o arquivo tiver
comentários (JSONC é válido ali), o parser JSON falha — nesse caso o script
**não toca no arquivo** e deixa o trecho em `~/.config/tokyonight/vscode-settings.json`
para você colar à mão. Preferir falhar a corromper.

**A fonte do sistema não dá para trocar.** O Omarchy usa JetBrainsMono também na
interface. No macOS não existe forma suportada de fazer isso — só substituindo
fontes do sistema com SIP desativado, o que quebra a cada atualização.

## Arquivos tocados

| Caminho | Conteúdo |
|---|---|
| `~/.config/ghostty/config` | Paleta, fonte, padding, titlebar, opacidade |
| `~/.config/starship.toml` | Formato e cores do prompt |
| `~/.config/tokyonight/shell.sh` | Cores do `fzf` e tema do `bat` |
| `~/.aerospace.toml` | Atalhos, gaps, regras de janelas |
| `~/.config/borders/bordersrc` | Cor e espessura da borda |
| `~/.config/zellij/config.kdl` | `theme "tokyo-night"` (o zellij já traz o tema embutido) |
| `~/.zshrc` | 2 linhas: carregar o snippet e iniciar o starship |
| `~/Pictures/Wallpapers/` | Wallpaper do tema |

## Desfazer

```bash
# backups completos, por data
ls ~/.omarchy-macos-backup/

# tiling
brew services stop borders && brew uninstall borders
brew uninstall --cask aerospace
rm ~/.aerospace.toml ~/.config/borders/bordersrc

# cores do sistema
defaults delete -g AppleAccentColor
defaults delete -g AppleHighlightColor

# remova também a linha marcada com "# tokyonight" do seu ~/.zshrc
```

## Extra: `scripts/acelera-zshrc.sh`

Não tem relação com o tema. Troca o carregamento ansioso do `nvm` por lazy-load e
tira o `rbenv rehash` da abertura do shell. Rode com `--dry-run` primeiro para ver
o diff. Num caso real, derrubou a abertura do zsh de 1,13s para 0,66s.

## Variantes do tema

O Tokyo Night tem três tons. Para trocar, mude o `background` no Ghostty e o
`style` no Neovim:

| Variante | Background |
|---|---|
| night (padrão) | `#1a1b26` |
| storm | `#24283b` |
| moon | `#222436` |

O Omarchy tem 22 temas além do Tokyo Night. A fonte da verdade de cada um é o
`colors.toml` em [`omacom/omarchy`](https://github.com/omacom/omarchy/tree/quattro/themes) —
dá para portar qualquer um mantendo a estrutura destes scripts.

## Referências

- [Manual do Omarchy](https://omarchy.org/manual/) ([fonte no GitHub](https://github.com/omacom/omarchy/tree/quattro/manual))
- [AeroSpace](https://github.com/nikitabobko/AeroSpace) · [comandos](https://nikitabobko.github.io/AeroSpace/commands)
- [JankyBorders](https://github.com/FelixKratz/JankyBorders)
- [Ghostty](https://ghostty.org) · [starship](https://starship.rs)
- [tokyonight.nvim](https://github.com/folke/tokyonight.nvim) — origem das paletas
