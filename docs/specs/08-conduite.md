# Spec 08 — Conduite (accélérer, freiner, tourner)

## Contexte

- Design : `docs/design/08-conduite.md`
- Bon de commande graphique : `docs/assets/08-conduite.md` (aucun asset binaire requis)
- Dépendances de specs précédentes :
  - **Spec 01 — Bootstrap** (`docs/specs/01-bootstrap.md`) : `project.godot` fonctionnel, section `[input]` accessible.
  - **Spec 02 — Scène 3D minimale** (`docs/specs/02-scene-3d-minimale.md`) : `main.tscn` avec `Main : Node3D` racine, sol physique.
  - **Spec 03 — Personnage joueur** (`docs/specs/03-personnage-joueur.md`) : `Player : CharacterBody3D` avec `PlayerController`.
  - **Spec 04 — Caméra TP** (`docs/specs/04-camera-tp.md`) : `CameraRig : Node3D` avec `CameraController`, cible déjà basculée sur le `VehicleBody3D` par `GameState.enter_vehicle`.
  - **Spec 06 — Voiture** (`docs/specs/06-voiture.md`) : `Car : VehicleBody3D` dans `main.tscn`, masse 1200 kg, 4 roues `VehicleWheel3D` configurées (roues avant directrices `use_as_steering = true`, roues arrière motrices `use_as_traction = true`), `wheel_friction_slip = 10.5`. Propriétés physiques `engine_force`, `brake`, `steering` du `VehicleBody3D` pilotables par script.
  - **Spec 07 — Entrer / sortir véhicule** (`docs/specs/07-entree-sortie-vehicule.md`) : `GameState extends Node` (script `src/core/game_state.gd`), `enum PlayerMode { ON_FOOT, IN_VEHICLE }`, propriété `player_mode: PlayerMode`, nœud `GameState` enfant de `Main` dans `main.tscn`.

**Note sur `extends` :** La spec 06 anticipait `class_name CarController extends VehicleBody3D`. Le design 08 (source de vérité de cette feature) précise `extends Node` avec référence au `VehicleBody3D` via `NodePath`. La présente spec annule cette anticipation : `CarController extends Node`.

## Objectif fonctionnel

Introduire le script `src/vehicles/car_controller.gd` (`CarController extends Node`) qui lit les actions clavier de conduite (`drive_forward`, `drive_backward`, `drive_left`, `drive_right`) et les traduit en propriétés physiques `engine_force`, `brake` et `steering` du `VehicleBody3D`. Le script est actif uniquement quand `GameState.player_mode == IN_VEHICLE`. Hors de ce mode, toutes les forces sont remises à zéro, garantissant que la voiture ne se pilote pas accidentellement quand le joueur est à pied. Le nœud `CarController` est ajouté à `main.tscn` comme enfant de `Main`.

## Arborescence cible

```
.
├── main.tscn                                        # modifié — nœud CarController ajouté
├── src/
│   └── vehicles/
│       └── car_controller.gd                        # créé — CarController extends Node
└── tests/
    └── test_08_conduite.gd                          # à écrire par le tester
```

Notes :
- `scenes/vehicles/car.tscn` n'est **pas** modifié par cette feature. Le `CarController` est un nœud séparé dans `main.tscn`, pas un script attaché à `Car`.
- `src/core/game_state.gd` n'est **pas** modifié. `CarController` est son complément : `GameState` gère les transitions d'état, `CarController` gère la physique de conduite.
- `project.godot` est modifié : ajout des 4 nouvelles actions d'entrée (`drive_forward`, `drive_backward`, `drive_left`, `drive_right`) dans la section `[input]`.
- Aucun fichier sous `assets/` n'est créé ou modifié.

## Interface publique (GDScript)

### `src/vehicles/car_controller.gd`

