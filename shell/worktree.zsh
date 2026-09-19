# ga / gd -- git worktrees, portados do capitulo 20 do manual do Omarchy.
#
# Worktree = varias branches abertas ao mesmo tempo, em pastas diferentes,
# compartilhando o mesmo .git. Sem stash, sem trocar de branch, sem rebuild.
#
#   ga DOLLA-1234     cria o worktree e entra nele
#   ga                lista os worktrees existentes
#   gd                remove o worktree atual e a branch (pergunta antes)
#
# Precisam ser FUNCOES, nao scripts, porque fazem 'cd' no seu shell.
# Instale com:
#   . ~/.config/omarchy/worktree.zsh     # no ~/.zshrc

# Raiz do repositorio principal, mesmo se voce ja estiver dentro de um worktree.
_wt_main_root() {
  local comum
  comum="$(git rev-parse --git-common-dir 2>/dev/null)" || return 1
  # caminho relativo -> absoluto
  case "$comum" in
    /*) ;;
    *) comum="$(cd "$(dirname "$comum")" && pwd)/$(basename "$comum")" ;;
  esac
  dirname "$comum"
}

# Branch padrao do remoto (main, master, o que for), com fallbacks.
_wt_default_branch() {
  local ref
  ref="$(git symbolic-ref --quiet refs/remotes/origin/HEAD 2>/dev/null)"
  if [ -n "$ref" ]; then
    echo "${ref#refs/remotes/origin/}"
    return 0
  fi
  for b in main master; do
    git show-ref --verify --quiet "refs/remotes/origin/$b" && { echo "$b"; return 0; }
  done
  git rev-parse --abbrev-ref HEAD 2>/dev/null
}

ga() {
  local branch="$1"
  local raiz nome pai destino padrao

  raiz="$(_wt_main_root)" || { echo "ga: voce nao esta num repositorio git" >&2; return 1; }

  if [ -z "$branch" ]; then
    echo "worktrees deste repositorio:"
    git worktree list
    echo
    echo "uso: ga <branch>"
    return 0
  fi

  nome="$(basename "$raiz")"
  pai="$(dirname "$raiz")"
  # branches com barra (feature/x) viram feature-x no nome da pasta
  destino="$pai/${nome}-${branch//\//-}"

  if [ -e "$destino" ]; then
    echo "ga: $destino ja existe" >&2
    return 1
  fi

  if git -C "$raiz" show-ref --verify --quiet "refs/heads/$branch"; then
    # branch ja existe localmente
    git -C "$raiz" worktree add "$destino" "$branch" || return 1
  elif git -C "$raiz" show-ref --verify --quiet "refs/remotes/origin/$branch"; then
    # existe no remoto: cria local rastreando
    git -C "$raiz" worktree add --track -b "$branch" "$destino" "origin/$branch" || return 1
  else
    # branch nova, a partir da padrao do remoto
    padrao="$(cd "$raiz" && _wt_default_branch)"
    echo "ga: branch nova '$branch' a partir de origin/$padrao"
    git -C "$raiz" worktree add -b "$branch" "$destino" "origin/$padrao" 2>/dev/null \
      || git -C "$raiz" worktree add -b "$branch" "$destino" "$padrao" || return 1
  fi

  cd "$destino" || return 1
  echo "-> $destino"
}

gd() {
  local raiz atual branch resposta forcar=""

  raiz="$(_wt_main_root)" || { echo "gd: voce nao esta num repositorio git" >&2; return 1; }
  atual="$(git rev-parse --show-toplevel 2>/dev/null)" || return 1

  if [ "$atual" = "$raiz" ]; then
    echo "gd: voce esta no repositorio principal, nao num worktree." >&2
    echo "    entre num worktree primeiro (veja 'ga' sem argumentos)." >&2
    return 1
  fi

  branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"

  echo "worktree: $atual"
  echo "branch:   $branch"

  if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
    echo
    echo "ATENCAO: ha alteracoes nao commitadas aqui:"
    git status --short | head -10
    forcar="--force"
  fi

  echo
  printf "remover o worktree e a branch? [s/N] "
  read -r resposta
  case "$resposta" in
    s|S|y|Y) ;;
    *) echo "cancelado."; return 1 ;;
  esac

  cd "$raiz" || return 1

  git worktree remove $forcar "$atual" || {
    echo "gd: nao consegui remover o worktree" >&2
    return 1
  }

  # -d so apaga se estiver mesclada; se recusar, pergunta de novo antes do -D
  if ! git branch -d "$branch" 2>/dev/null; then
    echo
    echo "a branch '$branch' tem commits que nao estao na base."
    printf "apagar mesmo assim? [s/N] "
    read -r resposta
    case "$resposta" in
      s|S|y|Y) git branch -D "$branch" ;;
      *) echo "worktree removido; a branch '$branch' foi mantida." ;;
    esac
  fi

  echo "-> $raiz"
}
