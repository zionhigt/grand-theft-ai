# Spec 19 — Animations véhicule (entrer / conduire / sortir)

## Contexte

- Design : `docs/design/19-animations-vehicule.md`
- Bon de commande graphique : `docs/assets/19-animations-vehicule.md`
- Dépendances de specs précédentes :
  - **Spec 10** (`docs/specs/10-personnage-3d.md`) : fournit `scenes/player/player.tscn` avec `PlayerBody : Node3D`, `AnimationPlayer` (animations "idle" / "walk"), `player_controller.gd` avec `_anim_player`, `_update_animation()`, `_injecter_animation()`.
  - **Spec 18** (`docs/specs/18-refonte-vehicule.md`) : fournit `src/core/game_state.gd` avec `enter_vehicle()` / `exit_vehicle()`, le reparentage de `_player_body` vers `VehicleBody3D`, les marqueurs `_driver_seat` / `_exit_point`, `src/vehicles/car_controller.gd` avec la guard `player_mode != IN_VEHICLE`.

Cette feature modifie `src/player/player_controller.gd` et `src/core/game_state.gd`. Elle ne réécrit pas `src/vehicles/car_controller.gd` mais en modifie la guard de conduite. Elle ne touche pas `scenes/vehicles/car.tscn`.

## Objectif fonctionnel

Ajouter trois animations squelettales (`"car_enter"`, `"car_drive"`, `"car_exit"`) au cycle d'interaction joueur-véhicule, via une machine à états à trois nouveaux états dans `PlayerController`. Chaque animation est jouée depuis l'`AnimationPlayer` de `scenes/player/player.tscn`. En l'absence des GLB Mixamo, la transition est instantanée (comportement feature 18 conservé). Aucun crash quelle que soit la présence des assets.

## Arborescence cible

```
src/
  player/
    player_controller.gd       [MODIFIÉ — nouveaux états + _play_anim + signal vehicle_anim_finished]
  core/
    game_state.gd              [MODIFIÉ — enter_vehicle / exit_vehicle délèguent aux animations]
  vehicles/
    car_controller.gd          [MODIFIÉ — guard étendue : bloquer les inputs pendant car_enter / car_exit]

scenes/
  player/
    player.tscn                [INCHANGÉ structurellement — AnimationPlayer étendu par code dans _ready()]

tests/
  test_19_animations_vehicule.gd   [à écrire par le tester]

assets/
  characters/
    player/
      player_body.glb          [livré — feature 10, inchangé]
      player_idle.glb          [livré — feature 10, inchangé]
      player_walk.glb          [livré — feature 10, inchangé]
      player_car_enter.glb     [nouveau — animation entrer dans voiture — non livré au moment de la spec]
      player_car_drive.glb     [nouveau — animation conduire/assis en boucle — non livré]
      player_car_exit.glb      [nouveau — animation sortir de voiture — non livré]
```

Aucun nouveau fichier `.tscn` ni dossier `assets/` n'est créé. Tous les changements sont en GDScript.

## Interface publique (GDScript)

### `src/player/player_controller.gd` (modifié)

