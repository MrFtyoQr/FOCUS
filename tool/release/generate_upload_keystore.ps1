# Genera el keystore de subida a Google Play (ejecutar una sola vez).
# Requiere JDK (keytool). Guarda las contraseñas en un gestor seguro.

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Find-Keytool {
    $candidates = @(
        (Join-Path $env:JAVA_HOME "bin\keytool.exe"),
        "E:\Android\jbr\bin\keytool.exe",
        "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe",
        "$env:LOCALAPPDATA\Programs\Android\Android Studio\jbr\bin\keytool.exe",
        "C:\Program Files\Java\jdk-21\bin\keytool.exe",
        "C:\Program Files\Eclipse Adoptium\jdk-21*\bin\keytool.exe"
    )
    foreach ($p in $candidates) {
        if ($p -and (Test-Path $p)) { return (Resolve-Path $p).Path }
        if ($p -like '*`**') {
            $resolved = Get-Item $p -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($resolved) { return $resolved.FullName }
        }
    }
    $fromPath = Get-Command keytool -ErrorAction SilentlyContinue
    if ($fromPath) { return $fromPath.Source }
    return $null
}

$Keytool = Find-Keytool
if (-not $Keytool) {
    Write-Host "No se encontro keytool.exe." -ForegroundColor Red
    Write-Host ""
    Write-Host "En tu PC esta en: E:\Android\jbr\bin\keytool.exe"
    Write-Host "Ejecuta en esta sesion:"
    Write-Host '  $env:Path = "E:\Android\jbr\bin;" + $env:Path'
    Write-Host "O instala JDK 17+ y define JAVA_HOME."
    exit 1
}

Write-Host "Usando keytool: $Keytool" -ForegroundColor Cyan

$Root = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$AndroidDir = Join-Path $Root "android"
$Keystore = Join-Path $AndroidDir "app\upload-keystore.jks"
$KeyPropsExample = Join-Path $AndroidDir "key.properties.example"
$KeyProps = Join-Path $AndroidDir "key.properties"

if (Test-Path $Keystore) {
    Write-Host "Ya existe: $Keystore" -ForegroundColor Yellow
    exit 0
}

$storePass = Read-Host "Contrasena del keystore (storePassword)" -AsSecureString
$keyPass = Read-Host "Contrasena de la clave (keyPassword, Enter = igual que store)" -AsSecureString
$storePlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($storePass))
$keyPlain = if ($keyPass.Length -eq 0) { $storePlain } else {
    [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($keyPass))
}

$dname = "CN=FOCUS, OU=Mobile, O=Tree Tech Solutions, L=, ST=, C=ES"
& $Keytool -genkeypair -v `
    -keystore $Keystore `
    -storetype JKS `
    -keyalg RSA -keysize 2048 -validity 10000 `
    -alias upload `
    -storepass $storePlain -keypass $keyPlain `
    -dname $dname

if (-not (Test-Path $KeyProps)) {
    Copy-Item $KeyPropsExample $KeyProps
    (Get-Content $KeyProps) `
        -replace 'TU_STORE_PASSWORD', $storePlain `
        -replace 'TU_KEY_PASSWORD', $keyPlain |
        Set-Content $KeyProps -Encoding UTF8
    Write-Host "Creado android/key.properties" -ForegroundColor Green
}

Write-Host ""
Write-Host "Keystore listo: $Keystore" -ForegroundColor Green
Write-Host "Guarda las contrasenas. Si pierdes el .jks no podras actualizar la app en Play con la misma clave."
