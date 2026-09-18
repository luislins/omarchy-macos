#!/usr/bin/env bash
#
# omarchy-tokyonight-macos.sh
#
# Deixa o macOS com a cara do Omarchy (tema Tokyo Night).
# Escopo: SOMENTE estetica. Nao mexe em gerenciamento de janelas,
# nao instala tiling WM, nao altera atalhos do sistema.
#
# O que faz:
#   - Ghostty com paleta Tokyo Night (night), titlebar minimalista, padding
#   - JetBrainsMono Nerd Font (a fonte padrao do Omarchy: terminal e sistema)
#   - starship prompt em Tokyo Night
#   - btop, bat, fzf, lazygit, neovim -> Tokyo Night (so os que ja existem)
#   - Cursor: extensao enkia.tokyo-night + fonte, igual ao Omarchy faz
#   - Dark mode + accent/highlight color azul Tokyo Night
#   - Wallpaper oficial do tema tokyo-night do Omarchy
#
# Uso:
#   chmod +x omarchy-tokyonight-macos.sh
#   ./omarchy-tokyonight-macos.sh              # instalacao normal
#   ./omarchy-tokyonight-macos.sh --no-install # nao instala nada via brew, so configura
#   ./omarchy-tokyonight-macos.sh --no-ghostty # nao instala nem configura o Ghostty
#   ./omarchy-tokyonight-macos.sh --dock       # tambem esconde o Dock automaticamente
#   ./omarchy-tokyonight-macos.sh --no-wallpaper        # nao mexe no papel de parede
#   ./omarchy-tokyonight-macos.sh --wallpaper ARQUIVO   # escolhe outro wallpaper
#   ./omarchy-tokyonight-macos.sh --vscode              # tematiza o VS Code tambem
#
# Wallpapers do tema tokyo-night (omacom/omarchy, branch quattro):
#   0-winding-road.webp   estrada sinuosa no por do sol roxo
#   1-quattro.webp        Audi Quattro de rally saltando  <-- padrao
#   2-swirl-buck.webp     silhueta de cervo em espiral rosa/roxa
#   3-sunset-lake.webp    4-omakub.webp   5-oma-cityscape.jpg
#   6-oma.webp            omarchy.webp
#
# Tudo que for sobrescrito vai para ~/.omarchy-macos-backup/<timestamp>/

set -euo pipefail

# ---------------------------------------------------------------- config base

TS="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$HOME/.omarchy-macos-backup/$TS"
XDG="${XDG_CONFIG_HOME:-$HOME/.config}"
SHELL_SNIPPET="$XDG/tokyonight/shell.sh"

DO_INSTALL=1
DO_DOCK=0
DO_GHOSTTY=1
DO_VSCODE=0
WALLPAPER="1-quattro.webp"

while [ $# -gt 0 ]; do
  case "$1" in
    --no-install)    DO_INSTALL=0 ;;
    --no-ghostty)    DO_GHOSTTY=0 ;;
    --vscode)        DO_VSCODE=1 ;;
    --dock)          DO_DOCK=1 ;;
    --no-wallpaper)  WALLPAPER="" ;;
    --wallpaper)     WALLPAPER="${2:-}"; shift ;;
    --wallpaper=*)   WALLPAPER="${1#*=}" ;;
    -h|--help)       sed -n '2,34p' "$0"; exit 0 ;;
    *) echo "argumento desconhecido: $1" >&2; exit 2 ;;
  esac
  shift
done

# --------------------------------------------------------------------- helpers

BLUE=$'\033[38;5;111m'; GREEN=$'\033[38;5;150m'; YELLOW=$'\033[38;5;179m'
RED=$'\033[38;5;204m'; DIM=$'\033[38;5;103m'; RESET=$'\033[0m'

info() { printf '%s==>%s %s\n' "$BLUE" "$RESET" "$*"; }
ok()   { printf '%s  ok%s %s\n' "$GREEN" "$RESET" "$*"; }
warn() { printf '%s  !!%s %s\n' "$YELLOW" "$RESET" "$*"; }
skip() { printf '%s  --%s %s\n' "$DIM" "$RESET" "$*"; }
die()  { printf '%serro%s %s\n' "$RED" "$RESET" "$*" >&2; exit 1; }

