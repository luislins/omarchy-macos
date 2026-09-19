#!/usr/bin/env bash
#
# install.sh -- roda tudo na ordem e instala os utilitarios em ~/.local/bin.
#
#   ./install.sh              # tema + tiling + utilitarios
#   ./install.sh --so-tema    # so as cores, sem tiling
#
# Os argumentos extras sao repassados para o script do tema:
#   ./install.sh --so-tema --no-ghostty

set -euo pipefail
cd "$(dirname "$0")"

SO_TEMA=0
ARGS=()
for a in "$@"; do
  case "$a" in
    --so-tema) SO_TEMA=1 ;;
    *) ARGS+=("$a") ;;
  esac
done

echo "==> tema"
./scripts/tema.sh ${ARGS[@]+"${ARGS[@]}"}

if [ "$SO_TEMA" -eq 0 ]; then
  echo
  echo "==> tiling"
  ./scripts/aerospace.sh
fi

echo
echo "==> funcoes de shell (ga/gd)"
mkdir -p "$HOME/.config/omarchy"
cp shell/worktree.zsh "$HOME/.config/omarchy/worktree.zsh"

RC="$HOME/.zshrc"
LINHA='[ -f "$HOME/.config/omarchy/worktree.zsh" ] && . "$HOME/.config/omarchy/worktree.zsh"   # omarchy'
if [ -f "$RC" ] && grep -qF -- "$LINHA" "$RC"; then
  echo "    ja carregado no ~/.zshrc"
else
  printf '\n%s\n' "$LINHA" >> "$RC"
  echo "    linha de carregamento adicionada ao ~/.zshrc"
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