```gdscript
class_name CarController
extends Node

# --- Constantes ---

const ENGINE_FORCE: float = 800.0
# Force motrice appliquée en N via VehicleBody3D.engine_force.

const BRAKE_FORCE: float = 20.0
# Force de freinage appliquée en N via VehicleBody3D.brake.

const MAX_STEERING: float = 0.4
# Angle de braquage maximum en radians (~22.9°), appliqué via VehicleBody3D.steering.

const STEERING_SPEED: float = 5.0
# Facteur lerp par seconde pour l'interpolation de steering.

const FORWARD_SPEED_THRESHOLD: float = 0.5
# Seuil en m/s en-dessous duquel drive_backward déclenche la marche arrière plutôt que le frein.

# --- Propriétés exportées ---

@export var game_state_path: NodePath
# NodePath vers le nœud GameState. Valeur assignée dans l'éditeur.
# Valeur attendue dans main.tscn : NodePath("../GameState")

@export var car_body_path: NodePath
# NodePath vers le nœud Car (VehicleBody3D). Valeur assignée dans l'éditeur.
# Valeur attendue dans main.tscn : NodePath("../Car")

# --- Variables internes ---

var _game_state: GameState = null
# Référence résolue dans _ready à partir de game_state_path.

var _car_body: VehicleBody3D = null
# Référence résolue dans _ready à partir de car_body_path.

var _steering: float = 0.0
# Valeur courante de l'angle de braquage, interpolée frame par frame.
# Clampée dans [-MAX_STEERING, MAX_STEERING] à chaque mise à jour.

# --- Cycle de vie ---

func _ready() -> void:
    # Résout _game_state et _car_body à partir des NodePaths exportés.
    # Échoue silencieusement (null) si les nœuds n'existent pas — les gardes
    # dans _physics_process protègent contre les crashes.
    _game_state = get_node_or_null(game_state_path) as GameState
    _car_body = get_node_or_null(car_body_path) as VehicleBody3D

func _physics_process(delta: float) -> void:
    # Garde : si les références sont nulles, pas de crash.
    # Voir section Cas limites.
    # Si player_mode != IN_VEHICLE : remise à zéro des forces et retour immédiat.
    # Sinon : lecture des inputs et application des forces physiques.
```

**Signature complète de `_physics_process` :**

```gdscript
func _physics_process(delta: float) -> void:
    if _car_body == null or _game_state == null:
        return
    if _game_state.player_mode != GameState.PlayerMode.IN_VEHICLE:
        _car_body.engine_force = 0.0
        _car_body.brake = 0.0
        return

    # Accélération
    if Input.is_action_pressed("drive_forward"):
        _car_body.engine_force = ENGINE_FORCE
    else:
        _car_body.engine_force = 0.0

    # Freinage / marche arrière
    if Input.is_action_pressed("drive_backward"):
        var forward_speed: float = _car_body.linear_velocity.dot(
            -_car_body.global_transform.basis.z
        )
        if forward_speed >= FORWARD_SPEED_THRESHOLD:
            _car_body.brake = BRAKE_FORCE
            _car_body.engine_force = 0.0
        else:
            _car_body.engine_force = -ENGINE_FORCE
            _car_body.brake = 0.0
    else:
        _car_body.brake = 0.0

    # Direction
    var target_steering: float = 0.0
    if Input.is_action_pressed("drive_left"):
        target_steering = MAX_STEERING
    elif Input.is_action_pressed("drive_right"):
        target_steering = -MAX_STEERING
    _steering = lerp(_steering, target_steering, STEERING_SPEED * delta)
    _steering = clamp(_steering, -MAX_STEERING, MAX_STEERING)
    _car_body.steering = _steering
```

**Notes importantes :**

- La vitesse avant (`forward_speed`) est calculée en projetant `linear_velocity` sur l'axe avant local du `VehicleBody3D`. En Godot 4, l'axe avant d'un nœud 3D est `-basis.z` (direction locale Z négative = avant).
- `_steering` est clampé après le `lerp` pour éviter tout dépassement numérique.
- `engine_force` et `brake` sont des propriétés du `VehicleBody3D` que Godot distribue automatiquement aux bonnes roues (`use_as_traction`, `use_as_steering`). `CarController` ne touche pas directement les `VehicleWheel3D`.
- `drive_forward` et `drive_backward` sont traités indépendamment : si les deux sont pressés simultanément, `drive_backward` l'emporte sur `drive_forward` pour `engine_force` car la branche `drive_backward` écrase le résultat de la branche `drive_forward`. Ce comportement est acceptable pour le proto.

