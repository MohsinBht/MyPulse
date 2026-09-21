# MyPulse — app Flutter

Scaffold V1 : les 6 écrans clés (accueil, choix de jumelage, générer un code, entrer un code, liaison réussie,
réglages), branchés sur les Cloud Functions et Firestore décrits dans `../docs/ARCHITECTURE.md`.

Ce scaffold suppose un `FirebaseApp` déjà configuré (`flutter create .` régénère les dossiers `android/`, `ios/`
natifs manquants, puis `flutterfire configure` génère `firebase_options.dart`) et un utilisateur déjà authentifié —
le choix du mode d'authentification (email, téléphone, Google...) n'est pas encore tranché dans la spec.

## Démarrer

```sh
flutter create . --platforms android
flutterfire configure
flutter pub get
flutter run
```

## Ce qui est implémenté

- `lib/models/signal_template.dart` — les 6 signaux prédéfinis, aucun texte libre.
- `lib/services/` — appels aux Cloud Functions (`sendSignal`, `generatePairingCode`, `redeemPairingCode`) et lecture
  Firestore (compteur du couple, historique, préférences).
- `lib/screens/` — les 6 écrans, navigables entre eux (contrairement aux mockups statiques).
- Le cooldown anti-spam grise les **6** boutons de signal en même temps, jamais un seul — cohérent avec la règle
  "pas de quota, un court cooldown après *tout* envoi".

## Pas encore fait

- Authentification (choix du provider).
- `android/`, `ios/` natifs et `firebase_options.dart` (générés par les commandes ci-dessus, pas commités).
- Écran de confirmation avant de délier un couple ("Gérer" en Réglages).
- Rendu de la notification push reçue (dépend du provider de notifications système, hors scope Flutter pur).
