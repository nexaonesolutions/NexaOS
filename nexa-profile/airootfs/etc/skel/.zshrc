# ==============================================================================
#  NEXA OS - ZSH CONFIGURATION FINAL (.zshrc)
#  Módulo Work: Backend Engineering + DevOps + Automação
#  Injetado em: airootfs/etc/skel/.zshrc
# ==============================================================================

export ZSH="$HOME/.oh-my-zsh"

# Tema Premium para Terminal de Engenheiro
ZSH_THEME="agnoster"

# Plugins Offline (todos clonados via build.sh)
plugins=(
    git
    docker
    docker-compose
    sudo
    extract
    zsh-autosuggestions
    zsh-syntax-highlighting
)

source "$ZSH/oh-my-zsh.sh"

# ==============================================================================
# VARIÁVEIS DE AMBIENTE — NEXA SOLUTIONS BACKEND
# ==============================================================================
export EDITOR='nvim'
export VISUAL='nvim'
export TERMINAL='kitty'
export BROWSER='firefox'

# Java 17 (Spring Boot / Maven)
export JAVA_HOME='/usr/lib/jvm/java-17-openjdk'
export PATH="$JAVA_HOME/bin:$PATH"

# Python — sem geração de bytecode desnecessário
export PYTHONDONTWRITEBYTECODE=1
export PYTHONUNBUFFERED=1

# NVM (Node Version Manager)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"

# Cores no terminal
autoload -U colors && colors
export CLICOLOR=1
export LSCOLORS=GxFxCxDxBxegedabagaced

# ==============================================================================
# ALIASES — GESTÃO DE SISTEMA (Arch Linux / Pacman)
# ==============================================================================
alias update="sudo pacman -Syu --noconfirm"
alias clean="sudo pacman -Sc --noconfirm"
alias install="sudo pacman -S --noconfirm"
alias remove="sudo pacman -Rns"
alias search="pacman -Ss"
alias orphans="sudo pacman -Rns \$(pacman -Qtdq 2>/dev/null) 2>/dev/null || echo 'Sem orfãos.'"

# Navegação rápida
alias ..="cd .."
alias ...="cd ../.."
alias ll="ls -lah --color=auto"
alias la="ls -A --color=auto"
alias cl="clear"
alias mkcd='f(){ mkdir -p "$1" && cd "$1"; }; f'

# ==============================================================================
# ALIASES — DOCKER & CONTAINERS (Nexa DevOps Standard)
# ==============================================================================
alias dup="docker compose up -d"
alias ddown="docker compose down"
alias dlogs="docker compose logs -f"
alias dbuild="docker compose up -d --build"
alias drestart="docker compose down && docker compose up -d"
alias dps="docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'"
alias dpa="docker ps -a --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}'"
alias dimages="docker images --format 'table {{.Repository}}\t{{.Tag}}\t{{.Size}}'"
alias dclean="docker system prune -a --volumes -f"
alias dstop-all="docker stop \$(docker ps -q) 2>/dev/null && echo '✔ Todos os containers parados.'"
alias drm-all="docker rm \$(docker ps -aq) 2>/dev/null && echo '✔ Containers removidos.'"
alias dexec="docker exec -it"
alias dlogs-tail="docker logs -f --tail=100"

# Função: Entrar em shell de container por nome parcial
dsh() {
    local ctr
    ctr=$(docker ps --format '{{.Names}}' | grep "$1" | head -1)
    [ -z "$ctr" ] && echo "❌ Container não encontrado: $1" && return 1
    docker exec -it "$ctr" /bin/bash 2>/dev/null || docker exec -it "$ctr" /bin/sh
}

# ==============================================================================
# ALIASES — BACKEND & AUTOMAÇÃO (Java / Spring Boot / Python)
# ==============================================================================

# Maven / Spring Boot
alias mvn-run="./mvnw spring-boot:run"
alias mvn-build="./mvnw clean package -DskipTests"
alias mvn-test="./mvnw test"
alias mvn-clean="./mvnw clean"
alias mvn-install="./mvnw clean install -DskipTests"

# Python / FastAPI / Django
alias py-env="source venv/bin/activate"
alias py-venv="python3 -m venv venv && source venv/bin/activate && pip install --upgrade pip"
alias py-run="python3 -m uvicorn main:app --reload --host 0.0.0.0 --port 8000"
alias py-test="python3 -m pytest -v"
alias py="python3"
alias pip-up="pip list --outdated | awk 'NR>2{print \$1}' | xargs pip install --upgrade"

# Node / NPM
alias ni="npm install"
alias nr="npm run"
alias nrd="npm run dev"
alias nrb="npm run build"
alias nrt="npm run test"

# ==============================================================================
# ALIASES — GIT WORKFLOW
# ==============================================================================
alias gst="git status -sb"
alias gco="git checkout"
alias gcb="git checkout -b"
alias gcm="git commit -m"
alias gca="git commit --amend --no-edit"
alias gp="git push"
alias gpf="git push --force-with-lease"
alias gl="git log --oneline --graph --decorate -n 15"
alias gd="git diff"
alias gds="git diff --staged"
alias gfp="git fetch --prune && git pull"
alias grb="git rebase"
alias gsta="git stash"
alias gstp="git stash pop"

# Função: Trocar de branch com auto-stash
gsw() {
    git stash push -m "auto-stash: $(date '+%H:%M %d/%m')"
    git checkout "$1"
    git stash pop
}

# ==============================================================================
# ALIASES — NEXA IA AGENT (localhost:8000)
# ==============================================================================
alias nexa-status="curl -s http://127.0.0.1:8000/status | python3 -m json.tool"
alias nexa-games="curl -s http://127.0.0.1:8000/api/games | python3 -m json.tool"
alias nexa-tel="watch -n 2 'curl -s http://127.0.0.1:8000/api/telemetry | python3 -m json.tool'"
alias nexa-restart="sudo systemctl restart nexa-ia"
alias nexa-log="sudo journalctl -fu nexa-ia"

# Modo Jogo (abre Game Mode via navegador)
alias gamemode-on="xdg-open http://127.0.0.1:8000/game-mode"
alias gamemode-status="gamemoded -s"

# ==============================================================================
# ALIASES — UTILITÁRIOS DE REDE E SISTEMA
# ==============================================================================
alias ports="ss -tulpn"
alias myip="curl -s ifconfig.me && echo ''"
alias diskuse="df -h | grep -v tmpfs"
alias memuse="free -h"
alias free-ram="sync && echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null && echo '✔ Cache RAM limpo.'"
alias topcpu="ps aux --sort=-%cpu | head -10"
alias topmem="ps aux --sort=-%mem | head -10"

# ==============================================================================
# APRESENTAÇÃO INICIAL DO TERMINAL (Nexa OS Brand)
# ==============================================================================
if [[ $- == *i* ]]; then
    fastfetch
fi