## Structure des scènes (.tscn)

### `main.tscn` (modifiée — ajout de `CarController`)

L'état actuel de `main.tscn` (après feature 07) :

```
Main : Node3D
  WorldEnvironment : WorldEnvironment
  DirectionalLight3D : DirectionalLight3D
  Ground : MeshInstance3D
  GroundCollider : StaticBody3D
    CollisionShape3D : CollisionShape3D
  Player : CharacterBody3D          (instance scenes/player/player.tscn)
  CameraRig : Node3D                (script src/camera/camera_controller.gd)
    Camera3D : Camera3D
  City : Node3D                     (instance scenes/city/city.tscn)
  Car : VehicleBody3D               (instance scenes/vehicles/car.tscn)
  GameState : Node                  (script src/core/game_state.gd)
```

Après feature 08, `main.tscn` contient en plus :

```
Main : Node3D
  ...                               (tous les nœuds précédents inchangés)
  CarController : Node              [NOUVEAU — feature 08]
    script = res://src/vehicles/car_controller.gd
    game_state_path = NodePath("../GameState")
    car_body_path = NodePath("../Car")
```

Le nœud `CarController` est ajouté après `GameState` dans l'ordre des enfants de `Main` (en dernier).

### `scenes/vehicles/car.tscn` (inchangée)

La scène `car.tscn` n'est pas modifiée. Le script `CarController` n'est **pas** attaché au nœud `Car`. Le commentaire `editor_description = "Script futur : res://src/vehicles/car_controller.gd — à créer en feature 08"` dans `car.tscn` peut être conservé à titre informatif ou supprimé par le developer — c'est indifférent pour les tests.

## Données et constantes

Toutes les constantes sont déclarées dans `src/vehicles/car_controller.gd`.

| Constante | Type | Valeur | Unité | Source design |
|-----------|------|--------|-------|---------------|
| `ENGINE_FORCE` | `float` | `800.0` | N | docs/design/08-conduite.md |
| `BRAKE_FORCE` | `float` | `20.0` | N | docs/design/08-conduite.md |
| `MAX_STEERING` | `float` | `0.4` | rad | docs/design/08-conduite.md |
| `STEERING_SPEED` | `float` | `5.0` | — (facteur lerp/s) | docs/design/08-conduite.md |
| `FORWARD_SPEED_THRESHOLD` | `float` | `0.5` | m/s | docs/design/08-conduite.md |

Valeur initiale de la variable interne :

| Variable | Valeur initiale |
|----------|----------------|
| `_steering` | `0.0` |
| `_game_state` | `null` |
| `_car_body` | `null` |

## Comportements attendus

Chaque comportement est testable unitairement avec GUT dans `tests/test_08_conduite.gd`. Les tests B1 à B4 ne nécessitent qu'une instance de `CarController` sans arbre de scène complet. Les tests B5 à B11 nécessitent des mocks de `VehicleBody3D` et de `GameState`. Le test B12 nécessite de charger `main.tscn`. Le test B13 vérifie le clamp de `_steering`.

**B1.** `CarController.ENGINE_FORCE == 800.0` :
```gdscript
var ctrl := CarController.new()
assert_eq(ctrl.ENGINE_FORCE, 800.0)
```

**B2.** `CarController.BRAKE_FORCE == 20.0` :
```gdscript
var ctrl := CarController.new()
assert_eq(ctrl.BRAKE_FORCE, 20.0)
```

**B3.** `CarController.MAX_STEERING == 0.4` :
```gdscript
var ctrl := CarController.new()
assert_eq(ctrl.MAX_STEERING, 0.4)
```