has() { command -v "$1" >/dev/null 2>&1; }

# Move um arquivo/diretorio existente para o backup antes de sobrescrever.
backup() {
  local target="$1"
  [ -e "$target" ] || return 0
  local rel="${target#"$HOME"/}"
  local dest="$BACKUP_DIR/$rel"
  mkdir -p "$(dirname "$dest")"
  cp -R "$target" "$dest"
}

# Escreve stdin em $1, com backup do que existia antes.
write_file() {
  local target="$1"
  backup "$target"
  mkdir -p "$(dirname "$target")"
  cat > "$target"
}

# Adiciona uma linha no rc do shell so se ela ainda nao estiver la.
ensure_line() {
  local file="$1" line="$2"
  [ -f "$file" ] || { backup "$file"; touch "$file"; }
  grep -qF -- "$line" "$file" && return 0
  backup "$file"
  printf '\n%s\n' "$line" >> "$file"
}

# ----------------------------------------------------------------- pre-flight

[ "$(uname -s)" = "Darwin" ] || die "este script e so para macOS."

mkdir -p "$BACKUP_DIR"
info "backup desta execucao: $BACKUP_DIR"

if ! has brew; then
  if [ "$DO_INSTALL" -eq 1 ]; then
    die "Homebrew nao encontrado. Instale em https://brew.sh ou rode com --no-install."
  fi
  warn "Homebrew nao encontrado; seguindo so com as configuracoes."
fi

# ----------------------------------------------------- 1. pacotes obrigatorios

if [ "$DO_INSTALL" -eq 1 ]; then
  info "instalando o minimo (fonte, Ghostty, starship)"

  if brew list --cask font-jetbrains-mono-nerd-font >/dev/null 2>&1; then
    skip "JetBrainsMono Nerd Font ja instalada"
  else
    brew install --cask font-jetbrains-mono-nerd-font
    ok "JetBrainsMono Nerd Font"
  fi

  if [ "$DO_GHOSTTY" -eq 0 ]; then
    skip "--no-ghostty: pulando instalacao do Ghostty"
  elif has ghostty || [ -d "/Applications/Ghostty.app" ]; then
    skip "Ghostty ja instalado"
  else
    brew install --cask ghostty
    ok "Ghostty"
  fi

  if has starship; then
    skip "starship ja instalado"
  else
    brew install starship
    ok "starship"
  fi
else
  skip "--no-install: pulando instalacao de pacotes"
fi

# --------------------------------------------------------------- 2. Ghostty

if [ "$DO_GHOSTTY" -eq 1 ]; then

info "configurando Ghostty (Tokyo Night night)"

write_file "$XDG/ghostty/config" <<'EOF'
# Tokyo Night (night) - tema Tokyo Night do Omarchy, fonte JetBrainsMono Nerd
# Font (a padrao do Omarchy). O terminal padrao do Omarchy e o Foot, que e
# Wayland-only e nao existe no macOS; Ghostty e uma das alternativas que o
# proprio Omarchy suporta oficialmente (Install > Terminal).
# docs: ghostty +show-config --default --docs

font-family = JetBrainsMono Nerd Font
font-size = 14
font-thicken = true

# --- paleta Tokyo Night (night) ---------------------------------------------
background = #1a1b26
foreground = #c0caf5
cursor-color = #c0caf5
cursor-text = #1a1b26
selection-background = #283457
selection-foreground = #c0caf5

palette = 0=#15161e
palette = 1=#f7768e
palette = 2=#9ece6a
palette = 3=#e0af68
palette = 4=#7aa2f7
palette = 5=#bb9af7
palette = 6=#7dcfff
palette = 7=#a9b1d6
palette = 8=#414868
palette = 9=#f7768e
palette = 10=#9ece6a
palette = 11=#e0af68
palette = 12=#7aa2f7
palette = 13=#bb9af7
palette = 14=#7dcfff
palette = 15=#c0caf5

