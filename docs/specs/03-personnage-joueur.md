# Spec 03 — Personnage joueur déplaçable (ZQSD/WASD)

## Contexte

- Design : `docs/design/03-personnage-joueur.md`
- Bon de commande graphique : `docs/assets/03-personnage-joueur.md`
- Dépendances de specs précédentes :
  - **Spec 01 — Bootstrap projet** (`docs/specs/01-bootstrap.md`) : fournit `project.godot` (autoload `Game`, section `[input]` vide) et `main.tscn` (nœud racine `Main : Node3D`).
  - **Spec 02 — Scène 3D minimale** (`docs/specs/02-scene-3d-minimale.md`) : fournit le nœud `Ground : MeshInstance3D` (PlaneMesh 200 × 200 m, matériau vert #4a7c3a), `DirectionalLight3D`, `WorldEnvironment` (ciel procédural) et `Camera3D` (position `Vector3(0, 8, 15)`, regarde vers l'origine). Cette feature 03 ajoute le corps physique du sol et le nœud personnage dans la même scène `main.tscn`.

## Objectif fonctionnel

Introduire le personnage joueur dans `main.tscn` : un `CharacterBody3D` capsulaire rouge visible depuis la caméra fixe existante, déplaçable au clavier AZERTY (ZQSD) et QWERTY (WASD) à 5 m/s, avec orientation progressive vers la direction du mouvement (8 rad/s) et gravité permanente. Le sol de la feature 02 reçoit un `StaticBody3D` + `CollisionShape3D` pour que le personnage s'y pose. Aucune caméra suivante, aucun saut, aucune animation squelettale.

## Arborescence cible

```
.
├── main.tscn                                        # modifié — nœuds GroundCollider et Player ajoutés
├── scenes/
│   └── player/
│       └── player.tscn                             # créé — scène réutilisable du personnage
├── src/
│   └── player/
│       └── player_controller.gd                   # créé — PlayerController extends CharacterBody3D
├── tests/
│   └── test_03_personnage_joueur.gd                # à écrire par le tester
└── assets/
    ├── characters/
    │   └── player/
    │       └── player.glb                          # non livré — mock CapsuleMesh inline dans player.tscn
    └── materials/
        └── characters/
            └── player_mock.tres                    # non livré — mock StandardMaterial3D inline dans player.tscn
```

Notes :
- `src/player/player_controller.gd` est le seul script de production créé par cette feature.
- `scenes/player/player.tscn` est la scène réutilisable du personnage, instanciée dans `main.tscn`.
- `main.tscn` est modifié (pas recréé) : les nœuds hérités des features 01 et 02 sont conservés.
- Les dossiers `assets/characters/player/` et `assets/materials/characters/` sont déclarés mais leurs fichiers finaux ne sont pas livrés à ce stade.

## Interface publique (GDScript)

### `src/player/player_controller.gd`

```gdscript
class_name PlayerController
extends CharacterBody3D

# --- Constantes ---

const SPEED: float = 5.0            # vitesse de déplacement horizontale en m/s
const GRAVITY: float = 9.8          # accélération gravitationnelle en m/s²
const ROTATION_SPEED: float = 8.0   # vitesse de rotation vers la direction du mouvement en rad/s

# --- Propriétés exportées ---

@export var speed: float = SPEED
@export var gravity: float = GRAVITY
@export var rotation_speed: float = ROTATION_SPEED

# --- État interne ---

var _state: String  # "idle" ou "walk" — accessible en lecture seule via get_state()

# --- Méthodes publiques ---

func get_state() -> String
    # Retourne l'état courant : "idle" si velocity.length() == 0.0, "walk" sinon.

func _physics_process(delta: float) -> void
    # Appelée par le moteur à chaque frame physique. Non testable directement en GUT headless
    # mais son comportement est validé via les méthodes ci-dessous.

func compute_input_direction() -> Vector3
    # Lit l'InputMap (move_forward, move_backward, move_left, move_right)
    # et retourne la direction horizontale normalisée (plan XZ).
    # Retourne Vector3.ZERO si aucun input actif.
    # La composante Y est toujours 0.0.

func apply_gravity(delta: float) -> void
    # Ajoute gravity * delta à velocity.y (vers le bas, signe négatif si gravity > 0).
    # velocity.y -= gravity * delta
    # N'est appliquée que si not is_on_floor().

func apply_movement(direction: Vector3) -> void
    # Met velocity.x et velocity.z selon direction * speed.
    # Si direction == Vector3.ZERO, met velocity.x = 0.0 et velocity.z = 0.0 (arrêt net).

func rotate_toward_direction(direction: Vector3, delta: float) -> void
    # Fait pivoter le nœud (rotation.y) vers la direction donnée, à rotation_speed rad/s.
    # Ne modifie que rotation.y. Sans effet si direction == Vector3.ZERO.
    # Utilise lerp_angle(rotation.y, atan2(-direction.x, -direction.z), rotation_speed * delta).
```

**Signatures typées complètes :**

```gdscript
class_name PlayerController
extends CharacterBody3D

const SPEED: float = 5.0
const GRAVITY: float = 9.8
const ROTATION_SPEED: float = 8.0

@export var speed: float = SPEED
@export var gravity: float = GRAVITY
@export var rotation_speed: float = ROTATION_SPEED

var _state: String = "idle"

func get_state() -> String:
    return _state

func compute_input_direction() -> Vector3

func apply_gravity(delta: float) -> void

func apply_movement(direction: Vector3) -> void

func rotate_toward_direction(direction: Vector3, delta: float) -> void

func _physics_process(delta: float) -> void:
    var direction := compute_input_direction()
    if not is_on_floor():
        apply_gravity(delta)
    apply_movement(direction)
    rotate_toward_direction(direction, delta)
    move_and_slide()
    _state = "walk" if direction != Vector3.ZERO else "idle"
```

**Notes importantes :**

- `apply_gravity` ne s'applique que quand `is_on_floor()` est `false` afin de ne pas accumuler de vitesse verticale négative à l'infini quand le personnage est au sol.
- `apply_movement` écrase complètement `velocity.x` et `velocity.z` à chaque frame (pas d'inertie).
- `rotate_toward_direction` utilise `lerp_angle` pour un pivot progressif et sans saut brusque.
- La méthode `compute_input_direction()` normalise le vecteur résultant (évite la sur-vitesse en diagonale).
- L'angle cible de rotation est calculé avec `atan2(-direction.x, -direction.z)` : convention Godot 3D où l'axe -Z monde est "forward".

## Structure des scènes (.tscn)

### `scenes/player/player.tscn` (créée)

```
Player : CharacterBody3D                              (nœud racine, script : res://src/player/player_controller.gd)
  position = Vector3(0, 0.9, 0)                       # pieds à y=0, centre capsule à y=0.9
  up_direction = Vector3(0, 1, 0)
  floor_max_angle = 0.785398                          # PI/4 = 45°
  │
  ├── CollisionShape3D : CollisionShape3D
  │     shape = CapsuleShape3D
  │       height = 1.8                               # mètres, axe Y
  │       radius = 0.4                               # mètres
  │     position = Vector3(0, 0, 0)                  # centré sur le CharacterBody3D
  │
  └── MeshInstance3D : MeshInstance3D
        mesh = CapsuleMesh
          height = 1.8
          radius = 0.4
        material_override = StandardMaterial3D
          albedo_color = Color(0.851, 0.290, 0.290, 1.0)   # #d94a4a
          shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
          cull_mode = BaseMaterial3D.CULL_BACK
        position = Vector3(0, 0, 0)
        # MOCK — à remplacer par res://assets/characters/player/player.glb
        # MOCK — matériau à remplacer par res://assets/materials/characters/player_mock.tres
```

### `main.tscn` (modifiée — ajout de deux nœuds)

```
Main : Node3D                                         (nœud racine hérité — inchangé)
│
├── WorldEnvironment : WorldEnvironment               (hérité de la feature 02 — inchangé)
├── DirectionalLight3D : DirectionalLight3D           (hérité de la feature 02 — inchangé)
│
├── Ground : MeshInstance3D                           (hérité de la feature 02 — inchangé)
│
├── GroundCollider : StaticBody3D                     (nœud nouveau — corps physique du sol)
│     position = Vector3(0, 0, 0)
│     │
│     └── CollisionShape3D : CollisionShape3D
│           shape = WorldBoundaryShape3D              # plan infini, origine y=0 (pas de fichier asset)
│           # Alternative acceptable : BoxShape3D(size=Vector3(200,0.2,200), position=Vector3(0,-0.1,0))
│           # Nœud de scène — aucun asset associé
│
├── Player : CharacterBody3D                          (nœud nouveau — instance de scenes/player/player.tscn)
│     position = Vector3(0, 0.9, 0)                  # spawn : pieds à y=0
│     # Instancié depuis res://scenes/player/player.tscn
│
└── Camera3D : Camera3D                               (hérité de la feature 02 — inchangé)
      current = true
      position = Vector3(0, 8, 15)
```

Notes de structure :
- `GroundCollider` est placé avant `Player` dans l'ordre des enfants de `Main`.
- `Player` est instancié comme scène enfant (instance de `scenes/player/player.tscn`), pas comme nœud inline.
- La `Camera3D` reste inchangée (feature 04 introduira le suivi du joueur).
- Le nœud `Ground` (MeshInstance3D) de la feature 02 n'est **pas** renommé ni déplacé.

## Données et constantes

Toutes les constantes de gameplay sont déclarées dans `src/player/player_controller.gd` et accessibles via `PlayerController.<NOM>`.

| Constante | Type | Valeur | Rôle |
|---|---|---|---|
| `PlayerController.SPEED` | `float` | `5.0` | Vitesse de déplacement horizontal en m/s |
| `PlayerController.GRAVITY` | `float` | `9.8` | Accélération gravitationnelle en m/s² (valeur par défaut Godot) |
| `PlayerController.ROTATION_SPEED` | `float` | `8.0` | Vitesse de pivot vers la direction du mouvement en rad/s |
| Position de spawn | `Vector3` | `Vector3(0, 0.9, 0)` | Centre de la capsule au spawn (pieds à y=0) |
| Hauteur CapsuleShape3D | `float` | `1.8` | Hauteur de la capsule de collision en mètres |
| Rayon CapsuleShape3D | `float` | `0.4` | Rayon de la capsule de collision en mètres |
| Couleur mock personnage | `Color` | `Color(0.851, 0.290, 0.290, 1.0)` | Albedo rouge vif #d94a4a du CapsuleMesh mock |
| `floor_max_angle` | `float` | `PI / 4` (~0.7854 rad) | Angle max de sol considéré comme praticable (45°, valeur par défaut Godot) |
| `up_direction` | `Vector3` | `Vector3(0, 1, 0)` | Direction haut pour la gravité (standard) |

## Comportements attendus

Chaque point est testable unitairement avec GUT dans `tests/test_03_personnage_joueur.gd`. Les tests B1 à B10 ne nécessitent pas de charger `main.tscn`. Les tests B11 et B12 requièrent un chargement de scène (headless admis).

**B1.** `PlayerController.SPEED == 5.0` — la constante de classe est exactement `5.0`.

**B2.** `PlayerController.GRAVITY == 9.8` — la constante de classe est exactement `9.8`.

**B3.** `PlayerController.ROTATION_SPEED == 8.0` — la constante de classe est exactement `8.0`.

**B4.** Un `PlayerController` instancié (`add_child_autofree`) a `speed == 5.0`, `gravity == 9.8`, `rotation_speed == 8.0` (les propriétés exportées reprennent les constantes).

**B5.** `PlayerController.apply_movement(Vector3(1, 0, 0))` donne `velocity.x == speed` et `velocity.z == 0.0` — déplacement pur vers la droite.

**B6.** `PlayerController.apply_movement(Vector3(0, 0, -1))` donne `velocity.z == -speed` et `velocity.x == 0.0` — déplacement pur vers l'avant.

**B7.** `PlayerController.apply_movement(Vector3.ZERO)` donne `velocity.x == 0.0` et `velocity.z == 0.0` — arrêt net sans inertie.

**B8.** `PlayerController.apply_gravity(0.1)` appliqué une fois (avec `velocity.y` initial à `0.0`) donne `velocity.y == -GRAVITY * 0.1` = `-0.98` (à 0.001 près). La composante Y est négative (vers le bas).

**B9.** `PlayerController.apply_movement` appliqué avec une direction diagonale normalisée `Vector3(1, 0, -1).normalized()` donne `velocity.length()` approximativement égal à `speed` (tolérance 0.001) — pas de sur-vitesse en diagonale.

**B10.** Après `apply_movement(Vector3(0, 0, -1))`, `get_state()` retourne `"walk"`. Après `apply_movement(Vector3.ZERO)`, `get_state()` retourne `"idle"`.

**B11.** `rotate_toward_direction(Vector3(1, 0, 0), 10.0)` (delta très grand) : `rotation.y` converge vers `atan2(-1.0, 0.0)` = `-PI/2` (à 0.01 rad près). La rotation ne dépasse pas la valeur cible (pas d'overshoot avec `lerp_angle`).

**B12.** `rotate_toward_direction(Vector3.ZERO, 1.0)` ne modifie pas `rotation.y` (valeur inchangée quel que soit l'état initial).

**B13.** Test de scène (headless) : charger `res://main.tscn`, appeler `add_child_autofree(scene)`, vérifier que `scene.get_node_or_null("Player") != null` et que le nœud est de classe `CharacterBody3D` (`scene.get_node("Player") is CharacterBody3D == true`).

**B14.** Test de scène (headless) : `scene.get_node_or_null("GroundCollider") != null` et `scene.get_node("GroundCollider") is StaticBody3D == true`.

**B15.** Test de scène (headless) : le nœud `Player` porte un script dont `get_script().get_global_name() == "PlayerController"` (ou `scene.get_node("Player") is PlayerController == true`).

## Cas limites / erreurs

**CL1.** `compute_input_direction()` sans aucun input actif retourne exactement `Vector3.ZERO` (aucun input pressé = pas de déplacement). Un test mock de l'InputMap (`Input.action_press` / `Input.action_release`) doit couvrir ce cas.

**CL2.** `apply_gravity(0.0)` (delta = 0) : `velocity.y` reste inchangé — aucun effet, pas de division par zéro, pas d'erreur.

**CL3.** `apply_movement` avec un vecteur non normalisé `Vector3(1, 0, 0)` (déjà unitaire) : `velocity.x == speed`. Si la direction est fournie non normalisée (ex. `Vector3(2, 0, 0)`), c'est la responsabilité de l'appelant (`compute_input_direction` normalise toujours — la méthode `apply_movement` elle-même ne normalise pas, elle utilise la direction telle quelle multipliée par `speed`).

**CL4.** `rotate_toward_direction` appelé avec `direction.y != 0` (exemple `Vector3(0, 1, 0)`) : seule la composante XZ de la direction doit être prise en compte. Le personnage ne s'incline pas (rotation.x et rotation.z restent à 0). Note : `compute_input_direction` garantit `y == 0`, mais `rotate_toward_direction` est publique et doit être robuste.

**CL5.** Deux instances distinctes de `PlayerController` partagent les mêmes constantes de classe mais ont des `velocity` indépendants — `apply_movement` sur l'une n'affecte pas l'autre.

**CL6.** `PlayerController` instancié sans parent dans l'arbre de scène (test unitaire pur) : `apply_movement`, `apply_gravity` et `rotate_toward_direction` ne crashent pas (aucun appel à `move_and_slide` dans ces méthodes isolées).

## Inputs Godot (Input Map)

Les quatre actions suivantes sont à ajouter dans la section `[input]` de `project.godot`. Chaque action reçoit **deux** mappings de touches pour couvrir AZERTY et QWERTY simultanément.

| Action Godot | Touche 1 (AZERTY) | Touche 2 (QWERTY) | Effet attendu |
|---|---|---|---|
| `move_forward` | `KEY_Z` | `KEY_W` | Déplacement vers l'avant (direction `Vector3(0, 0, -1)` monde) |
| `move_backward` | `KEY_S` | — (identique sur les deux layouts) | Déplacement vers l'arrière (direction `Vector3(0, 0, 1)` monde) |
| `move_left` | `KEY_Q` | `KEY_A` | Déplacement vers la gauche (direction `Vector3(-1, 0, 0)` monde) |
| `move_right` | `KEY_D` | — (identique sur les deux layouts) | Déplacement vers la droite (direction `Vector3(1, 0, 0)` monde) |

Section `[input]` à ajouter / compléter dans `project.godot` :

```ini
[input]

move_forward={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":90,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
, Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":87,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
]
}
move_backward={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":83,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
]
}
move_left={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":81,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
, Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":65,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
]
}
move_right={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":68,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
]
}
```

**Notes sur les codes physiques :**
- `physical_keycode = 90` = KEY_Z (position physique, indépendante du layout)
- `physical_keycode = 87` = KEY_W
- `physical_keycode = 83` = KEY_S
- `physical_keycode = 81` = KEY_Q
- `physical_keycode = 65` = KEY_A
- `physical_keycode = 68` = KEY_D

L'utilisation de `physical_keycode` (plutôt que `keycode`) garantit la compatibilité AZERTY/QWERTY : la touche est identifiée par sa position physique sur le clavier, pas par le caractère imprimé.

Dans `compute_input_direction()`, les actions sont lues via :
```gdscript
Input.get_action_strength("move_forward")   # positif → direction -Z
Input.get_action_strength("move_backward")  # positif → direction +Z
Input.get_action_strength("move_left")      # positif → direction -X
Input.get_action_strength("move_right")     # positif → direction +X
```

## Assets consommés

| Chemin `res://` | Mock attendu | Type mock | Usage dans la scène |
|---|---|---|---|
| `res://assets/characters/player/player.glb` | oui | `MeshInstance3D` avec `CapsuleMesh` (h=1.8, r=0.4) dans `scenes/player/player.tscn` | Représentation visuelle du personnage (capsule rouge #d94a4a) |
| `res://assets/materials/characters/player_mock.tres` | oui | `StandardMaterial3D` inline (`material_override` du MeshInstance3D du joueur) | Couleur albedo rouge vif #d94a4a du personnage mock |

Tous les assets sont mockés inline dans `scenes/player/player.tscn`. Aucun fichier `.tres` ni `.glb` externe n'est requis pour que la scène se lance.

Le nœud `MeshInstance3D` dans `player.tscn` doit porter les commentaires :
```
# MOCK — à remplacer par res://assets/characters/player/player.glb
# MOCK — matériau à remplacer par res://assets/materials/characters/player_mock.tres
```

## Dépendances

- **Spec 01 — Bootstrap projet** : fournit `project.godot`, `main.tscn` (nœud `Main : Node3D`), autoload `Game`.
- **Spec 02 — Scène 3D minimale** : fournit `main.tscn` enrichi (sol `Ground`, lumière, ciel, `Camera3D` repositionnée). Le personnage s'appuie sur ce sol.
- **`addons/gut/`** : addon GUT v9.4 ou supérieur, déjà installé depuis la feature 01.
- Aucun autre addon autorisé.

## Critères d'acceptation

- [ ] Le fichier `src/player/player_controller.gd` est présent, `class_name PlayerController` est reconnue par GDScript sans erreur de parse.
- [ ] Le fichier `scenes/player/player.tscn` est présent et s'ouvre dans l'éditeur Godot 4.6 sans erreur de ressource manquante.
- [ ] L'arbre de `player.tscn` dans l'éditeur affiche : `Player : CharacterBody3D` > `CollisionShape3D` + `MeshInstance3D`.
- [ ] `main.tscn` s'ouvre dans l'éditeur Godot 4.6 sans warning rouge. L'arbre affiche les nœuds : `WorldEnvironment`, `DirectionalLight3D`, `Ground`, `GroundCollider`, `Player`, `Camera3D`.
- [ ] `godot --path . res://main.tscn` se lance sans `ERROR:` ni `SCRIPT ERROR:` dans la console. Le personnage capsule rouge est visible sur le sol vert depuis la caméra fixe.
- [ ] En pressant Z/W, le personnage se déplace vers l'avant (direction -Z). En pressant S, vers l'arrière. En pressant Q/A, vers la gauche. En pressant D, vers la droite.
- [ ] Le personnage s'arrête net à relâcher toutes les touches directionnelles (aucun glissement).
- [ ] Le personnage pivote progressivement vers la direction de déplacement (effet visible à l'œil).
- [ ] Le personnage reste posé sur le sol (ne traverse pas le `GroundCollider`).
- [ ] La commande `godot --headless -s res://addons/gut/gut_cmdln.gd -gdir=res://tests -gexit` retourne le code de sortie 0 (tous les tests de `test_03_personnage_joueur.gd` passent au vert).
- [ ] Les 15 comportements attendus (B1 à B15) passent tous au vert dans GUT.
- [ ] Les 6 cas limites (CL1 à CL6) passent tous au vert dans GUT.
- [ ] Les quatre actions InputMap (`move_forward`, `move_backward`, `move_left`, `move_right`) sont déclarées dans `project.godot` avec les `physical_keycode` corrects.

## Hors-périmètre

- Animations squelettales (marche animée, idle animée) : hors proto v0.1 — le mesh reste statique.
- Sprint (Shift) : feature ultérieure si nécessaire.
- Saut : hors périmètre — le proto n'a pas de plateforme ni d'escalier.
- Collision avec les bâtiments : les bâtiments n'existent pas (feature 05). Les `CollisionShape3D` des bâtiments seront ajoutés en feature 05.
- Orientation du mouvement relative à la caméra : feature 04 (caméra TP).
- Entrée dans un véhicule : feature 07.
- Sons de pas : hors proto v0.1.
- HUD, minimap, barre de vie : hors proto v0.1.
- Inertie / glissement à l'arrêt : la réactivité proto prime — arrêt net voulu.
- Texture réelle du sol : hors périmètre, déclarée hors-périmètre en feature 02.
- L'asset final `res://assets/characters/player/player.glb` et le matériau `res://assets/materials/characters/player_mock.tres` en fichier `.tres` séparé : livrables d'une itération ultérieure.
