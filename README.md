# Lock Game

## Cahier des charges - Vue d'ensemble

**Lock Game** est un jeu mobile de réflexion et de logique, développé en Flutter pour Android, iOS et Web (optionnel). Le joueur déverrouille un cadenas en résolvant des énigmes chiffrées variées, au sein d’une interface immersive, épurée et stimulante.

---

## Table des matières

1. [Technologies](#technologies)
2. [Fonctionnalités principales](#fonctionnalités-principales)
   - [Authentification](#authentification)
   - [Écran d’accueil](#écran-daccueil)
   - [Sélecteur de niveaux](#sélecteur-de-niveaux)
   - [Écran de jeu](#écran-de-jeu)
   - [Énigmes et niveaux](#énigmes-et-niveaux)
   - [Système de points](#système-de-points)
   - [Publicités](#publicités)
   - [Achat intégré (IAP)](#achat-intégré-iap)
   - [Paramètres](#paramètres)
   - [Tutoriel (Comment jouer)](#tutoriel-comment-jouer)
3. [Structure des données](#structure-des-données)
4. [Installation](#installation)
5. [Contribution](#contribution)
6. [Licence](#licence)

---

## Technologies

- **Flutter** (Android, iOS, Web optionnel)
- **Firebase**
  - Authentication : Google, Apple, anonyme (sans email/mot de passe)
  - Firestore : progression, points, achat no-ads
- **Monétisation**
  - Google AdMob : bannières, interstitiels, vidéos récompensées
  - In-App Purchase (IAP) : suppression des publicités
- **Stockage local** : SharedPreferences

---

## Fonctionnalités principales

### Authentification

- Trois méthodes : **Google**, **Apple**, **Anonyme**
- **Sans** email/mot de passe
- Association du compte à la progression (niveaux, points, préférences publicitaires)

### Écran d’accueil

- Logo du jeu
- Affichage du nombre de points
- Boutons :
  - ▶️ **Commencer** : sélection des niveaux
  - ❓ **Comment jouer** : tutoriel intégré
  - ⚙️ **Paramètres** : configuration et déconnexion

### Sélecteur de niveaux

- Grille de 1 à 100 niveaux :
  - ✅ *Joués* : terminés
  - 🔓 *Débloqués* : accessibles
  - 🔒 *Verrouillés* : gris et inaccessibles
- Déblocage progressif (niveau suivant après réussite)
- Chargement depuis un fichier `levels.json` local ou Firestore

### Écran de jeu

- Affichage de l’énigme (1 à 3 phrases)
- Cases dynamiques selon la longueur du code attendu
- Clavier numérique intégré
- Boutons :
  - **Valider** : vérification de la réponse
  - **Aide** : déduction de points pour afficher la solution

### Énigmes et niveaux

- **100 niveaux** uniques et variés
- Types d’énigmes :
  - Logiques (mathématiques, comparaisons)
  - Culture générale (cinéma, technologie…)
  - Football (statistiques, dates)
  - Histoire (événements historiques)
  - Combinaisons (plusieurs indices)
- Données modifiables en JSON ou Firestore

### Système de points

- +10 points par niveau réussi
- –20 points pour l’utilisation de l’aide
- Synchronisation en temps réel avec Firestore
- En cas de points insuffisants : suggestion de regarder une publicité ou d’acheter des points

### Publicités

- **Bannière** : affichée en bas de certains écrans
- **Interstitiel** : tous les 5 niveaux
- **Rewarded** : offre +20 points
- Suppression des pubs via achat unique (stocké dans Firestore)

### Achat intégré (IAP)

- Produit unique : **Supprimer les publicités**
- Paramétrable depuis l’écran **Paramètres**

### Paramètres

- Déconnexion
- Activation/Désactivation de la musique (future option)
- Accès au support développeur (achat no-ads)

### Tutoriel (Comment jouer)

- Présentation du concept
- Fonctionnement du cadenas
- Explication du système de points et d’aide
- Rôle des publicités et options de soutien

---

## Structure des données

Exemple de niveau dans `levels.json` :

```json
{
  "level": 42,
  "category": "football",
  "instructions": [
    "L’année où la France a remporté sa première Coupe du Monde,",
    "puis ajoute le nombre de buts marqués en finale."
  ],
  "solution": "19983"
}
```

---

## Installation

1. Cloner le dépôt :
   ```bash
   git clone https://github.com/votre-utilisateur/lock-game.git
   cd lock-game
   ```
2. Installer les dépendances :
   ```bash
   flutter pub get
   ```
3. Configurer Firebase :
   - Placer `google-services.json` (Android) dans `android/app`
   - Placer `GoogleService-Info.plist` (iOS) dans `ios/Runner`
4. Lancer l’application :
   ```bash
   flutter run
   ```

---

## Contribution

Les contributions sont les bienvenues ! Merci de respecter les bonnes pratiques Flutter et de créer une branche pour chaque nouvelle fonctionnalité ou correction de bug.

---

## Licence

Ce projet est sous licence MIT. Consultez le fichier `LICENSE` pour plus d’informations.
