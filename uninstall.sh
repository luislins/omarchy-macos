#!/usr/bin/env bash
#
# uninstall.sh -- remove tudo que o omarchy-macos instalou.
#
# Mostra o que vai fazer e pede confirmacao antes de agir.
#
#   ./uninstall.sh          # interativo: pergunta antes de cada etapa
#   ./uninstall.sh --sim    # aceita tudo sem perguntar
#
# Versoes anteriores do projeto instalavam o AeroSpace (tiling window manager)
# e o JankyBorders. Este script tambem remove esses programas, se encontrados.

set -uo pipefail

XDG="${XDG_CONFIG_HOME:-$HOME/.config}"
RC="$HOME/.zshrc"

AUTO=0
[ "${1:-}" = "--sim" ] && AUTO=1

# --------------------------------------------------------------------- helpers

BLUE=$'\033[38;5;111m'; GREEN=$'\033[38;5;150m'; YELLOW=$'\033[38;5;179m'
DIM=$'\033[38;5;103m'; BOLD=$'\033[1m'; RESET=$'\033[0m'

info() { printf '%s==>%s %s\n' "$BLUE" "$RESET" "$*"; }
ok()   { printf '%s  ok%s %s\n' "$GREEN" "$RESET" "$*"; }
skip() { printf '%s  --%s %s\n' "$DIM" "$RESET" "$*"; }
warn() { printf '%s  !!%s %s\n' "$YELLOW" "$RESET" "$*"; }

has() { command -v "$1" >/dev/null 2>&1; }

confirmar() {
  [ "$AUTO" -eq 1 ] && return 0
  printf '\n%s%s%s [s/N] ' "$BOLD" "$1" "$RESET"
  read -r resp
  case "$resp" in
    [sS]|[yY]) return 0 ;;
    *) return 1 ;;
  esac
}

# ----------------------------------------- 1. AeroSpace + JankyBorders (legado)

if has brew && brew list --cask aerospace >/dev/null 2>&1 \
   || [ -d "/Applications/AeroSpace.app" ]; then
  if confirmar "Remover AeroSpace (tiling window manager)?"; then
    killall AeroSpace 2>/dev/null || true
    brew uninstall --cask aerospace 2>/dev/null || true
    rm -f "$HOME/.aerospace.toml"
    ok "AeroSpace removido"
  else
    skip "AeroSpace mantido"
  fi
else
  skip "AeroSpace nao instalado"
fi

if has brew && brew list borders >/dev/null 2>&1; then
  if confirmar "Remover JankyBorders (bordas de janela)?"; then
    brew services stop borders 2>/dev/null || true
    brew uninstall borders 2>/dev/null || true
    rm -f "$XDG/borders/bordersrc"
    rmdir "$XDG/borders" 2>/dev/null || true
    ok "JankyBorders removido"
  else
    skip "JankyBorders mantido"
  fi
else
  skip "JankyBorders nao instalado"
fi

rm -f "$HOME/.local/bin/aerokeys" "$HOME/.local/bin/aeroassign" 2>/dev/null

# --------------------------------------------------- 2. configs de apps (tema)

if confirmar "Remover config do Ghostty ($XDG/ghostty/config)?"; then
  rm -f "$XDG/ghostty/config"
  rmdir "$XDG/ghostty" 2>/dev/null || true
  ok "config do Ghostty removido"
else
  skip "config do Ghostty mantido"
fi

if confirmar "Remover config do starship ($XDG/starship.toml)?"; then
  rm -f "$XDG/starship.toml"
  ok "starship.toml removido"
else
  skip "starship.toml mantido"
fi

if [ -f "$XDG/tokyonight/shell.sh" ]; then
  if confirmar "Remover snippet de cores (fzf, bat)?"; then
    rm -f "$XDG/tokyonight/shell.sh"
    rm -f "$XDG/tokyonight/vscode-settings.json"
    rm -f "$XDG/tokyonight/lazygit-theme.yml"
    rmdir "$XDG/tokyonight" 2>/dev/null || true
    ok "snippet de cores removido"
  else
    skip "snippet de cores mantido"
  fi
else
  skip "snippet de cores nao encontrado"
fi

# --------------------------------------------------- 3. linhas do ~/.zshrc

