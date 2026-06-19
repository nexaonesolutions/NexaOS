#!/usr/bin/env bash
# ==============================================================================
#  NEXA OS - FULL BUILD AUTOMATION SCRIPT
#  Deve ser executado em ambiente Arch Linux com privilégios de root.
#
#  FLUXO DE EXECUÇÃO:
#   1. Verificação de dependências (archiso, git, imagemagick)
#   2. Injeção Offline do Oh My Zsh + plugins (git clone sem interatividade)
#   3. Scaffolding de Assets Visuais (logos, splashs)
#   4. Configuração de Links Simbólicos do Systemd no airootfs
#   5. Preparação dos diretórios de bootloader
#   6. Compilação da ISO via mkarchiso
# ==============================================================================

set -euo pipefail

# --- Cores para Output ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

log_info()    { echo -e "${CYAN}[INFO]${RESET} $*"; }
log_ok()      { echo -e "${GREEN}[OK]${RESET}   $*"; }
log_warn()    { echo -e "${YELLOW}[WARN]${RESET} $*"; }
log_error()   { echo -e "${RED}[ERROR]${RESET} $*"; exit 1; }

# --- Caminhos ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILE_DIR="${SCRIPT_DIR}/nexa-profile"
SKEL_DIR="${PROFILE_DIR}/airootfs/etc/skel"
ASSETS_SRC="${SCRIPT_DIR}/nexa-assets"
WORK_DIR="/tmp/nexa-archiso-work"
OUT_DIR="${SCRIPT_DIR}/output"

echo ""
echo -e "${BOLD}${CYAN}============================================================${RESET}"
echo -e "${BOLD}${CYAN}   NEXA OS - Build Automation Pipeline v2.1               ${RESET}"
echo -e "${BOLD}${CYAN}   Powered by Nexa Solutions DevOps                        ${RESET}"
echo -e "${BOLD}${CYAN}============================================================${RESET}"
echo ""

# ==============================================================================
# FASE 1: VERIFICAÇÃO DE DEPENDÊNCIAS
# ==============================================================================
log_info "Fase 1: Verificando dependências do ambiente de build..."

check_dep() {
    if ! command -v "$1" &>/dev/null; then
        log_error "Dependência não encontrada: '$1'. Instale com: pacman -S $2"
    fi
    log_ok "'$1' encontrado."
}

check_dep mkarchiso  archiso
check_dep git        git
# IMv7 usa 'magick' como binário principal; 'convert' é wrapper deprecated
check_dep magick     imagemagick

# ==============================================================================
# FASE 2: INJEÇÃO OFFLINE DO OH MY ZSH (CI/CD Safe — Zero Touch)
# ==============================================================================
log_info "Fase 2: Injetando Oh My Zsh + plugins offline via git clone..."

OMZ_TARGET="${SKEL_DIR}/.oh-my-zsh"
OMZ_PLUGINS_DIR="${OMZ_TARGET}/custom/plugins"

# 2a. Clonar o repositório principal do Oh My Zsh (sem interatividade, sem hooks)
if [ -d "${OMZ_TARGET}" ]; then
    log_warn "Oh My Zsh já presente em ${OMZ_TARGET}. Atualizando via git pull..."
    git -C "${OMZ_TARGET}" pull --quiet
else
    log_info "Clonando Oh My Zsh para ${OMZ_TARGET}..."
    git clone --depth=1 --quiet \
        "https://github.com/ohmyzsh/ohmyzsh.git" \
        "${OMZ_TARGET}"
    log_ok "Oh My Zsh clonado com sucesso."
fi

# 2b. Garantir que o diretório de plugins customizados existe
mkdir -p "${OMZ_PLUGINS_DIR}"

# 2c. Clonar zsh-autosuggestions
ZSH_AUTOSUGGEST="${OMZ_PLUGINS_DIR}/zsh-autosuggestions"
if [ -d "${ZSH_AUTOSUGGEST}" ]; then
    log_warn "zsh-autosuggestions já presente. Atualizando..."
    git -C "${ZSH_AUTOSUGGEST}" pull --quiet
else
    log_info "Clonando zsh-autosuggestions..."
    git clone --depth=1 --quiet \
        "https://github.com/zsh-users/zsh-autosuggestions.git" \
        "${ZSH_AUTOSUGGEST}"
    log_ok "zsh-autosuggestions clonado."
fi

