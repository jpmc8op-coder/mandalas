# Copia la app web a `www/`, que es la carpeta que empaqueta Capacitor.
#
# Por qué existe esta copia y no se apunta Capacitor a la raíz: en la raíz están
# el repo, la documentación, las herramientas de desarrollo y `node_modules`.
# Capacitor mete en el APK TODO lo que haya en su `webDir`.
#
# `sw.js` NO se copia a propósito. Dentro de una app nativa los archivos ya son
# locales, así que la caché no aporta nada, y sí puede dejar servida una versión
# vieja después de actualizar. El registro del service worker en `index.html`
# falla en silencio si el archivo no está, que es justo lo que queremos.
#
# Correr esto cada vez que se toque la app, y después `npx cap copy`.

$base = Split-Path $PSScriptRoot -Parent
$www  = Join-Path $base 'www'

New-Item -ItemType Directory -Force $www | Out-Null
Get-ChildItem $www -File | Remove-Item -Force

$archivos = @(
  'index.html',
  'manifest.json',
  'icon.svg',
  'icon-192.png',
  'icon-512.png',
  'icon-1024.png',
  'apple-touch-icon.png'
)
foreach ($a in $archivos) {
  Copy-Item (Join-Path $base $a) (Join-Path $www $a) -Force
}

# `assets/` es lo que lee @capacitor/assets para generar los iconos y la
# pantalla de arranque nativos. Son copias de icon-1024.png, por eso se
# regeneran aquí en vez de versionarse.
$assets = Join-Path $base 'assets'
New-Item -ItemType Directory -Force $assets | Out-Null
Copy-Item (Join-Path $base 'icon-1024.png') (Join-Path $assets 'logo.png') -Force
Copy-Item (Join-Path $base 'icon-1024.png') (Join-Path $assets 'icon.png') -Force

Get-ChildItem $www -File | Select-Object Name, Length
