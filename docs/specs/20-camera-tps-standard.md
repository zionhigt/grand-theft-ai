# Spec 20 — Refonte caméra TPS standard (spring-back + suppression reset molette)

## Contexte

- Design : `docs/design/20-camera-tps-standard.md`
- Bon de commande graphique : `docs/assets/20-camera-tps-standard.md` — aucun asset graphique (n/a)
- Dépendances de specs précédentes :
  - **Spec 09 — Caméra orbitale** (`docs/specs/09-camera-orbitale.md`) : fournit `CameraController` dans `src/camera/camera_controller.gd`, avec `_yaw`, `_pitch`, `_zoom_level`, `_right_mouse_held`, `ZOOM_DISTANCES`, `PITCH_MIN`, `PITCH_MAX`, `MOUSE_SENSITIVITY`, `EYE_HEIGHT`. La feature 20 modifie exclusivement `_process` et `_unhandled_input` de ce script.
  - **Spec 11 — Alignement personnage-caméra** (`docs/specs/11-alignement-camera-personnage.md`) : fournit `get_yaw()` sur `CameraController` et `set_camera_yaw()` sur `PlayerController`. Conservés intacts.
  - **Spec 12 — Déplacement camera-relatif** (`docs/specs/12-deplacement-camera-relatif.md`) : fournit la propagation permanente du yaw dans `_process`. Conservée, la valeur propagée reste `_yaw` courant (qui converge vers `home_yaw` en mode normal).
  - **Spec 18 — Refonte complète du véhicule** (`docs/specs/18-refonte-vehicule.md`) : fournit le `VehicleBody3D` cible lors de la conduite. La formule `home_yaw` s'applique identiquement à un véhicule et à un personnage.

## Objectif fonctionnel

