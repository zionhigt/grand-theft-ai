# Spec 04 — Caméra troisième personne suivant le joueur

## Contexte

- Design : `docs/design/04-camera-tp.md`
- Bon de commande graphique : `docs/assets/04-camera-tp.md` — aucun asset graphique (n/a)
- Dépendances de specs précédentes :
  - **Spec 01 — Bootstrap projet** (`docs/specs/01-bootstrap.md`) : fournit `project.godot` et `main.tscn` (nœud racine `Main : Node3D`).
  - **Spec 02 — Scène 3D minimale** (`docs/specs/02-scene-3d-minimale.md`) : fournit la `Camera3D` fixe (position `Vector3(0, 8, 15)`, `current = true`) héritée dans `main.tscn`. Cette feature 04 **retire** ce nœud et le remplace par `CameraRig`.
  - **Spec 03 — Personnage joueur** (`docs/specs/03-personnage-joueur.md`) : fournit le nœud `Player : CharacterBody3D` dans `main.tscn`, dont la position mondiale constitue la cible de suivi. `PlayerController` est indépendant — aucune modification de son script.

## Objectif fonctionnel

Remplacer la caméra fixe héritée de la feature 02 par un rig de suivi rigide : un `Node3D` nommé `CameraRig`, portant un script `CameraController`, se positionne chaque frame à `target.position + OFFSET` et oriente sa `Camera3D` enfant vers la tête de la cible. La cible est interchangeable via une propriété exportée, ce qui prépare la feature 07 (entrée en véhicule) sans modifier l'architecture.

## Arborescence cible

```
.
├── main.tscn                                        # modifié — Camera3D fixe retirée, CameraRig ajouté
├── src/
│   └── camera/
│       └── camera_controller.gd                   # créé — CameraController extends Node3D
└── tests/
    └── test_04_camera_tp.gd                        # à écrire par le tester
```

Notes :
- Aucun dossier `scenes/` ni `assets/` n'est créé ou modifié par cette feature.
- Le script `src/camera/camera_controller.gd` est le seul fichier de production créé.
- `main.tscn` est modifié (pas recréé) : les nœuds hérités des features 01, 02 et 03 sont conservés ; seul le nœud `Camera3D` fixe est supprimé et remplacé par le nœud `CameraRig` instancié inline.

## Interface publique (GDScript)

### `src/camera/camera_controller.gd`

```gdscript
class_name CameraController
extends Node3D

# --- Constantes ---

const OFFSET: Vector3 = Vector3(0, 3, 6)
# Décalage monde appliqué à target.position :
#   X = 0   → centré latéralement
#   Y = +3  → 3 m au-dessus de la cible
#   Z = +6  → 6 m derrière la cible (axe +Z monde = derrière un personnage spawn face à -Z)

const EYE_HEIGHT: float = 1.6
# Hauteur du point visé au-dessus de target.position (hauteur des yeux, personnage 1.8 m)

# --- Propriétés exportées ---

@export var target: Node3D
# Nœud suivi chaque frame. Si null, la caméra ne bouge pas (fail-safe).

# --- Méthodes publiques ---

func _process(delta: float) -> void:
    # Appelée par le moteur à chaque frame de rendu.
    # Si target est null, retour immédiat sans modification de la transform.
    # Sinon :
    #   1. global_position = target.global_position + OFFSET
    #   2. $Camera3D.look_at(target.global_position + Vector3(0, EYE_HEIGHT, 0))
    pass
```

**Signatures typées complètes :**

```gdscript
class_name CameraController
extends Node3D

const OFFSET: Vector3 = Vector3(0, 3, 6)
const EYE_HEIGHT: float = 1.6

@export var target: Node3D

func _process(delta: float) -> void:
    if target == null:
        return
    global_position = target.global_position + OFFSET
    $Camera3D.look_at(target.global_position + Vector3(0, EYE_HEIGHT, 0))
```

**Notes importantes :**

- `global_position` est utilisé (et non `position`) pour être robuste en cas de rig enfant de nœuds ayant une transform propre.
- `$Camera3D` suppose que l'enfant `Camera3D` est nommé exactement `Camera3D` dans la scène — conformément à la structure décrite ci-dessous.
- Pas de `lerp` ni d'interpolation : suivi rigide exact à chaque frame.
- `delta` est reçu en paramètre de `_process` mais non utilisé à ce stade — il est conservé dans la signature pour compatibilité future (lerp optionnel).
- La propriété `target` est `@export` pour être assignable depuis l'éditeur Godot ET depuis d'autres scripts (feature 07).

## Structure des scènes (.tscn)

### `main.tscn` (modifiée)

La `Camera3D` fixe héritée de la feature 02 est **supprimée**. Le nœud `CameraRig` est ajouté comme enfant direct de `Main`, après `Player` dans l'ordre des enfants.

