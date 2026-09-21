# MyPulse — Spécification produit V1

## Concept en une phrase
Une application mobile (Android, V1) pour deux personnes liées (un couple, ou plus largement deux personnes — pas de restriction de genre), qui permet d'envoyer des **signes d'attention rapides et sans obligation de réponse**, sans que ça devienne une messagerie classique.

## Le problème résolu
- Sur WhatsApp/iMessage, envoyer un petit signe d'attention ("je pense à toi", un cœur) **crée une obligation sociale de réponse** et se noie dans le reste de la conversation. Ça devient lourd à gérer au quotidien.
- Snapchat n'est pas un bon modèle de référence : il repose sur la création de contenu (photo), ce qui réintroduit de la friction — ce n'est pas ce qu'on veut.
- **Life360 est le vrai modèle d'inspiration** : c'est de l'information ambiante/passive (voir où est l'autre) sans obligation de réagir. C'est exactement le mécanisme à reproduire : un signal reçu = une info reçue, pas une conversation ouverte.

## Règle d'or (à appliquer à chaque décision produit)
**Chaque signal reçu ne doit générer aucune pression de réciprocité.** Si une fonctionnalité fait que l'utilisateur se sent mal de ne pas avoir répondu à un signal, c'est qu'on a recréé WhatsApp — donc c'est à éviter absolument.

## Ligne rouge identitaire
L'app ne doit **jamais devenir un outil de conversation** (pas de chat, pas de fil de discussion). C'est la limite à ne jamais franchir, quelle que soit la fonctionnalité envisagée.

---

## Fonctionnalités V1 (à développer)

### 1. Signaux prédéfinis (templates)
- L'utilisateur envoie un signal d'attention via des **templates prédéfinis uniquement** — pas de texte libre.
- Exemples de signaux : cœur, "je t'aime", "tu me manques", etc. (liste précise à définir dans une étape suivante).
- Le signal envoyé déclenche une **notification bien visible** chez le destinataire (façon "whiz"/notification forte, pas un simple message discret).
- Le destinataire peut, s'il le souhaite, répondre avec un signe d'attention en retour — mais ce n'est jamais obligatoire ni attendu.

### 2. Pas de texte libre en V1
- Décision actée : on **n'inclut pas** de champ de texte libre, même limité en caractères, pour éviter tout risque de dérapage (message négatif/agressif) et rester cohérent avec l'identité "pas une messagerie".
- Cette fonctionnalité (texte libre limité, pour exprimer quelque chose après coup, jamais en plein conflit) est repoussée en V2 éventuelle, à valider seulement si le besoin est confirmé par les utilisateurs.

### 3. Anti-spam par cooldown (pas de limite quotidienne)
- Pas de quota strict du type "10 signaux par jour" (jugé trop arbitraire/frustrant).
- À la place : un **cooldown court entre deux envois** (de l'ordre de 5 secondes), sur le modèle de Life360, pour empêcher d'envoyer 40 signaux d'affilée sans pour autant limiter l'usage naturel dans la journée.

### 4. Statistiques globales uniquement (pas de comparaison individuelle)
- Décision actée et importante : **ne jamais afficher de comparaison chiffrée entre les deux partenaires** (jamais de "toi : 12 signaux / elle : 2 signaux").
- Les statistiques doivent être présentées **de manière globale, au niveau du couple** (ex: "vous vous êtes envoyé X signaux cette semaine"), jamais individualisées ni comparées.
- Raison : éviter que l'app révèle ou creuse un déséquilibre affectif entre les deux partenaires (asymétrie d'usage naturelle dans beaucoup de couples).

### 5. Mode silencieux
- Un partenaire peut activer un mode silencieux (ex: réunion, sommeil) : les signaux reçus s'accumulent sans déclencher de notification immédiate.

### 6. Pairing simple entre deux comptes
- Système de liaison entre les deux téléphones via un **code à 6 chiffres** (ou QR code), simple et rapide.
- Pas de restriction de genre dans le pairing : "deux personnes liées", point (pas spécifiquement "homme et femme").

### 7. Notifications push fiables
- Élément critique du produit : les signaux doivent arriver de façon fiable et quasi instantanée (Firebase Cloud Messaging recommandé côté technique).

---

## Fonctionnalités explicitement repoussées à une V2 éventuelle (à ne PAS développer en V1)

- **Texte libre limité** pour exprimer quelque chose après coup (ex: après une tension, pouvoir formuler un mot sans que ce soit dans le feu de l'action) — decision : à réévaluer plus tard, pas en V1.
- **Signaux personnalisés** (au-delà des templates prédéfinis) — l'utilisateur pourra un jour créer ses propres signes avec emoji + mot custom, mais pas en V1.
- **Widget sur l'écran d'accueil** pour envoi rapide sans ouvrir l'app — jugé utile mais explicitement repoussé, pas en V1.
- **Messages programmés** (envoi différé) — évoqué puis explicitement écarté de la V1 par le porteur de projet.

## Fonctionnalités explicitement écartées (à ne PAS développer du tout, décision ferme)

- **Rappels utilitaires** (ex: "n'oublie pas tes médicaments", "sors les poubelles") — écarté car ça sort du concept émotionnel/affectif de l'app et risquerait de diluer son identité en la mélangeant avec de la logistique de couple.
- **Toute forme de chat/conversation/fil de discussion** — ligne rouge absolue, jamais.
- **Toute comparaison chiffrée entre partenaires dans les stats** — ligne rouge absolue.

---

## Contraintes techniques et de plateforme
- **V1 : Android uniquement** (natif ou Flutter à décider — Flutter recommandé si on veut faciliter un portage iOS futur sans tout refaire).
- **Backend simple suffisant pour V1** : Firebase (Firestore + Firebase Cloud Messaging pour les notifications push) recommandé, pas besoin d'un backend custom complexe au démarrage.
- **Pairing** : système de code à 6 chiffres (ou QR code) pour lier les deux comptes/téléphones.

---

## Nom de l'application
- **Nom retenu : MyPulse**
- Point de vigilance soulevé (non vérifié, pas de recherche web effectuée) : le nom "Pulse"/"MyPulse" est potentiellement déjà utilisé par d'autres applications, notamment dans le domaine santé/fitness (trackers cardiaques, bien-être).
- **Action à faire avant de s'engager définitivement** : vérifier la disponibilité du nom de package Android (type `com.nomdedeveloppeur.mypulse`) et la disponibilité du nom exact sur le Google Play Store, et envisager un dépôt de nom si développement à long terme.

---

## Étapes suivantes non encore traitées (à faire avec Claude Code ou en continuité)
1. Définir la **liste précise des signaux prédéfinis** de la V1 (combien de signaux, lesquels exactement, avec quelles icônes/couleurs associées).
2. Concevoir le **prototype de l'écran principal** (bouton d'envoi des signaux + historique des échanges + affichage des notifications reçues).
3. Concevoir l'**écran de pairing** (saisie/génération du code à 6 chiffres).
4. Décider du choix technique définitif : Flutter vs Android natif (Kotlin).
5. Mettre en place l'architecture Firebase (Firestore pour les données, FCM pour les notifications push).
