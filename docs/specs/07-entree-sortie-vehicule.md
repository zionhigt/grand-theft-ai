# Spec 07 — Entrer / sortir d'un véhicule (touche E)

## Contexte

- Design : `docs/design/07-entree-sortie-vehicule.md`
- Bon de commande graphique : `docs/assets/07-entree-sortie-vehicule.md`
- Dépendances de specs précédentes :
  - **Spec 01 — Bootstrap** (`docs/specs/01-bootstrap.md`) : `project.godot` fonctionnel, Input Map accessible.
  - **Spec 02 — Scène 3D minimale** (`docs/specs/02-scene-3d-minimale.md`) : `main.tscn` avec `Main : Node3D` racine, sol physique `GroundCollider`.
  - **Spec 03 — Personnage joueur** (`docs/specs/03-personnage-joueur.md`) : `Player : CharacterBody3D` (script `PlayerController`), spawn `Vector3(0, 0.9, 0)`, capsule rayon 0.4 m, hauteur 1.8 m, méthodes `set_process`, `set_physics_process`, propriété `visible` héritées de `Node`.
  - **Spec 04 — Caméra TP** (`docs/specs/04-camera-tp.md`) : `CameraRig : Node3D` (script `CameraController`), propriété `@export var target: Node3D` assignable dynamiquement, fallback `_ready` vers `../Player`.
  - **Spec 06 — Voiture** (`docs/specs/06-voiture.md`) : `Car : VehicleBody3D` dans `main.tscn`, spawn `Vector3(5, 0.75, 5)`, scène `scenes/vehicles/car.tscn`, nœud racine nommé `"Car"`, masse 1200 kg, aucun script en feature 06.

## Objectif fonctionnel

Permettre au joueur d'entrer dans la voiture (touche E à moins de 3 m) et d'en sortir (touche E quand dans la voiture). Un nœud `GameState` centralise l'état (`ON_FOOT` / `IN_VEHICLE`), masque le personnage, bascule la cible de la caméra et repositionne le joueur à la sortie. La voiture ne se conduit pas encore (feature 08), mais la structure de possession est entièrement en place.

## Arborescence cible

```
.
├── main.tscn                                       # modifié — nœuds GameState (+ HUD optionnel) ajoutés
├── scenes/
│   └── vehicles/
│       └── car.tscn                               # modifié — nœud InteractionZone + CollisionShape3D ajoutés
├── src/
│   └── core/
│       └── game_state.gd                          # créé — GameState extends Node
├── tests/
│   └── test_07_entree_sortie_vehicule.gd          # à écrire par le tester
└── assets/                                        # aucun fichier nouveau (voir bon de commande 07)
```

Notes :
- `src/vehicles/vehicle_entry.gd` n'est **pas** créé : la logique de proximité (`player_near`) réside dans le script du nœud `InteractionZone` géré par `GameState`, qui se connecte aux signaux de l'`Area3D`. Aucun script séparé sur la voiture n'est requis pour cette feature (la voiture reste sans script propre jusqu'à la feature 08).
- `main.tscn` reçoit un nœud `GameState` (et optionnellement `HUD`). Tous les nœuds hérités des features 01–06 sont conservés intacts.
- `scenes/vehicles/car.tscn` est modifié pour ajouter `InteractionZone : Area3D` et son `CollisionShape3D`.

## Interface publique (GDScript)

### `src/core/game_state.gd`

