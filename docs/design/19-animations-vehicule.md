# Design 19 — Animations véhicule

## Pitch (1 phrase)

Le personnage humanoïde joue trois animations squelettales lors des transitions entrer/conduire/sortir du véhicule, rendant le va-et-vient joueur-voiture visuellement crédible sans casser la physique existante.

## Pourquoi cette feature (valeur joueur)

Depuis la feature 18, entrer et sortir d'un véhicule est fonctionnel mais abrupt : le personnage disparaît instantanément (`visible = false`) dès que le joueur presse E, sans aucune transition visuelle. La conduite elle-même est tout aussi dépouillée — la caméra se déplace mais le siège reste vide. Cette feature corrige les trois moments du cycle véhicule :

1. L'entrée (le joueur "monte") est matérialisée par une courte animation d'installation.
2. La conduite est illustrée par le personnage visible à l'intérieur de la voiture, mains au volant.
3. La sortie est ponctuée par une animation de descente avant que le personnage reprenne sa liberté.

Le résultat est un proto qui sent comme un vrai jeu : le joueur voit son avatar interagir avec le monde plutôt que de disparaître mystérieusement.

## Description détaillée

### Vue d'ensemble des trois phases

La feature couvre exactement les transitions liées au véhicule, sans toucher aux animations idle/walk (feature 10) ni à la physique VehicleBody3D (feature 18).

```
État : PIED
  │  Joueur presse E (proche voiture)
  ▼
État : ENTREE_VEHICULE  (animation "car_enter", ~1 s, bloquant les inputs déplacement)
  │  Animation terminée
  ▼
État : CONDUITE  (animation "car_drive" en boucle, personnage assis visible dans la voiture)
  │  Joueur presse E
  ▼
État : SORTIE_VEHICULE  (animation "car_exit", ~0.8 s, bloquant les inputs déplacement)
  │  Animation terminée
  ▼
État : PIED  (reprise idle/walk normale)
```

### Phase 1 — Animation d'entrée ("car_enter")

**Déclencheur** : le joueur presse E à proximité d'un véhicule alors que son état est PIED.

**Séquence** :
1. `PlayerController` passe à l'état `ENTREE_VEHICULE`.
2. Les inputs de déplacement (ZQSD/WASD) sont bloqués durant l'animation.
3. L'animation `"car_enter"` se joue une fois (non bouclée, ~1 s).
4. Pendant l'animation, le nœud `Player` reste visible et se positionne à côté de la portière (ou la logique de positionnement de la feature 18 est conservée).
5. À la fin de l'animation (`animation_finished` ou timer), `PlayerController` passe à l'état `CONDUITE`.
6. La caméra bascule sur la voiture (logique déjà implémentée en feature 18).

