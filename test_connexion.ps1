# Script de diagnostic de connexion serveur
Write-Host "🔍 Diagnostic de connexion serveur" -ForegroundColor Cyan
Write-Host ""

# 1. Vérifier l'IP locale
Write-Host "1️⃣ Vérification de l'IP locale..." -ForegroundColor Yellow
$ipAddresses = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -like "192.168.*" -or $_.IPAddress -like "10.*" } | Select-Object -ExpandProperty IPAddress
if ($ipAddresses) {
    Write-Host "   ✅ IP(s) trouvée(s) :" -ForegroundColor Green
    foreach ($ip in $ipAddresses) {
        Write-Host "      - $ip" -ForegroundColor White
    }
} else {
    Write-Host "   ⚠️ Aucune IP locale trouvée" -ForegroundColor Red
}

Write-Host ""

# 2. Vérifier si le port 5000 est utilisé
Write-Host "2️⃣ Vérification du port 5000..." -ForegroundColor Yellow
$port5000 = Get-NetTCPConnection -LocalPort 5000 -ErrorAction SilentlyContinue
if ($port5000) {
    Write-Host "   ✅ Le port 5000 est utilisé (serveur probablement démarré)" -ForegroundColor Green
    Write-Host "      État : $($port5000.State)" -ForegroundColor White
} else {
    Write-Host "   ❌ Le port 5000 n'est pas utilisé (serveur non démarré)" -ForegroundColor Red
    Write-Host "   💡 Démarrez le serveur avec : cd ..\localisation_dash && npm run server" -ForegroundColor Yellow
}

Write-Host ""

# 3. Tester localhost
Write-Host "3️⃣ Test de connexion localhost:5000..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:5000/health" -TimeoutSec 3 -ErrorAction Stop
    Write-Host "   ✅ Serveur accessible sur localhost" -ForegroundColor Green
    Write-Host "      Réponse : $($response.StatusCode)" -ForegroundColor White
} catch {
    Write-Host "   ❌ Serveur non accessible sur localhost" -ForegroundColor Red
    Write-Host "      Erreur : $($_.Exception.Message)" -ForegroundColor White
}

Write-Host ""

# 4. Vérifier le firewall
Write-Host "4️⃣ Vérification du firewall..." -ForegroundColor Yellow
$firewallRule = Get-NetFirewallRule -DisplayName "*5000*" -ErrorAction SilentlyContinue
if ($firewallRule) {
    Write-Host "   ✅ Règle firewall trouvée pour le port 5000" -ForegroundColor Green
} else {
    Write-Host "   ⚠️ Aucune règle firewall spécifique pour le port 5000" -ForegroundColor Yellow
    Write-Host "   💡 Vous devrez peut-être autoriser le port dans le firewall" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "📝 Configuration actuelle dans app_constants.dart :" -ForegroundColor Cyan
Write-Host "   baseUrl = 'http://192.168.1.11:5000'" -ForegroundColor White
Write-Host ""
Write-Host "💡 Actions recommandées :" -ForegroundColor Yellow
Write-Host "   1. Vérifiez que votre IP correspond à l'une des IPs listées ci-dessus" -ForegroundColor White
Write-Host "   2. Si vous utilisez un émulateur Android, utilisez : http://10.0.2.2:5000" -ForegroundColor White
Write-Host "   3. Assurez-vous que le serveur est démarré dans localisation_dash" -ForegroundColor White
Write-Host "   4. Vérifiez que votre téléphone est sur le même réseau WiFi" -ForegroundColor White

