#!/bin/bash
# Nexa OS - First Boot OOBE Trigger

OOBE_FLAG="$HOME/.config/.nexa-oobe-done"

# Se for o ambiente Live (Instalador), não roda o OOBE, o usuário quer instalar o sistema
# O OOBE só deve rodar no sistema instalado.
# No Archiso, o usuário padrão é 'root' ou 'arch'. No Nexa, definimos o login do instalador.
# Vamos verificar se NÃO estamos no livecd.
# Uma forma simples é checar se não somos o root (livecd default) ou se o calamares/archinstall rodou.
# A forma mais garantida é apenas verificar a flag. O script de instalação pode injetar a flag no live user.
# Mas para simplificar: se a flag não existe, mostramos.

if [ ! -f "$OOBE_FLAG" ]; then
    # Dá um tempinho para o Waybar e o Wallpaper carregarem no fundo
    sleep 2
    
    # Inicia o Firefox no modo Kiosk travado com a classe NexaOOBE
    firefox --kiosk --class="NexaOOBE" "http://127.0.0.1:8000/oobe/index.html" &
    
    # Marca como feito para nunca mais rodar
    touch "$OOBE_FLAG"
fi