```gdscript
class_name GameState
extends Node

# --- Enum ---

enum PlayerMode { ON_FOOT, IN_VEHICLE }

# --- Propriétés publiques ---

var player_mode: PlayerMode = PlayerMode.ON_FOOT
# État courant du joueur. Lecture libre, modification via enter_vehicle / exit_vehicle.

var current_vehicle: VehicleBody3D = null
# Référence à la voiture occupée. null quand player_mode == ON_FOOT.

var player_near_car: bool = false
# true quand le CharacterBody3D du joueur est dans la zone InteractionZone de la voiture.
# Mis à jour par les signaux body_entered / body_exited de l'Area3D.

# --- Références internes (résolues dans _ready) ---

@export var player_path: NodePath = NodePath("../Player")
@export var camera_rig_path: NodePath = NodePath("../CameraRig")
@export var car_path: NodePath = NodePath("../Car")
# NodePaths vers les nœuds du monde. Assignées dans l'éditeur via l'inspecteur.
# Valeurs par défaut : paths relatifs à Main (GameState est enfant de Main).

# --- Méthodes publiques ---

func enter_vehicle(car: VehicleBody3D) -> void
# Déclenche l'entrée dans la voiture.
# Pré-condition : player_mode == ON_FOOT. Si déjà IN_VEHICLE, retour immédiat (idempotent).
# Séquence :
#   1. player_mode = PlayerMode.IN_VEHICLE
#   2. current_vehicle = car
#   3. _player.set_process_input(false)
#      _player.set_physics_process(false)
#      _player_mesh.visible = false
#   4. _camera_rig.target = car

func exit_vehicle() -> void
# Déclenche la sortie de la voiture.
# Pré-condition : player_mode == IN_VEHICLE. Si déjà ON_FOOT, retour immédiat (idempotent).
# Séquence :
#   1. Calcul de la position de spawn :
#      spawn_pos = current_vehicle.global_position
#                  + current_vehicle.global_transform.basis.x * -2.5
#                  + Vector3(0, 1.0, 0)
#   2. _player.global_position = spawn_pos
#   3. _player.set_process_input(true)
#      _player.set_physics_process(true)
#      _player_mesh.visible = true
#   4. _camera_rig.target = _player
#   5. player_mode = PlayerMode.ON_FOOT
#   6. current_vehicle = null

func _ready() -> void
# Résout les références internes à partir des NodePaths exportés.
# Connecte les signaux body_entered / body_exited de l'Area3D InteractionZone de la voiture.

func _unhandled_input(event: InputEvent) -> void
# Écoute l'action "interact" (touche E).
# Si event.is_action_pressed("interact") :
#   - Si player_mode == ON_FOOT et player_near_car == true : appel enter_vehicle(current_vehicle_ref)
#   - Si player_mode == IN_VEHICLE : appel exit_vehicle()
#   - Sinon : aucun effet (pas d'erreur)
```

**Signatures typées complètes :**

```gdscript
class_name GameState
extends Node

enum PlayerMode { ON_FOOT, IN_VEHICLE }

var player_mode: PlayerMode = PlayerMode.ON_FOOT
var current_vehicle: VehicleBody3D = null
var player_near_car: bool = false

@export var player_path: NodePath = NodePath("../Player")
@export var camera_rig_path: NodePath = NodePath("../CameraRig")
@export var car_path: NodePath = NodePath("../Car")

# Références internes résolues dans _ready
var _player: PlayerController = null
var _player_mesh: MeshInstance3D = null
var _camera_rig: CameraController = null
var _car: VehicleBody3D = null

func _ready() -> void:
    _player = get_node(player_path) as PlayerController
    _camera_rig = get_node(camera_rig_path) as CameraController
    _car = get_node(car_path) as VehicleBody3D
    if _player != null:
        _player_mesh = _player.get_node_or_null("MeshInstance3D") as MeshInstance3D
    if _car != null:
        var zone := _car.get_node_or_null("InteractionZone") as Area3D
        if zone != null:
            zone.body_entered.connect(_on_interaction_zone_body_entered)
            zone.body_exited.connect(_on_interaction_zone_body_exited)

func enter_vehicle(car: VehicleBody3D) -> void:
    if player_mode == PlayerMode.IN_VEHICLE:
        return
    player_mode = PlayerMode.IN_VEHICLE
    current_vehicle = car
    if _player != null:
        _player.set_process_input(false)
        _player.set_physics_process(false)
        if _player_mesh != null:
            _player_mesh.visible = false
    if _camera_rig != null:
        _camera_rig.target = car

func exit_vehicle() -> void:
    if player_mode == PlayerMode.ON_FOOT:
        return
    if current_vehicle != null and _player != null:
        var spawn_pos: Vector3 = current_vehicle.global_position \
            + current_vehicle.global_transform.basis.x * -2.5 \
            + Vector3(0, 1.0, 0)
        _player.global_position = spawn_pos
    if _player != null:
        _player.set_process_input(true)
        _player.set_physics_process(true)
        if _player_mesh != null:
            _player_mesh.visible = true
    if _camera_rig != null:
        _camera_rig.target = _player
    player_mode = PlayerMode.ON_FOOT
    current_vehicle = null

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("interact"):
        if player_mode == PlayerMode.ON_FOOT and player_near_car:
            enter_vehicle(_car)
        elif player_mode == PlayerMode.IN_VEHICLE:
            exit_vehicle()

func _on_interaction_zone_body_entered(body: Node3D) -> void:
    if body is CharacterBody3D:
        player_near_car = true

func _on_interaction_zone_body_exited(body: Node3D) -> void:
    if body is CharacterBody3D:
        player_near_car = false
```

