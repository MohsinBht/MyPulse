# MyPulse — app Flutter

Les 6 écrans clés (accueil, choix de jumelage, générer un code, entrer un code, liaison réussie, réglages) plus
l'onboarding, branchés sur les Cloud Functions et Firestore décrits dans `../docs/ARCHITECTURE.md`. Le dossier
`android/` est généré (`flutter create --platforms android`) ; `flutter analyze` et `flutter test` passent sans
erreur.

**Identité V1** : pas de mot de passe — un compte Firebase Auth anonyme est créé au premier lancement, l'utilisateur
choisit juste un prénom (`lib/screens/welcome_screen.dart`). Compromis assumé : désinstaller l'app ou changer de
téléphone fait perdre le compte, pas de récupération en V1.

Il manque encore, pour tourner sur un vrai téléphone :
- Un projet Firebase réel (console.firebase.google.com) — nécessite un compte Google, je ne peux pas le créer à ta
  place.
- `firebase_options.dart`, généré par `flutterfire configure` une fois ce projet créé et lié.

## Démarrer (une fois le projet Firebase créé)

```sh
flutterfire configure          # génère lib/firebase_options.dart, lie ce dossier au projet Firebase
flutter pub get
flutter run
```

Backend (une seule fois, depuis la racine du repo) :

```sh
firebase deploy --only firestore:rules,firestore:indexes,functions
```

## Ce qui est implémenté

- `lib/models/signal_template.dart` — les 6 signaux prédéfinis, aucun texte libre.
- `lib/services/` — auth anonyme + prénom, appels aux Cloud Functions (`sendSignal`, `generatePairingCode`,
  `redeemPairingCode`), lecture Firestore (compteur du couple, historique, préférences).
- `lib/screens/` — les 6 écrans + l'onboarding, navigables entre eux (contrairement aux mockups statiques).
- Le cooldown anti-spam grise les **6** boutons de signal en même temps, jamais un seul — cohérent avec la règle
  "pas de quota, un court cooldown après *tout* envoi".

## Pas encore fait

- `ios/` natif (si un portage iOS est décidé plus tard).
- Écran de confirmation avant de délier un couple ("Gérer" en Réglages).
- Rendu de la notification push reçue (dépend du provider de notifications système, hors scope Flutter pur).
- Récupération de compte (changement de téléphone) — hors scope tant que l'auth reste anonyme.
