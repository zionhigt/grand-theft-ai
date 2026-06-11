# Spec 18 — Refonte complète du véhicule

## Contexte

- Design : `docs/design/18-refonte-vehicule.md`
- Bon de commande graphique : `docs/assets/18-refonte-vehicule.md`
- Dépendances de specs précédentes :
  - **Spec 02** (`docs/specs/02-scene-3d-minimale.md`) — fournit le sol physique (`GroundCollider`) et l'environnement 3D
  - **Spec 03** (`docs/specs/03-personnage-joueur.md`) — fournit `PlayerController extends CharacterBody3D`, `set_process_input`, `set_physics_process`, enfant `PlayerBody : Node3D`
  - **Spec 04 / 09 / 11 / 12** — `CameraController` avec `@export var target: Node3D` assignable dynamiquement
  - **Spec 07** (`docs/specs/07-entree-sortie-vehicule.md`) — définit `GameState` (`enter_vehicle`, `exit_vehicle`, `player_near_car`), **inchangé par cette feature**
  - **Specs 06–17** — toutes supersédées ; leurs fichiers de production (`src/vehicles/`, `scenes/vehicles/car.tscn`) sont intégralement remplacés

Cette feature **supersède** les features 06, 07 (partie véhicule), 08, 13, 14, 15, 16, 17.
`src/core/game_state.gd` est **conservé sans modification**.

## Objectif fonctionnel

Reconstruire de zéro la scène véhicule (`scenes/vehicles/car.tscn`), le script de contrôle de conduite (`src/vehicles/car_controller.gd`) et le script de rendu de la carrosserie (`src/vehicles/car_visuals.gd`). À l'issue, le joueur peut entrer dans la voiture (touche E, via `GameState` inchangé), conduire (WASD/ZQSD), et sortir. Le GLB `car_body.glb` est chargé par code ; en cas d'absence, un BoxMesh rouge sert de fallback. Aucun `wheel.glb` ni roue visuelle séparée.

## Arborescence cible

```
scenes/
  vehicles/
    car.tscn                       [REÉCRIT — structure VehicleBody3D propre]

src/
  vehicles/
    car_controller.gd              [REÉCRIT — CarController extends Node]
    car_visuals.gd                 [REÉCRIT — CarVisuals extends Node3D]

tests/
  test_18_refonte_vehicule.gd      [à écrire par le tester]
  test_06_voiture.gd               [SUPPRIMÉ par le tester — supersédé]
  test_07_entree_sortie_vehicule.gd [SUPPRIMÉ par le tester — supersédé]
  test_08_conduite.gd              [SUPPRIMÉ par le tester — supersédé]
  test_13_carrosserie_glb_masquage_roues.gd [SUPPRIMÉ par le tester — supersédé]
  test_14_calibration_physique_vehicule.gd  [SUPPRIMÉ par le tester — supersédé]
  test_15_correction_geometrie_roues.gd     [SUPPRIMÉ par le tester — supersédé]
  test_16_suppression_wheelMesh.gd          [SUPPRIMÉ par le tester — supersédé]
  test_17_correction_orientation_glb_vitesse.gd [SUPPRIMÉ par le tester — supersédé]

assets/
  vehicles/
    car/
      car_body.glb                 [PRESENT — livré (feature 13), inchangé]
      # wheel.glb — supprimé de toute référence projet (suppression physique : agent mixamo)
```

Note : `main.tscn` et `src/core/game_state.gd` sont conservés sans modification structurelle — seul le contenu de l'instance `Car` change parce que `car.tscn` est réécrit.

## Interface publique (GDScript)

### `src/vehicles/car_controller.gd`

```
class_name CarController
extends Node

# --- Constantes ---
const ENGINE_FORCE: float = 8000.0
const BRAKE_FORCE: float = 80.0
const MAX_STEERING: float = 0.4
const STEERING_SPEED: float = 5.0
const FORWARD_SPEED_THRESHOLD: float = 0.5

# --- Exports ---
@export var game_state_path: NodePath
@export var car_body_path: NodePath

# --- Variables internes ---
var _game_state          # type non contraint — permet l'injection de mock en test
var _car_body: VehicleBody3D
var _steering: float = 0.0

# --- Cycle de vie ---
func _ready() -> void
# Résout _game_state et _car_body via les NodePaths
# UNIQUEMENT si les variables sont null au moment de l'appel
# (pattern d'injection : les tests injectent avant add_child, _ready ne doit pas écraser)

func _physics_process(delta: float) -> void
# Guard : retour immédiat si _car_body == null ou _game_state == null
# Guard : retour immédiat si _game_state.player_mode != GameState.PlayerMode.IN_VEHICLE
#   Dans ce cas : _car_body.engine_force = 0, _car_body.brake = 0
# Logique de conduite décrite dans la section Comportements attendus
```

