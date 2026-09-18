#!/usr/bin/env bash
#
# acelera-zshrc.sh
#
# Troca o carregamento ansioso do nvm por lazy-load, e tira o 'rbenv rehash'
# da abertura do shell. Nada aqui tem a ver com tema -- e so performance.
#
# Faz backup antes, casa por TEXTO (nao por numero de linha) e mostra o
# diff do que mudou. Se algum trecho nao bater exatamente, ele nao mexe.
#
# Uso:
#   chmod +x acelera-zshrc.sh
#   ./acelera-zshrc.sh              # aplica
#   ./acelera-zshrc.sh --dry-run    # so mostra o que faria

set -euo pipefail

DRY=0
[ "${1:-}" = "--dry-run" ] && DRY=1

ZSHRC="$HOME/.zshrc"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$HOME/.zshrc.bak-$STAMP"

GREEN=$'\033[38;5;150m'; YELLOW=$'\033[38;5;179m'; RED=$'\033[38;5;204m'
BLUE=$'\033[38;5;111m'; RESET=$'\033[0m'

[ -f "$ZSHRC" ] || { printf '%serro%s ~/.zshrc nao encontrado\n' "$RED" "$RESET"; exit 1; }

# O rbenv mudou a sintaxe entre versoes; so usamos --no-rehash se existir mesmo.
RBENV_NO_REHASH=0
if command -v rbenv >/dev/null 2>&1; then
  if rbenv init --help 2>&1 | grep -q -- '--no-rehash'; then
    RBENV_NO_REHASH=1
  else
    printf '%s  !!%s este rbenv nao aceita --no-rehash; vou pular essa parte\n' "$YELLOW" "$RESET"
  fi
fi

TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT
cp "$ZSHRC" "$TMP"

python3 - "$TMP" "$RBENV_NO_REHASH" <<'PY'
import sys

caminho, usar_no_rehash = sys.argv[1], sys.argv[2] == "1"
texto = original = open(caminho).read()
feitos, pulados = [], []

# ---- 1. nvm: carregamento ansioso -> lazy ----------------------------------
nvm_antigo = (
    '[ -s "$NVM_DIR/nvm.sh" ] && \\. "$NVM_DIR/nvm.sh"  # This loads nvm\n'
    '[ -s "$NVM_DIR/bash_completion" ] && \\. "$NVM_DIR/bash_completion"'
    '  # This loads nvm bash_completion\n'
)

nvm_novo = '''# node/npm/npx direto no PATH: disponiveis na hora, custo zero na abertura.
# Se trocar o default com 'nvm alias default', atualize a versao abaixo.
export PATH="$NVM_DIR/versions/node/v18.20.2/bin:$PATH"

# O nvm em si so e carregado quando voce chamar 'nvm' pela primeira vez.
nvm() {
  unset -f nvm
  [ -s "$NVM_DIR/nvm.sh" ] && \\. "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && \\. "$NVM_DIR/bash_completion"
  nvm "$@"
}
'''

if nvm_antigo in texto:
    texto = texto.replace(nvm_antigo, nvm_novo, 1)
    feitos.append("nvm -> lazy-load")
elif "unset -f nvm" in texto:
    pulados.append("nvm: lazy-load ja aplicado")
else:
    pulados.append("nvm: bloco nao bateu exatamente; NAO alterei")

# ---- 2. rbenv: tirar o rehash da abertura ----------------------------------
rbenv_antigo = 'eval "$(rbenv init - zsh)"'
rbenv_novo = 'eval "$(rbenv init - --no-rehash zsh)"'

if not usar_no_rehash:
    pulados.append("rbenv: --no-rehash indisponivel nesta versao")
elif rbenv_antigo in texto:
    texto = texto.replace(rbenv_antigo, rbenv_novo, 1)
    feitos.append("rbenv -> --no-rehash")
elif rbenv_novo in texto:
    pulados.append("rbenv: --no-rehash ja aplicado")
else:
    pulados.append("rbenv: linha nao bateu exatamente; NAO alterei")

if texto != original:
    open(caminho, "w").write(texto)

print("APLICADOS:" + ("".join("\n  + " + f for f in feitos) if feitos else " nenhum"))
if pulados:
    print("PULADOS:" + "".join("\n  - " + p for p in pulados))
print("MUDOU" if texto != original else "SEM_MUDANCA")
PY

if ! diff -q "$ZSHRC" "$TMP" >/dev/null 2>&1; then
  printf '\n%s--- o que muda ---%s\n' "$BLUE" "$RESET"
  diff -u "$ZSHRC" "$TMP" | sed -n '3,$p' || true

  if [ "$DRY" -eq 1 ]; then
    printf '\n%s--dry-run: nada foi gravado.%s\n' "$YELLOW" "$RESET"
    exit 0
  fi

  cp "$ZSHRC" "$BACKUP"
  cp "$TMP" "$ZSHRC"
  printf '\n%sgravado.%s backup em: %s\n' "$GREEN" "$RESET" "$BACKUP"
  printf '\nAgora meca num shell novo:\n  time zsh -i -c exit\n'
  printf '\nSe algo quebrar:\n  cp %s ~/.zshrc\n' "$BACKUP"
else
  printf '\n%snada a mudar.%s\n' "$YELLOW" "$RESET"
fi
