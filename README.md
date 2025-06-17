# Lock Game

## Cahier des charges - Vue d'ensemble

**Lock Game** est un jeu mobile de réflexion et de logique développé en Flutter pour Android, iOS et Web (optionnel). L’objectif est de déverrouiller un cadenas en résolvant des énigmes chiffrées variées, au sein d’une interface immersive, épurée et stimulante.

---

## Table des matières

1. [Technologies & Architecture](#technologies--architecture)
2. [Structure du projet](#structure-du-projet)
3. [Fonctionnalités principales](#fonctionnalités-principales)
4. [Structure des données](#structure-des-données)
5. [Installation & Exécution](#installation--exécution)
6. [Flux de travail pour GPT CodeX](#flux-de-travail-pour-gpt-codex)
7. [Tests & Qualité](#tests--qualité)
8. [Contribution](#contribution)
9. [Licence](#licence)

---

## Technologies & Architecture

- **Flutter** (Android, iOS, Web)
- **Firebase**
  - Authentication : Google, Apple, anonyme (sans email/mot de passe)
  - Firestore : progression, points, achat no-ads
- **Monétisation**
  - Google AdMob : bannières, interstitiels, vidéos récompensées
  - In-App Purchase (IAP) : suppression des publicités
- **Stockage local** : SharedPreferences

**Architecture** :
- **Presentation** : Widgets Flutter, responsive UI, thème clair/sombre
- **Logic** : Business logic in Providers / Bloc
- **Data** : Repositories encapsulant Firestore et JSON local
- **Configuration** : variables d’environnement (.env) pour clés Firebase & AdMob

---

## Structure du projet

```
/lib
  /main.dart           # Entrée de l’application
  /config              # Chargement .env, constantes
  /models              # Définitions des données et JSON parsing
  /services            # FirebaseAuth, Firestore, AdMob, IAP
  /providers           # Gestion d’état (Provider / Bloc)
  /screens
    home_screen.dart
    level_selector.dart
    game_screen.dart
    settings_screen.dart
    tutorial_screen.dart
  /widgets             # Composants réutilisables
/assets
  /levels.json         # Définition des niveaux
  /images              # Logos et icônes

/android, /ios         # Config natives
/pubspec.yaml          # Dépendances et assets

```

---

## Fonctionnalités principales

1. **Authentification**
   - Google, Apple, Anonyme (sans mot de passe)
   - Progression synchronisée par compte

2. **Écran d’accueil**
   - Logo, points, boutons : Commencer, Comment jouer, Paramètres

3. **Sélecteur de niveaux**
   - Grille 1–100 avec états : joué, débloqué, verrouillé
   - Chargement dynamque via levels.json / Firestore

4. **Écran de jeu**
   - Affiche l’énigme (1–3 phrases)
   - Cases de saisie dynamiques + clavier numérique
   - Gestion de la validation et de l’aide (–20 points)

5. **Énigmes & niveaux**
   - 100 énigmes variées : logiques, culturelles, historiques, sportives, combinaisons
   - JSON modifiable ou Firestore dynamic

6. **Système de points**
   - +10 points par réussite
   - –20 points pour aide
   - Suggestion pub / achat si points insuffisants

7. **Publicités**
   - Bannière, Interstitiel (tous les 5 niveaux), Rewarded (+20 points)
   - IAP unique pour désactiver

8. **Paramètres**
   - Déconnexion, musique (future option), support développeur

9. **Tutoriel**
   - Guide du concept, cadenas, points, pubs et soutien

---

## Structure des données

**levels.json**
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

## Installation & Exécution

```bash
# Cloner le dépôt
git clone https://github.com/<utilisateur>/lock-game.git
cd lock-game

# Installer dépendances
flutter pub get

# Copier .env.example en .env et compléter les clefs
cp .env.example .env

# Configurer Firebase
#   - Android: android/app/google-services.json
#   - iOS: ios/Runner/GoogleService-Info.plist

# Lancer en mode debug
flutter run

# Générer build release
flutter build apk --release
flutter build ios --release
``` 

---

## Flux de travail pour GPT CodeX

Pour maximiser l’efficacité de l’agent GPT CodeX :

1. **Prompt explicite** : décrire la tâche (ex. : « Génère le service `AuthService` avec méthodes »)
2. **Contextualisation** : pointer vers la structure (`/lib/services/auth_service.dart`)
3. **Spécifications** : lister entrées, sorties, erreurs à gérer
4. **Tests unitaires** : inclure exemples d’appels et résultats attendus
5. **Revue** : valider la cohérence avec l’architecture et les conventions


---

## Tests & Qualité

- Tests unitaires : `/test/models`, `/test/services`, `/test/providers`
- Linter : `flutter analyze`
- Formatage : `flutter format .`

---

## Contribution

Merci de suivre ce workflow :
1. Créer une branche feature/XXX
2. Développer et tester localement
3. Ouvrir une Pull Request en décrivant les changements
4. Lint et tests verts requis avant merge

---

## Licence

Ce projet est sous licence MIT. Voir le fichier [LICENSE](LICENSE) pour plus de détails.