### `src/vehicles/car_visuals.gd`

```
class_name CarVisuals
extends Node3D

# --- Constantes ---
const CAR_BODY_GLB: String = "res://assets/vehicles/car/car_body.glb"
const CAR_LENGTH_TARGET: float = 4.0   # longueur cible pour l'auto-scale AABB (mètres)

# --- Cycle de vie ---
func _ready() -> void
# Appelle _charger_carrosserie()

# --- Méthode publique ---
func _charger_carrosserie() -> void
# Si ResourceLoader.exists(CAR_BODY_GLB) :
#   charge le GLB, instancie, ajuste scale via AABB (dim max → CAR_LENGTH_TARGET),
#   applique rotation_degrees.y = -90.0, ajoute comme enfant de $CarBodyMesh
# Sinon :
#   push_warning("car_body.glb introuvable — mock BoxMesh actif")
#   crée MeshInstance3D + BoxMesh (4.0 × 1.5 × 2.0) + StandardMaterial3D albedo #cc2222
#   # MOCK — à remplacer par res://assets/vehicles/car/car_body.glb
#   ajoute comme enfant de $CarBodyMesh
```

**Contraintes supplémentaires :**
- Pas de méthode `_masquer_roues` ni aucune variante.
- Aucune référence au chemin `res://assets/vehicles/car/wheel.glb` dans le fichier source.
- Le calcul AABB utilise la dimension maximale parmi x, y, z : `scale = Vector3.ONE * (CAR_LENGTH_TARGET / aabb.size.length())` ou `CAR_LENGTH_TARGET / max(aabb.size.x, max(aabb.size.y, aabb.size.z))` — le developer choisit la formule la plus stable visuellement, l'essentiel est que l'auto-scale soit uniforme.

## Structure des scènes (.tscn)

### `scenes/vehicles/car.tscn` (réécrite)

```
Car : VehicleBody3D                             [racine — AUCUN script attaché]
  mass = 1200.0

  CarBodyCollision : CollisionShape3D
    shape = BoxShape3D
      size = Vector3(4.0, 1.5, 2.0)
    position = Vector3(0, 0, 0)

  CarBodyMesh : MeshInstance3D
    # Placeholder visible avant le chargement du GLB par CarVisuals
    mesh = BoxMesh
      size = Vector3(4.0, 1.5, 2.0)
    position = Vector3(0, 0, 0)
    # MOCK — à remplacer par res://assets/vehicles/car/car_body.glb

  WheelFrontLeft : VehicleWheel3D
    position = Vector3(-0.8, -0.5, -1.0)
    use_as_steering = true
    use_as_traction = false
    wheel_radius = 0.35
    wheel_rest_length = 0.25
    suspension_travel = 0.2
    suspension_stiffness = 5.88
    damping_compression = 0.83
    damping_relaxation = 0.88
    suspension_max_force = 6000.0
    wheel_friction_slip = 10.5
    # ZERO enfant MeshInstance3D

  WheelFrontRight : VehicleWheel3D
    position = Vector3(0.8, -0.5, -1.0)
    use_as_steering = true
    use_as_traction = false
    wheel_radius = 0.35
    wheel_rest_length = 0.25
    suspension_travel = 0.2
    suspension_stiffness = 5.88
    damping_compression = 0.83
    damping_relaxation = 0.88
    suspension_max_force = 6000.0
    wheel_friction_slip = 10.5
    # ZERO enfant MeshInstance3D

  WheelRearLeft : VehicleWheel3D
    position = Vector3(-0.8, -0.5, 1.0)
    use_as_steering = false
    use_as_traction = true
    wheel_radius = 0.35
    wheel_rest_length = 0.25
    suspension_travel = 0.2
    suspension_stiffness = 5.88
    damping_compression = 0.83
    damping_relaxation = 0.88
    suspension_max_force = 6000.0
    wheel_friction_slip = 10.5
    # ZERO enfant MeshInstance3D

  WheelRearRight : VehicleWheel3D
    position = Vector3(0.8, -0.5, 1.0)
    use_as_steering = false
    use_as_traction = true
    wheel_radius = 0.35
    wheel_rest_length = 0.25
    suspension_travel = 0.2
    suspension_stiffness = 5.88
    damping_compression = 0.83
    damping_relaxation = 0.88
    suspension_max_force = 6000.0
    wheel_friction_slip = 10.5
    # ZERO enfant MeshInstance3D

  CarVisuals : Node3D
    script = res://src/vehicles/car_visuals.gd
    # Charge car_body.glb dans _ready() et ajoute l'instance comme enfant de CarBodyMesh

  InteractionZone : Area3D
    monitoring = true
    monitorable = false
    collision_layer = 0
    collision_mask = 1

    CollisionShape3D : CollisionShape3D
      shape = SphereShape3D
        radius = 3.0
      position = Vector3(0, 0, 0)
```