# --- janela (visual "sem chrome" do Omarchy) --------------------------------
# 'tabs' = titlebar fininha, pintada com a cor do terminal, e abas nativas
# funcionando. E o mais proximo do Omarchy SEM perder usabilidade.
#
# 'hidden' remove a titlebar por completo, mas no macOS isso tambem:
#   - desativa as abas nativas (aba nativa exige titlebar)
#   - impede arrastar a janela com o mouse (desde o Ghostty 1.1.0)
# Se ainda assim quiser 'hidden', habilite o arraste global do macOS:
#   defaults write -g NSWindowShouldDragOnGesture -bool true
# e depois mova qualquer janela com Ctrl+Cmd+arrastar.
macos-titlebar-style = tabs
window-padding-x = 14
window-padding-y = 14
window-padding-balance = true
window-theme = ghostty
background-opacity = 0.97
# descomente se a sua versao do Ghostty suportar blur:
# background-blur = true

# --- comportamento ----------------------------------------------------------
cursor-style = block
mouse-hide-while-typing = true
copy-on-select = clipboard
confirm-close-surface = false
macos-option-as-alt = true
shell-integration = detect
EOF
ok "$XDG/ghostty/config"

else
  skip "--no-ghostty: config do Ghostty nao escrita"
fi

# --------------------------------------------------------------- 3. starship

info "configurando starship"

write_file "$XDG/starship.toml" <<'EOF'
# Tokyo Night
add_newline = true
format = "$directory$git_branch$git_status$cmd_duration$line_break$character"

[directory]
style = "bold #7aa2f7"
truncation_length = 3
truncate_to_repo = true
read_only = " "
read_only_style = "#f7768e"

[git_branch]
symbol = " "
style = "#bb9af7"
format = "on [$symbol$branch]($style) "

[git_status]
style = "#e0af68"
format = "([\\[$all_status$ahead_behind\\]]($style)) "

[cmd_duration]
min_time = 2000
style = "#565f89"
format = "[$duration]($style) "

[character]
success_symbol = "[❯](#9ece6a)"
error_symbol = "[❯](#f7768e)"
vimcmd_symbol = "[❮](#bb9af7)"
EOF
ok "$XDG/starship.toml"

# ------------------------------------------------- 4. snippet de shell (cores)

info "escrevendo snippet de shell com as cores (fzf, bat)"

write_file "$SHELL_SNIPPET" <<'EOF'
# Tokyo Night - carregado pelo ~/.zshrc (ou ~/.bashrc)
# Remova a linha que faz o source deste arquivo para desfazer.

export FZF_DEFAULT_OPTS="\
--color=bg+:#283457,bg:#16161e,border:#27a1b9,fg:#c0caf5 \
--color=gutter:#16161e,header:#ff9e64,hl+:#2ac3de,hl:#2ac3de \
--color=info:#545c7e,marker:#ff007c,pointer:#ff007c \
--color=prompt:#2ac3de,query:#c0caf5:regular,scrollbar:#27a1b9 \
--color=separator:#ff9e64,spinner:#ff007c"

export BAT_THEME="tokyonight_night"
EOF
ok "$SHELL_SNIPPET"

# rc do shell atual
case "${SHELL##*/}" in
  zsh)  RC="$HOME/.zshrc" ;;
  bash) RC="$HOME/.bash_profile" ;;
  *)    RC="$HOME/.zshrc" ;;
esac

ensure_line "$RC" "[ -f \"$SHELL_SNIPPET\" ] && . \"$SHELL_SNIPPET\"   # tokyonight"
ok "source do snippet em $RC"

if has starship; then
  case "${SHELL##*/}" in
    bash) ensure_line "$RC" 'eval "$(starship init bash)"' ;;
    *)    ensure_line "$RC" 'eval "$(starship init zsh)"' ;;
  esac
  ok "starship init em $RC"
fi

# ------------------------------------------------------------------- 5. bat

if has bat; then
  info "instalando tema Tokyo Night no bat"
  BAT_THEMES="$(bat --config-dir 2>/dev/null)/themes"
  mkdir -p "$BAT_THEMES"
  if curl -fsSL -o "$BAT_THEMES/tokyonight_night.tmTheme" \
      "https://raw.githubusercontent.com/folke/tokyonight.nvim/main/extras/sublime/tokyonight_night.tmTheme"; then
    bat cache --build >/dev/null
    ok "bat -> tokyonight_night"
  else
    warn "nao consegui baixar o tema do bat (rede?); pulando"
  fi
else
  skip "bat nao instalado"
fi

# ------------------------------------------------------------------- 6. btop

