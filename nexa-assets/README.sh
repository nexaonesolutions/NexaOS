#!/usr/bin/env bash
# ==============================================================================
#  NEXA OS - README: GUIA DE USO DO REPOSITÓRIO nexa-assets/
# ==============================================================================
#
#  Este diretório serve como a "fonte de verdade" dos assets visuais do Nexa OS.
#
#  INSTRUÇÃO:
#  Coloque os arquivos PNG de alta resolução finais aqui com os nomes exatos:
#
#    logo.png         → Logo principal da Nexa OS (ex: 800x400px, fundo transparente)
#    background.png   → Fundo do GRUB (1920x1080px, fundo escuro)
#    welcome.png      → Splash do Calamares (1200x800px)
#
#  O script build.sh verificará automaticamente este diretório ANTES de gerar
#  os placeholders via ImageMagick.
#
#  Se os arquivos existirem aqui → serão copiados para os destinos corretos.
#  Se NÃO existirem              → placeholders textuais serão gerados.
#
#  DESTINOS AUTOMÁTICOS:
#   logo.png     → airootfs/usr/share/sddm/themes/nexa-sddm/logo.png
#   logo.png     → airootfs/etc/calamares/branding/nexa/logo.png
#   logo.png     → airootfs/usr/share/grub/themes/nexa/logo.png
#   background.png → airootfs/usr/share/grub/themes/nexa/background.png
#   welcome.png  → airootfs/etc/calamares/branding/nexa/welcome.png
# ==============================================================================
echo "nexa-assets README carregado."