# 2d. Clonar zsh-syntax-highlighting
ZSH_SYNTAX="${OMZ_PLUGINS_DIR}/zsh-syntax-highlighting"
if [ -d "${ZSH_SYNTAX}" ]; then
    log_warn "zsh-syntax-highlighting já presente. Atualizando..."
    git -C "${ZSH_SYNTAX}" pull --quiet
else
    log_info "Clonando zsh-syntax-highlighting..."
    git clone --depth=1 --quiet \
        "https://github.com/zsh-users/zsh-syntax-highlighting.git" \
        "${ZSH_SYNTAX}"
    log_ok "zsh-syntax-highlighting clonado."
fi

# 2e. Ajustar permissões para evitar erros de segurança do ZSH (compaudit)
find "${OMZ_TARGET}" -type d -exec chmod 755 {} \;
find "${OMZ_TARGET}" -type f -exec chmod 644 {} \;
log_ok "Permissões do Oh My Zsh corrigidas."

# ==============================================================================
# FASE 3: SCAFFOLDING DE ASSETS VISUAIS (Branding & Logo)
# ==============================================================================
log_info "Fase 3: Scaffolding de assets visuais do Nexa OS..."

# Caminhos de destino no airootfs
SDDM_LOGO="${PROFILE_DIR}/airootfs/usr/share/sddm/themes/nexa-sddm/logo.png"
GRUB_LOGO="${PROFILE_DIR}/airootfs/usr/share/grub/themes/nexa/logo.png"
GRUB_BACKGROUND="${PROFILE_DIR}/airootfs/usr/share/grub/themes/nexa/background.png"
CALAMARES_LOGO="${PROFILE_DIR}/airootfs/etc/calamares/branding/nexa/logo.png"
CALAMARES_WELCOME="${PROFILE_DIR}/airootfs/etc/calamares/branding/nexa/welcome.png"

# Criar diretório de assets externos (fonte de verdade das imagens finais)
mkdir -p "${ASSETS_SRC}"

# Função: Verificar se a logo real existe em nexa-assets/ e usar; caso contrário, gerar placeholder
deploy_asset() {
    local src_name="$1"
    local dst_path="$2"
    local placeholder_cmd="$3"
    local src_file="${ASSETS_SRC}/${src_name}"

    mkdir -p "$(dirname "${dst_path}")"

    if [ -f "${src_file}" ]; then
        log_ok "Asset real encontrado: ${src_name} → copiando para destino."
        cp "${src_file}" "${dst_path}"
    else
        log_warn "Asset '${src_name}' não encontrado em nexa-assets/. Gerando placeholder via ImageMagick..."
        eval "${placeholder_cmd}"
        log_ok "Placeholder gerado: ${dst_path}"
    fi
}

# Comando base de placeholder usando 'magick' (IMv7 API — sem deprecation warnings)
NEXA_BLUE="#0088ff"
LOGO_SRC_NAME="LogoNexaOS.png"

PLACEHOLDER_LOGO="magick -size 800x400 xc:'${NEXA_BLUE}' \
    -gravity Center \
    -font 'DejaVu-Sans-Bold' \
    -pointsize 72 \
    -fill white \
    -annotate 0 'NEXA OS' \
    -quality 100 \
    '${SDDM_LOGO}'"

PLACEHOLDER_BG="magick -size 1920x1080 xc:'#020408' \
    -gravity Center \
    -font 'DejaVu-Sans' \
    -pointsize 36 \
    -fill '${NEXA_BLUE}' \
    -annotate 0 'NEXA OS - Booting Kernel Zen' \
    -quality 100 \
    '${GRUB_BACKGROUND}'"

PLACEHOLDER_WELCOME="magick -size 1200x800 xc:'#030814' \
    -gravity Center \
    -font 'DejaVu-Sans-Bold' \
    -pointsize 60 \
    -fill white \
    -annotate 0 'Bem-vindo ao Nexa OS' \
    -quality 100 \
    '${CALAMARES_WELCOME}'"

# Deploy de cada asset (real ou placeholder)
deploy_asset "${LOGO_SRC_NAME}"  "${SDDM_LOGO}"       "${PLACEHOLDER_LOGO}"
deploy_asset "${LOGO_SRC_NAME}"  "${CALAMARES_LOGO}"   "cp '${SDDM_LOGO}' '${CALAMARES_LOGO}'"
deploy_asset "${LOGO_SRC_NAME}"  "${GRUB_LOGO}"        "cp '${SDDM_LOGO}' '${GRUB_LOGO}'"
deploy_asset "background.png"    "${GRUB_BACKGROUND}"  "${PLACEHOLDER_BG}"
deploy_asset "welcome.png"       "${CALAMARES_WELCOME}" "${PLACEHOLDER_WELCOME}"

