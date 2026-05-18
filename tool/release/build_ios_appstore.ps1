# Preparación / build iOS para App Store (requiere macOS + Xcode + cuenta Apple Developer).
$ErrorActionPreference = "Stop"

if ($IsWindows -or $env:OS -match "Windows") {
    Write-Host "El IPA para App Store debe compilarse en macOS." -ForegroundColor Yellow
    Write-Host @"

Pasos en Mac (con el repo clonado):

  cd ios
  pod install
  cd ..
  flutter pub get
  flutter build ipa --release

O desde Xcode:
  1. open ios/Runner.xcworkspace
  2. Signing & Capabilities → Team (tu cuenta Apple)
  3. Bundle Identifier: com.treetech.hiperapp
  4. Product → Archive → Distribute App → App Store Connect

Salida esperada:
  build/ios/ipa/*.ipa

"@ 
    exit 0
}

$Root = Resolve-Path (Join-Path $PSScriptRoot "..\..")
Set-Location $Root
flutter pub get
Push-Location ios
pod install
Pop-Location
flutter build ipa --release
Write-Host "IPA en build/ios/ipa/"
