# 🚀 Guide Rapide - Démarrage Firebase Auth

## ⚡ En 5 Minutes

Vous avez déjà la majeure partie du code en place ! Voici ce qu'il vous reste à faire :

### 1️⃣ Vérifier Firebase Console (2 min)

1. **Allez sur** : https://console.firebase.google.com
2. **Sélectionnez** : Projet `geoloc-cotonou`
3. **Cliquez** : **Authentication** dans le menu de gauche
4. **Activez deux méthodes** dans l'onglet "Sign-in method" :
   - ✅ **Email/Password** → Activez le switch
   - ✅ **Google** → Activez et ajoutez votre email de support

C'est tout pour la console ! 🎉

### 2️⃣ Tester l'Application (3 min)

```powershell
# Dans votre terminal PowerShell
cd localisation
flutter run
```

**Test du mot de passe oublié :**

1. Sur l'écran de connexion, cliquez "Mot de passe oublié?"
2. Entrez votre email
3. Cliquez "Envoyer l'email"
4. Vérifiez votre boîte mail (et spams !)
5. Cliquez sur le lien reçu
6. Définissez votre nouveau mot de passe

---

## 📋 Diagnostic Rapide

Exécutez ce script pour vérifier votre configuration :

```powershell
.\test_firebase_auth.ps1
```

Tous les ✅ ? Vous êtes prêt ! 🎉

---

## 🧪 Widget de Test Intégré

Pour tester toutes les fonctionnalités facilement, ajoutez temporairement dans [lib/features/home/home_screen.dart](lib/features/home/home_screen.dart) :

```dart
import '../auth/screens/firebase_auth_test_screen.dart';

// Dans le Scaffold, ajoutez :
floatingActionButton: FloatingActionButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FirebaseAuthTestScreen(),
      ),
    );
  },
  child: const Icon(Icons.science),
  tooltip: 'Test Firebase Auth',
),
```

Cela ajoute un bouton flottant pour accéder à l'écran de test. 🧪

---

## ✨ Ce Qui Fonctionne Déjà

Votre projet a déjà tout le code nécessaire :

✅ **Service d'authentification** (`auth_service.dart`)

- Inscription email/password
- Connexion email/password
- **Mot de passe oublié** ← Votre fonctionnalité !
- Google Sign-In
- Déconnexion
- Vérification email
- Gestion du profil

✅ **Écrans d'interface**

- Écran de connexion avec lien "Mot de passe oublié?"
- **Écran de réinitialisation complet** (`forgot_password_screen.dart`)
- Navigation automatique entre les écrans

✅ **State Management**

- Providers Riverpod configurés
- Gestion de l'état d'authentification en temps réel
- Redirection automatique si connecté

✅ **Configuration Firebase**

- `google-services.json` présent
- Firebase initialisé dans `main.dart`
- Toutes les dépendances installées

---

## 🔧 Configuration Minimale Requise

### Firebase Console

```
1. Authentication → Sign-in method
   → Email/Password : ON ✅
   → Google : ON ✅ (optionnel)

2. Authentication → Templates
   → Password reset : Personnalisé ✅ (optionnel)
```

C'est vraiment tout ! Firebase gère le reste automatiquement. 🚀

---

## 📱 Comment Ça Marche ?

### Flux Utilisateur - Mot de Passe Oublié

```
┌─────────────────────┐
│  LoginScreen        │
│  [Mot de passe      │
│   oublié?] ←────────┼─── Clic utilisateur
└─────────┬───────────┘
          │
          ↓ Navigation
┌─────────────────────┐
│ ForgotPasswordScreen│
│ [Email]             │
│ [Envoyer]           │
└─────────┬───────────┘
          │
          ↓ authService.resetPassword(email)
┌─────────────────────┐
│  Firebase Auth      │
│  Envoie email       │
└─────────┬───────────┘
          │
          ↓
┌─────────────────────┐
│  📧 Email reçu      │
│  Lien de reset      │
└─────────┬───────────┘
          │
          ↓ Clic sur le lien
┌─────────────────────┐
│  Page Firebase      │
│  Nouveau MdP        │
│  Confirmation       │
└─────────┬───────────┘
          │
          ↓ MdP réinitialisé
┌─────────────────────┐
│  LoginScreen        │
│  Se connecter avec  │
│  nouveau MdP ✅     │
└─────────────────────┘
```

