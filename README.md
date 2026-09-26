# omarchy-macos

Deixa o macOS com a cara do [Omarchy](https://omarchy.org) — o setup Arch + Hyprland
do DHH — usando o tema **Tokyo Night**.

Só estética. Não mexe em nada do sistema que não seja reversível, e tudo
que é sobrescrito vai para `~/.omarchy-macos-backup/<timestamp>/`.

## O que isso instala

| Programa | Para quê |
|---|---|
| **Ghostty** | Terminal nativo e rápido, onde a paleta Tokyo Night aparece |
| **JetBrainsMono Nerd Font** | A fonte padrão do Omarchy. "Nerd Font" traz os ícones do prompt e dos TUIs |
| **starship** | O prompt: diretório, branch, status do git, duração de comandos lentos |
| extensão `enkia.tokyo-night` | O tema dentro do Cursor / VS Code |

Além disso, aplica o tema Tokyo Night no `bat`, `btop`, `lazygit`, `zellij` e no Neovim —
mas **só nos que já estiverem instalados**. Os passos são condicionais.

## Uso

```bash
git clone <url-deste-repo> ~/code/omarchy-macos
cd ~/code/omarchy-macos

./install.sh               # tema completo

# ou diretamente
./scripts/tema.sh          # cores, fonte, prompt, Cursor, wallpaper
```

Os scripts são **idempotentes**: rodar de novo pula o que já está feito e
não duplica linhas no `.zshrc`.

### Opções úteis

```bash
./scripts/tema.sh --help              # lista todas
./scripts/tema.sh --no-install        # só configura, não instala nada
./scripts/tema.sh --no-ghostty        # mantém seu terminal atual
./scripts/tema.sh --vscode            # tematiza o VS Code também
./scripts/tema.sh --wallpaper 2-swirl-buck.webp
./scripts/tema.sh --dock              # esconde o Dock
```

O `install.sh` aceita as mesmas flags do `tema.sh`:

```bash
./install.sh --no-backup              # sem guardar copia do que for sobrescrito
./install.sh --vscode                 # tematiza o VS Code tambem
```

| Comando | O que faz |
|---|---|
| `./scripts/doctor.sh` | Confere o estado da instalação e aponta sobras de versões anteriores. **Só lê** |

## Conferindo a instalação

```bash
./scripts/doctor.sh
```

Lista o estado atual (fonte do Ghostty, titlebar, tema do zellij, linhas do
`.zshrc`), aponta sobras de versões anteriores dos scripts e mostra quanto os
backups estão ocupando. **Ele nunca apaga nem altera nada** — no fim, imprime os
comandos de limpeza para você revisar e rodar se concordar.

## Decisões e pegadinhas

Estas são as razões por trás de escolhas que não são óbvias no código.

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
| `~/.config/zellij/config.kdl` | `theme "tokyo-night"` (o zellij já traz o tema embutido) |
| `~/.zshrc` | 2 linhas: carregar o snippet e iniciar o starship |
| `~/Pictures/Wallpapers/` | Wallpaper do tema |

## Desfazer

Por padrão, tudo que os scripts sobrescrevem é copiado antes para
`~/.omarchy-macos-backup/<timestamp>/`. Use `--no-backup` para desligar, e
`rm -rf ~/.omarchy-macos-backup` para apagar os acumulados.

```bash
# backups completos, por data
ls ~/.omarchy-macos-backup/

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
- [Ghostty](https://ghostty.org) · [starship](https://starship.rs)
- [tokyonight.nvim](https://github.com/folke/tokyonight.nvim) — origem das paletas
