#!/usr/bin/env bash
#
# doctor.sh -- confere o estado da instalacao e aponta sobras de versoes
# anteriores dos scripts.
#
# SO LE. Nunca apaga nem altera nada. No fim, imprime os comandos de limpeza
# para voce rodar se concordar.
#
#   ./scripts/doctor.sh

set -uo pipefail

XDG="${XDG_CONFIG_HOME:-$HOME/.config}"
RC="$HOME/.zshrc"

if [ -t 1 ]; then
  B=$'\033[1m'; G=$'\033[38;5;150m'; Y=$'\033[38;5;179m'
  D=$'\033[38;5;103m'; BL=$'\033[38;5;111m'; R=$'\033[0m'
else
  B=''; G=''; Y=''; D=''; BL=''; R=''
fi

ALERTAS=0
LIMPEZA=""

ok()    { printf '  %sok%s   %s\n' "$G" "$R" "$*"; }
nota()  { printf '  %s--%s   %s\n' "$D" "$R" "$*"; }
alerta() {
  printf '  %s!!%s   %s\n' "$Y" "$R" "$1"
  ALERTAS=$((ALERTAS + 1))
  [ -n "${2:-}" ] && LIMPEZA="${LIMPEZA}${2}"$'\n'
  return 0
}
titulo() { printf '\n%s%s%s\n' "$B" "$1" "$R"; }

has() { command -v "$1" >/dev/null 2>&1; }

titulo "configuracoes atuais"

# --- Ghostty: valores que mudaram entre as versoes do script ---
GCONF="$XDG/ghostty/config"
if [ -f "$GCONF" ]; then
  fonte="$(grep -E '^font-family' "$GCONF" | head -1 | sed 's/.*= *//')"
  title="$(grep -E '^macos-titlebar-style' "$GCONF" | head -1 | sed 's/.*= *//')"

  case "$fonte" in
    *JetBrainsMono*) ok "ghostty: fonte $fonte" ;;
    *Caskaydia*)     alerta "ghostty: ainda usa $fonte (versao antiga do script)" \
                       "  # corrigir a fonte do Ghostty:
  sed -i '' 's/^font-family = .*/font-family = JetBrainsMono Nerd Font/' $GCONF" ;;
    *)               nota "ghostty: fonte $fonte (personalizada)" ;;
  esac

  case "$title" in
    tabs)   ok "ghostty: titlebar tabs" ;;
    hidden) alerta "ghostty: titlebar 'hidden' (quebra abas nativas e o arraste)" \
              "  # voltar a titlebar utilizavel:
  sed -i '' 's/^macos-titlebar-style = .*/macos-titlebar-style = tabs/' $GCONF" ;;
    *)      nota "ghostty: titlebar $title" ;;
  esac
else
  nota "ghostty: sem config em $GCONF"
fi

# --- zellij: uma unica linha de theme ---
ZCONF="$XDG/zellij/config.kdl"
if [ -f "$ZCONF" ]; then
  n="$(grep -cE '^[[:space:]]*theme[[:space:]]' "$ZCONF")"
  if [ "$n" -eq 1 ]; then
    ok "zellij: $(grep -E '^[[:space:]]*theme[[:space:]]' "$ZCONF" | tr -s ' ')"
  elif [ "$n" -eq 0 ]; then
    nota "zellij: sem linha de theme"
  else
    alerta "zellij: $n linhas de 'theme' no config (a ultima vence)" \
      "  # deixe so uma linha de theme:
  \$EDITOR $ZCONF"
  fi
else
  nota "zellij: sem config"
fi

titulo "~/.zshrc"

if [ -f "$RC" ]; then
  for marca in "tokyonight/shell.sh" "starship init"; do
    n="$(grep -cF "$marca" "$RC")"
    case "$n" in
      0) nota "'$marca' ausente" ;;
      1) ok "'$marca' aparece 1x" ;;
      *) alerta "'$marca' aparece ${n}x (duplicado)" \
           "  # remova as linhas repetidas de '$marca':
  \$EDITOR $RC" ;;
    esac
  done

  if grep -q "omarchy/worktree.zsh" "$RC"; then
    alerta "carrega worktree.zsh, que foi removido do projeto" \
      "  # tirar o resto das funcoes ga/gd:
  sed -i '' '/config\\/omarchy\\/worktree.zsh/d' $RC
  rm -f $XDG/omarchy/worktree.zsh
  rmdir $XDG/omarchy 2>/dev/null"
  else
    ok "sem resquicio das funcoes ga/gd"
  fi