if has btop; then
  info "configurando btop"
  BTOP_THEME=""
  for candidate in \
    "$(brew --prefix 2>/dev/null)/share/btop/themes/tokyo-night.theme" \
    "/opt/homebrew/share/btop/themes/tokyo-night.theme" \
    "/usr/local/share/btop/themes/tokyo-night.theme"; do
    [ -f "$candidate" ] && { BTOP_THEME="$candidate"; break; }
  done

  if [ -z "$BTOP_THEME" ]; then
    mkdir -p "$XDG/btop/themes"
    if curl -fsSL -o "$XDG/btop/themes/tokyo-night.theme" \
        "https://raw.githubusercontent.com/aristocratos/btop/main/themes/tokyo-night.theme"; then
      BTOP_THEME="$XDG/btop/themes/tokyo-night.theme"
    fi
  fi

  if [ -n "$BTOP_THEME" ]; then
    CONF="$XDG/btop/btop.conf"
    if [ -f "$CONF" ]; then
      backup "$CONF"
      # substitui a linha color_theme mantendo o resto da config intacto
      /usr/bin/sed -i '' "s|^color_theme = .*|color_theme = \"$BTOP_THEME\"|" "$CONF"
      grep -q '^color_theme' "$CONF" || printf 'color_theme = "%s"\n' "$BTOP_THEME" >> "$CONF"
      grep -q '^theme_background' "$CONF" \
        && /usr/bin/sed -i '' 's|^theme_background = .*|theme_background = False|' "$CONF" \
        || printf 'theme_background = False\n' >> "$CONF"
    else
      mkdir -p "$(dirname "$CONF")"
      printf 'color_theme = "%s"\ntheme_background = False\nvim_keys = True\n' "$BTOP_THEME" > "$CONF"
    fi
    ok "btop -> tokyo-night"
  else
    warn "tema do btop nao encontrado nem baixado; pulando"
  fi
else
  skip "btop nao instalado"
fi

# ---------------------------------------------------------------- 7. lazygit

if has lazygit; then
  info "configurando lazygit"
  if [ -n "${XDG_CONFIG_HOME:-}" ] || [ -d "$HOME/.config/lazygit" ]; then
    LG_DIR="$XDG/lazygit"
  else
    LG_DIR="$HOME/Library/Application Support/lazygit"
  fi
  LG_CONF="$LG_DIR/config.yml"

  LG_THEME=$(cat <<'EOF'
gui:
  theme:
    activeBorderColor: ["#ff9e64", "bold"]
    inactiveBorderColor: ["#27a1b9"]
    searchingActiveBorderColor: ["#ff9e64", "bold"]
    optionsTextColor: ["#7aa2f7"]
    selectedLineBgColor: ["#283457"]
    cherryPickedCommitFgColor: ["#7aa2f7"]
    cherryPickedCommitBgColor: ["#bb9af7"]
    markedBaseCommitFgColor: ["#7aa2f7"]
    markedBaseCommitBgColor: ["#e0af68"]
    unstagedChangesColor: ["#db4b4b"]
    defaultFgColor: ["#c0caf5"]
EOF
)

  if [ -f "$LG_CONF" ]; then
    mkdir -p "$XDG/tokyonight"
    printf '%s\n' "$LG_THEME" > "$XDG/tokyonight/lazygit-theme.yml"
    warn "ja existe $LG_CONF - nao vou sobrescrever."
    warn "o bloco do tema esta em $XDG/tokyonight/lazygit-theme.yml para voce mesclar."
  else
    mkdir -p "$LG_DIR"
    printf '%s\n' "$LG_THEME" > "$LG_CONF"
    ok "lazygit -> Tokyo Night"
  fi
else
  skip "lazygit nao instalado"
fi

# ----------------------------------------------------------------- 8. neovim

if [ -d "$XDG/nvim/lua/plugins" ]; then
  info "configurando Neovim (LazyVim detectado)"
  write_file "$XDG/nvim/lua/plugins/tokyonight.lua" <<'EOF'
-- Tokyo Night, no mesmo estilo do Omarchy
return {
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      style = "night",
      transparent = false,
      styles = {
        comments = { italic = true },
        keywords = { italic = true },
        sidebars = "dark",
        floats = "dark",
      },
    },
  },
  {
    "LazyVim/LazyVim",
    opts = { colorscheme = "tokyonight-night" },
  },
}
EOF
  ok "$XDG/nvim/lua/plugins/tokyonight.lua"
