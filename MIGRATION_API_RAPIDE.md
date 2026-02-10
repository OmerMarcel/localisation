# ⚡ Migration API - Guide Ultra-Rapide

## ✅ Ce qui a été fait

**L'URL de l'API a été corrigée** dans votre app mobile !

```dart
// Avant
baseUrl = 'http://192.168.1.8:5000'

// Après ✅
baseUrl = 'http://192.168.1.8:3001'  // Backend localisation_dash
```

---

## 🚀 Pour Utiliser l'API Supabase

### 1. Démarrer le Backend (Terminal 1)

```bash
cd d:\local\localisation_dash
npm run dev
```

Attendez de voir :
```
✅ Connexion Supabase réussie
🚀 Serveur démarré sur le port 3001
```

### 2. Lancer l'App Mobile (Terminal 2)

```bash
cd d:\local\localisation
flutter run
```

### 3. Vérifier les Logs

Vous devriez voir :
```
✅ ApiService initialisé avec baseUrl=http://192.168.1.8:3001
✅ 23 infrastructures chargées depuis l'API
```

---

## 🎯 C'est Tout !

Votre app utilise maintenant les données de Supabase via l'API !

### Ce qui se passe automatiquement :

1. 📡 L'app charge les données depuis l'API (Supabase)
2. 💾 Les données sont mises en cache hors ligne
3. 🗺️ Les infrastructures s'affichent sur la carte
4. 🔄 Les modifications dans le dashboard apparaissent dans l'app

---

## 🧪 Test Rapide

### Tester que ça marche :

```bash
# Terminal 1 : Backend
cd d:\local\localisation_dash
npm run dev

# Terminal 2 : App mobile
cd d:\local\localisation
flutter run

# Terminal 3 : Test API
curl http://192.168.1.8:3001/api/infrastructures
```

---

## 📱 Selon Votre Appareil

### Sur Émulateur Android

Modifiez `lib/core/constants/app_constants.dart` :

```dart
static const String baseUrl = 'http://10.0.2.2:3001';
```

### Sur Appareil Physique (même WiFi)

```dart
static const String baseUrl = 'http://192.168.1.8:3001';  // ✅ Déjà configuré
```

---

## 🔄 Workflow Complet

```
Modification dans Dashboard
           ↓
    Supabase Database
           ↓
       API REST
           ↓
      App Mobile
           ↓
   Affichage sur Carte
```

---

## ❓ Si Ça Ne Marche Pas

### Vérifier :

1. **Le backend est démarré**
   ```bash
   cd d:\local\localisation_dash
   npm run server
   ```

2. **L'API répond**
   ```bash
   curl http://192.168.1.8:3001/api/infrastructures
   ```

3. **Les données sont dans Supabase**
   - Ouvrir supabase.com
   - Table Editor → infrastructures
   - Vérifier qu'il y a des données

4. **Le firewall ne bloque pas**
   - Autoriser Node.js dans le firewall Windows

---

## 🗑️ Supprimer le Fichier JSON (Optionnel)

**Après avoir testé que tout fonctionne :**

```bash
cd d:\local\localisation\assets\data

# Backup
copy sample_infrastructures.json sample_infrastructures.json.backup

# Supprimer
del sample_infrastructures.json
```

> ⚠️ **Note** : L'app a un fallback vers ce fichier si l'API ne répond pas. Gardez-le pour le développement !

---

## 📖 Documentation Complète

Pour plus de détails : [MIGRATION_VERS_API_SUPABASE.md](MIGRATION_VERS_API_SUPABASE.md)

---

**C'est prêt ! Lancez le backend et l'app, et tout devrait fonctionner ! 🎉**