else
  nota "sem ~/.zshrc"
fi

titulo "sobras de execucoes anteriores"

# --- fonte errada da primeira versao ---
if has brew && brew list --cask font-caskaydia-mono-nerd-font >/dev/null 2>&1; then
  alerta "CaskaydiaMono Nerd Font instalada (da versao que errava a fonte)" \
    "  # remover a fonte que nao e usada:
  brew uninstall --cask font-caskaydia-mono-nerd-font"
else
  nota "CaskaydiaMono nao instalada"
fi

# --- arquivo de merge manual do Cursor, criado so quando o merge falha ---
if [ -f "$XDG/tokyonight/vscode-settings.json" ]; then
  alerta "existe vscode-settings.json (o merge no Cursor falhou em algum momento)" \
    "  # se voce ja aplicou o tema no Cursor, pode apagar:
  rm -f $XDG/tokyonight/vscode-settings.json"
else
  nota "sem pendencia de merge do Cursor"
fi

if [ -f "$XDG/tokyonight/lazygit-theme.yml" ]; then
  alerta "existe lazygit-theme.yml para mesclar a mao" \
    "  # se o lazygit ja esta em Tokyo Night, pode apagar:
  rm -f $XDG/tokyonight/lazygit-theme.yml"
else
  nota "sem pendencia de merge do lazygit"
fi

# --- worktree.zsh orfao ---
if [ -f "$XDG/omarchy/worktree.zsh" ] && ! grep -q "omarchy/worktree.zsh" "$RC" 2>/dev/null; then
  alerta "worktree.zsh existe mas nao e carregado (arquivo orfao)" \
    "  rm -f $XDG/omarchy/worktree.zsh && rmdir $XDG/omarchy 2>/dev/null"
fi

titulo "backups acumulados"

BK="$HOME/.omarchy-macos-backup"
if [ -d "$BK" ]; then
  n="$(find "$BK" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')"
  tam="$(du -sh "$BK" 2>/dev/null | cut -f1)"
  [ "$n" -eq 1 ] && palavra="execucao guardada" || palavra="execucoes guardadas"
  alerta "$n $palavra, $tam no total" \
    "  # apagar os backups dos scripts (regeneraveis: e so rodar de novo):
  rm -rf $BK"
else
  nota "nenhum backup dos scripts"
fi

for padrao in "$HOME"/.zshrc.bak-* "$HOME"/.aerospace.toml.bak-*; do
  [ -e "$padrao" ] || continue
  alerta "$(basename "$padrao")" ""
done
if ls "$HOME"/.zshrc.bak-* >/dev/null 2>&1; then
  printf '       %sguarde o .zshrc.bak por uns dias: e o unico que nao da para%s\n' "$D" "$R"
  printf '       %sreconstruir a partir do repositorio (mudanca do nvm)%s\n' "$D" "$R"
fi

titulo "o que esta rodando"

for p in AeroSpace borders; do
  if pgrep -f "$p" >/dev/null 2>&1; then
    ok "$p ativo"
  else
    nota "$p nao esta rodando"
  fi
done

for u in aerokeys aeroassign; do
  if [ -x "$HOME/.local/bin/$u" ]; then ok "$u instalado"; else nota "$u ausente"; fi
done

# ----------------------------------------------------------------- veredito

printf '\n%s' "$B"
if [ "$ALERTAS" -eq 0 ]; then
  printf '%studo limpo.%s\n' "$G" "$R"
else
  printf '%s%s ponto(s) de atencao.%s\n\n' "$Y" "$ALERTAS" "$R"
  printf '%sComandos sugeridos (revise antes de rodar):%s\n' "$BL" "$R"
  printf '%s\n' "$LIMPEZA"
fi
