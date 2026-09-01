# Genera el AAB firmado que pide Google Play.
#
# El APK de depuracion que se instala a mano NO sirve para la tienda: Play exige
# un Android App Bundle firmado con una clave propia. Las contrasenas se leen de
# `android/keystore.properties`, que esta fuera de git.
#
# Uso:  npm run aab

$base = Split-Path $PSScriptRoot -Parent
$and  = Join-Path $base 'android'
$dest = Join-Path $base '_apk'
$props = Join-Path $and 'keystore.properties'

if (-not (Test-Path $props)) {
  Write-Host ""
  Write-Host "  Falta android/keystore.properties" -ForegroundColor Red
  Write-Host "  Sin el, el AAB saldria firmado como depuracion y Play lo rechaza."
  Write-Host "  Crea la clave y ese archivo siguiendo dev/ficha-play.md."
  Write-Host ""
  exit 1
}

# Las contrasenas en blanco son el olvido tipico: mejor avisar aqui que ver
# fallar a Gradle con un error que no dice nada.
$txt = Get-Content $props -Raw
foreach ($campo in @('storeFile', 'storePassword', 'keyAlias', 'keyPassword')) {
  if ($txt -notmatch "(?m)^$campo=.+$") {
    Write-Host ""
    Write-Host "  $campo esta vacio en android/keystore.properties" -ForegroundColor Red
    Write-Host ""
    exit 1
  }
}

# El JDK de Android Studio es un Java 25 que Gradle todavia no soporta.
$jdk = 'C:\Program Files\Eclipse Adoptium\jdk-21.0.12.8-hotspot'
if (Test-Path $jdk) { $env:JAVA_HOME = $jdk }
$env:ANDROID_HOME = "$env:LOCALAPPDATA\Android\Sdk"

Push-Location $and
try {
  & .\gradlew.bat bundleRelease --console=plain
  if ($LASTEXITCODE -ne 0) { throw "Gradle fallo con codigo $LASTEXITCODE" }
} finally {
  Pop-Location
}

$aab = Join-Path $and 'app\build\outputs\bundle\release\app-release.aab'
if (-not (Test-Path $aab)) { throw "No se genero el AAB" }

New-Item -ItemType Directory -Force $dest | Out-Null
$final = Join-Path $dest 'Mandalas.aab'
Copy-Item $aab $final -Force

$mb = [math]::Round((Get-Item $final).Length / 1MB, 2)
Write-Host ""
Write-Host "  AAB listo: $final  ($mb MB)" -ForegroundColor Green
Write-Host "  Subelo en Play Console: Pruebas > Pruebas internas > Crear version"
Write-Host ""
