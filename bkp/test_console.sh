#!/usr/bin/env bash

set -e

# Salva a fonte atual
OLD_FONT=$(tty | xargs -I{} showconsolefont -v 2>/dev/null | grep -m1 'font' | awk '{print $2}')

echo "$OLD_FONT" > ~/.current_console_font

# Muda para uma fonte que suporta peças de xadrez
setfont Lat2-Terminus16

echo -e "\u2654 \u2655 \u2656 \u2657 \u2658 \u2659"  # peças brancas
echo -e "\u265A \u265B \u265C \u265D \u265E \u265F"  # peças pretas

# Aguarda usuário
read -p "Pressione Enter para restaurar a fonte original..."

# Restaura fonte padrão (manual, pois showconsolefont não retorna nome utilizável diretamente)
setfont lat9w-16
