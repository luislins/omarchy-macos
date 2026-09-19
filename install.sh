#!/usr/bin/env bash
#
# install.sh -- roda tudo na ordem e instala os utilitarios em ~/.local/bin.
#
#   ./install.sh                # tema + tiling + utilitarios
#   ./install.sh --so-tema      # so as cores, sem tiling
#   ./install.sh --no-backup    # sem guardar copia do que for sobrescrito
#
# As demais flags sao encaminhadas para o script que as entende:
#   --no-install e --no-backup vao para os dois
#   --no-borders vai so para o aerospace.sh
#   o resto (--no-ghostty, --vscode, --dock, --wallpaper X) vai para o tema.sh

set -euo pipefail
cd "$(dirname "$0")"

SO_TEMA=0
TEMA_ARGS=()
AERO_ARGS=()

# Cada script conhece so as suas flags, entao encaminhamos cada uma para quem
# entende. Passar --no-borders para o tema.sh, por exemplo, abortaria tudo.
while [ $# -gt 0 ]; do
  case "$1" in
    --so-tema)    SO_TEMA=1 ;;
    # valem para os dois
    --no-install|--no-backup)
                  TEMA_ARGS+=("$1"); AERO_ARGS+=("$1") ;;
    # so o aerospace.sh conhece
    --no-borders) AERO_ARGS+=("$1") ;;
    # leva valor junto
    --wallpaper)  TEMA_ARGS+=("$1" "${2:-}"); shift ;;
    # o resto e do tema.sh
    *)            TEMA_ARGS+=("$1") ;;
  esac
  shift
done

echo "==> tema"
./scripts/tema.sh ${TEMA_ARGS[@]+"${TEMA_ARGS[@]}"}

if [ "$SO_TEMA" -eq 0 ]; then
  echo
  echo "==> tiling"
  ./scripts/aerospace.sh ${AERO_ARGS[@]+"${AERO_ARGS[@]}"}
fi

echo
echo "==> utilitarios em ~/.local/bin"
mkdir -p "$HOME/.local/bin"
cp bin/aerokeys bin/aeroassign "$HOME/.local/bin/"
chmod +x "$HOME/.local/bin/aerokeys" "$HOME/.local/bin/aeroassign"
echo "    aerokeys, aeroassign"

case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) echo "    !! ~/.local/bin nao esta no PATH; adicione no seu ~/.zshrc" ;;
esac

echo
echo "pronto. abra um terminal novo."