**Points structurels critiques :**
- Le nœud racine `Car` n'a **aucun script** (`get_script() == null` en GDScript).
- Aucun `VehicleWheel3D` n'a d'enfant `MeshInstance3D` — les roues visuelles sont dans `car_body.glb`.
- `CarVisuals` est distinct de `CarBodyMesh` : `CarVisuals` est le nœud Node3D qui porte le script ; `CarBodyMesh` est le `MeshInstance3D` auquel `CarVisuals` attache le GLB instancié.

### `main.tscn` (inchangé structurellement)

Aucune modification de `main.tscn`. La structure actuelle est conservée telle quelle. La position de `Car` reste `Vector3(5.0, 1.1, 5.0)` (valeur déjà présente dans le fichier .tscn). `CarController` reste un nœud enfant de `Main` avec `game_state_path = NodePath("../GameState")` et `car_body_path = NodePath("../Car")`.

## Données et constantes

### `src/vehicles/car_controller.gd`

| Constante | Valeur | Unité | Rôle |
|-----------|--------|-------|------|
| `ENGINE_FORCE` | `8000.0` | N | Force moteur appliquée à `VehicleBody3D.engine_force` |
| `BRAKE_FORCE` | `80.0` | valeur directe `VehicleBody3D.brake` | Force de freinage (Godot : force par roue active) |
| `MAX_STEERING` | `0.4` | radians (~22.9°) | Angle max de braquage appliqué à `VehicleBody3D.steering` |
| `STEERING_SPEED` | `5.0` | facteur lerp | Vitesse d'interpolation du braquage par frame delta |
| `FORWARD_SPEED_THRESHOLD` | `0.5` | m/s | Seuil de vitesse séparant le freinage de la marche arrière |

### `src/vehicles/car_visuals.gd`

| Constante | Valeur | Rôle |
|-----------|--------|------|
| `CAR_BODY_GLB` | `"res://assets/vehicles/car/car_body.glb"` | Chemin de chargement du GLB |
| `CAR_LENGTH_TARGET` | `4.0` | Longueur cible (m) pour l'auto-scale AABB |

### `scenes/vehicles/car.tscn`

| Paramètre | Valeur | Nœud |
|-----------|--------|------|
| `mass` | `1200.0` kg | `Car : VehicleBody3D` |
| `CarBodyCollision.shape.size` | `Vector3(4.0, 1.5, 2.0)` | `BoxShape3D` |
| Position WheelFrontLeft | `Vector3(-0.8, -0.5, -1.0)` | `WheelFrontLeft` |
| Position WheelFrontRight | `Vector3(0.8, -0.5, -1.0)` | `WheelFrontRight` |
| Position WheelRearLeft | `Vector3(-0.8, -0.5, 1.0)` | `WheelRearLeft` |
| Position WheelRearRight | `Vector3(0.8, -0.5, 1.0)` | `WheelRearRight` |
| `wheel_radius` | `0.35` m | chaque VehicleWheel3D |
| `wheel_rest_length` | `0.25` m | chaque VehicleWheel3D |
| `suspension_travel` | `0.2` m | chaque VehicleWheel3D |
| `suspension_stiffness` | `5.88` | chaque VehicleWheel3D |
| `damping_compression` | `0.83` | chaque VehicleWheel3D |
| `damping_relaxation` | `0.88` | chaque VehicleWheel3D |
| `suspension_max_force` | `6000.0` N | chaque VehicleWheel3D |
| `wheel_friction_slip` | `10.5` | chaque VehicleWheel3D |
| `InteractionZone` rayon | `3.0` m | `SphereShape3D` |