**B4.** `CarController.STEERING_SPEED == 5.0` :
```gdscript
var ctrl := CarController.new()
assert_eq(ctrl.STEERING_SPEED, 5.0)
```

**B5.** Quand `player_mode == IN_VEHICLE` et l'action `drive_forward` est pressée, `_physics_process` applique `_car_body.engine_force > 0` :

Stratégie de test : injecter `_game_state` et `_car_body` directement (avant `_ready`, ou après en affectant les champs), simuler `Input.is_action_pressed("drive_forward") == true` via `InputEventKey` + `Input.parse_input_event`, puis appeler `_physics_process(0.016)`.
```gdscript
# Après injection et simulation de drive_forward :
assert_gt(ctrl._car_body.engine_force, 0.0)
```

**B6.** Quand `player_mode == IN_VEHICLE`, `drive_backward` est pressé et la vitesse linéaire projetée sur l'axe avant >= `FORWARD_SPEED_THRESHOLD` (0.5 m/s) → `_car_body.brake > 0` et `_car_body.engine_force == 0.0` :
```gdscript
# car_mock.linear_velocity simulée pour que forward_speed >= 0.5
assert_gt(ctrl._car_body.brake, 0.0)
assert_eq(ctrl._car_body.engine_force, 0.0)
```

**B7.** Quand `player_mode == IN_VEHICLE`, `drive_backward` est pressé et la vitesse linéaire projetée sur l'axe avant < `FORWARD_SPEED_THRESHOLD` (0.5 m/s) → `_car_body.engine_force < 0` et `_car_body.brake == 0.0` :
```gdscript
# car_mock.linear_velocity simulée pour que forward_speed < 0.5
assert_lt(ctrl._car_body.engine_force, 0.0)
assert_eq(ctrl._car_body.brake, 0.0)
```

**B8.** Quand `player_mode == IN_VEHICLE` et `drive_left` est pressé pendant plusieurs frames, `_steering` converge vers `MAX_STEERING` (valeur positive) :
```gdscript
# Après plusieurs appels à _physics_process avec drive_left pressé :
assert_gt(ctrl._steering, 0.0)
```

**B9.** Quand `player_mode == IN_VEHICLE` et `drive_right` est pressé pendant plusieurs frames, `_steering` converge vers `-MAX_STEERING` (valeur négative) :
```gdscript
# Après plusieurs appels à _physics_process avec drive_right pressé :
assert_lt(ctrl._steering, 0.0)
```

**B10.** Quand `player_mode == IN_VEHICLE`, `_steering != 0` au départ et aucune touche de direction n'est pressée → `_steering` se rapproche de `0.0` à chaque appel de `_physics_process` (retour au neutre par lerp) :
```gdscript
ctrl._steering = 0.3  # valeur initiale non nulle
# Appel _physics_process sans drive_left ni drive_right
var before := ctrl._steering
ctrl._physics_process(0.016)
assert_lt(absf(ctrl._steering), absf(before))
```

**B11.** Quand `player_mode == ON_FOOT` → `_car_body.engine_force == 0.0` et `_car_body.brake == 0.0`, sans erreur :
```gdscript
# game_state_mock.player_mode = GameState.PlayerMode.ON_FOOT
ctrl._physics_process(0.016)
assert_eq(ctrl._car_body.engine_force, 0.0)
assert_eq(ctrl._car_body.brake, 0.0)
```

**B12.** Charger `res://main.tscn` : le nœud `"CarController"` existe parmi les enfants de `Main` et est de type `CarController` :
```gdscript
var main := load("res://main.tscn").instantiate()
add_child(main)
var ctrl_node := main.get_node_or_null("CarController")
assert_not_null(ctrl_node)
assert_true(ctrl_node is CarController)
```