**Notes importantes :**

- `_player_mesh` est résolu via `_player.get_node_or_null("MeshInstance3D")`. Dans `scenes/player/player.tscn`, le nœud visuel s'appelle `MeshInstance3D` (enfant direct du `CharacterBody3D`). Si le nom diffère dans l'implémentation réelle, le developer doit ajuster ce chemin ou le rendre exporté.
- `_unhandled_input` est utilisé (et non `_input`) pour ne pas interférer avec les inputs UI qui consommeraient l'événement en premier.
- `enter_vehicle` reçoit une référence explicite à `car: VehicleBody3D` afin d'être testable unitairement avec une instance mock. En pratique, l'appelant interne passe `_car`.
- La résolution des NodePaths dans `_ready` échoue silencieusement si les nœuds n'existent pas (retourne `null`), ce qui est géré par les gardes `if ... != null` dans chaque méthode.

## Structure des scènes (.tscn)

### `scenes/vehicles/car.tscn` (modifiée — ajout de `InteractionZone`)

L'arbre existant (feature 06) est conservé. Les nœuds suivants sont ajoutés comme enfants du nœud racine `Car` :

```
Car : VehicleBody3D                                  (inchangé — feature 06)
  CarBodyCollision : CollisionShape3D                (inchangé)
  CarBodyMesh : MeshInstance3D                       (inchangé)
  WheelFrontLeft : VehicleWheel3D                    (inchangé)
    WheelMesh : MeshInstance3D
  WheelFrontRight : VehicleWheel3D                   (inchangé)
    WheelMesh : MeshInstance3D
  WheelRearLeft : VehicleWheel3D                     (inchangé)
    WheelMesh : MeshInstance3D
  WheelRearRight : VehicleWheel3D                    (inchangé)
    WheelMesh : MeshInstance3D

  InteractionZone : Area3D                           [NOUVEAU — feature 07]
    # Zone d'interaction joueur/voiture — rayon 3.0 m
    # Détecte body_entered / body_exited pour CharacterBody3D
    monitoring = true
    monitorable = false
    collision_layer = 0                              # ne fait pas partie d'une couche de collision physique
    collision_mask = 1                               # détecte la couche 1 (joueur, sol — couche par défaut)

    CollisionShape3D : CollisionShape3D              [NOUVEAU — feature 07]
      shape = SphereShape3D
        radius = 3.0                                 # mètres
      position = Vector3(0, 0, 0)                   # centrée sur le VehicleBody3D
```

### `main.tscn` (modifiée — ajout de `GameState`, optionnellement `HUD`)

L'état actuel de `main.tscn` (après feature 06) :

```
Main : Node3D
  WorldEnvironment : WorldEnvironment
  DirectionalLight3D : DirectionalLight3D
  Ground : MeshInstance3D
  GroundCollider : StaticBody3D
    CollisionShape3D : CollisionShape3D
  Player : CharacterBody3D              (instance scenes/player/player.tscn)
  CameraRig : Node3D                    (script src/camera/camera_controller.gd)
    Camera3D : Camera3D
  City : Node3D                         (instance scenes/city/city.tscn)
  Car : VehicleBody3D                   (instance scenes/vehicles/car.tscn)
```

Après feature 07, `main.tscn` contient en plus :

```
Main : Node3D
  ...                                   (tous les nœuds précédents inchangés)
  GameState : Node                      [NOUVEAU — feature 07]
    script = res://src/core/game_state.gd
    player_path = NodePath("../Player")
    camera_rig_path = NodePath("../CameraRig")
    car_path = NodePath("../Car")

  HUD : CanvasLayer                     [NOUVEAU optionnel — feature 07]
    # MOCK — à remplacer par res://assets/ui/hud/interact_prompt.tscn si un asset UI est commandé
    layer = 1

    InteractLabel : Label               [NOUVEAU optionnel — feature 07]
      text = "E : Entrer"
      visible = false                   # géré dynamiquement par GameState
      horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
      vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
      anchors_preset = PRESET_BOTTOM_WIDE
      offset_bottom = -40
      # Police par défaut Godot, taille 24 pt, couleur blanche #ffffff
      # Fond semi-transparent : via modulate ou StyleBoxFlat à définir en polish
```

