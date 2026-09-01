#!/usr/bin/env bash
# Capturas para la ficha de Google Play.
#
# Play pide mínimo 2 y máximo 8 capturas de teléfono, de 320 a 3840 px de lado.
# Se generan a 1080x1920 (9:16, lo que espera un teléfono) renderizando a 540x960
# con factor de escala 2: por debajo de ~500 px de ancho, Chrome headless ignora
# el `--window-size` y devuelve una imagen en blanco. Y 540 está por debajo del
# corte de 860 px de la app, así que sale la interfaz de móvil, no la de
# escritorio.
#
# Requiere el servidor local en el 8777.

set -u
BASE="/c/Users/jpmc_/OneDrive/Documentos/claude code/mandalas"
WBASE='C:\Users\jpmc_\OneDrive\Documentos\claude code\mandalas'
CHROME="/c/Program Files/Google/Chrome/Application/chrome.exe"
SAL="$BASE/_capturas/tienda"
mkdir -p "$SAL"

# Copia de index.html con el inyector dentro, para poder fijar el estado por URL.
python -c "
import io
src=io.open(r'$WBASE\\index.html',encoding='utf-8').read()
iny=io.open(r'$WBASE\\dev\\hoja-contacto.js',encoding='utf-8').read()
i=src.rfind('</script>')
io.open(r'$WBASE\\_hoja.html','w',encoding='utf-8').write(src[:i]+'\n'+iny+'\n'+src[i:])
"

tirar () {   # $1 = nombre   $2 = query
  local out="$SAL/$1.png"
  rm -f "$out"
  "$CHROME" --headless=new --disable-gpu --no-sandbox \
    --user-data-dir="/c/Users/jpmc_/AppData/Local/Temp/chr-cap-$RANDOM" \
    --hide-scrollbars --force-device-scale-factor=2 --window-size=540,960 \
    --virtual-time-budget=12000 \
    --screenshot="$WBASE\\_capturas\\tienda\\$1.png" \
    "http://localhost:8777/_hoja.html?hoja=1&modo=app&$2" 2>/dev/null
  for _ in $(seq 1 20); do [ -f "$out" ] && break; sleep 0.3; done
  printf '%-22s %s\n' "$1" "$(ls -la "$out" 2>/dev/null | awk '{print $5}')"
}

tirar 1-hindu    "e=hindu&p=Flor&s=8080&n=14&a=8&d=70&plegado=1"
tirar 2-colorear "e=natura&p=Selva&s=60606&n=10&a=6&d=55&b=1&tab=col&pinta=2:0:c0392b,2:3:e6b422,2:6:2e7d5b,4:1:1e88a8&fondoc=f6e7c1"
tirar 3-robot    "e=robot&s=21&n=12&a=7&d=70&plegado=1"
tirar 4-taza     "e=africano&p=Kente&s=33&n=12&a=7&d=65&v=taza&tab=ver"
tirar 5-lineas   "e=animal&p=Fauna&s=45&n=10&a=7&d=70&l=1&plegado=1"
tirar 6-galeria  "e=circuito&s=140&n=16&a=8&d=75&tab=gen"

rm -f "$BASE/_hoja.html"