Transformer la caméra orbitale de la feature 09 en une caméra TPS standard : sans input, `_yaw` suit automatiquement le dos de la cible via un `lerp_angle` vers `home_yaw` (calculé depuis l'orientation de la cible). Le clic droit maintenu suspend ce spring-back et permet l'orbite libre. Dès le relâchement, le spring-back reprend. Le reset clic milieu est supprimé. Le pitch ne bénéficie pas de spring-back.

## Arborescence cible

```
.
├── src/
│   └── camera/
│       └── camera_controller.gd    # modifié — ajout SPRING_RATE, logique spring dans _process,
│                                   #           suppression du reset clic milieu dans _unhandled_input
└── tests/
    └── test_20_camera_tps_standard.gd   # à écrire par le tester (nouveau fichier)
```

Notes :
- Aucune scène `.tscn` n'est créée ni modifiée par cette feature.
- Aucun asset ni mock n'est ajouté.
- `test_09_camera_orbitale.gd` est **partiellement impacté** — voir §Impact sur tests existants.
- `test_11_alignement_camera_personnage.gd` et `test_12_deplacement_camera_relatif.gd` ne sont **pas modifiés**.

## Interface publique (GDScript)

### `src/camera/camera_controller.gd` (modifié)

Le fichier existant est modifié minimalement. Les éléments hérités des features 04, 09, 11, 12 sont conservés sauf indication contraire. Voici le diff complet de ce qui change :

#### Constante ajoutée

```gdscript
const SPRING_RATE: float = 5.0
# Coefficient du lerp_angle appliqué chaque frame vers home_yaw.
# _yaw = lerp_angle(_yaw, home_yaw, SPRING_RATE * delta)
# À 60 FPS (delta ≈ 0.0167) : facteur ≈ 0.083 par frame.
# Retour à ~99 % de l'écart initial en ~1 seconde pour un swipe de 90°.
# Actif uniquement quand _right_mouse_held == false.
```

#### Constantes inchangées (conservation intégrale)

```gdscript
const OFFSET: Vector3 = Vector3(0, 3, 6)         # rétrocompat tests 04 — non utilisé dans _process
const EYE_HEIGHT: float = 1.6
const ZOOM_DISTANCES: Array[float] = [3.0, 4.5, 6.708]
const DEFAULT_PITCH: float = 0.4636
const DEFAULT_YAW: float = 0.0
const DEFAULT_ZOOM_LEVEL: int = 0
const MOUSE_SENSITIVITY: float = 0.003
const PITCH_MIN: float = -0.1745
const PITCH_MAX: float = 1.2217
```

#### Variables d'état inchangées

```gdscript
var _yaw: float = DEFAULT_YAW
# Conservé — angle horizontal courant, absolu en valeur monde.
# En mode normal : converge vers home_yaw via lerp_angle.
# En mode orbite : modifié librement par la souris.
# C'est la valeur propagée à PlayerController via set_camera_yaw(_yaw).

var _pitch: float = DEFAULT_PITCH
# Conservé — borné entre PITCH_MIN et PITCH_MAX.
# Pas de spring-back sur le pitch.

var _zoom_level: int = DEFAULT_ZOOM_LEVEL
# Conservé — entier dans [0, 2].

var _right_mouse_held: bool = false
# Conservé — true = mode orbite (spring suspendu), false = mode normal (spring actif).
```

#### `_process` modifié

```gdscript
func _process(delta: float) -> void:
    if target == null:
        return
    # Spring-back : quand pas en orbite, _yaw converge vers home_yaw
    if not _right_mouse_held:
        var home_yaw: float = target.global_transform.basis.get_euler().y + PI
        _yaw = lerp_angle(_yaw, home_yaw, SPRING_RATE * delta)
    # Positionnement orbital (inchangé depuis feature 09 / 12)
    var target_pos: Vector3 = target.global_position if target.is_inside_tree() else target.position
    var dist: float = ZOOM_DISTANCES[_zoom_level]
    var orbit: Vector3 = Vector3(0.0, 0.0, dist).rotated(Vector3.RIGHT, -_pitch).rotated(Vector3.UP, _yaw)
    global_position = target_pos + orbit
    $Camera3D.look_at(target_pos + Vector3(0.0, EYE_HEIGHT, 0.0), Vector3.UP)
    # Propagation permanente du yaw vers PlayerController (feature 12 — inchangée)
    if target.has_method("set_camera_yaw"):
        target.set_camera_yaw(_yaw)
```

#### `_unhandled_input` modifié

Seul le bloc `MOUSE_BUTTON_MIDDLE` est supprimé. Tous les autres blocs sont conservés à l'identique.

```gdscript
func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        var mb := event as InputEventMouseButton
        if mb.button_index == MOUSE_BUTTON_RIGHT:
            _right_mouse_held = mb.pressed
            if mb.pressed:
                Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
            else:
                Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
        # SUPPRIMÉ : elif mb.button_index == MOUSE_BUTTON_MIDDLE and mb.pressed:
        #     _yaw = DEFAULT_YAW
        #     _zoom_level = DEFAULT_ZOOM_LEVEL
        elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
            _zoom_level = min(_zoom_level + 1, 2)
        elif mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
            _zoom_level = max(_zoom_level - 1, 0)
    elif event is InputEventMouseMotion and _right_mouse_held:
        var mm := event as InputEventMouseMotion
        _yaw -= mm.relative.x * MOUSE_SENSITIVITY
        _pitch = clamp(_pitch - mm.relative.y * MOUSE_SENSITIVITY, PITCH_MIN, PITCH_MAX)
```

#### Méthode `get_yaw()` — inchangée

```gdscript
func get_yaw() -> float:
    return _yaw
```

#### `_ready()` — inchangée

```gdscript
func _ready() -> void:
    if target == null:
        target = get_node_or_null("../Player")
```

## Structure des scènes (.tscn)

`main.tscn` n'est pas modifié. La structure de scène héritée des features précédentes est inchangée :

```
Main : Node3D
│
├── WorldEnvironment : WorldEnvironment
├── DirectionalLight3D : DirectionalLight3D
├── Ground : MeshInstance3D
├── GroundCollider : StaticBody3D
├── Player : CharacterBody3D          (PlayerController)
├── Car : VehicleBody3D               (VehicleController — feature 18)
├── GameState : Node
└── CameraRig : Node3D
      script : res://src/camera/camera_controller.gd
      └── Camera3D : Camera3D
```

## Données et constantes

| Identifiant | Fichier | Type | Valeur | Rôle |
|---|---|---|---|---|
| `SPRING_RATE` | `camera_controller.gd` | `float` | `5.0` | Coefficient lerp_angle par seconde vers home_yaw |
| `OFFSET` | `camera_controller.gd` | `Vector3` | `Vector3(0, 3, 6)` | Rétrocompatibilité tests 04 — non utilisé en runtime |
| `EYE_HEIGHT` | `camera_controller.gd` | `float` | `1.6` | Hauteur du point visé (m) |
| `ZOOM_DISTANCES` | `camera_controller.gd` | `Array[float]` | `[3.0, 4.5, 6.708]` | Distances orbitales discrètes (m) |
| `DEFAULT_PITCH` | `camera_controller.gd` | `float` | `0.4636` | Pitch initial ≈ atan2(3, 6) |
| `DEFAULT_YAW` | `camera_controller.gd` | `float` | `0.0` | Yaw initial |
| `DEFAULT_ZOOM_LEVEL` | `camera_controller.gd` | `int` | `0` | Niveau de zoom initial |
| `MOUSE_SENSITIVITY` | `camera_controller.gd` | `float` | `0.003` | Sensibilité souris (rad/px) |
| `PITCH_MIN` | `camera_controller.gd` | `float` | `-0.1745` | Pitch minimum : -10° |
| `PITCH_MAX` | `camera_controller.gd` | `float` | `1.2217` | Pitch maximum : +70° |
| `_yaw` | `camera_controller.gd` | `float` | init: `DEFAULT_YAW` | Angle horizontal courant — converge vers home_yaw en mode normal |
| `_pitch` | `camera_controller.gd` | `float` | init: `DEFAULT_PITCH` | Angle d'élévation courant — pas de spring |
| `_zoom_level` | `camera_controller.gd` | `int` | init: `DEFAULT_ZOOM_LEVEL` | Niveau de zoom courant `[0, 2]` |
| `_right_mouse_held` | `camera_controller.gd` | `bool` | init: `false` | Flag clic droit maintenu — suspend le spring |
| `home_yaw` | `camera_controller.gd` | `float` | calculé en runtime | `target.global_transform.basis.get_euler().y + PI` — local à `_process` |

## Comportements attendus

Les tests de cette feature s'écrivent dans `tests/test_20_camera_tps_standard.gd`. Chaque comportement ci-dessous est testable unitairement avec GUT sans charger `main.tscn`.

**B1 — Constante SPRING_RATE présente et égale à 5.0.**
`CameraControllerScript.SPRING_RATE` existe et vaut approximativement `5.0` (tolérance `0.0001`).

**B2 — Spring-back actif en mode normal : _yaw converge vers home_yaw.**
Instancier un `CameraController` avec `Camera3D` enfant. Créer une cible `Node3D` dans l'arbre, sans rotation (donc `rotation.y = 0.0`). Assigner `sut.target = cible`. Poser `sut._yaw = PI` (caméra devant la cible). Poser `sut._right_mouse_held = false`. Appeler `sut._process(0.1)`. Vérifier que `sut._yaw` est strictement entre `0.0` et `PI` — c'est-à-dire que le spring a commencé à ramener `_yaw` vers `home_yaw = 0.0 + PI = PI`. Tolérance : `abs(sut._yaw - PI) < abs(PI - PI)` — reformulation : avec `_right_mouse_held = false` et `_yaw` déjà égal à `home_yaw`, `_yaw` ne doit pas changer. Voir B3 pour le cas de convergence.

**B2 (reformulé) — Spring-back : _yaw initial différent de home_yaw est modifié après _process.**
Instancier `sut` avec `Camera3D` enfant. Créer une cible à rotation `y = 0.0` (home_yaw = PI). Poser `sut._yaw = 0.0` (opposé de home_yaw). Poser `sut._right_mouse_held = false`. Appeler `sut._process(0.016)`. Vérifier que `sut._yaw != 0.0` — le spring a modifié `_yaw`.

**B3 — Spring-back : direction de convergence correcte.**
Même setup que B2. Poser `sut._yaw = 0.0`, cible sans rotation (`rotation.y = 0.0`, donc `home_yaw = PI`). Appeler `sut._process(0.016)`. Vérifier : `sut._yaw > 0.0` (convergence vers PI, départ depuis 0, donc _yaw augmente). La valeur attendue est approximativement `lerp_angle(0.0, PI, 5.0 * 0.016)` = `lerp_angle(0.0, PI, 0.08)` ≈ `0.251` (tolérance `0.01`).

**B4 — Spring-back suspendu en mode orbite.**
Instancier `sut` avec `Camera3D` enfant. Créer une cible sans rotation (home_yaw = PI). Poser `sut._yaw = 0.0`. Poser `sut._right_mouse_held = true`. Appeler `sut._process(0.016)`. Vérifier : `sut._yaw` est approximativement `0.0` (tolérance `0.001`) — le spring n'a pas modifié `_yaw`.

**B5 — home_yaw calculé depuis l'orientation de la cible.**
Instancier `sut` avec `Camera3D` enfant. Créer une cible `Node3D` dans l'arbre. Assigner `cible.rotation.y = PI / 2.0`. Poser `sut._yaw = 0.0`. Poser `sut._right_mouse_held = false`. Appeler `sut._process(0.016)`. Calculer `home_yaw_attendu = PI / 2.0 + PI`. Vérifier que `sut._yaw` est compris entre `0.0` et `home_yaw_attendu` dans le sens de la convergence — concrètement `sut._yaw > 0.0` (tolérance `0.001`), car `lerp_angle(0.0, PI/2+PI, 0.08)` est positif.

**B6 — Spring-back avec delta grand : _yaw atteint home_yaw.**
Instancier `sut` avec `Camera3D` enfant. Créer une cible sans rotation (home_yaw = PI). Poser `sut._yaw = 0.0`. Poser `sut._right_mouse_held = false`. Appeler `sut._process(100.0)` (delta très grand, facteur lerp > 1 — clamped à 1 par `lerp_angle`). Vérifier : `sut._yaw` est approximativement `PI` (tolérance `0.01`) — convergence complète en une frame.

**B7 — Suppression du reset clic milieu : clic milieu n'a aucun effet.**
Instancier `sut`. Poser `sut._yaw = 1.57`. Poser `sut._zoom_level = 2`. Construire un `InputEventMouseButton` avec `button_index = MOUSE_BUTTON_MIDDLE`, `pressed = true`. Appeler `sut._unhandled_input(event)`. Vérifier : `sut._yaw` est approximativement `1.57` (tolérance `0.0001`) ET `sut._zoom_level == 2` — aucune valeur réinitialisée.

**B8 — Zoom molette conservé : molette bas depuis niveau 0 passe à niveau 1.**
Comportement inchangé depuis feature 09 — testé ici pour confirmer la non-régression dans la nouvelle implémentation. Poser `sut._zoom_level = 0`. Envoyer `MOUSE_BUTTON_WHEEL_DOWN pressed`. Vérifier : `sut._zoom_level == 1`.

**B9 — Zoom molette conservé : molette haut depuis niveau 2 passe à niveau 1.**
Poser `sut._zoom_level = 2`. Envoyer `MOUSE_BUTTON_WHEEL_UP pressed`. Vérifier : `sut._zoom_level == 1`.

**B10 — Clic droit presse : _right_mouse_held true, spring suspendu.**
Envoyer `MOUSE_BUTTON_RIGHT pressed`. Vérifier : `sut._right_mouse_held == true`. Appeler `sut._process(0.016)` avec une cible (home_yaw ≠ _yaw). Vérifier : `_yaw` inchangé (spring suspendu).

**B11 — Clic droit relâché : _right_mouse_held false, spring reprend.**
Poser `sut._right_mouse_held = true`. Envoyer `MOUSE_BUTTON_RIGHT pressed = false`. Vérifier : `sut._right_mouse_held == false`. Appeler `sut._process(0.016)` avec une cible dont `home_yaw != _yaw`. Vérifier : `_yaw` a changé (spring actif).

**B12 — Propagation du yaw vers PlayerController : valeur propagée = _yaw courant (post-spring).**
Instancier `sut` avec `Camera3D` enfant et un `PlayerController` comme cible. Poser `sut._yaw = 0.0`. Poser `sut._right_mouse_held = false` (spring actif). Cible `rotation.y = 0.0` → `home_yaw = PI`. Appeler `sut._process(0.016)`. Le spring modifie `sut._yaw` (≈ 0.251). Vérifier : `player._camera_yaw` est approximativement égal à `sut._yaw` post-spring (tolérance `0.001`). La valeur propagée est le `_yaw` post-spring — pas `home_yaw`.

**B13 — En véhicule : pas de propagation vers VehicleBody3D.**
Instancier `sut` avec `Camera3D` enfant. Assigner `sut.target = VehicleBody3D` dans l'arbre. Poser `sut._right_mouse_held = false`. Appeler `sut._process(0.016)`. Vérifier : aucun crash. Vérifier : `vehicule.has_method("set_camera_yaw") == false`.

**B14 — Spring-back en véhicule : _yaw converge vers home_yaw du véhicule.**
Instancier `sut` avec `Camera3D` enfant. Créer un `VehicleBody3D` dans l'arbre avec `rotation.y = PI / 4.0`. Assigner `sut.target = vehicule`. Poser `sut._yaw = 0.0`. Poser `sut._right_mouse_held = false`. Appeler `sut._process(0.016)`. `home_yaw = PI/4 + PI`. Vérifier : `sut._yaw > 0.0` (convergence amorcée, tolérance `0.001`).

**B15 — Constante SPRING_RATE présente sur la classe (accessible comme ZOOM_DISTANCES).**
`CameraControllerScript.SPRING_RATE` est accessible depuis la classe (constante de classe, pas d'instance). Valeur ≈ `5.0` (tolérance `0.0001`).

## Cas limites / erreurs

**CL1 — _yaw déjà égal à home_yaw : lerp_angle ne modifie pas _yaw.**
Instancier `sut` avec `Camera3D` enfant. Créer une cible sans rotation (home_yaw = PI). Poser `sut._yaw = PI`. Poser `sut._right_mouse_held = false`. Appeler `sut._process(0.016)`. Vérifier : `sut._yaw` est approximativement `PI` (tolérance `0.0001`) — le spring ne cause pas de dérive quand déjà à la cible.

**CL2 — delta = 0 en mode normal : lerp_angle avec facteur 0 ne modifie pas _yaw.**
Instancier `sut` avec `Camera3D` enfant. Cible sans rotation (home_yaw = PI). Poser `sut._yaw = 0.0`. Poser `sut._right_mouse_held = false`. Appeler `sut._process(0.0)`. Vérifier : `sut._yaw` est approximativement `0.0` (tolérance `0.0001`) — `lerp_angle(0, PI, 5.0 * 0.0)` = `lerp_angle(0, PI, 0)` = `0.0`.

**CL3 — target null : guard protège avant le calcul de home_yaw.**
Poser `sut.target = null`. Poser `sut.global_position = Vector3(1, 2, 3)`. Appeler `sut._process(0.016)`. Vérifier : aucun crash. Vérifier : `sut.global_position == Vector3(1, 2, 3)` (inchangée).

**CL4 — Cible sans rotation appliquée : home_yaw = 0 + PI = PI.**
Créer une cible `Node3D` fraîchement instanciée sans rotation. Vérifier : `home_yaw = cible.global_transform.basis.get_euler().y + PI` est approximativement `PI` (tolérance `0.001`). Note : ce cas limite valide la formule, pas le comportement de `_process`.

**CL5 — lerp_angle passage ±PI : pas de saut angulaire.**
Instancier `sut` avec `Camera3D` enfant. Cible avec `rotation.y = PI - 0.05` → `home_yaw ≈ 2*PI - 0.05`. Poser `sut._yaw = -(PI - 0.05)` (proche de -PI, côté opposé). Poser `sut._right_mouse_held = false`. Appeler `sut._process(0.016)`. Vérifier : la modification de `_yaw` est inférieure à `0.5` rad (pas de saut de plusieurs radians — `lerp_angle` prend le chemin court).

**CL6 — Mouvement souris avec clic droit : _yaw modifié par la souris, pas par le spring.**
Poser `sut._right_mouse_held = true`. Poser `sut._yaw = 0.0`. Envoyer `InputEventMouseMotion` avec `relative = Vector2(100.0, 0.0)`. Vérifier : `sut._yaw` est approximativement `-0.3` (= `-100 * MOUSE_SENSITIVITY`, tolérance `0.0001`) — valeur orbitale, pas spring.

**CL7 — target hors arbre : `target.global_position` inaccessible, fallback sur `target.position`.**
Cette branche (`target.global_position if target.is_inside_tree() else target.position`) est conservée depuis la feature 09. La feature 20 ne modifie pas ce fallback. Aucun nouveau test requis — couvert par les tests existants de la feature 09.

## Inputs Godot (Input Map)

Aucune nouvelle action n'est ajoutée dans `project.godot`. Les boutons souris sont gérés directement via `InputEventMouseButton` et `InputEventMouseMotion` dans `_unhandled_input`. Le clic milieu ne produit désormais aucun effet (bloc supprimé).

Les actions existantes (`move_forward`, `move_backward`, `move_left`, `move_right`, `interact`, `drive_forward`, `drive_backward`, `drive_left`, `drive_right`) restent inchangées.

## Assets consommés et intégration par code

Cette feature ne consomme aucun asset graphique. Aucun mock n'est requis.

| Chemin `res://` | Statut | Intégration GDScript |
|---|---|---|
| (aucun) | n/a | — |

## Impact sur les tests existants

### `tests/test_09_camera_orbitale.gd` — ACTION REQUISE DU TESTER

**B14 (`test_clic_milieu_reset_yaw_et_zoom_mais_conserve_pitch`) — CE TEST CASSE INTENTIONNELLEMENT avec feature 20.**

Ce test vérifie que `_yaw` est remis à `0.0` et `_zoom_level` à `0` après clic milieu. Avec la feature 20, le bloc clic milieu est supprimé — clic milieu n'a plus aucun effet.

Le tester feature 20 **doit** modifier `test_09_camera_orbitale.gd` :
- **Remplacer** le corps de `test_clic_milieu_reset_yaw_et_zoom_mais_conserve_pitch` pour vérifier le **nouveau comportement** : clic milieu n'a aucun effet sur `_yaw`, `_zoom_level` ni `_pitch`.
- La nouvelle assertion correspond au comportement B7 de la spec 20.

Recommandation : conserver le nom de la fonction test pour traçabilité GUT, remplacer les assertions :
```gdscript
func test_clic_milieu_reset_yaw_et_zoom_mais_conserve_pitch() -> void:
    # Feature 20 : clic milieu supprimé — aucun effet
    sut._yaw = 1.57
    sut._pitch = 0.8
    sut._zoom_level = 2
    var ev = _creer_event_bouton(MOUSE_BUTTON_MIDDLE, true)
    sut._unhandled_input(ev)
    assert_almost_eq(sut._yaw, 1.57, 0.0001, "Clic milieu ne doit pas modifier _yaw (feature 20)")
    assert_eq(sut._zoom_level, 2, "Clic milieu ne doit pas modifier _zoom_level (feature 20)")
    assert_almost_eq(sut._pitch, 0.8, 0.0001, "Clic milieu ne doit pas modifier _pitch (feature 20)")
```

**B5 (`test_position_initiale_yaw0_pitch_default_zoom0`) — comportement à vérifier avec soin.**

Ce test instancie `sut`, assigne une cible à `(0, 0, 0)` sans fixer de rotation de cible, puis appelle `sut._process(0.016)` avec `_yaw = DEFAULT_YAW = 0.0` et `_right_mouse_held = false` (valeurs par défaut).

Avec la feature 20, `_process` calcule `home_yaw = cible.rotation.y + PI = 0 + PI = PI`. Il appelle alors `lerp_angle(0.0, PI, 5.0 * 0.016) = lerp_angle(0.0, PI, 0.08) ≈ 0.251`. Donc `_yaw ≠ 0.0` après `_process`.

La position calculée ne sera plus `Vector3(0, 1.342, 2.683)` mais une position avec composante X non nulle.

**Ce test échoue avec la feature 20 telle que décrite.** Le tester doit choisir une des deux options :

**Option A (recommandée) :** Modifier B5 pour utiliser `_right_mouse_held = true` (mode orbite — spring suspendu). Le spring est désactivé, `_yaw` reste `0.0`, la position calculée est identique à l'ancienne feature 09 :
```gdscript
func test_position_initiale_yaw0_pitch_default_zoom0() -> void:
    _ajouter_camera3d()
    var cible = _creer_cible(Vector3(0, 0, 0))
    sut.target = cible
    sut._right_mouse_held = true  # spring suspendu — yaw fixe
    sut._process(0.016)
    assert_almost_eq(sut.global_position.x, 0.0, 0.05, ...)
    assert_almost_eq(sut.global_position.y, 1.342, 0.05, ...)
    assert_almost_eq(sut.global_position.z, 2.683, 0.05, ...)
```

**Option B :** Mettre à jour les valeurs attendues avec `_yaw ≈ 0.251` après spring et recalculer la position orbitale attendue.

Le tester choisit l'option A — elle préserve la sémantique du test (vérifier la formule sphérique à yaw connu) sans tester la valeur du spring.

**Autres tests de `test_09_camera_orbitale.gd` — non impactés.**

| Test 09 | Analyse de compatibilité feature 20 |
|---------|--------------------------------------|
| B1 à B4 — constantes | Toutes conservées. Valides. |
| B6/B7 — clic droit press/release | Bloc inchangé dans `_unhandled_input`. Valides. |
| B8 — mouvement souris + clic droit | Bloc inchangé. Valide. |
| B9 — mouvement souris sans clic droit | `_right_mouse_held = false` → `_unhandled_input` n'agit pas sur mouvement. Valide. |
| B10/B11/B12/B13 — zoom molette | Blocs molette inchangés. Valides. |
| B15 — position caméra avec yaw = PI/2 | Ce test pose `sut._yaw = PI / 2.0` directement, puis appelle `_process(0.016)` sans fixer `_right_mouse_held`. Valeur par défaut : `_right_mouse_held = false` → spring actif. `home_yaw = cible.rotation.y + PI = 0 + PI = PI`. `lerp_angle(PI/2, PI, 0.08) ≈ 1.697`. La position calculée avec ce yaw sera différente de `(dist, 0, 0)`. **Ce test casse également.** Le tester doit ajouter `sut._right_mouse_held = true` pour geler `_yaw = PI/2`. |
| B16 — distance euclidienne | Distance euclidienne est `ZOOM_DISTANCES[zoom_level]` quelle que soit l'orientation. Le spring modifie `_yaw` mais pas la norme de l'orbit. **Valide** — mais `_right_mouse_held` non fixé → spring actif. La distance reste exactement `ZOOM_DISTANCES[zoom_level]` car `lerp_angle` modifie uniquement le yaw, pas la norme. **Valide sans modification.** |
| CL1/CL2 — pitch clamp | Blocs `_right_mouse_held = true` → orbite. Spring suspendu. Valides. |
| CL3 — target null | Guard inchangé. Valide. |
| CL4 — delta = 0 | Avec feature 20 et `_right_mouse_held = false` : `lerp_angle(_yaw, home_yaw, 0.0) = _yaw`. Position identique à delta normal. **Valide.** |
| CL5 — multiple zoom | Zoom inchangé. Valide. |
| `test_constante_default_yaw_est_0` | `DEFAULT_YAW` conservé. Valide. |
| `test_variables_etat_initialisees` | `_yaw`, `_pitch`, `_zoom_level`, `_right_mouse_held` conservés. Valides. |

**Résumé des tests 09 à modifier par le tester :**
1. **B14** : remplacer les assertions (clic milieu sans effet).
2. **B5** : ajouter `sut._right_mouse_held = true` pour geler le yaw.
3. **B15** : ajouter `sut._right_mouse_held = true` pour geler le yaw à `PI/2`.

### `tests/test_11_alignement_camera_personnage.gd` — aucune modification nécessaire

- **B2 (`test_get_yaw_retourne_zero_par_defaut`)** : `get_yaw()` retourne `_yaw`. À l'initialisation, `_yaw = DEFAULT_YAW = 0.0`. Aucune rotation de cible n'est configurée dans ce test — le spring ne tourne pas sans cible. Valide.
- **B7 (`test_camera_controller_propage_yaw_quand_clic_droit_maintenu`)** : pose `sut_cam._yaw = 0.5` et `_right_mouse_held = true`. Spring suspendu. `_yaw` reste `0.5`. Propagation de `0.5`. Valide.
- **B8 (`test_camera_controller_propage_yaw_meme_sans_clic_droit`)** : pose `sut_cam._yaw = 0.5` et `_right_mouse_held = false`. Spring actif. Cible = `sut_player` (PlayerController). `home_yaw = sut_player.global_transform.basis.get_euler().y + PI`. À l'init, rotation du PlayerController est `(0, 0, 0)`, donc `home_yaw = 0 + PI = PI`. `lerp_angle(0.5, PI, 0.08) ≈ 0.71`. `_yaw` change de `0.5`. Le test vérifie `player._camera_yaw_dirty == true` après `_process`. La propagation a lieu avec la nouvelle valeur `_yaw ≈ 0.71`. Le test n'assert pas la **valeur** de `_camera_yaw`, uniquement `dirty == true`. **Valide.**
- **Tous les autres tests** : pas de dépendance au comportement du spring.

### `tests/test_12_deplacement_camera_relatif.gd` — aucune modification nécessaire

- **B1** : pose `sut_cam._yaw = 0.5`, `_right_mouse_held = false`. Spring actif. Cible = `sut_player`. `home_yaw = PI`. `lerp_angle(0.5, PI, 0.08) ≈ 0.71`. La valeur propagée est `_yaw ≈ 0.71`, non `0.5`. Le test vérifie `player._camera_yaw ≈ 0.5`. **Ce test CASSE avec feature 20.**
- **B2** : pose `sut_cam._yaw = 1.2`, `_right_mouse_held = true`. Spring suspendu. `_yaw` reste `1.2`. Valide.

**B1 de `test_12` casse également. Le tester feature 20 doit ajouter `sut_cam._right_mouse_held = true` dans le test B1 de `test_12`.**

Note pour le tester : B1 de `test_12` vérifie que la propagation a lieu sans clic droit. L'assertion correcte est que le flag `_camera_yaw_dirty` soit levé — il l'est toujours. Pour ne pas tester la valeur exacte de `_yaw` après spring (qui dépend du `home_yaw` calculé à la volée), l'option propre est de vérifier `dirty == true` plutôt que la valeur précise propagée, **ou** de poser `sut_cam._right_mouse_held = true` pour figer le yaw à `0.5` et garder l'assertion `_camera_yaw ≈ 0.5`.

Recommandation pour le tester : ajouter `sut_cam._right_mouse_held = true` dans le setup de B1 pour préserver l'assertion sur la valeur. Cela ne viole pas l'intent de B1 (qui est de tester la propagation sans condition, non le spring).

**Résumé des tests 12 à modifier par le tester :**
1. **B1** : ajouter `sut_cam._right_mouse_held = true` dans le setup, ou changer l'assertion pour vérifier `dirty == true` plutôt que la valeur exacte.

## Algorithme `_process` — pseudo-code détaillé

```
_process(delta):
  si target == null: retourner immédiatement

  si PAS _right_mouse_held:
    home_yaw ← target.global_transform.basis.get_euler().y + PI
    _yaw ← lerp_angle(_yaw, home_yaw, SPRING_RATE * delta)
    # Note : lerp_angle gère automatiquement le passage ±PI sans saut
    # Note : si SPRING_RATE * delta >= 1.0, lerp_angle retourne home_yaw directement

  target_pos ← target.global_position (ou target.position si hors arbre)
  dist ← ZOOM_DISTANCES[_zoom_level]
  orbit ← Vector3(0, 0, dist) roté de -_pitch autour de RIGHT, puis de _yaw autour de UP
  global_position ← target_pos + orbit
  Camera3D.look_at(target_pos + Vector3(0, EYE_HEIGHT, 0), Vector3.UP)

  si target.has_method("set_camera_yaw"):
    target.set_camera_yaw(_yaw)
    # La valeur propagée est _yaw post-spring si mode normal,
    # ou _yaw orbital si mode orbite.
```

## Dépendances

- **Spec 09 — Caméra orbitale** : `CameraController` existant dans `src/camera/camera_controller.gd`. La feature 20 modifie ce fichier.
- **Spec 11 — Alignement personnage-caméra** : `get_yaw()` et `set_camera_yaw()` réutilisés sans modification.
- **Spec 12 — Déplacement camera-relatif** : propagation permanente du yaw conservée.
- **Spec 18 — Refonte complète du véhicule** : `VehicleBody3D` comme cible possible. Le spring s'applique identiquement.
- **`addons/gut/`** : addon GUT v9.6, déjà installé depuis la feature 01.
- Aucun autre addon autorisé.

## Critères d'acceptation

- [ ] `src/camera/camera_controller.gd` contient la constante `SPRING_RATE = 5.0`, accessible depuis la classe.
- [ ] Dans `_process`, la branche `if not _right_mouse_held:` précède le calcul orbital et appelle `lerp_angle(_yaw, home_yaw, SPRING_RATE * delta)` avec `home_yaw = target.global_transform.basis.get_euler().y + PI`.
- [ ] Dans `_unhandled_input`, le bloc `elif mb.button_index == MOUSE_BUTTON_MIDDLE` est absent (clic milieu sans effet).
- [ ] `godot --path . res://main.tscn` se lance sans `ERROR:` ni `SCRIPT ERROR:`. En avançant tout droit, la caméra reste dans le dos du joueur. Après un swipe clic droit, la caméra revient progressivement derrière le joueur dès le relâchement du bouton droit.
- [ ] `test_09_camera_orbitale.gd` : tests B14, B5 et B15 mis à jour par le tester. Tous les autres tests B/CL restent verts sans modification.
- [ ] `test_11_alignement_camera_personnage.gd` : aucun test modifié. Tous verts.
- [ ] `test_12_deplacement_camera_relatif.gd` : test B1 mis à jour par le tester. Tous verts.
- [ ] `tests/test_20_camera_tps_standard.gd` existe et contient les tests B1 à B15 et CL1 à CL6 spécifiés.
- [ ] La commande `godot --headless -s res://addons/gut/gut_cmdln.gd -gdir=res://tests -gexit` retourne le code de sortie 0 (tous les tests de toutes les suites passent au vert).

## Hors-périmètre

- Collision de caméra (empêcher la caméra de traverser les murs) : hors proto v0.1.
- Spring-back sur le pitch (le pitch reste à la dernière valeur orbitale) : hors périmètre.
- Sensibilité souris réglable dans un menu : hors proto v0.1.
- Rotation automatique après inactivité prolongée (différent du spring-back continu) : hors périmètre.
- Effets visuels liés à la caméra (motion blur, FOV dynamique, depth of field) : hors périmètre.
- Gestion pad / joystick : hors périmètre, clavier + souris uniquement.
- Zoom interpolé (lerp vers la nouvelle distance) : hors périmètre.
- Caméra cinématique (entrée/sortie véhicule) : hors périmètre.
- Inversion axe Y souris : hors périmètre.
