#!/usr/bin/env bash
#
# omarchy-aerospace-macos.sh
#
# Tiling de janelas no macOS no estilo Omarchy (Hyprland), usando AeroSpace.
# Complementa o omarchy-tokyonight-macos.sh, que cuida so das cores.
#
# O que instala:
#   - AeroSpace  -> tiling window manager estilo i3. NAO exige desativar o SIP.
#   - JankyBorders (opcional) -> borda colorida na janela focada, em Tokyo Night.
#     O AeroSpace nao desenha bordas; quem faz isso e este segundo programa.
#     Requer macOS 14+.
#
# Uso:
#   chmod +x omarchy-aerospace-macos.sh
#   ./omarchy-aerospace-macos.sh                # instala e configura tudo
#   ./omarchy-aerospace-macos.sh --no-borders   # so o AeroSpace, sem bordas
#   ./omarchy-aerospace-macos.sh --no-install   # so escreve as configs
#   ./omarchy-aerospace-macos.sh --no-backup    # nao guarda copia do que sobrescrever
#
# Backups do que existia antes vao para ~/.omarchy-macos-backup/<timestamp>/
#
# Para desinstalar tudo:
#   brew services stop borders
#   brew uninstall borders
#   brew uninstall --cask aerospace
#   rm ~/.aerospace.toml ~/.config/borders/bordersrc

set -euo pipefail

TS="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$HOME/.omarchy-macos-backup/$TS"
XDG="${XDG_CONFIG_HOME:-$HOME/.config}"

DO_INSTALL=1
DO_BORDERS=1
DO_BACKUP=1

while [ $# -gt 0 ]; do
  case "$1" in
    --no-install) DO_INSTALL=0 ;;
    --no-backup)   DO_BACKUP=0 ;;
    --no-borders) DO_BORDERS=0 ;;
    -h|--help)    sed -n '2,27p' "$0"; exit 0 ;;
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

backup() {
  local target="$1"
  [ "$DO_BACKUP" -eq 1 ] || return 0
  [ -e "$target" ] || return 0
  local rel="${target#"$HOME"/}"
  local dest="$BACKUP_DIR/$rel"
  mkdir -p "$(dirname "$dest")"
  cp -R "$target" "$dest"
}

write_file() {
  local target="$1"
  backup "$target"
  mkdir -p "$(dirname "$target")"
  cat > "$target"
}

# ----------------------------------------------------------------- pre-flight

[ "$(uname -s)" = "Darwin" ] || die "este script e so para macOS."

MACOS_MAJOR="$(sw_vers -productVersion | cut -d. -f1)"
[ "$MACOS_MAJOR" -ge 13 ] || die "o AeroSpace exige macOS 13 ou mais novo (voce tem $(sw_vers -productVersion))."

if [ "$DO_BORDERS" -eq 1 ] && [ "$MACOS_MAJOR" -lt 14 ]; then
  warn "JankyBorders exige macOS 14+; voce tem $(sw_vers -productVersion). Pulando as bordas."
  DO_BORDERS=0
fi

if ! has brew && [ "$DO_INSTALL" -eq 1 ]; then
  die "Homebrew nao encontrado. Instale em https://brew.sh ou rode com --no-install."
fi

if [ "$DO_BACKUP" -eq 1 ]; then
  mkdir -p "$BACKUP_DIR"
  info "backup desta execucao: $BACKUP_DIR"
  TXT_BACKUP="backups completos em: $BACKUP_DIR"
else
  warn "--no-backup: o que for sobrescrito NAO sera salvo em lugar nenhum"
  TXT_BACKUP="rodou com --no-backup: nada foi salvo"
fi

# ------------------------------------------------------------- 1. instalacao

if [ "$DO_INSTALL" -eq 1 ]; then
  if has aerospace || [ -d "/Applications/AeroSpace.app" ]; then
    skip "AeroSpace ja instalado"
  else
    info "instalando AeroSpace"
    brew install --cask nikitabobko/tap/aerospace
    ok "AeroSpace"
  fi

  if [ "$DO_BORDERS" -eq 1 ]; then
    if has borders; then
      skip "JankyBorders ja instalado"
    else
      info "instalando JankyBorders"
      brew tap FelixKratz/formulae
      brew install borders
      ok "JankyBorders"
    fi
  fi
else
  skip "--no-install: pulando instalacao"
fi

# --------------------------------------------------------- 2. ~/.aerospace.toml

info "escrevendo ~/.aerospace.toml"

