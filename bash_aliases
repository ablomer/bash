# enable aliases in sudo
alias sudo='sudo '

# docker aliases
alias dc='docker compose --env-file /srv/containers/.env'
alias dps='docker ps --format "table {{.Image}}\t{{.Status}}\t{{.Names}}"'
alias btop='btop --utf-force'
alias dtop='/srv/containers/dtop.sh'

cdd() {
  # Usage: cdd <container_name>
  cd /srv/containers/"$1"
}

_cdd_completion() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    COMPREPLY=( $(compgen -W "$(ls /srv/containers/)" -- "$cur") )
}

complete -F _cdd_completion cdd

dbash() {
  container_name=$(basename "$PWD")
  docker exec -it "$container_name" bash
}
