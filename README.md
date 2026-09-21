# MyPulse

Une application mobile (Android, V1) pour deux personnes liées, qui permet d'envoyer des **signes d'attention rapides et sans obligation de réponse**, sans que ça devienne une messagerie classique.

Voir [docs/PRODUCT_SPEC.md](docs/PRODUCT_SPEC.md) pour la spécification produit complète de la V1, et
[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) pour l'architecture technique (Firestore, règles de sécurité,
Cloud Functions).

## Structure du repo

- `app/` — application Flutter (voir [app/README.md](app/README.md))
- `functions/` — Cloud Functions (sendSignal, pairing)
- `firestore.rules`, `firestore.indexes.json` — règles et index Firestore