**Note sur le HUD :** le `Label` `InteractLabel` est affiché uniquement quand `player_near_car == true` et `player_mode == ON_FOOT`. La mise à jour de `visible` est effectuée dans `_process` de `GameState` (ou par signal). Le developer décide de l'implémentation exacte, mais le nœud doit exister dans la scène si le HUD est implémenté. Si le HUD n'est pas implémenté en feature 07, les comportements B13/B14 sont marqués optionnels dans les tests.

## Données et constantes

Toutes les constantes de cette feature sont déclarées dans `src/core/game_state.gd`.

| Constante / Valeur | Type | Valeur | Source | Rôle |
|--------------------|------|--------|--------|------|
| `PlayerMode.ON_FOOT` | `enum` | `0` | `game_state.gd` | Joueur à pied, contrôleur actif |
| `PlayerMode.IN_VEHICLE` | `enum` | `1` | `game_state.gd` | Joueur dans la voiture, contrôleur désactivé |
| Rayon `InteractionZone` | `float` | `3.0` | `car.tscn` (SphereShape3D) | Distance maximale joueur-voiture pour interaction |
| Distance de spawn latéral à la sortie | `float` | `2.5` | `game_state.gd` (exit_vehicle) | Distance du centre voiture sur axe X local (côté gauche) |
| Hauteur de spawn joueur à la sortie | `float` | `1.0` | `game_state.gd` (exit_vehicle) | Décalage Y mondial pour éviter le sol |
| `player_mode` valeur initiale | `PlayerMode` | `ON_FOOT` | `game_state.gd` | État au démarrage |
| `current_vehicle` valeur initiale | `VehicleBody3D` | `null` | `game_state.gd` | Aucune voiture occupée au démarrage |
| `player_near_car` valeur initiale | `bool` | `false` | `game_state.gd` | Joueur hors zone au démarrage |

## Comportements attendus

Chaque comportement est testable unitairement avec GUT dans `tests/test_07_entree_sortie_vehicule.gd`. Les comportements B1–B8 s'appuient sur des instances directes de `GameState` et de nœuds mock. Les comportements B9–B11 testent la scène `car.tscn`. Les comportements B12–B14 testent `main.tscn`.

**B1.** Un `GameState` instancié (`add_child_autofree`) a `player_mode == GameState.PlayerMode.ON_FOOT` à la construction — valeur initiale correcte.

**B2.** Après appel `game_state.enter_vehicle(car_mock)` (où `car_mock` est un `VehicleBody3D` ajouté à la scène), `game_state.player_mode == GameState.PlayerMode.IN_VEHICLE` et `game_state.current_vehicle == car_mock`.

