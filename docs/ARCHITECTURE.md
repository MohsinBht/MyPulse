# MyPulse — Architecture technique V1

Stack retenue : **Flutter** (client Android V1, portage iOS facilité) + **Firebase** (Firestore + Cloud Functions + FCM).

Principe directeur : le client ne fait jamais confiance à lui-même pour les règles qui protègent l'esprit du produit
(cooldown anti-spam, stats jamais individualisées). Tout ce qui doit être infalsifiable passe par une Cloud Function ;
Firestore refuse l'écriture directe sur ces chemins.

## Modèle de données Firestore

```
users/{uid}
  displayName: string
  coupleId: string | null
  fcmTokens: string[]          // un ou plusieurs appareils
  silentMode: boolean          // "mode silencieux" (réglages)
  soundEnabled: boolean
  createdAt: timestamp

couples/{coupleId}
  memberUids: [uidA, uidB]     // exactement 2, jamais plus
  totalSignals: number         // compteur agrégé, AU NIVEAU DU COUPLE UNIQUEMENT
  createdAt: timestamp

couples/{coupleId}/signals/{signalId}
  senderUid: string
  templateId: string           // un des 6 templates prédéfinis, jamais de texte libre
  sentAt: timestamp            // server timestamp

pairingCodes/{code}            // code à 6 chiffres, clé du document = le code
  creatorUid: string
  createdAt: timestamp
  expiresAt: timestamp         // createdAt + 10 min
  used: boolean
```

Pas de champ de comparaison par personne nulle part (ex : jamais de `signalsSentByUser`). Le seul compteur exposé au
client est `couples/{coupleId}.totalSignals` — c'est une contrainte de schéma qui rend la ligne rouge "pas de
comparaison chiffrée" difficile à violer par accident côté client.

Les 6 templates (`Cœur`, `Je t'aime`, `Tu me manques`, `Pensée pour toi`, `Câlin`, `Bisou`) sont codés en dur côté
client (`SignalTemplate` dans `lib/models/signal_template.dart`) — pas besoin d'une collection Firestore pour une
liste fixe en V1.

## Règles de sécurité Firestore (`firestore.rules`)

- `users/{uid}` : lecture/écriture uniquement par `uid` lui-même ; un membre du couple peut lire le `displayName` de
  son/sa partenaire (pas le reste).
- `couples/{coupleId}` : lecture par ses deux `memberUids` uniquement. **Aucune écriture cliente** — `totalSignals`
  n'est incrémenté que par la Cloud Function `sendSignal`, jamais par le client directement (sinon un client modifié
  pourrait gonfler ou comparer les compteurs).
- `couples/{coupleId}/signals/{signalId}` : lecture par les deux membres. **Aucune écriture cliente directe** — c'est
  la garantie serveur du cooldown : si le client pouvait écrire un signal lui-même, il pourrait contourner l'anti-spam
  côté app. Seule la Cloud Function `sendSignal` (Admin SDK, bypasse les règles) écrit ici.
- `pairingCodes/{code}` : lecture désactivée côté client (pas besoin, tout passe par les Cloud Functions) ; écriture
  désactivée aussi. Génération et rédemption exclusivement via `generatePairingCode` / `redeemPairingCode`.

## Cloud Functions

### `sendSignal` (callable, authentifié)
Entrée : `{ templateId }`. Le `coupleId` est lu depuis `users/{uid}`, jamais transmis par le client.

1. Vérifie que `templateId` fait partie de la liste des 6 templates valides (rejette sinon).
2. Lit le dernier signal envoyé par cet utilisateur dans son couple (`signals` triés par `sentAt desc`, `senderUid ==
   uid`, `limit(1)`). Si `now - lastSentAt < 5s` → rejette avec `failed-precondition` (c'est le cooldown anti-spam
   de la spec — pas de quota journalier, juste cet intervalle court).
3. Écrit le document `signals` et incrémente `couples/{coupleId}.totalSignals` (transaction).
4. Lit `users/{partnerUid}.silentMode` :
   - `false` → envoie une notification FCM "bien visible" (high-priority, son) à tous les `fcmTokens` du partenaire.
   - `true` → n'envoie **aucune** notification push ; le signal existe déjà dans Firestore, donc il apparaîtra dans
     "Échanges récents" dès que le partenaire rouvre l'app (c'est la définition du mode silencieux : accumulation
     silencieuse, pas de perte de signal).

### `generatePairingCode` (callable, authentifié)
1. Génère un code à 6 chiffres aléatoire, vérifie qu'aucun document `pairingCodes/{code}` actif (non expiré, non
   utilisé) n'existe déjà avec ce code — sinon retire et retente.
2. Crée `pairingCodes/{code}` avec `expiresAt = now + 10min`.
3. Retourne le code au client.

### `redeemPairingCode` (callable, authentifié)
Entrée : `{ code }`.

1. Lit `pairingCodes/{code}`. Rejette si absent, `used == true`, ou `expiresAt < now`.
2. Rejette si l'appelant est le créateur du code (on ne se jumelle pas à soi-même) ou si l'un des deux comptes a déjà
   un `coupleId`.
3. Transaction : crée `couples/{coupleId}` avec les deux `memberUids`, met à jour `users/{uid}.coupleId` pour les deux
   comptes, marque le code `used: true`.

### `cleanupExpiredPairingCodes` (scheduled, toutes les heures)
Supprime les documents `pairingCodes` expirés et non utilisés — évite l'accumulation, pas de logique métier dedans.

## Notifications (FCM)

- Priorité haute + son, comme demandé ("façon whiz") — sauf mode silencieux actif chez le destinataire.
- Payload minimal : `{ type: "signal", templateId, senderName }` — jamais de contenu libre, cohérent avec l'absence
  de texte libre dans le produit.
- Un appareil qui reçoit peut afficher l'icône/label du template directement depuis le payload (pas de round-trip
  Firestore nécessaire pour afficher la notification).

## Pourquoi ce découpage

Le risque produit central de MyPulse n'est pas technique, c'est que l'app dérive vers une messagerie ou une pression
de réciprocité. Deux garde-fous sont donc mis **côté serveur**, pas seulement dans l'UI Flutter :
1. Le cooldown est vérifié par `sendSignal`, pas seulement désactivé visuellement dans l'app (un écran modifié ou une
   requête rejouée ne peut pas le contourner).
2. `couples/{coupleId}.totalSignals` est le seul compteur exposé, et les règles Firestore empêchent un client de lire
   ou fabriquer un compteur par personne — la ligne rouge "jamais de comparaison chiffrée" est donc aussi une
   contrainte de schéma, pas juste une convention d'UI.