```gdscript
class_name PlayerController
extends CharacterBody3D

# (tout le contenu existant des specs 03, 10, 11, 12 est conservé intact)

# --- Constantes ajoutées (feature 19) ---

const DRIVER_SEAT_OFFSET: Vector3 = Vector3(-0.4, 0.6, 0.3)
# Offset du siège conducteur par rapport à l'origine du VehicleBody3D (espace local).
# Utilisé pour repositionner PlayerController en _physics_process quand état == DRIVING.
# Ajustable à l'implémentation visuelle — cette valeur est la valeur de référence spécifiée.

# --- Signaux ajoutés (feature 19) ---

signal vehicle_anim_finished
# Émis par _on_vehicle_anim_finished() à la fin d'une animation véhicule non bouclée.
# Permet à GameState de déclencher la transition d'état suivante sans coupler
# les deux scripts via un appel direct.

# --- Variables d'état ajoutées (feature 19) ---

var _vehicle_state: String = "none"
# État courant dans le cycle véhicule.
# Valeurs possibles : "none", "car_enter", "car_drive", "car_exit"
# "none" = état piéton normal, _vehicle_state n'interfère pas avec idle/walk.

var _followed_vehicle: VehicleBody3D = null
# Référence au VehicleBody3D suivi pendant l'état "car_drive".
# null quand _vehicle_state != "car_drive".
# Assigné par GameState avant d'appeler start_car_enter().

# --- Méthodes publiques ajoutées (feature 19) ---

func start_car_enter(vehicle: VehicleBody3D) -> void
# Appelée par GameState juste avant enter_vehicle().
# Enregistre _followed_vehicle.
# Passe _vehicle_state à "car_enter".
# Appelle _play_anim("car_enter").
# Désactive set_process_input(false) et set_physics_process(false) pendant la durée de l'animation.
# Si _play_anim détecte l'absence de l'animation (fallback), vehicle_anim_finished est émis
# immédiatement via _on_vehicle_anim_finished() sans attendre de signal AnimationPlayer.

func start_car_drive() -> void
# Appelée par GameState après réception du signal vehicle_anim_finished en provenance de
# l'état "car_enter".
# Passe _vehicle_state à "car_drive".
# Appelle _play_anim("car_drive").
# Réactive set_physics_process(true) pour le suivi de position du siège en _physics_process.
# set_process_input reste false (inputs pilotés par CarController).

func start_car_exit(exit_position: Vector3) -> void
# Appelée par GameState quand le joueur presse E depuis l'état "car_drive".
# Positionne le PlayerController à exit_position (position de spawn à côté de la portière).
# Passe _vehicle_state à "car_exit".
# Appelle _play_anim("car_exit").
# set_physics_process(false) pendant l'animation.
# Si fallback (animation absente), vehicle_anim_finished est émis immédiatement.

func finish_car_exit() -> void
# Appelée par GameState après réception du signal vehicle_anim_finished en provenance de
# l'état "car_exit".
# Passe _vehicle_state à "none".
# _followed_vehicle = null.
# Réactive set_process_input(true) et set_physics_process(true).
# Reprend l'animation idle/walk normale via _update_animation().

func _play_anim(anim_name: String) -> void
# Joue l'animation anim_name sur _anim_player.
# Guard 1 : si _anim_player == null → appel immédiat de _on_vehicle_anim_finished() + return.
# Guard 2 : si not _anim_player.has_animation(anim_name) :
#   # MOCK — animation absente, transition instantanée.
#   # À remplacer par res://assets/characters/player/<anim_name>.glb
#   _on_vehicle_anim_finished()
#   return
# Sinon :
#   _anim_player.play(anim_name)
#   (le signal AnimationPlayer.animation_finished appellera _on_vehicle_anim_finished
#    uniquement pour les animations non bouclées — voir section Comportements attendus)

func _on_vehicle_anim_finished(anim_name: String = "") -> void
# Callback connecté au signal AnimationPlayer.animation_finished dans _ready().
# Filtre : si anim_name est "idle" ou "walk", retour immédiat (ces animations ne déclenchent pas
# de transition véhicule).
# Si anim_name == "car_enter" ou anim_name == "" (fallback) et _vehicle_state == "car_enter" :
#   émet vehicle_anim_finished.
# Si anim_name == "car_exit" ou anim_name == "" (fallback) et _vehicle_state == "car_exit" :
#   émet vehicle_anim_finished.
# Pour "car_drive" (animation bouclée) : ne pas connecter la fin d'animation au signal
# (la boucle ne se "termine" jamais).
```

**Modification de `_ready()` :** connexion du signal `AnimationPlayer.animation_finished` au callback `_on_vehicle_anim_finished`, et chargement des animations véhicule via `_charger_animations_vehicule()`.

```gdscript
func _ready() -> void:
    _charger_mesh_joueur()
    _charger_animations()
    _charger_animations_vehicule()   # <-- ajout feature 19
    _anim_player = get_node_or_null("AnimationPlayer") as AnimationPlayer
    if _anim_player != null:
        _anim_player.animation_finished.connect(_on_vehicle_anim_finished)

func _charger_animations_vehicule() -> void
# Injecte les trois animations véhicule dans l'AnimationPlayer via _injecter_animation().
# Utilise les chemins :
#   "res://assets/characters/player/player_car_enter.glb" → nom "car_enter"
#   "res://assets/characters/player/player_car_drive.glb" → nom "car_drive"
#   "res://assets/characters/player/player_car_exit.glb"  → nom "car_exit"
# Si un GLB est absent (ResourceLoader.exists retourne false), _injecter_animation est ignorée
# silencieusement pour ce GLB (load retourne null → return immédiat dans _injecter_animation).
# Après injection, configurer le mode boucle sur "car_drive" :
#   var anim: Animation = _anim_player.get_animation("car_drive")
#   anim.loop_mode = Animation.LOOP_LINEAR
# Les animations "car_enter" et "car_exit" restent en LOOP_NONE (défaut Mixamo = non bouclé).
```

