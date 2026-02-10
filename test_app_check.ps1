# Test Firebase App Check Configuration
# Usage: .\test_app_check.ps1

Write-Host ""
Write-Host "🔐 Test Configuration Firebase App Check" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# 1. Vérifier que le code est à jour
Write-Host "1️⃣  Vérification du code main.dart..." -ForegroundColor Yellow
$mainPath = "lib\main.dart"
if (Test-Path $mainPath) {
    $mainContent = Get-Content $mainPath -Raw
    
    if ($mainContent -match "AndroidProvider\.playIntegrity") {
        Write-Host "   ✅ Configuration Play Integrity présente" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  Play Integrity non configuré" -ForegroundColor Yellow
        Write-Host "      Le code utilise toujours debug provider" -ForegroundColor Cyan
    }
    
    if ($mainContent -match "AppleProvider\.deviceCheck") {
        Write-Host "   ✅ Configuration Device Check présente" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  Device Check non configuré" -ForegroundColor Yellow
    }
    
    if ($mainContent -match "kDebugMode") {
        Write-Host "   ✅ Détection du mode (debug/release) active" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  Mode statique (pas de détection debug/release)" -ForegroundColor Yellow
    }
} else {
    Write-Host "   ❌ Fichier main.dart non trouvé" -ForegroundColor Red
}

# 2. Vérifier pubspec.yaml
Write-Host ""
Write-Host "2️⃣  Vérification des dépendances..." -ForegroundColor Yellow
$pubspecPath = "pubspec.yaml"
if (Test-Path $pubspecPath) {
    $pubspecContent = Get-Content $pubspecPath -Raw
    
    if ($pubspecContent -match "firebase_app_check:") {
        Write-Host "   ✅ firebase_app_check présent" -ForegroundColor Green
        
        # Extraire la version
        if ($pubspecContent -match "firebase_app_check:\s+([\d\.]+)") {
            $version = $matches[1]
            Write-Host "      Version: $version" -ForegroundColor Cyan
        }
    } else {
        Write-Host "   ❌ firebase_app_check manquant" -ForegroundColor Red
    }
    
    if ($pubspecContent -match "firebase_core:") {
        Write-Host "   ✅ firebase_core présent" -ForegroundColor Green
    } else {
        Write-Host "   ❌ firebase_core manquant" -ForegroundColor Red
    }
}

# 3. Test de compilation
Write-Host ""
Write-Host "3️⃣  Test de compilation..." -ForegroundColor Yellow
Write-Host "   (Analyse statique du code)" -ForegroundColor Cyan

$analyzeOutput = flutter analyze --no-pub 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "   ✅ Aucune erreur de compilation détectée" -ForegroundColor Green
} else {
    Write-Host "   ⚠️  Erreurs ou warnings détectés" -ForegroundColor Yellow
    Write-Host "      Exécutez 'flutter analyze' pour plus de détails" -ForegroundColor Cyan
}

# 4. Instructions Firebase Console
Write-Host ""
Write-Host "4️⃣  Configuration Firebase Console..." -ForegroundColor Yellow
Write-Host ""
Write-Host "   📋 Checklist manuelle:" -ForegroundColor Cyan
Write-Host ""
Write-Host "   Android (Play Integrity):" -ForegroundColor White
Write-Host "   ☐ Aller sur: https://console.cloud.google.com" -ForegroundColor Gray
Write-Host "   ☐ APIs & Services → Library" -ForegroundColor Gray
Write-Host "   ☐ Rechercher: Play Integrity API" -ForegroundColor Gray
Write-Host "   ☐ Cliquer: Enable" -ForegroundColor Gray
Write-Host ""
Write-Host "   Firebase:" -ForegroundColor White
Write-Host "   ☐ Aller sur: https://console.firebase.google.com" -ForegroundColor Gray
Write-Host "   ☐ Projet: geoloc-cotonou" -ForegroundColor Gray
Write-Host "   ☐ Project Settings → App Check" -ForegroundColor Gray
Write-Host "   ☐ Android app → Play Integrity (Register)" -ForegroundColor Gray
Write-Host "   ☐ iOS app → DeviceCheck (Register)" -ForegroundColor Gray
Write-Host ""