**Fallback (asset absent)** : si le GLB `player_car_enter.glb` n'est pas livré ou si l'animation `"car_enter"` n'existe pas dans l'`AnimationPlayer`, la transition est instantanée (comportement actuel de la feature 18 conservé à l'identique). Aucun crash.

### Phase 2 — Animation de conduite ("car_drive")

**Condition** : le joueur est dans l'état `CONDUITE`.

**Comportement** :
- Le nœud `Player` (CharacterBody3D) reste **visible** (abandon du `visible = false` de la feature 18).
- Le personnage est positionné au siège conducteur de la voiture. Sa position et orientation sont mises à jour chaque frame pour suivre la voiture (parenting ou mise à jour manuelle de la transform).
- L'animation `"car_drive"` tourne en boucle (mains sur le volant, légère oscillation du buste).
- Les inputs de conduite (WASD) restent actifs et pilotent le VehicleBody3D normalement.

**Positionnement du personnage dans la voiture** :
- Le nœud `Player` est reparenté au VehicleBody3D lors de l'entrée en état CONDUITE, ou sa position est mise à jour manuellement chaque frame via `global_transform`. La position cible est le siège conducteur : un offset constant par rapport à l'origine du VehicleBody3D, typiquement `Vector3(-0.4, 0.6, 0.3)` (côté gauche, légèrement surélevé, légèrement en avant) — valeur ajustable à l'implémentation.
- La CollisionShape3D du Player est désactivée pendant la conduite (pour éviter tout conflit physique avec le VehicleBody3D).

**Fallback (asset absent)** : si `player_car_drive.glb` n'est pas livré, le personnage reste visible mais sans animation (pose statique T-Pose ou dernière pose de l'animation d'entrée). Alternative acceptable pour le proto : le personnage est masqué (`visible = false`) comme dans la feature 18. La décision est prise à l'implémentation selon la cohérence visuelle.

### Phase 3 — Animation de sortie ("car_exit")

**Déclencheur** : le joueur presse E depuis l'état `CONDUITE`.

**Séquence** :
1. `PlayerController` passe à l'état `SORTIE_VEHICULE`.
2. Les inputs de conduite sont bloqués.
3. Le nœud `Player` est désancré du VehicleBody3D (si reparenté) et positionné à côté de la voiture, à l'emplacement de sortie.
4. L'animation `"car_exit"` se joue une fois (~0.8 s).
5. À la fin, `PlayerController` revient à l'état PIED. Les animations idle/walk reprennent normalement.
6. La CollisionShape3D du Player est réactivée.
7. La caméra rebascule sur le Player.

**Fallback (asset absent)** : si `player_car_exit.glb` n'est pas livré, la sortie est instantanée (comportement feature 18 conservé). Aucun crash.

### Gestion de l'AnimationPlayer

L'`AnimationPlayer` existant dans `scenes/player/player.tscn` (feature 10) est étendu avec trois nouvelles pistes d'animation :

| Nom de l'animation | Source GLB | Boucle | Durée approx. |
|-------------------|------------|--------|----------------|
| `"car_enter"` | `player_car_enter.glb` | non | ~1.0 s |
| `"car_drive"` | `player_car_drive.glb` | oui | ~2.0 s |
| `"car_exit"` | `player_car_exit.glb` | non | ~0.8 s |

Les animations existantes `"idle"` et `"walk"` sont inchangées.

### Priorité d'animation

L'`AnimationPlayer` ne joue qu'une animation à la fois. La logique de priorité dans `player_controller.gd` :

1. Si état `ENTREE_VEHICULE` : jouer `"car_enter"` (bloque idle/walk).
2. Si état `CONDUITE` : jouer `"car_drive"` en boucle.
3. Si état `SORTIE_VEHICULE` : jouer `"car_exit"`.
4. Si état `PIED` : reprendre idle/walk selon le mouvement (logique feature 10 inchangée).

## Contrôles / inputs

| Touche / Action | Effet |
|-----------------|-------|
| E (à pied, proche véhicule) | Déclenche animation `"car_enter"` puis passage à l'état CONDUITE |
| ZQSD / WASD (pendant `"car_enter"`) | Bloqués — pas de déplacement pied pendant l'animation d'entrée |
| WASD (état CONDUITE) | Conduite normale du VehicleBody3D (feature 18 inchangée) |
| E (état CONDUITE) | Déclenche animation `"car_exit"` puis retour à l'état PIED |
| ZQSD / WASD (pendant `"car_exit"`) | Bloqués — pas de déplacement pied pendant l'animation de sortie |
| Tous inputs déplacement (état PIED après sortie) | Reprise normale (feature 03 / 12 inchangées) |

## Feedback joueur

### Visuel

- **Entrée** : le personnage joue une animation de 1 s où il ouvre la portière (ou s'installe), puis la caméra glisse vers la voiture. L'action est lisible et confirme que "monter en voiture" s'est bien passé.
- **Conduite** : le personnage est visible assis dans la voiture, les mains sur un volant imaginaire (ou le volant du mesh de voiture si celui-ci en dispose). Une légère oscillation du buste suit les virages (animation boucle — pas de blend avec la physique en proto v0.1).
- **Sortie** : le personnage descend visuellement avant de se retrouver à pied. La continuité spatiale est respectée (il réapparaît à côté de la portière, pas en l'air).

### Sonore

Aucun son ajouté par cette feature. Les sons de portière (feature ultérieure) sont hors périmètre.

### Mouvement de caméra

Le basculement de caméra joueur ↔ voiture est déjà implémenté en feature 18 et reste inchangé. Cette feature n'ajoute pas de mouvement de caméra spécifique aux animations.

## Règles et limites

| Paramètre | Valeur | Raison |
|-----------|--------|--------|
| Durée animation d'entrée | ~1.0 s | Assez court pour ne pas frustrer, assez long pour être lisible |
| Durée animation de conduite | ~2.0 s (boucle) | Cycle de boucle discret |
| Durée animation de sortie | ~0.8 s | Plus rapide que l'entrée, sortie d'urgence ressentie |
| Inputs déplacement pied bloqués | pendant `"car_enter"` et `"car_exit"` uniquement | Cohérence de l'animation |
| Inputs conduite bloqués | pendant `"car_exit"` uniquement | Le joueur ne doit pas accélérer en sortant |
| Positionnement siège conducteur | offset `Vector3(-0.4, 0.6, 0.3)` par rapport à VehicleBody3D origin | Ajustable à l'implémentation |
| CollisionShape3D Player | désactivée pendant CONDUITE | Évite les conflits physique Player ↔ VehicleBody3D |
| Fallback si GLB absent | transition instantanée (comportement feature 18) | Le jeu reste lançable et jouable |
| Blend d'animations | aucun (transitions instantanées) | Simplicité proto |
| AnimationTree | non utilisé | Hors proto v0.1 |
| Conflit de caméra | non géré — logique feature 18 inchangée | Hors périmètre |

## Dépendances de design

- **Feature 10 — Personnage 3D Mixamo** : fournit `scenes/player/player.tscn` avec l'`AnimationPlayer`, le mesh humanoïde GLB et les animations idle/walk. La feature 19 étend cet `AnimationPlayer`.
- **Feature 18 — Refonte complète du véhicule** : fournit la logique d'entrée/sortie (touche E), le VehicleBody3D, la gestion de la caméra en mode conduite. La feature 19 s'insère dans cette logique sans la réécrire.

## Hors-périmètre

- Sons de portière, d'assise, de ceinture : hors proto v0.1.
- Animation de démarrage du moteur séparée : hors proto v0.1.
- Blend d'animations (AnimationTree) : hors proto v0.1.
- Oscillation du personnage synchronisée avec la physique réelle du véhicule (roulis, tangage) : hors proto v0.1.
- Passagers (siège passager, banquette arrière) : hors proto v0.1.
- Animation spécifique pour entrer côté passager : hors proto v0.1.
- Véhicule intérieur modélisé (volant 3D, tableau de bord interactif) : hors proto v0.1.
- PNJ animés en voiture : hors proto v0.1.