## Comportements attendus

Chaque comportement est testable unitairement avec GUT dans `tests/test_18_refonte_vehicule.gd`.

### Structure de car.tscn

**B1.** La scène `res://scenes/vehicles/car.tscn` instanciée : la racine s'appelle `"Car"`, est de type `VehicleBody3D`, et `car.get_script() == null` (aucun script attaché à la racine).

**B2.** `car.get_node("CarBodyCollision")` est un `CollisionShape3D` dont la `shape` est une `BoxShape3D` avec `size == Vector3(4.0, 1.5, 2.0)` (tolérance 0.001 par composante).

**B3.** `car` a exactement 4 enfants de type `VehicleWheel3D` : compter les enfants avec `is VehicleWheel3D == true` donne `4`.

**B4.** `car.get_node("WheelFrontLeft").use_as_steering == true` et `car.get_node("WheelFrontLeft").use_as_traction == false`. Idem pour `WheelFrontRight`.

**B5.** `car.get_node("WheelRearLeft").use_as_steering == false` et `car.get_node("WheelRearLeft").use_as_traction == true`. Idem pour `WheelRearRight`.

**B6.** `car.get_node("WheelFrontLeft").position` est approximativement `Vector3(-0.8, -0.5, -1.0)` (tolérance 0.001 par composante).

**B7.** `car.get_node("WheelFrontRight").position` est approximativement `Vector3(0.8, -0.5, -1.0)` (tolérance 0.001 par composante).

**B8.** `car.get_node("WheelRearLeft").position` est approximativement `Vector3(-0.8, -0.5, 1.0)` (tolérance 0.001 par composante).

**B9.** `car.get_node("WheelRearRight").position` est approximativement `Vector3(0.8, -0.5, 1.0)` (tolérance 0.001 par composante).

**B10.** Pour chacun des 4 `VehicleWheel3D`, les paramètres suivants sont vérifiés (tolérance 0.001) : `wheel_radius == 0.35`, `suspension_travel == 0.2`, `suspension_stiffness == 5.88`, `damping_compression == 0.83`, `damping_relaxation == 0.88`, `suspension_max_force == 6000.0`, `wheel_friction_slip == 10.5`, `wheel_rest_length == 0.25`.

**B11.** Pour chacun des 4 `VehicleWheel3D`, le nombre d'enfants de type `MeshInstance3D` est 0 : `wheel.get_children().filter(func(c): return c is MeshInstance3D).size() == 0`.

### Intégration GLB (CarVisuals)

**B12.** `ResourceLoader.exists("res://assets/vehicles/car/car_body.glb") == true` — le fichier GLB est présent et chargeable.

**B13.** `ResourceLoader.exists("res://assets/vehicles/car/wheel.glb") == false` — le fichier wheel.glb n'existe pas (aucune référence ni fichier attendu).

**B14.** Après instanciation de `car.tscn` et entrée dans le SceneTree (`add_child_autofree(car)`), `car.get_node("CarBodyMesh").get_child_count() >= 1` — le GLB (ou le fallback BoxMesh) a été ajouté comme enfant par `CarVisuals._ready()`.

**B15.** Quand `car_body.glb` est présent : le premier enfant `Node3D` de `CarBodyMesh` a `rotation_degrees.y` approximativement égal à `-90.0` (tolérance 0.1°).

**B16.** `CarVisuals` n'a pas de méthode nommée `_masquer_roues` : `car_visuals_instance.has_method("_masquer_roues") == false`.