### Code Backend (géré par Firebase)

Vous n'avez **rien à coder côté serveur** ! Firebase gère :

- ✅ Génération du token de réinitialisation
- ✅ Envoi de l'email
- ✅ Validation du lien (expiration 1h)
- ✅ Page web de réinitialisation
- ✅ Mise à jour sécurisée du mot de passe
- ✅ Sécurité anti-spam

---

## 🎯 Vérifications Essentielles

### 1. Firebase Console

```bash
✅ Authentication activée
✅ Email/Password configuré
✅ google-services.json téléchargé et placé dans android/app/
```

### 2. Code (déjà fait ✅)

- Service auth avec méthode `resetPassword()` ✅
- Écran ForgotPasswordScreen ✅
- Navigation depuis LoginScreen ✅
- Providers Riverpod ✅

### 3. Test

```bash
flutter run
# Tester : "Mot de passe oublié?" → Email → Lien → Nouveau MdP
```

---

## 🐛 Problèmes Courants

### "Email non reçu"

**Solutions** :

1. ✅ Vérifier les **spams/courrier indésirable**
2. ✅ Attendre 1-2 minutes (délai d'envoi)
3. ✅ Vérifier que l'email existe dans Firebase Console (Authentication → Users)
4. ✅ Vérifier que Email/Password est activé dans Firebase

### "Erreur: user-not-found"

**Cause** : L'email n'existe pas dans Firebase  
**Solution** : Créer d'abord un compte avec cet email

### "Google Sign-In ne fonctionne pas"

**Solutions** :

1. Générer et ajouter SHA-1 dans Firebase :
   ```bash
   cd android
   .\gradlew.bat signingReport
   # Copier SHA1 et l'ajouter dans Firebase Console
   ```
2. Télécharger à nouveau `google-services.json`
3. Rebuild : `flutter clean && flutter run`

---

## 📚 Documentation Complète

Pour plus de détails, consultez :

| Document                                                                 | Description                                  |
| ------------------------------------------------------------------------ | -------------------------------------------- |
| [GUIDE_AUTHENTIFICATION_FIREBASE.md](GUIDE_AUTHENTIFICATION_FIREBASE.md) | Guide complet avec toutes les configurations |
| [CHECKLIST_FIREBASE_AUTH.md](CHECKLIST_FIREBASE_AUTH.md)                 | Checklist détaillée pour validation          |
| Ce fichier                                                               | Démarrage rapide en 5 minutes                |

---

## 🛠️ Commandes Utiles

```powershell
# Lancer l'app
flutter run

# Tester la configuration
.\test_firebase_auth.ps1

# Nettoyer et rebuild
flutter clean
flutter pub get
flutter run

# Voir les logs Firebase
flutter run --verbose

# Générer SHA-1 (Google Sign-In)
cd android
.\gradlew.bat signingReport
```

---

## 🔐 Sécurité du Mot de Passe Oublié

Firebase gère automatiquement :

- ✅ **Token unique** par demande
- ✅ **Expiration** après 1 heure
- ✅ **Usage unique** (le lien ne fonctionne qu'une fois)
- ✅ **Limitation** : max 5 emails/heure par IP
- ✅ **HTTPS obligatoire** pour les liens
- ✅ **Validation** de l'email avant envoi

Vous n'avez rien à configurer, c'est sécurisé par défaut ! 🔒

---

## ✅ Validation Rapide

Votre configuration est prête si :

```
✅ Firebase Console → Authentication activée
✅ Email/Password activé dans Sign-in method
✅ google-services.json dans android/app/
✅ App compile : flutter run
✅ Navigation "Mot de passe oublié?" fonctionne
✅ Email de reset reçu après test
```

---

## 🎉 C'est Tout !

Votre système d'authentification avec **mot de passe oublié** est fonctionnel !

**Prochaines étapes (optionnelles)** :

1. Personnaliser le template d'email dans Firebase Console
2. Ajouter la vérification d'email après inscription
3. Implémenter les analytics pour tracker l'utilisation
4. Configurer un domaine personnalisé pour les emails

**Besoin d'aide ?**

- Consultez les documents détaillés
- Exécutez `test_firebase_auth.ps1` pour diagnostiquer
- Utilisez le widget de test `FirebaseAuthTestScreen`

---

**Bon développement ! 🚀**

_Date : 10 février 2026_