elif [ -d "$XDG/nvim" ]; then
  skip "nvim existe mas nao parece LazyVim - adicione folke/tokyonight.nvim manualmente"
else
  skip "neovim sem config"
fi

# ------------------------------------------------------------------ 9. Cursor

# O Omarchy tematiza Cursor/VSCode da forma mais simples possivel: instala a
# extensao enkia.tokyo-night e seleciona o tema "Tokyo Night". E literalmente
# o conteudo de themes/tokyo-night/vscode.json no repo do Omarchy.
# O manual (18-development-tools.md) confirma: "Theme matching is offered for
# VSCode, Cursor, VSCodium, and Helix."

TOKYO_VSCODE_JSON='{
  "workbench.colorTheme": "Tokyo Night",
  "editor.fontFamily": "JetBrainsMono Nerd Font, Menlo, monospace",
  "editor.fontSize": 14,
  "editor.fontLigatures": true,
  "terminal.integrated.fontFamily": "JetBrainsMono Nerd Font",
  "terminal.integrated.fontSize": 14
}'

theme_vscode_like() {
  local nome="$1" app_dir="$2" cli="$3"
  local settings="$app_dir/User/settings.json"
  local merged=0

  if [ ! -d "$app_dir" ]; then
    skip "$nome nao encontrado"
    return 0
  fi

  info "configurando $nome"

  # --- extensao do tema ---
  if [ -n "$cli" ] && [ -x "$cli" ]; then
    if "$cli" --install-extension enkia.tokyo-night >/dev/null 2>&1; then
      ok "$nome: extensao enkia.tokyo-night"
    else
      warn "$nome: a CLI nao instalou a extensao; instale 'Tokyo Night' (enkia) pela loja"
    fi
  else
    warn "$nome: CLI nao encontrada; instale a extensao 'Tokyo Night' (enkia) pela loja"
  fi

  # --- settings.json ---
  # Nunca sobrescreve as suas configuracoes: se o arquivo ja existe, faz merge.
  if [ ! -f "$settings" ]; then
    mkdir -p "$(dirname "$settings")"
    printf '%s\n' "$TOKYO_VSCODE_JSON" > "$settings"
    ok "$nome: settings.json criado"
    return 0
  fi

  backup "$settings"

  if has python3; then
    if python3 - "$settings" <<'PY'
import json, sys

caminho = sys.argv[1]
# json.load falha de proposito se o arquivo tiver comentarios (JSONC).
# Preferimos falhar e pedir merge manual a corromper as configuracoes.
with open(caminho) as f:
    cfg = json.load(f)

cfg.update({
    "workbench.colorTheme": "Tokyo Night",
    "editor.fontFamily": "JetBrainsMono Nerd Font, Menlo, monospace",
    "editor.fontSize": 14,
    "editor.fontLigatures": True,
    "terminal.integrated.fontFamily": "JetBrainsMono Nerd Font",
    "terminal.integrated.fontSize": 14,
})

with open(caminho, "w") as f:
    json.dump(cfg, f, indent=2, ensure_ascii=False)
    f.write("\n")
PY
    then
      merged=1
    fi
  fi

  if [ "$merged" -eq 1 ]; then
    ok "$nome: settings.json atualizado (merge, sem perder o que ja tinha)"
  else
    mkdir -p "$XDG/tokyonight"
    printf '%s\n' "$TOKYO_VSCODE_JSON" > "$XDG/tokyonight/vscode-settings.json"
    warn "$nome: nao consegui fazer o merge automatico (settings.json com"
    warn "comentarios, ou python3 ausente). Seu arquivo ficou INTACTO."
    warn "cole as chaves de $XDG/tokyonight/vscode-settings.json no seu settings.json"
  fi
}

CURSOR_CLI=""
if has cursor; then
  CURSOR_CLI="$(command -v cursor)"
elif [ -x "/Applications/Cursor.app/Contents/Resources/app/bin/cursor" ]; then
  CURSOR_CLI="/Applications/Cursor.app/Contents/Resources/app/bin/cursor"