write_file "$HOME/.aerospace.toml" <<'EOF'
# AeroSpace no estilo Omarchy (Hyprland)
# Referencia: https://github.com/nikitabobko/AeroSpace
#
# NOTA SOBRE O MODIFICADOR
# ------------------------
# O Omarchy usa Super (a tecla Windows) para tudo. No Mac, o equivalente seria
# Cmd -- mas Cmd ja esta tomado pelo sistema: Cmd+1..9 troca abas no navegador,
# Cmd+W fecha aba, Cmd+F abre busca. Usar Cmd aqui quebraria esses atalhos em
# todos os aplicativos.
#
# Por isso usamos Alt (Option), que e o padrao do AeroSpace e nao conflita.
# Mentalmente: onde o Omarchy diz "Super", aqui leia "Alt".

config-version = 2

start-at-login = true
auto-reload-config = true

# Normalizacoes da arvore de janelas (padrao do AeroSpace)
enable-normalization-flatten-containers = true
enable-normalization-opposite-orientation-for-nested-containers = true

accordion-padding = 30
default-root-container-layout = 'tiles'
default-root-container-orientation = 'auto'

# O mouse acompanha o monitor focado
on-focused-monitor-changed = ['move-mouse monitor-lazy-center']

automatically-unhide-macos-hidden-apps = false
key-mapping.preset = 'qwerty'
focus-follows-mouse.enabled = false

# --- gaps: o respiro entre janelas que da a cara do Omarchy ------------------
gaps.inner.horizontal = 8
gaps.inner.vertical   = 8
gaps.outer.left       = 8
gaps.outer.bottom     = 8
gaps.outer.top        = 8
gaps.outer.right      = 8

# --- apps que funcionam melhor flutuando -------------------------------------
# O AeroSpace ja flutua dialogos automaticamente por heuristica, entao esta
# lista e curta de proposito: so o que a heuristica costuma errar.
# Para descobrir o ID de um app: aerospace list-apps
on-window-detected = [
    { if = 'test %{app-bundle-id} = com.apple.systempreferences', run = 'layout floating' },
    { if = 'test %{app-bundle-id} = com.apple.ActivityMonitor',   run = 'layout floating' },
    { if = 'test %{app-bundle-id} = com.apple.calculator',        run = 'layout floating' },
    { if = 'test %{app-bundle-id} = com.apple.AppStore',          run = 'layout floating' },
    { if = 'test %{app-bundle-id} = com.apple.finder',            run = 'layout floating' },
]

[mode.main.binding]

    # --- abrir terminal ------------------------------------------------------
    # Omarchy: Super + Return
    alt-enter = 'exec-and-forget open -na Ghostty'

    # --- foco ----------------------------------------------------------------
    # Omarchy: Super + setas. hjkl tambem, no estilo vim/i3.
    alt-left  = 'focus left'
    alt-down  = 'focus down'
    alt-up    = 'focus up'
    alt-right = 'focus right'
    alt-h = 'focus left'
    alt-j = 'focus down'
    alt-k = 'focus up'
    alt-l = 'focus right'

    # --- mover a janela ------------------------------------------------------
    # Omarchy: Super + Shift + setas
    alt-shift-left  = 'move left'
    alt-shift-down  = 'move down'
    alt-shift-up    = 'move up'
    alt-shift-right = 'move right'
    alt-shift-h = 'move left'
    alt-shift-j = 'move down'
    alt-shift-k = 'move up'
    alt-shift-l = 'move right'

    # --- redimensionar -------------------------------------------------------
    # Omarchy: Super + Minus / Equal
    alt-minus = 'resize smart -50'
    alt-equal = 'resize smart +50'

    # --- layout --------------------------------------------------------------
    alt-slash = 'layout tiles horizontal vertical'      # alterna a orientacao
    alt-comma = 'layout accordion horizontal vertical'  # empilha em acordeao
    alt-t     = 'layout floating tiling'                # Omarchy: Super + T
    alt-f     = 'fullscreen'                            # Omarchy: Super + F

    # --- fechar janela -------------------------------------------------------
    # Omarchy: Super + W
    alt-w = 'close'

    # --- workspaces ----------------------------------------------------------
    # Omarchy: Super + 1/2/3/4
    alt-1 = 'workspace 1'
    alt-2 = 'workspace 2'
    alt-3 = 'workspace 3'
    alt-4 = 'workspace 4'
    alt-5 = 'workspace 5'
    alt-6 = 'workspace 6'
    alt-7 = 'workspace 7'
    alt-8 = 'workspace 8'
    alt-9 = 'workspace 9'

    # Omarchy: Super + Shift + 1/2/3/4 (leva a janela junto)
    alt-shift-1 = 'move-node-to-workspace 1'
    alt-shift-2 = 'move-node-to-workspace 2'
    alt-shift-3 = 'move-node-to-workspace 3'
    alt-shift-4 = 'move-node-to-workspace 4'
    alt-shift-5 = 'move-node-to-workspace 5'
    alt-shift-6 = 'move-node-to-workspace 6'
    alt-shift-7 = 'move-node-to-workspace 7'
    alt-shift-8 = 'move-node-to-workspace 8'
    alt-shift-9 = 'move-node-to-workspace 9'

    # Omarchy: Super + Ctrl + Tab (volta para o workspace anterior)
    alt-tab       = 'workspace-back-and-forth'
    alt-shift-tab = 'move-workspace-to-monitor --wrap-around next'

    # --- modo service --------------------------------------------------------
    # Alt + Shift + ; entra num modo onde teclas soltas viram comandos.
    alt-shift-semicolon = 'mode service'