**Modification de `_physics_process()` :** pendant l'état `"car_drive"`, repositionner le `PlayerController` au siège conducteur :

```gdscript
func _physics_process(delta: float) -> void:
    # (contenu existant features 03, 10, 11, 12 — inchangé)
    # ...
    # --- Feature 19 : suivi siège conducteur ---
    if _vehicle_state == "car_drive" and _followed_vehicle != null:
        global_position = _followed_vehicle.global_position \
            + _followed_vehicle.global_transform.basis * DRIVER_SEAT_OFFSET
```

**Modification de `_update_animation()` :** bloquer idle/walk pendant les états véhicule :

```gdscript
func _update_animation() -> void:
    if _anim_player == null:
        return
    # --- Feature 19 : ne pas jouer idle/walk pendant les transitions véhicule ---
    if _vehicle_state != "none":
        return
    var anim_name: String = "walk" if get_state() == "walk" else "idle"
    if not _anim_player.has_animation(anim_name):
        return
    if _anim_player.current_animation != anim_name:
        _anim_player.play(anim_name)
```

### `src/core/game_state.gd` (modifié)

Les méthodes `enter_vehicle()` et `exit_vehicle()` sont modifiées pour déléguer l'animation au `PlayerController` et attendre le signal `vehicle_anim_finished` avant de poursuivre la logique.

```gdscript
# --- Variables ajoutées (feature 19) ---

var _anim_enter_pending: bool = false
# true entre le début de "car_enter" et la réception de vehicle_anim_finished.
# Bloque un double déclenchement de enter_vehicle.

var _anim_exit_pending: bool = false
# true entre le début de "car_exit" et la réception de vehicle_anim_finished.

# --- Modification de _ready() ---

func _ready() -> void:
    # (résolutions NodePaths existantes — inchangées)
    if _player != null:
        _player.vehicle_anim_finished.connect(_on_player_vehicle_anim_finished)
    # ... (reste inchangé)

# --- Méthodes modifiées ---

func enter_vehicle(car: VehicleBody3D) -> void:
    # Guard : idempotent — si déjà IN_VEHICLE ou animation en cours, retour immédiat.
    if player_mode == PlayerMode.IN_VEHICLE:
        return
    if _anim_enter_pending:
        return
    _anim_enter_pending = true
    # Lancer l'animation d'entrée via PlayerController
    if _player != null:
        _player.start_car_enter(car)
    else:
        # Pas de joueur → transition instantanée (comportement feature 18)
        _complete_enter_vehicle(car)

func _complete_enter_vehicle(car: VehicleBody3D) -> void
# Exécute la logique d'entrée effective (ancienne logique de enter_vehicle feature 18) :
#   player_mode = PlayerMode.IN_VEHICLE
#   current_vehicle = car
#   reparentage de _player_body vers car
#   positionnement au _driver_seat
#   appel _player.start_car_drive()
#   basculement caméra sur car
#   _anim_enter_pending = false

func exit_vehicle() -> void:
    # Guard : idempotent — si déjà ON_FOOT ou animation en cours, retour immédiat.
    if player_mode == PlayerMode.ON_FOOT:
        return
    if _anim_exit_pending:
        return
    _anim_exit_pending = true
    # Bloquer les inputs de conduite immédiatement
    if _player != null:
        var exit_pos: Vector3
        if _exit_point != null:
            exit_pos = _exit_point.global_position + Vector3(0, 0.9, 0)
        else:
            exit_pos = current_vehicle.global_position \
                + current_vehicle.global_transform.basis.x * -2.5 \
                + Vector3(0, 1.0, 0)
        _player.start_car_exit(exit_pos)
    else:
        _complete_exit_vehicle()

func _complete_exit_vehicle() -> void
# Exécute la logique de sortie effective (ancienne logique de exit_vehicle feature 18) :
#   réactivation set_process_input(true) et set_physics_process(true)
#   reparentage _player_body vers original_parent
#   remise à zéro position/rotation locale de _player_body
#   _player_body.visible = true
#   basculement caméra sur _player
#   player_mode = PlayerMode.ON_FOOT
#   current_vehicle = null
#   appel _player.finish_car_exit()
#   _anim_exit_pending = false

func _on_player_vehicle_anim_finished() -> void
# Récepteur du signal vehicle_anim_finished émis par PlayerController.
# Discrimine selon l'état courant :
#   Si _anim_enter_pending == true : appeler _complete_enter_vehicle(current_vehicle ou _car)
#   Si _anim_exit_pending == true  : appeler _complete_exit_vehicle()
```