**B3.** Après appel `game_state.exit_vehicle()` (précédé d'un `enter_vehicle`), `game_state.player_mode == GameState.PlayerMode.ON_FOOT` et `game_state.current_vehicle == null`.

**B4.** Après `enter_vehicle(car_mock)` : un `PlayerController` mock attaché à `game_state._player` a `is_physics_processing() == false` et `is_processing_input() == false`. Son enfant `MeshInstance3D` a `visible == false`.

**B5.** Après `enter_vehicle(car_mock)` : `game_state._camera_rig.target == car_mock` (la cible de la caméra est la voiture).

**B6.** Après `exit_vehicle()` : la position mondiale du joueur (`_player.global_position`) est égale à `car_mock.global_position + car_mock.global_transform.basis.x * -2.5 + Vector3(0, 1.0, 0)` (tolérance 0.001 par composante).

**B7.** Après `exit_vehicle()` : le `PlayerController` mock a `is_physics_processing() == true` et `is_processing_input() == true`. Son enfant `MeshInstance3D` a `visible == true`.

**B8.** Après `exit_vehicle()` : `game_state._camera_rig.target == _player` (la cible de la caméra est le joueur).

**B9.** La scène `res://scenes/vehicles/car.tscn` instanciée contient un nœud `InteractionZone` enfant direct de `Car` : `car.get_node_or_null("InteractionZone") != null` et `car.get_node("InteractionZone") is Area3D == true`.

**B10.** Le nœud `InteractionZone` contient un `CollisionShape3D` avec une `SphereShape3D` de rayon `3.0` : `car.get_node("InteractionZone/CollisionShape3D").shape is SphereShape3D == true` et `car.get_node("InteractionZone/CollisionShape3D").shape.radius` est à `3.0` (tolérance 0.001).

**B11.** L'`Area3D` `InteractionZone` émet le signal `body_entered` quand un `CharacterBody3D` entre dans la zone : connexion du signal, ajout manuel d'un corps, vérification via `watch_signals` GUT ou compteur interne.

**B12.** Charger `res://main.tscn` : le nœud `"GameState"` existe (`main.get_node_or_null("GameState") != null`) et est de type `GameState` (`main.get_node("GameState") is GameState == true`).

**B13 (optionnel — si HUD implémenté).** Charger `res://main.tscn` : `main.get_node_or_null("HUD") != null` et `main.get_node_or_null("HUD/InteractLabel") != null`.

**B14 (optionnel — si HUD implémenté).** Le nœud `InteractLabel` a `visible == false` au démarrage (`player_near_car` initial = false).

## Cas limites / erreurs

**CL1.** `enter_vehicle(car_mock)` appelé alors que `player_mode == IN_VEHICLE` : retour immédiat, `player_mode` reste `IN_VEHICLE`, `current_vehicle` est inchangé, aucune erreur. Idempotent.

**CL2.** `exit_vehicle()` appelé alors que `player_mode == ON_FOOT` : retour immédiat, `player_mode` reste `ON_FOOT`, aucune erreur. Idempotent.

**CL3.** Action `interact` pressée avec `player_mode == ON_FOOT` et `player_near_car == false` : aucun appel à `enter_vehicle`, `player_mode` reste `ON_FOOT`, aucune erreur.

**CL4.** `_player == null` au moment de `enter_vehicle` (NodePath invalide) : les blocs `if _player != null` évitent tout crash. `player_mode` passe quand même à `IN_VEHICLE` (la transition d'état est effectuée même si les effets secondaires échouent). Aucune erreur GDScript levée.

**CL5.** `_camera_rig == null` au moment de `enter_vehicle` : le bloc `if _camera_rig != null` évite le crash. La cible de la caméra n'est pas modifiée, mais aucune erreur levée.

**CL6.** `current_vehicle == null` au moment de `exit_vehicle` alors que `player_mode == IN_VEHICLE` (état incohérent) : la position de spawn n'est pas calculée (guard `if current_vehicle != null`), le joueur est réactivé et la caméra basculée vers lui, `player_mode` repasse à `ON_FOOT`. Pas de crash.

**CL7.** `exit_vehicle` appelé avec `current_vehicle` positionné à `Vector3(0, 0, 0)` et `basis.x == Vector3(1, 0, 0)` (rotation identité) : position de spawn = `Vector3(-2.5, 1.0, 0)`. Pas de division par zéro, pas d'erreur, comportement déterministe.

## Inputs Godot (Input Map)

L'action `interact` est ajoutée dans la section `[input]` de `project.godot` :

| Action Godot | Touche | Physical keycode | Effet |
|---|---|---|---|
| `interact` | E | `KEY_E` = 69 | Entrer dans la voiture (si proche) ou en sortir |

Section `[input]` à ajouter dans `project.godot` (à compléter après les entrées existantes `move_forward`, `move_backward`, `move_left`, `move_right`) :

```ini
interact={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":69,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
]
}
```

**Note :** `physical_keycode = 69` correspond à la touche `E` sur la position physique du clavier (indépendant du layout AZERTY/QWERTY — la touche E est à la même position sur les deux).

## Assets consommés

| Chemin `res://` | Mock attendu | Usage dans la scène |
|-----------------|-------------|---------------------|
| (aucun asset binaire nouveau) | — | — |

Les éléments de scène fonctionnels suivants sont les "assets" de cette feature (nœuds Godot purs) :

| Nœud / Ressource | Type Godot | Emplacement | Mock ? | Notes |
|---|---|---|---|---|
| `InteractionZone : Area3D` | `Area3D` | enfant de `Car` dans `car.tscn` | Non — nœud définitif | Zone de détection proximité joueur, rayon 3.0 m |
| `InteractionZone/CollisionShape3D` | `CollisionShape3D` | enfant de `InteractionZone` | Non — nœud définitif | `SphereShape3D` rayon 3.0 m, invisible en jeu |
| `GameState : Node` | `Node` | enfant de `Main` dans `main.tscn` | Non — nœud définitif | script `res://src/core/game_state.gd` |
| `HUD : CanvasLayer` (optionnel) | `CanvasLayer` | enfant de `Main` dans `main.tscn` | Oui (mock UI) | `# MOCK — à remplacer par res://assets/ui/hud/interact_prompt.tscn si un asset UI est commandé` |
| `HUD/InteractLabel : Label` (optionnel) | `Label` | enfant de `HUD` | Oui (mock UI) | Texte `"E : Entrer"`, police par défaut Godot |

## Dépendances

- **Spec 01 — Bootstrap projet** : `project.godot` fonctionnel, Input Map avec section `[input]`.
- **Spec 03 — Personnage joueur** : `PlayerController extends CharacterBody3D`, méthodes `set_process_input`, `set_physics_process`, enfant `MeshInstance3D` visible dans `player.tscn`.
- **Spec 04 — Caméra TP** : `CameraController extends Node3D`, propriété `@export var target: Node3D` dynamiquement assignable.
- **Spec 06 — Voiture** : `VehicleBody3D` nommé `Car` dans `main.tscn`, scène `scenes/vehicles/car.tscn`, pas de script propre (inchangé par cette feature).
- **`addons/gut/`** : addon GUT v9.6, installé dans `addons/gut/`. Aucun autre addon autorisé.

## Critères d'acceptation

- [ ] Le fichier `src/core/game_state.gd` est présent, `class_name GameState` est reconnue par GDScript sans erreur de parse.
- [ ] `scenes/vehicles/car.tscn` s'ouvre dans l'éditeur Godot 4.6 sans warning rouge. L'arbre affiche un nœud `InteractionZone : Area3D` enfant de `Car`, avec un enfant `CollisionShape3D` (SphereShape3D rayon 3.0 m).
- [ ] `main.tscn` s'ouvre dans l'éditeur Godot 4.6 sans warning rouge. L'arbre affiche un nœud `GameState : GameState` enfant de `Main`.
- [ ] Les NodePaths `player_path`, `camera_rig_path`, `car_path` du nœud `GameState` sont assignés dans l'inspecteur et résolvent vers les nœuds `Player`, `CameraRig`, `Car`.
- [ ] `godot --path . res://main.tscn` se lance sans `ERROR:` ni `SCRIPT ERROR:` dans la console.
- [ ] En jeu : approcher la voiture à moins de 3 m et appuyer sur E → le personnage disparaît, la caméra suit la voiture.
- [ ] En jeu, depuis la voiture : appuyer sur E → le personnage réapparaît à côté de la voiture, la caméra reprend le joueur.
- [ ] La commande `godot --headless -s res://addons/gut/gut_cmdln.gd -gdir=res://tests -gexit` retourne 0 (tous les tests passent).
- [ ] Les 12 comportements attendus obligatoires (B1 à B12) passent au vert dans GUT.
- [ ] Les 7 cas limites (CL1 à CL7) passent au vert dans GUT.
- [ ] L'action `interact` est déclarée dans `project.godot` avec `physical_keycode = 69` (touche E).

## Hors-périmètre

- Conduite (accélérer, freiner, tourner) : feature 08. Appuyer sur ZQSD/WASD dans la voiture n'a aucun effet en feature 07.
- Script `src/vehicles/car_controller.gd` : feature 08.
- Sons de portière, d'entrée, de sortie : hors proto v0.1.
- Animation du joueur s'asseyant ou sortant : hors proto v0.1. Le joueur disparaît sans transition.
- Test d'obstruction à la sortie (côté droit si côté gauche bloqué) : hors proto v0.1. Position de spawn fixe côté gauche.
- Sélection de la voiture la plus proche quand plusieurs voitures sont présentes : hors proto v0.1.
- Cinématique d'entrée (porte qui s'ouvre, caméra qui s'approche) : hors proto.
- Asset UI dédié `res://assets/ui/hud/` : déclaré hors-périmètre par le bon de commande 07.
- Cooldown entre deux appuis sur E : hors proto v0.1.
- PNJ occupant la voiture : hors proto.
