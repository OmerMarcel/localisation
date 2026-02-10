# Script de test pour la configuration Firebase Auth
# Usage: .\test_firebase_auth.ps1

Write-Host "🔥 Test de Configuration Firebase Authentication" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Vérifier que Flutter est installé
Write-Host "1️⃣  Vérification de Flutter..." -ForegroundColor Yellow
$flutterVersion = flutter --version 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "   ✅ Flutter installé" -ForegroundColor Green
} else {
    Write-Host "   ❌ Flutter non trouvé" -ForegroundColor Red
    exit 1
}

# 2. Vérifier google-services.json
Write-Host ""
Write-Host "2️⃣  Vérification des fichiers de configuration..." -ForegroundColor Yellow
$googleServicesPath = "android\app\google-services.json"
if (Test-Path $googleServicesPath) {
    Write-Host "   ✅ google-services.json trouvé" -ForegroundColor Green
    
    # Lire et afficher les infos du projet
    $googleServices = Get-Content $googleServicesPath | ConvertFrom-Json
    $projectId = $googleServices.project_info.project_id
    $projectNumber = $googleServices.project_info.project_number
    
    Write-Host "      Project ID: $projectId" -ForegroundColor Cyan
    Write-Host "      Project Number: $projectNumber" -ForegroundColor Cyan
} else {
    Write-Host "   ❌ google-services.json non trouvé dans android/app/" -ForegroundColor Red
    Write-Host "      Téléchargez-le depuis Firebase Console" -ForegroundColor Yellow
}

# 3. Vérifier pubspec.yaml
Write-Host ""
Write-Host "3️⃣  Vérification des dépendances Firebase..." -ForegroundColor Yellow
$pubspecPath = "pubspec.yaml"
if (Test-Path $pubspecPath) {
    $pubspecContent = Get-Content $pubspecPath -Raw
    
    $firebaseDeps = @(
        "firebase_core",
        "firebase_auth",
        "google_sign_in"
    )
    
    foreach ($dep in $firebaseDeps) {
        if ($pubspecContent -match $dep) {
            Write-Host "   ✅ $dep présent" -ForegroundColor Green
        } else {
            Write-Host "   ❌ $dep manquant" -ForegroundColor Red
        }
    }
}

# 4. Vérifier build.gradle.kts
Write-Host ""
Write-Host "4️⃣  Vérification de la configuration Android..." -ForegroundColor Yellow
$buildGradlePath = "android\app\build.gradle.kts"
if (Test-Path $buildGradlePath) {
    $buildGradleContent = Get-Content $buildGradlePath -Raw
    
    if ($buildGradleContent -match "com\.google\.gms\.google-services") {
        Write-Host "   ✅ Plugin Google Services présent" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  Plugin Google Services manquant" -ForegroundColor Red
        Write-Host "      Ajoutez: id('com.google.gms.google-services')" -ForegroundColor Yellow
    }
}

# 5. Vérifier AndroidManifest.xml
Write-Host ""
Write-Host "5️⃣  Vérification d'AndroidManifest..." -ForegroundColor Yellow
$manifestPath = "android\app\src\main\AndroidManifest.xml"
if (Test-Path $manifestPath) {
    $manifestContent = Get-Content $manifestPath -Raw
    
    if ($manifestContent -match "INTERNET") {
        Write-Host "   ✅ Permission INTERNET présente" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  Permission INTERNET manquante" -ForegroundColor Yellow
    }
}

# 6. Vérifier les fichiers d'authentification
Write-Host ""
Write-Host "6️⃣  Vérification des fichiers d'authentification..." -ForegroundColor Yellow

$authFiles = @{
    "Service Auth" = "lib\core\services\auth_service.dart"
    "Providers" = "lib\core\providers\auth_providers.dart"
    "Login Screen" = "lib\features\auth\screens\login_screen.dart"
    "Forgot Password" = "lib\features\auth\screens\forgot_password_screen.dart"
}

foreach ($file in $authFiles.GetEnumerator()) {
    if (Test-Path $file.Value) {
        Write-Host "   ✅ $($file.Key) présent" -ForegroundColor Green
    } else {
        Write-Host "   ❌ $($file.Key) manquant: $($file.Value)" -ForegroundColor Red
    }
}

# 7. Test de compilation
Write-Host ""
Write-Host "7️⃣  Test de compilation..." -ForegroundColor Yellow
Write-Host "   (Ceci peut prendre quelques minutes)" -ForegroundColor Cyan

$analyzeOutput = flutter analyze 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "   ✅ Analyse du code réussie" -ForegroundColor Green
} else {
    Write-Host "   ⚠️  Erreurs détectées dans le code" -ForegroundColor Yellow
    Write-Host "   Exécutez 'flutter analyze' pour plus de détails" -ForegroundColor Cyan
}

# 8. Générer les clés SHA pour Google Sign-In
Write-Host ""
Write-Host "8️⃣  Génération des clés SHA (pour Google Sign-In)..." -ForegroundColor Yellow
Write-Host "   (Facultatif - uniquement pour Google Sign-In)" -ForegroundColor Cyan

Push-Location android
$shaOutput = .\gradlew.bat signingReport 2>&1 | Select-String "SHA1"
Pop-Location

if ($shaOutput) {
    Write-Host "   ✅ Clés SHA trouvées:" -ForegroundColor Green
    $shaOutput | ForEach-Object {
        Write-Host "      $_" -ForegroundColor Cyan
    }
    Write-Host ""
    Write-Host "   📋 Ajoutez ces clés SHA dans Firebase Console:" -ForegroundColor Yellow
    Write-Host "      Project Settings → Your apps → Android → SHA certificate fingerprints" -ForegroundColor Cyan
} else {
    Write-Host "   ⚠️  Impossible de générer les clés SHA" -ForegroundColor Yellow
    Write-Host "      Exécutez manuellement: cd android && .\gradlew.bat signingReport" -ForegroundColor Cyan
}

# Résumé final
Write-Host ""
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "📊 RÉSUMÉ" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "✅ = Configuré correctement" -ForegroundColor Green
Write-Host "⚠️  = Attention requise" -ForegroundColor Yellow
Write-Host "❌ = Configuration manquante" -ForegroundColor Red
Write-Host ""

# Instructions suivantes
Write-Host "🚀 PROCHAINES ÉTAPES:" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Si tout est ✅, vous pouvez tester l'app:" -ForegroundColor White
Write-Host "   flutter run" -ForegroundColor Green
Write-Host ""
Write-Host "2. Vérifiez Firebase Console:" -ForegroundColor White
Write-Host "   - Authentication → Sign-in method" -ForegroundColor Cyan
Write-Host "   - Activez Email/Password et Google" -ForegroundColor Cyan
Write-Host ""
Write-Host "3. Testez le mot de passe oublié:" -ForegroundColor White
Write-Host "   - Créez un compte de test" -ForegroundColor Cyan
Write-Host "   - Utilisez la fonction 'Mot de passe oublié'" -ForegroundColor Cyan
Write-Host "   - Vérifiez vos emails (et spams)" -ForegroundColor Cyan
Write-Host ""
Write-Host "4. Documentation complète:" -ForegroundColor White
Write-Host "   Consultez GUIDE_AUTHENTIFICATION_FIREBASE.md" -ForegroundColor Cyan
Write-Host ""

Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "Test terminé!" -ForegroundColor Green