### `src/vehicles/car_controller.gd` (modifié)

La guard de `_physics_process` est étendue pour bloquer les inputs de conduite pendant `"car_enter"` et `"car_exit"`. La référence au `PlayerController` est ajoutée.

```gdscript
# --- Export ajouté ---

@export var player_path: NodePath

# --- Variable ajoutée ---

var _player: PlayerController = null

# --- Modification de _ready() ---

func _ready() -> void:
    # (résolutions existantes — inchangées)
    if _player == null and not player_path.is_empty():
        _player = get_node(player_path) as PlayerController

# --- Modification de _physics_process() ---

func _physics_process(delta: float) -> void:
    Input.flush_buffered_events()
    if _car_body == null or _game_state == null:
        return
    if _game_state.player_mode != GameState.PlayerMode.IN_VEHICLE:
        _car_body.engine_force = 0
        _car_body.brake = 0
        return
    # --- Feature 19 : bloquer les inputs pendant les transitions d'animation ---
    if _player != null and _player._vehicle_state != "car_drive":
        _car_body.engine_force = 0
        _car_body.brake = 0
        return
    # (reste de la logique de conduite — inchangé)
```

## Structure des scènes (.tscn)

### `scenes/player/player.tscn` (inchangée structurellement)

L'arbre des nœuds reste identique à la spec 10 :

```
Player : CharacterBody3D
  (script = res://src/player/player_controller.gd)
  ├── CollisionShape3D : CollisionShape3D
  │     shape = CapsuleShape3D (height=1.8, radius=0.4)
  │     [INCHANGÉ]
  ├── PlayerBody : Node3D
  │     [INCHANGÉ — contient player_body.glb instancié par _charger_mesh_joueur()]
  └── AnimationPlayer : AnimationPlayer
        # Contient "idle" et "walk" (chargées par _charger_animations() depuis feature 10)
        # Feature 19 y ajoute par code : "car_enter", "car_drive" (loop), "car_exit"
        # Si les GLB sont absents, ces pistes ne sont pas présentes → fallback instantané.
        autoplay = ""
```

Aucun nœud supplémentaire n'est ajouté dans la scène. Les animations véhicule sont injectées exclusivement par code dans `_charger_animations_vehicule()`.

**Note sur la `CollisionShape3D` pendant `"car_drive"` :** selon le design, la `CollisionShape3D` du `Player` doit être désactivée pendant la conduite pour éviter les conflits physiques avec le `VehicleBody3D`. La désactivation se fait dans `_complete_enter_vehicle()` via `_player.get_node("CollisionShape3D").disabled = true`, et la réactivation dans `_complete_exit_vehicle()` via `_player.get_node("CollisionShape3D").disabled = false`.

### `main.tscn` (inchangée)

La structure de `main.tscn` reste celle de la spec 18. Le nœud `CarController` doit recevoir un nouveau `player_path` pointant sur `../Player` pour que la guard de conduite fonctionne.

```
Main : Node3D
  ...
  CarController : Node         [MODIFIÉ : player_path = NodePath("../Player") ajouté]
  ...
```

## Données et constantes

