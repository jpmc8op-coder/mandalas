# Hoja de contacto: renderiza varias mandalas de una vez y las captura en PNG.
#
# Cómo funciona y por qué así:
#  - `index.html` declara todo con `const` en el tope del script, y esas ligaduras
#    NO quedan en `window`: desde un iframe o desde fuera no se ven. Por eso el
#    código de la hoja se INYECTA dentro del propio script, antes del último
#    </script>, en una copia temporal (`_hoja.html`).
#  - El arranque de la app hace `replaceState('?seed=...')`, así que para cuando
#    corre la hoja los parámetros de la URL ya no están: hay que leerlos de la
#    entrada de navegación (ver `hoja-contacto.js`).
#  - Chrome headless necesita un `--user-data-dir` libre; si queda otro proceso
#    con el mismo perfil, no escribe el PNG y no avisa. Por eso se usa uno nuevo
#    en cada corrida.
#
# Requiere el servidor local levantado en el puerto 8777.
#
# Ejemplos:
#   .\hoja.ps1 -q "e=robot&p=Mecha&s=11,23,47,88,131,205"
#   .\hoja.ps1 -q "e=hindu&p=Flor&l=1" -png hindu.png
#   .\hoja.ps1 -q "modo=motivos&m=canon,pinon,viga" -png motivos.png -size "1300,700"
#
# Parámetros de la URL: e=estilo  p=paleta  s=semillas  n=simetrías  a=anillos
#   d=detalles  l=1 (solo líneas)  ac=acabado  modo=motivos&m=lista

param(
  [string]$q    = "e=robot",
  [string]$png  = "hoja.png",
  [string]$size = "1320,900",
  [string]$dest = "$PSScriptRoot\..\_capturas"
)

$base = Split-Path $PSScriptRoot -Parent
$src  = [IO.File]::ReadAllText("$base\index.html")
$iny  = [IO.File]::ReadAllText("$PSScriptRoot\hoja-contacto.js")
$i    = $src.LastIndexOf('</script>')
[IO.File]::WriteAllText("$base\_hoja.html",
  $src.Substring(0, $i) + "`n" + $iny + "`n" + $src.Substring($i),
  [Text.UTF8Encoding]::new($false))

New-Item -ItemType Directory -Force $dest | Out-Null
# Chrome no escribe el PNG si la ruta trae `..`: hay que resolverla antes.
$dest = (Resolve-Path $dest).Path
$out  = Join-Path $dest $png
if (Test-Path $out) { Remove-Item $out }

$perfil = "$env:TEMP\chr-hoja-$(Get-Random)"
$url    = "http://localhost:8777/_hoja.html?hoja=1&$q"
# Ojo: `$args` es variable automática de PowerShell; usar otro nombre.
$argv = @('--headless=new', '--disable-gpu', '--no-sandbox', "--user-data-dir=$perfil",
          '--hide-scrollbars', "--screenshot=$out", "--window-size=$size",
          '--virtual-time-budget=9000', $url)
& "C:\Program Files\Google\Chrome\Application\chrome.exe" @argv

# `chrome.exe --headless` puede devolver el control antes de terminar de escribir
# el PNG: si se borra `_hoja.html` de inmediato, la página se cae con 404 y la
# captura sale vacía o no sale. Hay que esperar a que aparezca el archivo.
$t = 0
while (-not (Test-Path $out) -and $t -lt 20) { Start-Sleep -Milliseconds 500; $t++ }
Remove-Item "$base\_hoja.html" -Force -ErrorAction SilentlyContinue
if (Test-Path $out) { $out } else { "sin archivo (¿servidor apagado o perfil de Chrome bloqueado?)" }