fi
theme_vscode_like "Cursor" "$HOME/Library/Application Support/Cursor" "$CURSOR_CLI"

if [ "$DO_VSCODE" -eq 1 ]; then
  VSCODE_CLI=""
  if has code; then
    VSCODE_CLI="$(command -v code)"
  elif [ -x "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" ]; then
    VSCODE_CLI="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
  fi
  theme_vscode_like "VS Code" "$HOME/Library/Application Support/Code" "$VSCODE_CLI"
fi

# ---------------------------------------------------------- 10. macOS aparencia

info "aplicando aparencia do sistema"

osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to true' \
  && ok "dark mode ativado" || warn "nao consegui ativar o dark mode (permissao de automacao?)"

# accent = azul; highlight = #7aa2f7 do Tokyo Night
defaults write -g AppleAccentColor -int 4
defaults write -g AppleHighlightColor -string "0.478431 0.635294 0.968627 Blue"
ok "accent/highlight color"

# ----------------------------------------------------------- 11. wallpaper

if [ -z "$WALLPAPER" ]; then
  skip "--no-wallpaper: papel de parede inalterado"
else
  info "baixando wallpaper: $WALLPAPER"
  WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
  mkdir -p "$WALLPAPER_DIR"

  BG_BASE="https://raw.githubusercontent.com/omacom/omarchy/quattro/themes/tokyo-night/backgrounds"
  WALL_SRC="$WALLPAPER_DIR/$WALLPAPER"

  if curl -fsSL --max-time 120 -o "$WALL_SRC" "$BG_BASE/$WALLPAPER"; then
    WALL_FILE="$WALL_SRC"

    # o macOS nem sempre aceita .webp como papel de parede; converte com sips
    # (que ja vem no sistema). Se falhar, tenta aplicar o .webp direto.
    case "$WALLPAPER" in
      *.webp)
        if sips -s format png "$WALL_SRC" --out "${WALL_SRC%.webp}.png" >/dev/null 2>&1; then
          WALL_FILE="${WALL_SRC%.webp}.png"
          rm -f "$WALL_SRC"
        else
          warn "sips nao converteu o .webp; tentando aplicar no formato original"
        fi
        ;;
    esac

    if osascript -e "tell application \"System Events\" to tell every desktop to set picture to \"$WALL_FILE\"" 2>/dev/null; then
      ok "wallpaper: $WALL_FILE"
    else
      warn "baixado em $WALL_FILE, mas nao consegui aplicar."
      warn "aplique na mao: Ajustes > Papel de Parede > Adicionar Foto"
    fi
  else
    warn "falha ao baixar '$WALLPAPER'. confira o nome na lista do topo deste script,"
    warn "ou veja: https://github.com/omacom/omarchy/tree/quattro/themes/tokyo-night/backgrounds"
  fi
fi

# ---------------------------------------------------------- 12. Dock (opcional)

if [ "$DO_DOCK" -eq 1 ]; then
  info "escondendo o Dock"
  defaults write com.apple.dock autohide -bool true
  defaults write com.apple.dock autohide-delay -float 0
  defaults write com.apple.dock autohide-time-modifier -float 0.15
  defaults write com.apple.dock show-recents -bool false
  killall Dock 2>/dev/null || true
  ok "Dock em autohide"
else
  skip "Dock inalterado (use --dock para esconder)"
fi

# -------------------------------------------------------------------- resumo

cat <<EOF

${GREEN}pronto.${RESET}

Proximos passos:
  1. abra (ou reabra) o Ghostty  -> ele le $XDG/ghostty/config no start
     (se a sua versao ignorar esse caminho, faca:
      ln -sf "$XDG/ghostty/config" ~/Library/Application\\ Support/com.mitchellh.ghostty/config)
  2. abra um shell novo, ou:  source $RC
  3. reinicie o Cursor -> o tema so troca depois que a extensao carrega
  4. accent/highlight so aparecem 100% depois de sair e entrar na conta

Desfazer:
  - backups completos em: $BACKUP_DIR
  - remova a linha "# tokyonight" de $RC
  - defaults delete -g AppleAccentColor; defaults delete -g AppleHighlightColor

Variantes do tema: troque 'night' por 'storm' / 'moon' no nvim, e no Ghostty
o background para #24283b (storm) ou #222436 (moon).
EOF