| Constante / Paramètre | Valeur | Script | Description |
|-----------------------|--------|--------|-------------|
| `DRIVER_SEAT_OFFSET` | `Vector3(-0.4, 0.6, 0.3)` | `player_controller.gd` | Offset siège conducteur en espace local VehicleBody3D. X négatif = côté gauche (conducteur), Y positif = mi-hauteur caisse, Z positif = légèrement en avant. Ajustable. |
| Durée animation `"car_enter"` | ~1.0 s | Données GLB Mixamo | Non bouclée. Fallback si absente : instantané. |
| Durée animation `"car_drive"` | ~2.0 s (boucle) | Données GLB Mixamo | Bouclée. `loop_mode = Animation.LOOP_LINEAR`. |
| Durée animation `"car_exit"` | ~0.8 s | Données GLB Mixamo | Non bouclée. Fallback si absente : instantané. |
| Nom animation entrée | `"car_enter"` | `player_controller.gd` | Nom exact dans l'AnimationPlayer après injection. |
| Nom animation conduite | `"car_drive"` | `player_controller.gd` | Nom exact — boucle. |
| Nom animation sortie | `"car_exit"` | `player_controller.gd` | Nom exact. |
| Mode boucle `"car_drive"` | `Animation.LOOP_LINEAR` | `player_controller.gd` | Défini par code après injection dans `_charger_animations_vehicule()`. |

## Comportements attendus

Chaque comportement est testable unitairement avec GUT dans `tests/test_19_animations_vehicule.gd`.

### Machine à états PlayerController (B1–B8)

**B1.** `PlayerController` instancié et ajouté au SceneTree : `ctrl._vehicle_state == "none"` et `ctrl._followed_vehicle == null`.

**B2.** `ctrl.start_car_enter(vehicle_mock)` appelé : `ctrl._vehicle_state == "car_enter"` et `ctrl._followed_vehicle == vehicle_mock`.

**B3.** Après `start_car_enter(vehicle_mock)` avec un `AnimationPlayer` **sans** l'animation `"car_enter"` : le signal `vehicle_anim_finished` est émis immédiatement (dans le même appel, synchrone), `_vehicle_state` reste à `"car_enter"` jusqu'à que `GameState` appelle `start_car_drive()`.

**B4.** `ctrl.start_car_drive()` appelé (après `start_car_enter`) : `ctrl._vehicle_state == "car_drive"`.

**B5.** `ctrl.start_car_exit(Vector3(1.0, 0.9, 0.0))` appelé : `ctrl._vehicle_state == "car_exit"` et `ctrl.global_position` est approximativement `Vector3(1.0, 0.9, 0.0)` (tolérance 0.01 par composante, après add_child_autofree dans le SceneTree).

**B6.** Après `start_car_exit(exit_pos)` avec un `AnimationPlayer` **sans** l'animation `"car_exit"` : le signal `vehicle_anim_finished` est émis immédiatement.

**B7.** `ctrl.finish_car_exit()` appelé : `ctrl._vehicle_state == "none"` et `ctrl._followed_vehicle == null`.

