# Actualiza Mandalas sin tener que escribir comandos.
#
# Se lanza con doble clic en ACTUALIZAR.bat, que está en la raíz del proyecto.
#
# Hace lo mismo que se haría a mano, pero sin que se pueda olvidar ningún paso.
# El que más se olvida, y el que más confunde: **subir el número de VERSION de
# sw.js**. Sin eso el teléfono sigue sirviendo la copia guardada y parece que los
# cambios no se aplicaron.

# `-op` permite lanzarlo sin menú (1 web, 2 APK, 3 ambas). Sirve para
# automatizarlo y para poder probarlo; el doble clic sigue preguntando.
param([string]$op, [string]$msg)

$ErrorActionPreference = 'Stop'
$base = Split-Path $PSScriptRoot -Parent
Set-Location $base

# El JDK de Android Studio es un Java 25 que Gradle todavía no soporta, así que
# se apunta al 21 instalado aparte. Si no está, la compilación lo dirá claro.
$jdk = 'C:\Program Files\Eclipse Adoptium\jdk-21.0.12.8-hotspot'
$env:ANDROID_HOME = "$env:LOCALAPPDATA\Android\Sdk"
$env:Path = "C:\Program Files\nodejs;$env:APPDATA\npm;$env:Path"

function Titulo($t) {
  Write-Host ""
  Write-Host "  $t" -ForegroundColor Cyan
  Write-Host "  $('-' * $t.Length)" -ForegroundColor DarkCyan
}

$interactivo = [string]::IsNullOrWhiteSpace($op)

Write-Host ""
Write-Host "  MANDALAS - actualizar" -ForegroundColor Yellow
Write-Host ""
Write-Host "    1  Publicar en la web       (sube a GitHub Pages)"
Write-Host "    2  Compilar el APK          (deja _apk\Mandalas.apk)"
Write-Host "    3  Las dos cosas"
Write-Host "    0  Salir"
Write-Host ""
if ($interactivo) { $op = Read-Host "  Que hago" } else { Write-Host "  Opcion: $op" }

if ($op -eq '0' -or [string]::IsNullOrWhiteSpace($op)) { return }
if ($op -notin @('1','2','3')) { Write-Host "  Opcion no valida." -ForegroundColor Red; return }

$web = $op -in @('1','3')
$apk = $op -in @('2','3')

# ---------- WEB ----------
if ($web) {
  Titulo "Preparando la version web"

  # Hay dos formas de tener algo sin publicar: cambios sin guardar en el
  # proyecto, o commits ya hechos que no se han subido. Si solo se mirara lo
  # primero, quedarian commits atascados sin que nadie avisara.
  $cambios = git status --porcelain
  $pendientes = 0
  try { $pendientes = [int](git rev-list --count origin/main..main 2>$null) } catch { }
  $hayCambios = -not [string]::IsNullOrWhiteSpace($cambios)

  if (-not $hayCambios -and $pendientes -eq 0) {
    Write-Host "  No hay nada que publicar: ya esta todo subido." -ForegroundColor DarkGray
  } else {
    # La version de la cache solo sube cuando hay cambios de verdad. Subirla en
    # cada ejecucion llenaria el historial de commits que solo cambian un numero.
    if ($hayCambios) {
      $swPath = Join-Path $base 'sw.js'
      $sw = Get-Content $swPath -Raw
      if ($sw -match "const VERSION = 'mandalas-v(\d+)'") {
        $n = [int]$Matches[1] + 1
        $sw = $sw -replace "const VERSION = 'mandalas-v\d+'", "const VERSION = 'mandalas-v$n'"
        Set-Content $swPath $sw -NoNewline -Encoding UTF8
        Write-Host "  Cache de la web: mandalas-v$($n-1) -> mandalas-v$n" -ForegroundColor Green
      } else {
        Write-Host "  AVISO: no encontre VERSION en sw.js, no lo he tocado." -ForegroundColor Yellow
      }

      Write-Host ""
      if ($interactivo) { $msg = Read-Host "  Que cambiaste (una linea)" }
      if ([string]::IsNullOrWhiteSpace($msg)) { $msg = "Cambios del $(Get-Date -Format 'd MMM yyyy')" }
      git add -A
      git commit -q -m $msg
    } else {
      Write-Host "  Sin cambios nuevos, pero hay $pendientes commit(s) sin subir." -ForegroundColor DarkGray
    }

    Titulo "Subiendo a GitHub"
    git push -q origin main
    if ($LASTEXITCODE -ne 0) { throw "El push fallo. Revisa la conexion o las credenciales." }
    Write-Host "  Subido." -ForegroundColor Green
    Write-Host "  En 1-2 minutos estara en:" -ForegroundColor DarkGray
    Write-Host "  https://jpmc8op-coder.github.io/mandalas/" -ForegroundColor Cyan
  }
}

# ---------- APK ----------
if ($apk) {
  Titulo "Compilando el APK"
  Write-Host "  (la primera vez tarda; despues son segundos)" -ForegroundColor DarkGray

  if (-not (Test-Path $jdk)) { throw "No encuentro el JDK 21 en $jdk" }
  $env:JAVA_HOME = $jdk

  & (Join-Path $PSScriptRoot 'preparar-www.ps1') | Out-Null
  npx cap copy android
  if ($LASTEXITCODE -ne 0) { throw "La copia a Android fallo." }

  Push-Location (Join-Path $base 'android')
  & .\gradlew.bat assembleDebug --console=plain -q
  $ok = $LASTEXITCODE -eq 0
  Pop-Location
  if (-not $ok) { throw "La compilacion fallo." }

  New-Item -ItemType Directory -Force (Join-Path $base '_apk') | Out-Null
  Copy-Item (Join-Path $base 'android\app\build\outputs\apk\debug\app-debug.apk') `
            (Join-Path $base '_apk\Mandalas.apk') -Force
  $mb = [math]::Round((Get-Item (Join-Path $base '_apk\Mandalas.apk')).Length / 1MB, 2)
  Write-Host "  Listo: _apk\Mandalas.apk ($mb MB)" -ForegroundColor Green
}

Write-Host ""
Write-Host "  Listo." -ForegroundColor Green
Write-Host ""
Write-Host "  En el telefono:" -ForegroundColor DarkGray
Write-Host "   - La web/PWA se actualiza sola la proxima vez que la abras CON internet." -ForegroundColor DarkGray
Write-Host "     Si la tenias abierta en segundo plano, cierrala del todo primero." -ForegroundColor DarkGray
Write-Host "   - El APK hay que instalarlo encima; lo pintado se conserva." -ForegroundColor DarkGray
Write-Host ""
if ($interactivo) { Read-Host "  Enter para cerrar" | Out-Null }