```
Main : Node3D                                         (nœud racine — inchangé)
│
├── WorldEnvironment : WorldEnvironment               (hérité feature 02 — inchangé)
├── DirectionalLight3D : DirectionalLight3D           (hérité feature 02 — inchangé)
├── Ground : MeshInstance3D                           (hérité feature 02 — inchangé)
├── GroundCollider : StaticBody3D                     (hérité feature 03 — inchangé)
│     └── CollisionShape3D : CollisionShape3D
├── Player : CharacterBody3D                          (hérité feature 03 — inchangé)
│     # instance de res://scenes/player/player.tscn
│
└── CameraRig : Node3D                                (nouveau — feature 04)
      script : res://src/camera/camera_controller.gd
      target : <NodePath vers Player>                 # assigné dans l'éditeur : ../Player
      │
      └── Camera3D : Camera3D
            current = true
            fov = 75.0                               # valeur par défaut Godot
            near = 0.05                              # valeur par défaut Godot
            far = 300.0                              # valeur par défaut Godot
```

**Nœud retiré :**
```
# SUPPRIMÉ (feature 04) — remplacé par CameraRig
# Camera3D : Camera3D
#   transform = Transform3D(1, 0, 0, 0, 0.882353, 0.470588, 0, -0.470588, 0.882353, 0, 8, 15)
#   current = true
```

**Notes de structure :**
- `CameraRig` est un enfant direct de `Main`, **pas** un enfant de `Player`. Le suivi est géré par script, pas par parenté.
- `target` est assigné via NodePath dans l'éditeur (`../Player`), pas par code.
- La `Camera3D` enfant de `CameraRig` a `current = true`. Il ne doit pas subsister d'autre `Camera3D` avec `current = true` dans la scène.
- Le nœud `Camera3D` enfant doit être nommé exactement `Camera3D` (correspondance avec `$Camera3D` dans le script).

## Données et constantes

Toutes les constantes de la caméra sont déclarées dans `src/camera/camera_controller.gd` et accessibles via `CameraController.<NOM>`.

| Constante | Type | Valeur | Rôle |
|---|---|---|---|
| `CameraController.OFFSET` | `Vector3` | `Vector3(0, 3, 6)` | Décalage monde : centré, +3 m en hauteur, +6 m derrière |
| `CameraController.EYE_HEIGHT` | `float` | `1.6` | Hauteur du point visé (m) — hauteur des yeux personnage 1.8 m |
| `fov` Camera3D | `float` | `75.0` | Champ de vision (degrés) — valeur par défaut Godot |
| `near` Camera3D | `float` | `0.05` | Plan de coupe proche (m) |
| `far` Camera3D | `float` | `300.0` | Plan de coupe lointain (m) |

## Comportements attendus

Chaque point est testable unitairement avec GUT dans `tests/test_04_camera_tp.gd`. Les tests B1 à B6 ne nécessitent pas de charger `main.tscn`. Les tests B7 à B10 requièrent un chargement de scène (headless admis).

**B1.** `CameraController.OFFSET == Vector3(0, 3, 6)` — la constante de classe est exactement `Vector3(0, 3, 6)`.

**B2.** `CameraController.EYE_HEIGHT == 1.6` — la constante de classe est exactement `1.6`.

**B3.** Un `CameraController` instancié (`add_child_autofree`) avec `target` laissé à `null` : appeler `_process(0.016)` ne produit aucune erreur et ne modifie pas `global_position` (la valeur reste `Vector3.ZERO`, valeur initiale).