log_ok "Todos os assets de branding estão prontos."

# ==============================================================================
# FASE 4: CONFIGURAÇÃO DOS LINKS SIMBÓLICOS DO SYSTEMD
# ==============================================================================
log_info "Fase 4: Configurando serviços Systemd no airootfs..."

WANTS_DIR="${PROFILE_DIR}/airootfs/etc/systemd/system/multi-user.target.wants"
SYSTEMD_DIR="${PROFILE_DIR}/airootfs/etc/systemd/system"
mkdir -p "${WANTS_DIR}"
mkdir -p "${SYSTEMD_DIR}"

# Função para criar symlinks de forma idempotente
link_service() {
    local src="$1"
    local dst="$2"
    ln -sf "${src}" "${dst}"
    log_ok "Serviço habilitado: $(basename "${dst}")"
}

link_service "/usr/lib/systemd/system/NetworkManager.service" \
    "${WANTS_DIR}/NetworkManager.service"

link_service "/usr/lib/systemd/system/sddm.service" \
    "${SYSTEMD_DIR}/display-manager.service"

link_service "/usr/lib/systemd/system/docker.service" \
    "${WANTS_DIR}/docker.service"

# nexa-ia.service aponta para o arquivo dentro do airootfs (caminho correto no sistema instalado)
link_service "/usr/lib/systemd/system/nexa-ia.service" \
    "${WANTS_DIR}/nexa-ia.service"

# ==============================================================================
# FASE 5: PREPARAÇÃO DOS DIRETÓRIOS DE BOOTLOADER
# ==============================================================================
log_info "Fase 5: Preparando diretórios de bootloader (syslinux e efiboot)..."

# Copiar configurações oficiais do archiso releng como base
# Isso satisfaz a validação do mkarchiso para os bootmodes bios.syslinux e uefi-x64.systemd-boot
RELENG_SRC="/usr/share/archiso/configs/releng"

if [ -d "${RELENG_SRC}/syslinux" ]; then
    mkdir -p "${PROFILE_DIR}/syslinux"
    cp -r "${RELENG_SRC}/syslinux/." "${PROFILE_DIR}/syslinux/"
    log_ok "Configurações syslinux copiadas do releng."
else
    log_warn "Diretório syslinux do releng não encontrado. Criando estrutura mínima..."
    mkdir -p "${PROFILE_DIR}/syslinux"
fi

if [ -d "${RELENG_SRC}/efiboot" ]; then
    mkdir -p "${PROFILE_DIR}/efiboot"
    cp -r "${RELENG_SRC}/efiboot/." "${PROFILE_DIR}/efiboot/"
    log_ok "Configurações efiboot copiadas do releng."
else
    log_warn "Diretório efiboot do releng não encontrado. Criando estrutura mínima..."
    mkdir -p "${PROFILE_DIR}/efiboot"
fi

# ==============================================================================
# FASE 6: COMPILAÇÃO DA ISO
# ==============================================================================
log_info "Fase 6: Iniciando compilação do NexaOS-Installer.iso..."

# Garantir que o keyring do pacman está populado e os bancos sincronizados.
# Isso é crítico em ambientes containerizados onde o keyring pode estar vazio.
log_info "Inicializando keyring do pacman e sincronizando bases de dados..."
pacman-key --init
pacman-key --populate archlinux
pacman -Sy --noconfirm
log_ok "Keyring e bases de dados prontos."

# Limpar build anterior
if [ -d "${WORK_DIR}" ]; then
    log_warn "Limpando diretório de trabalho anterior em ${WORK_DIR}..."
    rm -rf "${WORK_DIR}"
fi

mkdir -p "${OUT_DIR}"

mkarchiso -v -w "${WORK_DIR}" -o "${OUT_DIR}" "${PROFILE_DIR}"

echo ""
echo -e "${BOLD}${GREEN}============================================================${RESET}"
echo -e "${BOLD}${GREEN}   BUILD CONCLUÍDO COM SUCESSO!                            ${RESET}"
echo -e "${BOLD}${GREEN}   ISO disponível em: ${OUT_DIR}/                          ${RESET}"
echo -e "${BOLD}${GREEN}============================================================${RESET}"
echo ""