if [ -f "$RC" ]; then
  LINHAS=""
  grep -n "tokyonight/shell.sh" "$RC" >/dev/null 2>&1 && LINHAS="tokyonight"
  grep -n "starship init" "$RC" >/dev/null 2>&1 && LINHAS="$LINHAS starship"

  if [ -n "$LINHAS" ]; then
    if confirmar "Remover linhas do ~/.zshrc ($LINHAS)?"; then
      cp "$RC" "$RC.bak-uninstall-$(date +%Y%m%d-%H%M%S)"
      sed -i '' '/tokyonight\/shell\.sh/d' "$RC"
      sed -i '' '/starship init/d' "$RC"
      ok "linhas removidas do ~/.zshrc (backup salvo)"
    else
      skip "~/.zshrc inalterado"
    fi
  else
    skip "nenhuma linha do omarchy no ~/.zshrc"
  fi
fi

# -------------------------------------------------- 4. configs de TUIs

if [ -f "$XDG/nvim/lua/plugins/tokyonight.lua" ]; then
  if confirmar "Remover tema Tokyo Night do Neovim?"; then
    rm -f "$XDG/nvim/lua/plugins/tokyonight.lua"
    ok "tokyonight.lua removido"
  else
    skip "neovim mantido"
  fi
fi

if [ -f "$XDG/btop/btop.conf" ]; then
  if confirmar "Resetar tema do btop?"; then
    sed -i '' 's|^color_theme = .*tokyo.*|color_theme = "Default"|i' "$XDG/btop/btop.conf"
    ok "btop resetado para Default"
  else
    skip "btop mantido"
  fi
fi

if [ -f "$XDG/zellij/config.kdl" ]; then
  if confirmar "Remover tema do zellij?"; then
    sed -i '' '/^[[:space:]]*theme[[:space:]].*tokyo/d' "$XDG/zellij/config.kdl"
    ok "tema do zellij removido"
  else
    skip "zellij mantido"
  fi
fi

# ------------------------------------------------- 5. cores do sistema

if confirmar "Resetar accent/highlight color do macOS?"; then
  defaults delete -g AppleAccentColor 2>/dev/null || true
  defaults delete -g AppleHighlightColor 2>/dev/null || true
  ok "cores do sistema resetadas (efeito completo apos logout)"
else
  skip "cores do sistema mantidas"
fi

# ------------------------------------------------- 6. wallpaper

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
if [ -d "$WALLPAPER_DIR" ] && ls "$WALLPAPER_DIR"/*.png "$WALLPAPER_DIR"/*.webp >/dev/null 2>&1; then
  if confirmar "Remover wallpapers baixados ($WALLPAPER_DIR)?"; then
    rm -f "$WALLPAPER_DIR"/*.png "$WALLPAPER_DIR"/*.webp 2>/dev/null
    rmdir "$WALLPAPER_DIR" 2>/dev/null || true
    ok "wallpapers removidos"
  else
    skip "wallpapers mantidos"
  fi
fi

# ------------------------------------------------- 7. backups dos scripts

BK="$HOME/.omarchy-macos-backup"
if [ -d "$BK" ]; then
  tam="$(du -sh "$BK" 2>/dev/null | cut -f1)"
  if confirmar "Apagar backups dos scripts ($tam em $BK)?"; then
    rm -rf "$BK"
    ok "backups removidos"
  else
    skip "backups mantidos"
  fi
fi

# ------------------------------------------------- 8. Dock (se foi escondido)

if defaults read com.apple.dock autohide 2>/dev/null | grep -q 1; then
  if confirmar "Restaurar o Dock (desfazer autohide)?"; then
    defaults delete com.apple.dock autohide 2>/dev/null || true
    defaults delete com.apple.dock autohide-delay 2>/dev/null || true
    defaults delete com.apple.dock autohide-time-modifier 2>/dev/null || true
    defaults delete com.apple.dock show-recents 2>/dev/null || true
    killall Dock 2>/dev/null || true
    ok "Dock restaurado"
  else
    skip "Dock mantido"
  fi
fi

# -------------------------------------------------------------------- resumo

printf '\n%spronto.%s\n' "$GREEN" "$RESET"
printf 'Abra um terminal novo para ver o efeito completo.\n'
printf 'Accent/highlight color so muda 100%% apos sair e entrar na conta.\n'