# 5. Test Debug
Write-Host "5️⃣  Test en mode Debug..." -ForegroundColor Yellow
Write-Host "   Lancement de l'app en mode debug..." -ForegroundColor Cyan
Write-Host ""
Write-Host "   Commande: flutter run --debug" -ForegroundColor White
Write-Host ""
Write-Host "   Recherchez dans les logs:" -ForegroundColor Cyan
Write-Host "   ✓ '🔥 AppCheck debug token: ...'" -ForegroundColor Green
Write-Host "   ✓ '🔥 AppCheck initialisé — Debug mode'" -ForegroundColor Green
Write-Host ""

# 6. Build Release
Write-Host "6️⃣  Test Build Release..." -ForegroundColor Yellow
Write-Host "   Pour tester Play Integrity en condition réelle:" -ForegroundColor Cyan
Write-Host ""
Write-Host "   Android APK:" -ForegroundColor White
Write-Host "   flutter build apk --release" -ForegroundColor Gray
Write-Host ""
Write-Host "   Android App Bundle:" -ForegroundColor White
Write-Host "   flutter build appbundle --release" -ForegroundColor Gray
Write-Host ""
Write-Host "   iOS:" -ForegroundColor White
Write-Host "   flutter build ios --release" -ForegroundColor Gray
Write-Host ""

# 7. SHA Fingerprints
Write-Host "7️⃣  SHA Fingerprints (pour Google Sign-In)..." -ForegroundColor Yellow
Write-Host "   Génération des SHA-1 et SHA-256..." -ForegroundColor Cyan
Write-Host ""

Push-Location android -ErrorAction SilentlyContinue
if ($?) {
    Write-Host "   Exécution de gradlew signingReport..." -ForegroundColor White
    $shaOutput = .\gradlew.bat signingReport 2>&1 | Select-String "SHA"
    
    if ($shaOutput) {
        Write-Host ""
        Write-Host "   📋 Clés trouvées:" -ForegroundColor Green
        $shaOutput | ForEach-Object {
            Write-Host "      $_" -ForegroundColor Cyan
        }
        Write-Host ""
        Write-Host "   ⚠️  Important:" -ForegroundColor Yellow
        Write-Host "      Ces clés sont pour DEBUG uniquement" -ForegroundColor White
        Write-Host "      En PRODUCTION, utilisez les clés de votre keystore release" -ForegroundColor White
        Write-Host ""
    } else {
        Write-Host "   ⚠️  Impossible de générer les clés SHA" -ForegroundColor Yellow
    }
    Pop-Location
} else {
    Write-Host "   ⚠️  Dossier android non trouvé" -ForegroundColor Yellow
}

# Résumé
Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "📊 RÉSUMÉ" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "✅ Configuration dans le code:" -ForegroundColor Green
Write-Host "   • Mode Debug  : AndroidProvider.debug" -ForegroundColor White
Write-Host "   • Mode Release: AndroidProvider.playIntegrity" -ForegroundColor White
Write-Host ""

Write-Host "📋 TODO - Firebase Console:" -ForegroundColor Yellow
Write-Host "   1. Activer Play Integrity API (Google Cloud)" -ForegroundColor White
Write-Host "   2. Configurer App Check (Firebase Console)" -ForegroundColor White
Write-Host "   3. Ajouter SHA fingerprints (pour release)" -ForegroundColor White
Write-Host ""

Write-Host "🧪 Tests:" -ForegroundColor Cyan
Write-Host "   • Debug  : flutter run --debug" -ForegroundColor White
Write-Host "   • Release: flutter build apk --release" -ForegroundColor White
Write-Host ""

Write-Host "📚 Documentation:" -ForegroundColor Magenta
Write-Host "   Consultez: CONFIGURATION_APP_CHECK_PRODUCTION.md" -ForegroundColor White
Write-Host ""

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "✅ Test terminé!" -ForegroundColor Green
Write-Host ""
