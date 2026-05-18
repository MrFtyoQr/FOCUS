# Compila el Android App Bundle (.aab) para Google Play Console.
$ErrorActionPreference = "Stop"

$FlutterBin = if ($env:FLUTTER_ROOT) { Join-Path $env:FLUTTER_ROOT "bin" } else { "E:\flutter\bin" }
$JbrBin = if (Test-Path "E:\Android\jbr\bin") { "E:\Android\jbr\bin" } else { "" }
$env:Path = "$FlutterBin;$JbrBin;C:\Users\josep\AppData\Local\Android\sdk\platform-tools;" + $env:Path
$env:JAVA_HOME = if ($env:JAVA_HOME) { $env:JAVA_HOME } elseif (Test-Path "E:\Android\jbr") { "E:\Android\jbr" } else { $env:JAVA_HOME }
$env:ANDROID_HOME = if ($env:ANDROID_HOME) { $env:ANDROID_HOME } else { "$env:LOCALAPPDATA\Android\sdk" }
$env:PUB_CACHE = if ($env:PUB_CACHE) { $env:PUB_CACHE } else { "E:\pub-cache" }

$Root = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$KeyProps = Join-Path $Root "android\key.properties"

if (-not (Test-Path $KeyProps)) {
    Write-Host "Falta android/key.properties. Ejecuta primero:" -ForegroundColor Red
    Write-Host "  .\tool\release\generate_upload_keystore.ps1"
    exit 1
}

Set-Location $Root
flutter pub get
flutter build appbundle --release

$Out = Join-Path $Root "build\app\outputs\bundle\release\app-release.aab"
$Dist = Join-Path $Root "dist"
New-Item -ItemType Directory -Force -Path $Dist | Out-Null
if (Test-Path $Out) {
    Copy-Item $Out (Join-Path $Dist "hipperapp-release.aab") -Force
    Write-Host "`nAAB listo:" -ForegroundColor Green
    Write-Host "  $Dist\hipperapp-release.aab"
} else {
    Write-Host "No se encontró el AAB en $Out" -ForegroundColor Red
    exit 1
}
