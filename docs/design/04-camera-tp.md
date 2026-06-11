# Design 04 — Caméra troisième personne suivant le joueur

## Pitch (1 phrase)

Une `Camera3D` portée par un bras rigide de 6 m suit le joueur (ou tout autre cible désignée) en se positionnant toujours derrière et légèrement au-dessus, dans le style classique GTA troisième personne.

## Pourquoi cette feature (valeur joueur)

Avec la caméra fixe de la feature 02, le joueur perd son personnage de vue dès qu'il s'éloigne de l'origine. La caméra TP corrige cela : le personnage est toujours cadré, le joueur sait où il va, et la sensation d'habiter un corps dans un monde ouvert commence réellement. C'est le socle perceptif de toutes les features suivantes (ville, voiture, conduite).

## Description détaillée

### Architecture générale

Un nœud `Node3D` nommé `CameraRig` porte la `Camera3D`. Le `CameraRig` est instancié dans `main.tscn` comme nœud de niveau racine (enfant direct de la scène, pas enfant du joueur). Son script GDScript (`camera_rig.gd`) lit chaque frame la position de sa propriété `target` et se positionne en conséquence.

Découpler le rig du joueur (ne pas en faire un enfant direct) présente deux avantages :
1. L'interpolation de position peut être appliquée librement sans héritage de transform.
2. La cible est interchangeable sans modifier la hiérarchie de scène — la feature 07 (entrée en voiture) n'aura qu'à affecter `camera_rig.target = vehicle_node`.

### Propriété `target`

```gdscript
@export var target : Node3D
```

La propriété est exportée pour pouvoir être assignée dans l'éditeur Godot et depuis d'autres scripts. Par défaut, elle pointe sur le nœud `Player` de `main.tscn`. Quand `target` est `null`, la caméra ne bouge pas (fail-safe).

### Position de la caméra

La caméra se place à un décalage fixe par rapport à la position de la cible :

| Axe | Décalage | Justification |
|-----|----------|---------------|
| Horizontal (derrière) | −6 m sur l'axe avant local de la cible | Distance typique GTA TP — personnage visible en pied |
| Vertical (hauteur) | +3 m | Légère plongée vers le bas — lisibilité du sol et des obstacles devant |
| Latéral | 0 m | Axe centré, symétrie gauche/droite |

Le décalage est exprimé dans le **repère monde** à ce stade (feature 04). Comme il n'y a pas encore de contrôle de caméra par la souris, la caméra regarde toujours depuis un point fixe par rapport à l'orientation du monde : derrière = axe +Z monde (le joueur spawn face à -Z). La caméra se place donc à `target.position + Vector3(0, 3, 6)`.

> Note pour la feature future de rotation souris : le décalage devra être exprimé dans un espace sphérique (pivot + pitch/yaw). La propriété `target` restera identique. Seule la logique de calcul du décalage changera.

### Orientation de la caméra

La `Camera3D` appelle `look_at(target.position + Vector3(0, 1.6, 0))` chaque frame pour pointer vers la tête approximative de la cible (origine + 1.6 m en Y, soit la hauteur des yeux pour un personnage de 1.8 m).

### Mode de suivi : rigide (pas d'interpolation)

Choix retenu pour le prototype : suivi **rigide** (la caméra copie exactement la position calculée à chaque `_process`).

Justification : l'interpolation (lerp) introduit un décalage perceptible entre personnage et caméra qui peut désorienter sur un prototype sans animations. Le suivi rigide garantit que la caméra est toujours exactement derrière le joueur, quelle que soit la vitesse. Si le résultat est trop mécanique lors des tests joueur, un léger `lerp` (facteur 0.2) pourra être ajouté en une ligne sans changer l'architecture.

### Remplacement de la caméra fixe (feature 02)

La `Camera3D` définie dans la feature 02 à la position `Vector3(0, 8, 15)` est **retirée de `main.tscn`**. Elle est remplacée par le nœud `CameraRig` (Node3D + script `camera_rig.gd`) qui porte sa propre `Camera3D` enfant (`current = true`).

Cette suppression est explicitement documentée dans la spec technique (feature 04) et dans `main.tscn` via un commentaire de suppression.