[mode.service.binding]
    esc       = ['reload-config', 'mode main']
    r         = ['flatten-workspace-tree', 'mode main']   # reseta o layout
    f         = ['layout floating tiling', 'mode main']
    backspace = ['close-all-windows-but-current', 'mode main']

    alt-shift-h = ['join-with left', 'mode main']
    alt-shift-j = ['join-with down', 'mode main']
    alt-shift-k = ['join-with up', 'mode main']
    alt-shift-l = ['join-with right', 'mode main']
EOF
ok "~/.aerospace.toml"

# ------------------------------------------------------------- 3. bordas

if [ "$DO_BORDERS" -eq 1 ]; then
  info "configurando JankyBorders (Tokyo Night)"
  write_file "$XDG/borders/bordersrc" <<'EOF'
#!/bin/bash
# Borda da janela focada, em Tokyo Night.
# Formato da cor: 0xAARRGGBB (o 0xff da frente e a opacidade).
#   #7aa2f7 = azul Tokyo Night (janela focada)
#   #414868 = cinza-azulado    (janelas em segundo plano)
options=(
	style=round
	width=6.0
	hidpi=off
	active_color=0xff7aa2f7
	inactive_color=0xff414868
)
borders "${options[@]}"
EOF
  chmod +x "$XDG/borders/bordersrc"
  ok "$XDG/borders/bordersrc"

  if has brew; then
    brew services restart borders >/dev/null 2>&1 \
      && ok "servico borders iniciado" \
      || warn "nao consegui iniciar o servico; rode: brew services start borders"
  fi
else
  skip "bordas desativadas"
fi

# ------------------------------------------------------------- 4. subir o WM

if [ -d "/Applications/AeroSpace.app" ]; then
  info "abrindo o AeroSpace"
  open -a AeroSpace || warn "abra o AeroSpace manualmente pelo Launchpad"
fi

# -------------------------------------------------------------------- resumo

cat <<EOF

${GREEN}pronto.${RESET}

${YELLOW}PASSO OBRIGATORIO:${RESET} o macOS vai pedir permissao de ${YELLOW}Acessibilidade${RESET}
para o AeroSpace. Sem isso ele nao consegue mover as janelas de outros apps.
  Ajustes > Privacidade e Seguranca > Acessibilidade > marque AeroSpace

Onde o Omarchy diz Super, aqui leia ${BLUE}Alt${RESET} (Option):

  Alt + Enter           abrir terminal (Ghostty)
  Alt + setas / hjkl    mover o foco entre janelas
  Alt + Shift + setas   mover a janela
  Alt + 1..9            ir para o workspace
  Alt + Shift + 1..9    levar a janela para o workspace
  Alt + Minus / Equal   diminuir / aumentar a janela
  Alt + F               tela cheia
  Alt + T               alternar entre flutuante e em mosaico
  Alt + W               fechar a janela
  Alt + Tab             voltar ao workspace anterior
  Alt + Shift + ;       modo service (esc recarrega, r reseta o layout)

Ajustes finos:
  - a config recarrega sozinha quando voce salva ~/.aerospace.toml
  - para fazer um app flutuar, pegue o ID com 'aerospace list-apps'
    e acrescente uma linha em on-window-detected
  - gaps: mude os valores de gaps.inner / gaps.outer

Desfazer tudo:
  brew services stop borders && brew uninstall borders
  brew uninstall --cask aerospace
  rm ~/.aerospace.toml $XDG/borders/bordersrc
  ($TXT_BACKUP)
EOF
