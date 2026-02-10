## 🔧 SOLUTION IMMÉDIATE - Configuration clé API

### ❗ ÉTAPES URGENTES À SUIVRE :

1. **Aller sur Google Cloud Console** : https://console.cloud.google.com/
2. **APIs & Services** → **Credentials**
3. **Cliquer sur votre clé API** (AIzaSyBWg2j9co5lNFP8wZ7K1yW54uEg7r_n9hI)

### 🔓 DÉSACTIVER TEMPORAIREMENT LES RESTRICTIONS :

#### Application restrictions :

- ✅ Sélectionner **"None"** (aucune restriction)

#### API restrictions :

- ✅ Sélectionner **"Don't restrict key"**

### 💾 SAUVEGARDER ET ATTENDRE

- Cliquer **"Save"**
- ⏰ Attendre **2-3 minutes** pour que les changements prennent effet

---

### 🔒 APRÈS LES TESTS (POUR LA SÉCURITÉ) :

#### Remettre les restrictions Android :

1. **Application restrictions** → **Android apps**
2. **Package name:** `com.example.localisation`
3. **SHA-1:** `41:B3:EE:7A:B7:02:4C:59:14:66:D5:15:2F:B7:7B:6D:ED:90:57:9C`

#### API restrictions :

- **Restrict key** avec seulement :
  - Directions API
  - Maps SDK for Android
  - Geocoding API

---

### 🧪 TESTER APRÈS CHAQUE ÉTAPE :

Menu app → Test API Directions

### 📞 SI ÇA NE MARCHE TOUJOURS PAS :

1. Vérifier que la **Directions API** est activée
2. Vérifier les **quotas** (pas dépassés)
3. Créer une **nouvelle clé API** si nécessaire
