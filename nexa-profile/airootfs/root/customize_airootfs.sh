#!/usr/bin/env bash
# ==============================================================================
#  NEXA OS - customize_airootfs.sh
#  Executado pelo mkarchiso DENTRO do chroot, APÓS a instalação de todos os
#  pacotes. É aqui que aplicamos customizações que conflitariam se fossem
#  pre-colocadas no airootfs/ (ex: arquivos gerenciados por pacotes core).
#
#  Referência: Padrão usado por Garuda Linux, EndeavourOS, Manjaro.
# ==============================================================================

set -euo pipefail

echo "[NEXA] Iniciando customize_airootfs.sh..."

# ==============================================================================
# 1. BRANDING DO SISTEMA OPERACIONAL
#    /usr/lib/os-release é de propriedade do pacote 'filesystem'.
#    Sobrescrevemos APÓS a instalação para aplicar o branding do Nexa OS.
# ==============================================================================
cat > /usr/lib/os-release << 'EOF'
NAME="Nexa OS"
PRETTY_NAME="Nexa OS 1.0-alpha (Hyprland Edition)"
ID=nexaos
ID_LIKE=arch
BUILD_ID=rolling
ANSI_COLOR="38;2;0;136;255"
HOME_URL="https://github.com/NexaSolutions/nexaos"
DOCUMENTATION_URL="https://github.com/NexaSolutions/nexaos/wiki"
SUPPORT_URL="https://github.com/NexaSolutions/nexaos/issues"
BUG_REPORT_URL="https://github.com/NexaSolutions/nexaos/issues"
LOGO=nexa-logo
EOF
echo "[NEXA] os-release configurado."

# ==============================================================================
# 2. HOSTNAME PADRÃO DO LIVE ENVIRONMENT
# ==============================================================================
echo "nexa-os" > /etc/hostname
echo "[NEXA] Hostname: nexa-os"

# ==============================================================================
# 3. SHELL PADRÃO E PLYMOUTH
# ==============================================================================
chsh -s /bin/zsh root
sed -i 's|^SHELL=.*|SHELL=/bin/zsh|' /etc/default/useradd 2>/dev/null || true
echo "[NEXA] Shell padrão definido como zsh."

plymouth-set-default-theme bgrt || true
echo "[NEXA] Plymouth theme set to bgrt."

# ==============================================================================
# 4. HABILITAR SERVIÇOS SYSTEMD NA ISO LIVE
#    (os symlinks do build.sh são para o sistema instalado;
#     aqui habilitamos via systemctl para o live environment)
# ==============================================================================
systemctl enable NetworkManager.service
systemctl enable bluetooth.service
systemctl enable sddm.service
systemctl enable docker.service
systemctl enable nexa-ia.service 2>/dev/null || echo "[NEXA] nexa-ia.service não disponível no live, pulando."
echo "[NEXA] Serviços habilitados."

echo "[NEXA] customize_airootfs.sh concluído com sucesso."
