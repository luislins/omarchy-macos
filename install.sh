#!/usr/bin/env bash
#
# install.sh -- roda tudo na ordem.
#
#   ./install.sh                # tema completo
#   ./install.sh --no-backup    # sem guardar copia do que for sobrescrito
#
# As flags sao encaminhadas para o tema.sh.

set -euo pipefail
cd "$(dirname "$0")"

TEMA_ARGS=()

while [ $# -gt 0 ]; do
  case "$1" in
    --wallpaper)  TEMA_ARGS+=("$1" "${2:-}"); shift ;;
    *)            TEMA_ARGS+=("$1") ;;
  esac
  shift
done

echo "==> tema"
./scripts/tema.sh ${TEMA_ARGS[@]+"${TEMA_ARGS[@]}"}

echo
echo "pronto. abra um terminal novo."