**B8.** `ctrl._update_animation()` appelé avec `ctrl._vehicle_state == "car_drive"` et un `AnimationPlayer` ayant "idle" et "walk" : la méthode retourne sans jouer "idle" ni "walk" (l'animation courante ne change pas si elle était "car_drive").

### Méthode _play_anim (B9–B12)

**B9.** `ctrl._play_anim("car_enter")` avec `_anim_player == null` : aucun crash, `vehicle_anim_finished` est émis.

**B10.** `ctrl._play_anim("car_enter")` avec un `AnimationPlayer` ne contenant pas `"car_enter"` : aucun crash, `vehicle_anim_finished` est émis.

**B11.** `ctrl._play_anim("car_enter")` avec un `AnimationPlayer` contenant `"car_enter"` : l'animation `"car_enter"` est en cours de lecture (`_anim_player.current_animation == "car_enter"`), `vehicle_anim_finished` **n'est pas encore** émis (il le sera à la fin de l'animation).

**B12.** `ctrl._play_anim("car_drive")` avec un `AnimationPlayer` contenant `"car_drive"` : l'animation `"car_drive"` est en cours de lecture, et l'animation a `loop_mode == Animation.LOOP_LINEAR`.

### Signal vehicle_anim_finished (B13–B15)

**B13.** `ctrl._on_vehicle_anim_finished("idle")` appelé (fin d'une animation idle) : `vehicle_anim_finished` **n'est pas** émis (les animations piéton ne déclenchent pas de transition véhicule).

**B14.** `ctrl._on_vehicle_anim_finished("walk")` appelé : `vehicle_anim_finished` n'est pas émis.

**B15.** `ctrl._on_vehicle_anim_finished("car_enter")` appelé avec `_vehicle_state == "car_enter"` : `vehicle_anim_finished` est émis exactement une fois. Vérifiable via `watch_signals(ctrl)` + `assert_signal_emitted_with_parameters` ou `assert_signal_emit_count`.

### Suivi du siège conducteur (B16–B17)

**B16.** `ctrl._vehicle_state == "car_drive"` et `ctrl._followed_vehicle` pointant sur un `VehicleBody3D` positionné à `Vector3(0, 0, 0)` avec `global_transform = Transform3D.IDENTITY` : après un appel explicite de `ctrl._physics_process(0.016)`, `ctrl.global_position` est approximativement `DRIVER_SEAT_OFFSET` (tolérance 0.01 par composante).

**B17.** `ctrl._vehicle_state == "none"` (piéton normal) : `ctrl._physics_process(0.016)` ne modifie pas la position du `PlayerController` à cause de la logique de siège conducteur (la condition `_vehicle_state == "car_drive"` n'est pas remplie).

### Guard CarController (B18–B20)

**B18.** `CarController._physics_process(0.016)` avec `_game_state.player_mode == IN_VEHICLE` et `_player._vehicle_state == "car_enter"` : `_car_body.engine_force == 0` et `_car_body.brake == 0`.

**B19.** `CarController._physics_process(0.016)` avec `_game_state.player_mode == IN_VEHICLE` et `_player._vehicle_state == "car_exit"` : `_car_body.engine_force == 0` et `_car_body.brake == 0`.

**B20.** `CarController._physics_process(0.016)` avec `_game_state.player_mode == IN_VEHICLE` et `_player._vehicle_state == "car_drive"` et `drive_forward` pressé : `_car_body.engine_force != 0` (la conduite est active).

### Intégration GameState (B21–B27)

**B21.** `GameState.enter_vehicle(car_mock)` appelé avec un `_player` mock ayant `_vehicle_state == "none"` : `_player.start_car_enter(car_mock)` est appelé (vérifiable via un `PlayerController` sous-classé dans le test, ou via `watch_signals`), `gs._anim_enter_pending == true`.

**B22.** Double appel `GameState.enter_vehicle(car_mock)` : le deuxième appel est ignoré (`_anim_enter_pending == true` → return immédiat), `start_car_enter` n'est appelé qu'une seule fois.

**B23.** Après `GameState.enter_vehicle(car_mock)` puis émission de `vehicle_anim_finished` par `_player` : `gs.player_mode == GameState.PlayerMode.IN_VEHICLE` et `gs._anim_enter_pending == false`.

**B24.** Après `_complete_enter_vehicle()` : `_player.get_node("CollisionShape3D").disabled == true` (la collision du joueur est désactivée pendant la conduite).

**B25.** `GameState.exit_vehicle()` avec `_player._vehicle_state == "car_drive"` : `_player.start_car_exit(exit_pos)` est appelé, `gs._anim_exit_pending == true`.

**B26.** Double appel `GameState.exit_vehicle()` : le deuxième appel est ignoré (`_anim_exit_pending == true` → return immédiat).

**B27.** Après `GameState.exit_vehicle()` puis émission de `vehicle_anim_finished` par `_player` : `gs.player_mode == GameState.PlayerMode.ON_FOOT` et `_player.get_node("CollisionShape3D").disabled == false` (collision réactivée).

### Chargement des animations véhicule (B28–B31)

**B28.** `PlayerController` instancié et ajouté au SceneTree : `ctrl.has_method("_charger_animations_vehicule") == true`.

**B29.** Si `res://assets/characters/player/player_car_drive.glb` est présent : après `_charger_animations_vehicule()`, `ctrl._anim_player.has_animation("car_drive") == true` et l'animation a `loop_mode == Animation.LOOP_LINEAR`.

**B30.** Si `res://assets/characters/player/player_car_enter.glb` est absent (ResourceLoader.exists retourne false) : aucun crash dans `_charger_animations_vehicule()`, `_anim_player.has_animation("car_enter") == false`.

**B31.** Le signal `AnimationPlayer.animation_finished` est connecté à `ctrl._on_vehicle_anim_finished` après `_ready()` : `ctrl._anim_player.animation_finished.is_connected(ctrl._on_vehicle_anim_finished) == true` (si `_anim_player != null`).

## Cas limites / erreurs

**CL1.** `_play_anim("")` (chaîne vide) : aucun crash — guard `has_animation("")` retourne false → `_on_vehicle_anim_finished()` appelé immédiatement.

**CL2.** `start_car_enter(null)` (vehicle null) : aucun crash — `_followed_vehicle = null`, `_vehicle_state = "car_enter"`, `_play_anim("car_enter")` appelé normalement. En mode fallback (animation absente), `vehicle_anim_finished` est émis immédiatement. Le suivi de position en `_physics_process` est protégé par `if _followed_vehicle != null`.

**CL3.** `finish_car_exit()` appelé deux fois de suite : idempotent — `_vehicle_state` passe à `"none"` à la première invocation, la deuxième n'a aucun effet visible (remet des valeurs déjà à leur état nominal).

**CL4.** `_on_vehicle_anim_finished` appelé avec `_vehicle_state == "none"` (hors contexte véhicule) : aucun signal `vehicle_anim_finished` émis, aucun crash.

**CL5.** `CarController._physics_process(0.016)` avec `_player == null` et `_game_state.player_mode == IN_VEHICLE` : la guard `_player != null` est absente dans la logique étendue — si `_player == null`, le check `_player._vehicle_state` provoquerait un crash. La guard doit être : `if _player != null and _player._vehicle_state != "car_drive":` → si `_player == null`, cette condition est vraie (car `null != null` est faux... attention : en GDScript `null != null` est `false` donc la condition `_player != null` est `false` → ne rentre pas dans le block → passe à la logique de conduite). **Correction** : la guard doit s'écrire `if _player == null or _player._vehicle_state != "car_drive":` pour bloquer les inputs quand le joueur est inconnu.

**CL6.** `start_car_drive()` appelé alors que `_vehicle_state == "none"` (appel hors séquence) : aucun crash — `_vehicle_state` passe à `"car_drive"`, mais `_followed_vehicle` peut être null → le suivi de position est protégé par `if _followed_vehicle != null`.

**CL7.** Connexion du signal `animation_finished` dans `_ready()` alors que `_anim_player == null` : la connexion est conditionnée par `if _anim_player != null` → aucune tentative de connexion sur null.

## Inputs Godot (Input Map)

Aucune nouvelle action Input Map n'est requise. Les actions existantes sont utilisées sans modification :

| Action | Touche | Comportement modifié |
|--------|--------|---------------------|
| `interact` | E | Déclenche `enter_vehicle` / `exit_vehicle` via `GameState._unhandled_input` — inchangé |
| `move_forward`, `move_backward`, `move_left`, `move_right` | ZQSD/WASD | Bloqués pendant `"car_enter"` et `"car_exit"` via `set_process_input(false)` |
| `drive_forward`, `drive_backward`, `drive_left`, `drive_right` | ZQSD/WASD | Bloqués pendant `"car_enter"` et `"car_exit"` via la guard étendue de `CarController._physics_process` |

## Assets consommés et intégration par code

| Chemin `res://...` | Statut | Intégration GDScript |
|--------------------|--------|----------------------|
| `res://assets/characters/player/player_body.glb` | livré (feature 10) | Inchangé — `_charger_mesh_joueur()` dans `player_controller.gd._ready()` |
| `res://assets/characters/player/player_idle.glb` | livré (feature 10) | Inchangé — `_charger_animations()` via `_injecter_animation()` |
| `res://assets/characters/player/player_walk.glb` | livré (feature 10) | Inchangé |
| `res://assets/characters/player/player_car_enter.glb` | non livré — mock comportemental | `_charger_animations_vehicule()` via `_injecter_animation(ap, chemin, "car_enter")`. Si absent : `_play_anim("car_enter")` appelle `_on_vehicle_anim_finished()` immédiatement. `# MOCK — animation car_enter absente, transition instantanée. À remplacer par res://assets/characters/player/player_car_enter.glb` |
| `res://assets/characters/player/player_car_drive.glb` | non livré — mock comportemental | `_charger_animations_vehicule()` via `_injecter_animation(ap, chemin, "car_drive")`. Si absent : pendant `"car_drive"`, le personnage reste visible sans animation (T-Pose ou dernière pose). `# MOCK — animation car_drive absente. Fallback : visible = true, T-Pose. À remplacer par res://assets/characters/player/player_car_drive.glb` |
| `res://assets/characters/player/player_car_exit.glb` | non livré — mock comportemental | `_charger_animations_vehicule()` via `_injecter_animation(ap, chemin, "car_exit")`. Si absent : `_play_anim("car_exit")` appelle `_on_vehicle_anim_finished()` immédiatement. `# MOCK — animation car_exit absente, transition instantanée. À remplacer par res://assets/characters/player/player_car_exit.glb` |

**Stratégie d'intégration des GLB d'animation :** identique aux animations idle/walk (spec 10). `_injecter_animation()` (existante) charge le GLB, extrait le premier clip disponible (priorité `"mixamo_com"`, sinon premier de la liste), zeroe les tracks de position X/Z, injecte dans la librairie `""` de l'AnimationPlayer. Après injection de `"car_drive"`, appliquer `anim.loop_mode = Animation.LOOP_LINEAR`.

## Dépendances

- **Spec 10** : `PlayerController` avec `_anim_player`, `_injecter_animation()`, `_update_animation()`, `_charger_animations()`, `AnimationPlayer` dans `player.tscn`.
- **Spec 18** : `GameState` avec `enter_vehicle()` / `exit_vehicle()`, `_player_body`, `_driver_seat`, `_exit_point`, `CarController` avec guard `player_mode != IN_VEHICLE`.
- **`addons/gut/`** : addon GUT v9.6 — seul addon autorisé.
- Aucun addon supplémentaire. `AnimationPlayer` et le système de signaux sont natifs Godot 4.6.

## Critères d'acceptation

- [ ] `src/player/player_controller.gd` compile sans erreur GDScript : `_vehicle_state`, `_followed_vehicle`, `start_car_enter()`, `start_car_drive()`, `start_car_exit()`, `finish_car_exit()`, `_play_anim()`, `_on_vehicle_anim_finished()`, `_charger_animations_vehicule()` sont définis. Signal `vehicle_anim_finished` est déclaré.
- [ ] `src/core/game_state.gd` compile sans erreur GDScript : `_anim_enter_pending`, `_anim_exit_pending`, `_complete_enter_vehicle()`, `_complete_exit_vehicle()`, `_on_player_vehicle_anim_finished()` sont définis.
- [ ] `src/vehicles/car_controller.gd` compile sans erreur GDScript : `player_path`, `_player`, guard étendue dans `_physics_process()` sont définis.
- [ ] `godot --path . res://main.tscn` se lance sans `ERROR:` ni `SCRIPT ERROR:` dans la console Godot.
- [ ] En jeu (GLB absents) : touche E près de la voiture → le personnage disparaît instantanément dans la voiture (comportement feature 18 conservé). Touche E dans la voiture → personnage réapparaît instantanément à côté.
- [ ] En jeu (GLB livrés) : touche E près de la voiture → animation `"car_enter"` visible (~1 s), puis personnage visible au siège conducteur. Touche E dans la voiture → animation `"car_exit"` visible (~0.8 s), puis personnage à pied.
- [ ] En jeu : pendant l'animation `"car_enter"`, ZQSD/WASD et accélération ne déplacent rien.
- [ ] En jeu : pendant `"car_drive"`, ZQSD/WASD contrôlent normalement la voiture.
- [ ] En jeu : pendant l'animation `"car_exit"`, aucun déplacement possible.
- [ ] Tests GUT B1–B31 et CL1–CL7 tous verts dans `test_19_animations_vehicule.gd`.
- [ ] Aucun test de `test_18_refonte_vehicule.gd` ne régresse (B1–B42 et CL1–CL4 restent verts).
- [ ] `godot --headless -s res://addons/gut/gut_cmdln.gd -gdir=res://tests -gexit` retourne 0.

## Hors-périmètre

- Sons de portière, d'assise, de ceinture : hors proto v0.1.
- Animation de démarrage moteur séparée : hors proto v0.1.
- Blend d'animations (AnimationTree) : hors proto v0.1.
- Oscillation du personnage synchronisée avec la physique réelle du véhicule : hors proto v0.1.
- Passagers (siège passager, banquette arrière) : hors proto v0.1.
- Modification de la physique VehicleBody3D (feature 18 conservée intacte).
- Modification de la caméra orbitale (feature 09 conservée intacte).
- Toute logique d'animation pour les PNJ.