**B4.** Un `CameraController` instancié avec une cible factice (`target` = un `Node3D` positionné à l'origine, `Vector3(0, 0, 0)`) : après `_process(0.016)`, `global_position == Vector3(0, 3, 6)` (tolérance `0.001` par composante).

**B5.** Un `CameraController` instancié avec une cible positionnée à `Vector3(10, 0, -5)` : après `_process(0.016)`, `global_position == Vector3(10, 3, 1)` — soit `target.position + OFFSET` = `(10+0, 0+3, -5+6)`.

**B6.** Un `CameraController` instancié avec une cible à `Vector3(0, 0, 0)` : après `_process(0.016)`, l'enfant `Camera3D` est orienté de sorte que son axe `-Z` local pointe vers `Vector3(0, 1.6, 0)` depuis `Vector3(0, 3, 6)`. Concrètement : `$Camera3D.global_transform.basis.z.normalized()` est approximativement l'opposé du vecteur normalisé `(Vector3(0, 1.6, 0) - Vector3(0, 3, 6)).normalized()` (tolérance `0.01` par composante).

**B7.** Un `CameraController` instancié avec une cible déplacée de `Vector3(0,0,0)` à `Vector3(5, 0, 0)` puis `_process(0.016)` appelé : `global_position == Vector3(5, 3, 6)` (la caméra suit le déplacement instantanément — pas de lerp).

**B8.** Test de scène (headless) : charger `res://main.tscn`, vérifier que `scene.get_node_or_null("CameraRig") != null` et que `scene.get_node("CameraRig") is CameraController == true`.

**B9.** Test de scène (headless) : `scene.get_node_or_null("CameraRig/Camera3D") != null` et `scene.get_node("CameraRig/Camera3D") is Camera3D == true` et `scene.get_node("CameraRig/Camera3D").current == true`.

**B10.** Test de scène (headless) : `scene.get_node_or_null("Camera3D") == null` — la caméra fixe de la feature 02 a bien été supprimée de `main.tscn` (aucun enfant direct de `Main` nommé `Camera3D`).

## Cas limites / erreurs

**CL1.** `target == null` au moment de `_process` : retour immédiat, aucune exception, aucune modification de `global_position` ni de l'orientation de `$Camera3D`. Ce cas peut se produire si la cible est libérée (queue_free) pendant le jeu.

**CL2.** Cible positionnée exactement à la même position mondiale que `CameraRig` (distance nulle) : `look_at` reçoit un point visé à `Vector3(0, EYE_HEIGHT, 0)` relatif — avec `OFFSET = Vector3(0, 3, 6)`, le point visé est toujours distinct de la position de la caméra (l'offset Y et Z non nuls garantissent l'absence de vecteur nul dans `look_at`). Aucun crash attendu.

**CL3.** `_process(0.0)` (delta nul) : aucune erreur, le suivi rigide ne dépend pas de `delta` — `global_position` et `look_at` sont calculés indépendamment du delta.

**CL4.** Deux `CameraController` dans la même scène : si deux `Camera3D` ont `current = true`, Godot activera la dernière rencontrée dans l'arbre. La spec garantit qu'une seule `Camera3D` avec `current = true` existe dans `main.tscn` après suppression de la caméra fixe feature 02.

**CL5.** `target` assigné à un nœud hors de l'arbre de scène (non ajouté avec `add_child`) : `global_position` du nœud orphelin est `Vector3(0,0,0)` par défaut — la caméra se positionne à `OFFSET` sans crash.

## Inputs Godot (Input Map)

Aucune action d'entrée n'est définie ou modifiée par cette feature. La caméra est entièrement passive.

## Assets consommés

Cette feature ne consomme aucun asset graphique. Aucun mock n'est requis.

| Chemin `res://` | Mock attendu | Usage |
|---|---|---|
| (aucun) | non | — |

## Dépendances

- **Spec 01 — Bootstrap projet** : fournit `project.godot` et `main.tscn` (nœud racine `Main : Node3D`).
- **Spec 02 — Scène 3D minimale** : fournit `main.tscn` enrichi avec la `Camera3D` fixe que cette feature retire.
- **Spec 03 — Personnage joueur** : fournit le nœud `Player : CharacterBody3D` qui sera la cible initiale du rig. `PlayerController` n'est pas modifié.
- **`addons/gut/`** : addon GUT v9.4 ou supérieur, déjà installé depuis la feature 01.
- Aucun autre addon autorisé.

## Critères d'acceptation

- [ ] Le fichier `src/camera/camera_controller.gd` est présent, `class_name CameraController` est reconnue par GDScript sans erreur de parse.
- [ ] `main.tscn` s'ouvre dans l'éditeur Godot 4.6 sans warning rouge. L'arbre affiche : `WorldEnvironment`, `DirectionalLight3D`, `Ground`, `GroundCollider`, `Player`, `CameraRig` — et **aucun** nœud `Camera3D` enfant direct de `Main`.
- [ ] L'arbre de `CameraRig` dans l'éditeur affiche : `CameraRig : Node3D` (script `camera_controller.gd`) > `Camera3D : Camera3D` (`current = true`).
- [ ] La propriété `target` de `CameraRig` est assignée au nœud `Player` dans l'éditeur (NodePath visible dans l'inspecteur).
- [ ] `godot --path . res://main.tscn` se lance sans `ERROR:` ni `SCRIPT ERROR:` dans la console. La caméra suit le personnage dès le démarrage.
- [ ] En pressant Z/W, le personnage et la caméra se déplacent ensemble — le personnage reste au centre de l'écran.
- [ ] La commande `godot --headless -s res://addons/gut/gut_cmdln.gd -gdir=res://tests -gexit` retourne le code de sortie 0 (tous les tests de `test_04_camera_tp.gd` passent au vert).
- [ ] Les 10 comportements attendus (B1 à B10) passent tous au vert dans GUT.
- [ ] Les 5 cas limites (CL1 à CL5) passent tous au vert dans GUT.

## Hors-périmètre

- Rotation de la caméra à la souris (pivot orbital, pitch/yaw) : feature future.
- Zoom (molette souris) : feature future.
- Interpolation (lerp) lors du suivi : hors proto v0.1 — suivi rigide voulu.
- Collision de caméra (éviter que la caméra traverse les murs) : hors proto v0.1.
- Effet de secousse (camera shake) : hors proto v0.1.
- Champ de vision dynamique (FOV dynamique à grande vitesse) : hors proto v0.1.
- Transition animée lors du changement de cible : hors proto v0.1.
- La propriété `target` n'est pas modifiée dans cette feature (sera faite en feature 07).
