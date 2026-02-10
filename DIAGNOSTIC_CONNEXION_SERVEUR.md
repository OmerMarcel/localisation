# 🔍 Diagnostic : Serveur non accessible depuis l'application mobile

## 📋 Checklist de diagnostic

### 1. ✅ Vérifier que le serveur est démarré

```bash
# Aller dans le dossier du backend
cd ../localisation_dash

# Démarrer le serveur
npm run server
```

Vous devriez voir :
```
🚀 Serveur démarré sur le port 5000
```

**Si le port est déjà utilisé :**
```bash
# Windows
netstat -ano | findstr :5000
taskkill /PID <PID> /F

# Linux/Mac
lsof -i :5000
kill -9 <PID>
```

---

### 2. 🌐 Vérifier votre IP locale

L'application utilise actuellement : `http://192.168.1.11:5000`

**Trouver votre vraie IP :**

**Windows :**
```cmd
ipconfig
```
Cherchez "Adresse IPv4" (ex: 192.168.1.6, 192.168.0.10, etc.)

**Linux/Mac :**
```bash
ifconfig
# ou
ip addr show
```

**Important :** Mettez à jour l'IP dans `lib/core/constants/app_constants.dart` ligne 11 :
```dart
static const String baseUrl = 'http://VOTRE_IP:5000';
```

---

### 3. 📱 Configuration selon votre environnement

#### A. Émulateur Android
Si vous testez sur un **émulateur Android**, utilisez :
```dart
static const String baseUrl = 'http://10.0.2.2:5000';
```
⚠️ `10.0.2.2` est l'adresse spéciale de l'émulateur pour accéder à `localhost` de votre machine.

#### B. Appareil physique (même réseau WiFi)
Si vous testez sur un **appareil physique**, utilisez votre IP locale :
```dart
static const String baseUrl = 'http://192.168.1.XX:5000'; // Remplacez XX
```

**Vérifications :**
- ✅ L'appareil mobile est sur le **même réseau WiFi** que votre ordinateur
- ✅ Le serveur écoute sur `0.0.0.0` (déjà configuré dans `server/index.js`)
- ✅ Le port 5000 n'est pas bloqué par le firewall

---

### 4. 🔥 Vérifier le Firewall Windows

Le firewall peut bloquer le port 5000.

**Solution :**
1. Ouvrez "Pare-feu Windows Defender"
2. Cliquez sur "Paramètres avancés"
3. Règles de trafic entrant → Nouvelle règle
4. Port → TCP → 5000 → Autoriser la connexion

**Ou via PowerShell (Admin) :**
```powershell
New-NetFirewallRule -DisplayName "Node.js Server" -Direction Inbound -LocalPort 5000 -Protocol TCP -Action Allow
```

---

### 5. 🧪 Tester la connexion

#### Test 1 : Depuis votre navigateur (même machine)
```
http://localhost:5000/health
```
Devrait retourner : `{"status":"OK",...}`

#### Test 2 : Depuis votre navigateur (IP locale)
```
http://192.168.1.11:5000/health
```
Si ça ne fonctionne pas, votre IP est incorrecte.

#### Test 3 : Depuis votre téléphone (même WiFi)
Ouvrez le navigateur sur votre téléphone et allez sur :
```
http://VOTRE_IP:5000/health
```

#### Test 4 : Depuis l'application Flutter
L'application devrait afficher des logs dans la console.

---

### 6. 🔧 Solutions rapides

#### Solution 1 : Changer l'IP dans app_constants.dart
```dart
// Trouvez votre IP avec ipconfig/ifconfig
static const String baseUrl = 'http://VOTRE_IP:5000';
```

#### Solution 2 : Utiliser ngrok (pour tester rapidement)
```bash
# Installer ngrok
npm install -g ngrok

# Créer un tunnel
ngrok http 5000
```
Utilisez l'URL fournie par ngrok (ex: `https://abc123.ngrok.io`)

#### Solution 3 : Vérifier le réseau
- ✅ Ordinateur et téléphone sur le même WiFi
- ✅ Pas de réseau invité/isolé
- ✅ WiFi 2.4GHz et 5GHz peuvent causer des problèmes

---

### 7. 🐛 Erreurs courantes

#### "No route to host"
- ❌ IP incorrecte
- ❌ Serveur non démarré
- ❌ Firewall bloque la connexion

#### "Connection refused"
- ❌ Port incorrect
- ❌ Serveur écoute sur localhost au lieu de 0.0.0.0

#### "Timeout"
- ❌ Réseaux différents
- ❌ Firewall bloque
- ❌ IP incorrecte

---

### 8. ✅ Vérification finale

1. ✅ Serveur démarré : `npm run server` dans `localisation_dash`
2. ✅ IP correcte dans `app_constants.dart`
3. ✅ Firewall autorise le port 5000
4. ✅ Même réseau WiFi
5. ✅ Test navigateur fonctionne : `http://VOTRE_IP:5000/health`

---

## 🚀 Commandes utiles

```bash
# Trouver votre IP (Windows)
ipconfig | findstr IPv4

# Trouver votre IP (Linux/Mac)
hostname -I
# ou
ifconfig | grep "inet "

# Tester la connexion (Windows)
curl http://localhost:5000/health

# Vérifier si le port est ouvert (Windows)
netstat -an | findstr :5000
```

---

## 📞 Si le problème persiste

1. Vérifiez les logs du serveur pour voir les requêtes reçues
2. Vérifiez les logs Flutter dans la console
3. Testez avec Postman/curl depuis votre machine
4. Testez avec Postman depuis votre téléphone (même WiFi)