### Compatibilité feature 07 (entrée/sortie véhicule)

Quand le joueur monte dans une voiture (feature 07), le script de gestion du véhicule appelle :

```gdscript
camera_rig.target = vehicle_node
```

Quand le joueur sort de la voiture :

```gdscript
camera_rig.target = player_node
```

Aucune autre modification du script `camera_rig.gd` n'est nécessaire. Le décalage de suivi (position + orientation) est identique pour le joueur et la voiture à ce stade — une feature de conduite pourra éventuellement ajuster le `offset` via une propriété exportée distincte.

### Résumé de la structure du nœud

```
main.tscn
├── ...
├── Player (CharacterBody3D)          ← feature 03, inchangé
└── CameraRig (Node3D)                ← feature 04, nouveau
    ├── script : res://src/camera/camera_rig.gd
    └── Camera3D
          current = true
```

## Contrôles / inputs

Aucune touche n'est associée à la caméra dans cette feature. La caméra est entièrement passive — elle réagit à la position de sa cible, pas à des inputs joueur.

| Action | Touche | Effet |
|--------|--------|-------|
| (aucune) | — | La caméra suit automatiquement la cible |

> La rotation de caméra à la souris est hors périmètre de cette feature.

## Feedback joueur

### Visuel

- Dès le lancement, le personnage est visible au centre de l'écran, cadré depuis derrière et légèrement en hauteur.
- Quand le joueur appuie sur une touche directionnelle, le personnage se déplace et la caméra suit instantanément (suivi rigide) — le personnage reste toujours centré à l'écran.
- Comme la caméra regarde toujours `target.position + Vector3(0, 1.6, 0)`, le sol devant le personnage est visible, ce qui aide à anticiper les obstacles.

### Sonore

Aucun son associé à la caméra.

### Mouvement de caméra

Suivi rigide à chaque frame : la caméra ne tremble pas, ne rebondit pas. Si le personnage saute à l'avenir, la caméra montera et descendra avec lui. C'est le comportement attendu pour le proto.

## Règles et limites

| Paramètre | Valeur | Raison |
|-----------|--------|--------|
| Distance horizontale (arrière) | 6 m | Visibilité pied-tête du personnage + portion de sol devant lui |
| Hauteur | 3 m | Légère vue en plongée — lisibilité du sol |
| Décalage latéral | 0 m | Centré, symétrie neutre pour le proto |
| Point visé | `target.position + Vector3(0, 1.6, 0)` | Hauteur des yeux d'un personnage de 1.8 m |
| Mode de suivi | rigide (`_process`, pas de lerp) | Réactivité maximale pour le proto |
| Cible par défaut | nœud `Player` de `main.tscn` | Seule entité présente à ce stade |
| Cible changeable | oui, propriété `@export var target : Node3D` | Prépare feature 07 |
| FOV | 75° (valeur par défaut Godot Camera3D) | Valeur neutre, à ajuster en polish |
| Near clip | 0.05 m (valeur par défaut Godot) | Évite le clipping sur objets proches |
| Far clip | 300 m (valeur par défaut Godot) | Suffisant pour la ville minimale proto |
| `_process` vs `_physics_process` | `_process` | La caméra est visuelle, pas physique — évite le jitter de l'interpolation physique |

## Dépendances de design

- **Feature 01 — Bootstrap** : fournit `project.godot` et le nœud racine de `main.tscn`.
- **Feature 02 — Scène 3D minimale** : fournit la `Camera3D` fixe que cette feature retire et remplace.
- **Feature 03 — Personnage joueur** : fournit le nœud `Player` (`CharacterBody3D`) qui sera la cible initiale du rig.

## Hors-périmètre

- Rotation de la caméra à la souris (pivot orbital, pitch/yaw) : feature future.
- Zoom (molette souris) : feature future.
- Collision de caméra (éviter que la caméra traverse les murs) : hors proto v0.1.
- Effet de secousse (camera shake) : hors proto v0.1.
- Champ de vision dynamique (FOV dynamique à grande vitesse) : hors proto v0.1.
- Transition animée lors du changement de cible (fondu, cut) : hors proto v0.1.
- Cible multiple / split-screen : hors périmètre total.