**B17.** Le contenu textuel du fichier source `res://src/vehicles/car_visuals.gd` ne contient ni la chaîne `"wheel.glb"` ni la chaîne `"_masquer_roues"`. (Test via `FileAccess.open(...).get_as_text()` suivi d'un `find`.)

### Constantes CarController

**B18.** `CarController.ENGINE_FORCE == 8000.0` : instancier `CarController` (ou lire la constante de classe), vérifier l'égalité stricte.

**B19.** `CarController.BRAKE_FORCE == 80.0` : même approche.

**B20.** `CarController.MAX_STEERING == 0.4` : même approche.

**B21.** `CarController.STEERING_SPEED == 5.0` : même approche.

**B22.** `CarController.FORWARD_SPEED_THRESHOLD == 0.5` : même approche.

### Comportement de conduite

Les tests B23 à B30 utilisent un `CarController` instancié avec injection manuelle de `_game_state` (mock `GameState` avec `player_mode = IN_VEHICLE`) et `_car_body` (instance réelle de `VehicleBody3D` ajoutée au SceneTree). `_physics_process(0.016)` est appelé explicitement après injection des inputs simulés.

Pour simuler un input : utiliser `Input.action_press("drive_forward")` / `Input.action_release(...)` dans `before_each` / `after_each`, ou utiliser un sous-class mock de `CarController` qui surcharge la lecture des inputs.

**B23.** `drive_forward` pressé + `_game_state.player_mode == IN_VEHICLE` + appel `_physics_process(0.016)` → `_car_body.engine_force > 0`.

**B24.** `drive_backward` pressé + vitesse linéaire du `_car_body` ≥ 0.5 m/s (injected via `_car_body.linear_velocity = Vector3(0, 0, -1.0)`) + appel `_physics_process(0.016)` → `_car_body.brake > 0` et `_car_body.engine_force == 0`.

**B25.** `drive_backward` pressé + vitesse linéaire du `_car_body` < 0.5 m/s (injected via `_car_body.linear_velocity = Vector3.ZERO`) + appel `_physics_process(0.016)` → `_car_body.engine_force < 0` et `_car_body.brake == 0`.

**B26.** `drive_left` pressé, appel `_physics_process(0.016)` répété 10 fois → `ctrl._steering > 0`.

**B27.** `drive_right` pressé, appel `_physics_process(0.016)` répété 10 fois → `ctrl._steering < 0`.

**B28.** `_steering` initialisé à `MAX_STEERING` (0.4), aucun input directionnel actif, appel `_physics_process(0.016)` → `abs(ctrl._steering) < 0.4` (retour vers 0 amorcé).

**B29.** `_game_state.player_mode == ON_FOOT` + appel `_physics_process(0.016)` (quel que soit l'input) → `_car_body.engine_force == 0` et `_car_body.brake == 0`.

**B30.** Appel `_physics_process(0.016)` avec `drive_left` maintenu pendant 1000 frames → `ctrl._steering <= MAX_STEERING + 0.001` (le braquage reste clampé à `MAX_STEERING`). Symétriquement avec `drive_right` → `ctrl._steering >= -MAX_STEERING - 0.001`.

### Entrée/sortie véhicule (via GameState inchangé)

Ces tests portent sur `src/core/game_state.gd` tel qu'il est déjà implémenté. Ils constituent des tests de non-régression validant que l'interface de `GameState` reste compatible avec l'architecture de la feature 18.

**B31.** `GameState` instancié seul : `gs.player_mode == GameState.PlayerMode.ON_FOOT`.

**B32.** `gs.enter_vehicle(car_mock)` (avec `car_mock : VehicleBody3D` dans le SceneTree) → `gs.player_mode == GameState.PlayerMode.IN_VEHICLE` et `gs.current_vehicle == car_mock`.

**B33.** Double appel `gs.enter_vehicle(car_mock)` sans `exit_vehicle()` intermédiaire → pas de crash, `gs.player_mode` reste `IN_VEHICLE`, `gs.current_vehicle` est inchangé.

**B34.** `gs.exit_vehicle()` après `enter_vehicle(car_mock)` → `gs.player_mode == GameState.PlayerMode.ON_FOOT` et `gs.current_vehicle == null`.

**B35.** Double appel `gs.exit_vehicle()` sans `enter_vehicle()` intermédiaire → pas de crash, `gs.player_mode` reste `ON_FOOT`.

**B36.** Après `gs.exit_vehicle()` avec `car_mock` positionné à `Vector3(0, 0, 0)` et un `_player` mock en SceneTree : la position du joueur est à distance `<= 3.5` m du centre du `car_mock` (`_player.global_position.distance_to(car_mock.global_position) <= 3.5`).

**B37.** `car.tscn` instancié : `car.get_node_or_null("InteractionZone") != null` et `car.get_node("InteractionZone") is Area3D`.

**B38.** `player_near_car` passe de `false` à `true` quand un `CharacterBody3D` entre dans `InteractionZone` (test via connexion manuelle du signal `body_entered` sur `GameState`, ou via `watch_signals`). Repasse à `false` sur `body_exited`.

### Intégration main.tscn

**B39.** `main.tscn` chargée et instanciée : `main.get_node_or_null("Car") != null` et `main.get_node("Car") is VehicleBody3D`.

**B40.** `main.get_node("Car").position` est approximativement `Vector3(5.0, 1.1, 5.0)` (tolérance 0.001 par composante).

**B41.** `main.get_node_or_null("CarController") != null` et le script attaché à ce nœud a `class_name CarController` (vérifiable via `main.get_node("CarController") is CarController`).

**B42.** Les actions `drive_forward`, `drive_backward`, `drive_left`, `drive_right` sont déclarées dans `InputMap` : `InputMap.has_action("drive_forward") == true`, idem pour les 3 autres.

## Cas limites / erreurs

**CL1.** `_car_body == null` au moment d'appeler `_physics_process(delta)` : le guard retourne immédiatement, aucun appel de propriété sur `_car_body`, aucun crash.

**CL2.** `_game_state == null` au moment d'appeler `_physics_process(delta)` : le guard retourne immédiatement, aucun accès à `_game_state.player_mode`, aucun crash.

**CL3.** `delta == 0.0` passé à `_physics_process` : les formules d'interpolation (`lerp(..., delta * STEERING_SPEED)`) convergent vers la valeur courante sans divergence — `_steering` reste inchangé si lerp(x, target, 0) == x. Aucun crash, aucune division par zéro.

**CL4.** `car_body.glb` absent au runtime (`ResourceLoader.exists(...)` retourne `false`) : `_charger_carrosserie()` ne tente pas de charger ni d'instancier le GLB. Un `BoxMesh` rouge (4.0 × 1.5 × 2.0, albedo `Color(0.8, 0.133, 0.133)`) est ajouté comme enfant de `$CarBodyMesh`. Un `push_warning("car_body.glb introuvable — mock BoxMesh actif")` est émis. Aucun crash. La scène reste jouable.

## Inputs Godot (Input Map)

Les actions suivantes doivent être présentes dans `project.godot`. Elles existent déjà depuis la feature 08 — cette spec confirme qu'elles sont conservées sans modification :

| Action Godot | Touche | Physical keycode | Mode |
|---|---|---|---|
| `drive_forward` | Z (AZERTY) / W (QWERTY) | `KEY_Z` = 90 ou `KEY_W` = 87 selon layout | Accélérer |
| `drive_backward` | S | `KEY_S` = 83 | Freiner / marche arrière |
| `drive_left` | Q (AZERTY) / A (QWERTY) | `KEY_Q` = 81 ou `KEY_A` = 65 | Braquer gauche |
| `drive_right` | D | `KEY_D` = 68 | Braquer droite |
| `interact` | E | `KEY_E` = 69 | Entrer / sortir véhicule (géré par `GameState`) |

Aucune nouvelle action n'est créée par cette feature. Si l'une des actions ci-dessus est absente de `project.godot`, le developer doit l'ajouter selon le format établi dans les specs 03 et 07.

## Assets consommés et intégration par code

| Chemin `res://...` | Statut | Intégration GDScript |
|--------------------|--------|----------------------|
| `res://assets/vehicles/car/car_body.glb` | livré (feature 13, présent dans `assets/vehicles/car/`) | Dans `car_visuals.gd._charger_carrosserie()` : `if ResourceLoader.exists(CAR_BODY_GLB): var body_scene = load(CAR_BODY_GLB); var inst = body_scene.instantiate(); inst.rotation_degrees.y = -90.0; [auto-scale AABB]; $CarBodyMesh.add_child(inst)` |
| `res://assets/vehicles/car/wheel.glb` | supprimé — ne doit plus exister comme référence | Aucune référence dans aucun script ni scène |

**Intégration détaillée de `car_body.glb` :**

1. Vérification d'existence via `ResourceLoader.exists(CAR_BODY_GLB)`.
2. Chargement : `var body_scene: PackedScene = load(CAR_BODY_GLB)`.
3. Instanciation : `var inst: Node3D = body_scene.instantiate()`.
4. Auto-scale AABB : calculer l'AABB du sous-arbre de `inst` (récursif si nécessaire), extraire la dimension maximale, calculer `scale_factor = CAR_LENGTH_TARGET / dim_max`, appliquer `inst.scale = Vector3.ONE * scale_factor`.
5. Rotation d'alignement : `inst.rotation_degrees.y = -90.0` (aligne l'axe -X du GLB sur l'axe -Z de `VehicleBody3D`).
6. Attachement : `$CarBodyMesh.add_child(inst)`.

**Fallback mock (si GLB absent) :**

```
# MOCK — à remplacer par res://assets/vehicles/car/car_body.glb
var mock := MeshInstance3D.new()
var box := BoxMesh.new()
box.size = Vector3(4.0, 1.5, 2.0)
mock.mesh = box
var mat := StandardMaterial3D.new()
mat.albedo_color = Color(0.8, 0.133, 0.133)   # #cc2222
mock.material_override = mat
$CarBodyMesh.add_child(mock)
```

## Dépendances

- **Spec 02** : sol physique `GroundCollider` (StaticBody3D + WorldBoundaryShape3D) dans `main.tscn` — nécessaire pour que le VehicleBody3D ne tombe pas à l'infini.
- **Spec 03** : `PlayerController` avec `set_process_input`, `set_physics_process`, enfant `PlayerBody`.
- **Spec 04 / 09** : `CameraController` avec `@export var target: Node3D`.
- **Spec 07** : `GameState` inchangé — interface `enter_vehicle`, `exit_vehicle`, `player_near_car`, `InteractionZone` — cette spec 18 est rétrocompatible avec `game_state.gd`.
- **Addon GUT** : `addons/gut/` (seul addon autorisé).

## Critères d'acceptation

- [ ] `src/vehicles/car_controller.gd` présent, `class_name CarController` reconnue sans erreur de parse.
- [ ] `src/vehicles/car_visuals.gd` présent, `class_name CarVisuals` reconnue sans erreur de parse.
- [ ] `scenes/vehicles/car.tscn` ouvrable dans l'éditeur Godot 4.6 sans warning rouge ni erreur de ressource manquante.
- [ ] L'arbre de `car.tscn` dans l'éditeur affiche : `Car (VehicleBody3D, sans script)` > `CarBodyCollision`, `CarBodyMesh`, `WheelFrontLeft`, `WheelFrontRight`, `WheelRearLeft`, `WheelRearRight`, `CarVisuals`, `InteractionZone`.
- [ ] Aucun enfant `MeshInstance3D` sous aucun `VehicleWheel3D`.
- [ ] `godot --path . res://main.tscn` se lance sans `ERROR:` ni `SCRIPT ERROR:` dans la console Godot.
- [ ] En jeu : la voiture est visible à `Vector3(5.0, 1.1, 5.0)`, le GLB carrosserie est rendu (ou le BoxMesh rouge si GLB absent).
- [ ] En jeu : touche E près de la voiture → joueur disparaît, caméra suit la voiture, conduite possible.
- [ ] En jeu : conduite → la voiture accélère (Z/W), freine (S à vitesse > 0.5), recule (S à l'arrêt), tourne (Q/A, D).
- [ ] En jeu : touche E dans la voiture → joueur réapparaît à côté, caméra revient sur le joueur.
- [ ] Tests GUT B1–B42 et CL1–CL4 tous verts dans `test_18_refonte_vehicule.gd`.
- [ ] Les anciens fichiers de tests supersédés (`test_06`, `test_07`, `test_08`, `test_13`, `test_14`, `test_15`, `test_16`, `test_17`) sont supprimés ou ne font plus échouer la suite GUT.
- [ ] `godot --headless -s res://addons/gut/gut_cmdln.gd -gdir=res://tests -gexit` retourne 0.

## Hors-périmètre

- Animation de rotation des roues visuelles en fonction de la vitesse.
- Son moteur, son de freinage, son de portière.
- HUD vitesse / indicateur de carburant.
- Plusieurs véhicules simultanés.
- Dommages/collisions destructibles.
- Cinématique d'entrée (porte qui s'ouvre, animation joueur).
- Physique avancée (anti-roll bar, centre de gravité variable).
- Suppression physique du fichier `wheel.glb` du disque — rôle de l'agent `mixamo` uniquement.
- Modification de `src/core/game_state.gd` — ce fichier est hors-périmètre de cette spec.
- Modification de `main.tscn` au-delà de ce que la réécriture de `car.tscn` impose implicitement.