**B13.** `_steering` est toujours clampé dans `[-MAX_STEERING, MAX_STEERING]` même si le lerp dépasse numériquement (test de robustesse) :
```gdscript
# Forcer une valeur hors-borne avant l'appel
ctrl._steering = 0.5  # > MAX_STEERING (0.4)
ctrl._physics_process(0.016)
assert_le(ctrl._steering, CarController.MAX_STEERING)
assert_ge(ctrl._steering, -CarController.MAX_STEERING)
```

## Cas limites / erreurs

**CL1.** `_car_body == null` au moment de `_physics_process` : la garde `if _car_body == null or _game_state == null: return` absorbe le cas. Aucun crash, aucune erreur GDScript. Comportement observable : `_physics_process` retourne immédiatement sans modifier quoi que ce soit.

**CL2.** `_game_state == null` au moment de `_physics_process` : même garde que CL1. Retour immédiat, pas de crash.

**CL3.** `delta == 0.0` passé à `_physics_process` : `lerp(_steering, target, STEERING_SPEED * 0.0)` retourne `_steering` inchangé. Le clamp s'applique quand même. Pas d'erreur, `_steering` reste à sa valeur courante. `engine_force` et `brake` sont mis à jour normalement (ils ne dépendent pas de `delta`).

**CL4.** `drive_forward` et `drive_backward` pressés simultanément : `engine_force` est d'abord mis à `ENGINE_FORCE` par la branche `drive_forward`, puis écrasé par la branche `drive_backward` (soit `BRAKE_FORCE` sur `brake` et `engine_force = 0.0`, soit `engine_force = -ENGINE_FORCE` et `brake = 0.0`). Comportement déterministe, pas de crash. Acceptable pour le proto.

**CL5.** `drive_left` et `drive_right` pressés simultanément : la condition `if drive_left ... elif drive_right` donne la priorité à `drive_left`. `target_steering = MAX_STEERING`. Comportement déterministe, pas de crash.

**CL6.** `_ready()` appelé avec un `NodePath` vide ou invalide : `get_node_or_null` retourne `null` sans erreur. `_game_state` et/ou `_car_body` restent `null`. La garde dans `_physics_process` protège contre tout crash ultérieur.

## Inputs Godot (Input Map)

Les 4 actions suivantes doivent être déclarées dans la section `[input]` de `project.godot`, après les entrées existantes (`move_forward`, `move_backward`, `move_left`, `move_right`, `interact`).

| Action Godot | Touches | Physical keycode(s) | Effet |
|---|---|---|---|
| `drive_forward` | W, Z | 87 (W), 90 (Z) | Accélérer (`engine_force = ENGINE_FORCE`) |
| `drive_backward` | S | 83 (S) | Freiner si avance ; reculer si arrêté |
| `drive_left` | A, Q | 65 (A), 81 (Q) | Tourner à gauche (`_steering` → `MAX_STEERING`) |
| `drive_right` | D | 68 (D) | Tourner à droite (`_steering` → `-MAX_STEERING`) |

Section `[input]` à ajouter dans `project.godot` (après l'entrée `interact`) :

```ini
drive_forward={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":87,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
, Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":90,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
]
}
drive_backward={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":83,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
]
}
drive_left={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":65,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
, Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":81,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
]
}
drive_right={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":68,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
]
}
```

**Note :** Ces actions sont distinctes des actions de déplacement à pied (`move_forward`, `move_backward`, `move_left`, `move_right`) pour éviter tout conflit. Un même keycode peut être lié à deux actions différentes dans Godot — c'est intentionnel ici car le contexte (ON_FOOT vs IN_VEHICLE) détermine quelle action est active via la garde dans `_physics_process` et la désactivation du `PlayerController`.

**Keycodes de référence :**

| Touche physique | physical_keycode |
|---|---|
| W | 87 |
| Z | 90 |
| S | 83 |
| A | 65 |
| Q | 81 |
| D | 68 |

## Assets consommés

| Chemin `res://` | Mock attendu (oui/non) | Usage dans la scène |
|-----------------|------------------------|---------------------|
| (aucun asset binaire) | — | — |

Cette feature ne consomme aucun asset binaire (`.glb`, `.png`, `.ogg`, `.tres`). Elle n'introduit pas de nouveau nœud visuel. L'arborescence `assets/` reste identique à celle établie par le bon de commande 07.

## Dépendances

- **Spec 01 — Bootstrap projet** : `project.godot` fonctionnel, section `[input]` existante.
- **Spec 06 — Voiture** : `VehicleBody3D` nommé `Car` dans `main.tscn`, propriétés `engine_force`, `brake`, `steering`, `linear_velocity` accessibles par script.
- **Spec 07 — Entrer / sortir véhicule** : `class_name GameState`, `enum PlayerMode { ON_FOOT, IN_VEHICLE }`, propriété `player_mode: PlayerMode` accessible en lecture. Nœud `GameState` dans `main.tscn` avec NodePath `"GameState"` depuis `Main`.
- **`addons/gut/`** : addon GUT v9.6, installé dans `addons/gut/`. Aucun autre addon autorisé.

## Critères d'acceptation

- [ ] Le fichier `src/vehicles/car_controller.gd` est présent et `class_name CarController` est reconnue par GDScript sans erreur de parse.
- [ ] `main.tscn` s'ouvre dans l'éditeur Godot 4.6 sans warning rouge. L'arbre affiche un nœud `CarController : CarController` (type = `Node`, script = `car_controller.gd`) parmi les enfants de `Main`.
- [ ] Les propriétés exportées `game_state_path` et `car_body_path` du nœud `CarController` sont assignées dans l'inspecteur à `NodePath("../GameState")` et `NodePath("../Car")` respectivement.
- [ ] `project.godot` contient les 4 nouvelles actions `drive_forward`, `drive_backward`, `drive_left`, `drive_right` dans la section `[input]`.
- [ ] `godot --path . res://main.tscn` se lance sans `ERROR:` ni `SCRIPT ERROR:` dans la console.
- [ ] En jeu : entrer dans la voiture (touche E), puis appuyer sur W/Z → la voiture avance.
- [ ] En jeu : appuyer sur S pendant que la voiture avance → la voiture décélère.
- [ ] En jeu : appuyer sur S à l'arrêt → la voiture recule.
- [ ] En jeu : appuyer sur A/Q ou D → la voiture tourne (les roues avant pivotent).
- [ ] En jeu : relâcher A/Q ou D → le volant revient au neutre progressivement.
- [ ] En jeu : sortir de la voiture (touche E) → la voiture s'arrête progressivement par friction, aucune force résiduelle.
- [ ] La commande `godot --headless -s res://addons/gut/gut_cmdln.gd -gdir=res://tests -gexit` retourne le code de sortie 0 (tous les tests de `test_08_conduite.gd` et des features précédentes passent au vert).
- [ ] Les 13 comportements attendus (B1 à B13) passent tous au vert dans GUT.
- [ ] Les 6 cas limites (CL1 à CL6) passent tous au vert dans GUT.

## Hors-périmètre

- Sons moteur, crissements de pneus, klaxon : hors proto v0.1.
- Compteur de vitesse, jauge de carburant, HUD de conduite : hors proto v0.1.
- Dommages de collision (visuels ou physiques) : hors proto v0.1.
- Caméra spéciale conduite (FOV modifié, effet de vitesse) : hors proto v0.1. La `CameraController` de feature 04 suffit.
- Frein à main / dérapage (handbrake) : hors proto v0.1.
- Transmission (vitesses, régime moteur) : hors proto v0.1. Modèle simplifié à force constante.
- Vitesse maximale explicite : hors proto v0.1. La résistance physique de Godot limite naturellement.
- Contrôle à la manette / gamepad : hors proto v0.1 (clavier uniquement).
- Plusieurs voitures conduisibles simultanément : hors proto v0.1.
- IA de conduite pour les PNJ : hors proto v0.1.
- Détection de sortie de route, ralentissement sur herbe : hors proto v0.1.
- Nitro, turbo, boost : hors proto v0.1.
- Animation du volant visible dans l'habitacle : hors proto v0.1.
