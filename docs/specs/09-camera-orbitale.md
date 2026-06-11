# Spec 09 — Caméra orbitale (rotation souris + zoom molette + reset clic milieu)

## Contexte

- Design : `docs/design/09-camera-orbitale.md`
- Bon de commande graphique : `docs/assets/09-camera-orbitale.md` — aucun asset graphique (n/a)
- Dépendances de specs précédentes :
  - **Spec 04 — Caméra troisième personne** (`docs/specs/04-camera-tp.md`) : fournit `CameraController` dans `src/camera/camera_controller.gd`, avec les constantes `OFFSET`, `EYE_HEIGHT`, la propriété `@export var target: Node3D`, et les méthodes `_ready()` et `_process()`. La feature 09 **modifie** ce script existant — elle n'en crée pas un nouveau.
  - **Spec 07 — Entrer / sortir d'un véhicule** (`docs/specs/07-entree-vehicule.md`) : fournit le mécanisme de changement de `target` dans `CameraController`. Le yaw, pitch et zoom_level doivent être conservés lors du changement de cible (aucune réinitialisation au changement de `target`).

## Objectif fonctionnel

Étendre `CameraController` pour permettre au joueur de contrôler librement la vue de la caméra : rotation orbitale autour de la cible via clic droit maintenu + déplacement souris (yaw libre à 360°, pitch borné entre -10° et +70°), zoom discret à trois niveaux via la molette, et réinitialisation yaw + zoom au clic milieu. La position de la caméra est calculée par formule sphérique (yaw, pitch, distance) en remplacement du vecteur `OFFSET` fixe. À l'état initial (yaw=0, pitch=DEFAULT_PITCH, zoom=0), la position calculée est identique à `target.global_position + OFFSET` — rétrocompatibilité totale avec la feature 04.

## Arborescence cible

```
.
├── src/
│   └── camera/
│       └── camera_controller.gd    # modifié — ajout des constantes, variables d'état, _unhandled_input, formule sphérique dans _process
└── tests/
    └── test_09_camera_orbitale.gd  # à écrire par le tester (nouveau fichier)
```

Notes :
- `main.tscn` n'est pas modifié par cette feature (aucune modification de la structure de scène).
- `test_04_camera_tp.gd` n'est pas modifié : les tests B4 et B5 qui vérifient la position en termes de `OFFSET` restent valides grâce à la rétrocompatibilité (voir §Impact sur tests existants).
- Aucun asset ni mock n'est ajouté.

## Interface publique (GDScript)

### `src/camera/camera_controller.gd` (modifié)

Le fichier existant est étendu. Les éléments hérités de la spec 04 (`OFFSET`, `EYE_HEIGHT`, `@export var target`, `_ready()`) sont **conservés sans modification**. Les ajouts sont les suivants :

```gdscript
class_name CameraController
extends Node3D

# --- Constantes héritées (feature 04 — inchangées) ---

const OFFSET: Vector3 = Vector3(0, 3, 6)
const EYE_HEIGHT: float = 1.6

# --- Nouvelles constantes (feature 09) ---

const ZOOM_DISTANCES: Array[float] = [6.708, 12.0, 18.0]
# Trois distances orbitales discrètes (mètres).
# Index 0 : 6.708 ≈ sqrt(3²+6²) — distance initiale rétrocompatible avec OFFSET(0,3,6).
# Index 1 : 12.0 — vue intermédiaire.
# Index 2 : 18.0 — vue large pour les poursuites.

const DEFAULT_PITCH: float = 0.4636
# Angle de pitch initial en radians ≈ atan2(3.0, 6.0) — reproduit exactement OFFSET(0,3,6)
# quand yaw=0 et zoom_level=0 : distance*sin(pitch)≈3, distance*cos(pitch)*cos(0)≈6.

const DEFAULT_YAW: float = 0.0
# Yaw initial : 0 rad, caméra derrière la cible.

const DEFAULT_ZOOM_LEVEL: int = 0
# Niveau de zoom initial : 0 (distance la plus proche).

const MOUSE_SENSITIVITY: float = 0.003
# Sensibilité souris en radians par pixel. ≈ 0.17°/px.

const PITCH_MIN: float = -0.1745
# Pitch minimum : -10° en radians (-0.1745 rad).

const PITCH_MAX: float = 1.2217
# Pitch maximum : +70° en radians (1.2217 rad).

# --- Propriétés exportées héritées (feature 04 — inchangées) ---

@export var target: Node3D

# --- Variables d'état (feature 09) ---

var _yaw: float = DEFAULT_YAW
# Angle de rotation horizontal autour de l'axe Y du monde. Libre à 360°, non borné.

var _pitch: float = DEFAULT_PITCH
# Angle d'élévation vertical. Borné entre PITCH_MIN et PITCH_MAX.

var _zoom_level: int = DEFAULT_ZOOM_LEVEL
# Niveau de zoom courant. Entier dans [0, 2].

var _right_mouse_held: bool = false
# Vrai si le bouton droit de la souris est actuellement maintenu enfoncé.

# --- Méthodes ---

func _ready() -> void:
    # Inchangé (feature 04) : résolution automatique de la cible si non assignée.
    if target == null:
        target = get_node_or_null("../Player")

func _process(_delta: float) -> void:
    # Remplace la formule OFFSET fixe par la formule sphérique orbitale.
    # Si target est null, retour immédiat sans modification (comportement feature 04 conservé).
    if target == null:
        return
    var target_pos: Vector3 = target.global_position if target.is_inside_tree() else target.position
    var dist: float = ZOOM_DISTANCES[_zoom_level]
    var orbit: Vector3 = Vector3(0.0, 0.0, dist).rotated(Vector3.RIGHT, _pitch).rotated(Vector3.UP, _yaw)
    global_position = target_pos + orbit
    $Camera3D.look_at(target_pos + Vector3(0.0, EYE_HEIGHT, 0.0), Vector3.UP)

func _unhandled_input(event: InputEvent) -> void:
    # Gestion du clic droit (capture / libération souris), de la souris en mouvement,
    # de la molette (zoom), et du clic milieu (reset).
    if event is InputEventMouseButton:
        var mb := event as InputEventMouseButton
        if mb.button_index == MOUSE_BUTTON_RIGHT:
            if mb.pressed:
                _right_mouse_held = true
                Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
            else:
                _right_mouse_held = false
                Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
        elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
            _zoom_level = min(_zoom_level + 1, 2)
        elif mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
            _zoom_level = max(_zoom_level - 1, 0)
        elif mb.button_index == MOUSE_BUTTON_MIDDLE and mb.pressed:
            _yaw = 0.0
            _zoom_level = DEFAULT_ZOOM_LEVEL
            # _pitch n'est PAS réinitialisé (comportement voulu, cf. design §Réinitialisation)
    elif event is InputEventMouseMotion:
        if _right_mouse_held:
            var mm := event as InputEventMouseMotion
            _yaw -= mm.relative.x * MOUSE_SENSITIVITY
            _pitch = clamp(_pitch - mm.relative.y * MOUSE_SENSITIVITY, PITCH_MIN, PITCH_MAX)
```

**Notes importantes :**

- La formule `Vector3(0.0, 0.0, dist).rotated(Vector3.RIGHT, _pitch).rotated(Vector3.UP, _yaw)` est équivalente aux formules trigonométriques du design :
  - `offset_x = dist * cos(pitch) * sin(yaw)`
  - `offset_y = dist * sin(pitch)`
  - `offset_z = dist * cos(pitch) * cos(yaw)`
- À l'état initial (`_yaw=0`, `_pitch=DEFAULT_PITCH≈atan2(3,6)`, `_zoom_level=0`, `dist=6.708`), l'orbit calculé est approximativement `Vector3(0, 3, 6)` — rétrocompatibilité exacte avec `OFFSET`.
- `_unhandled_input` est préféré à `_input` pour ne pas consommer les événements qui doivent atteindre d'autres nœuds (UI par exemple).
- La constante `OFFSET` est conservée dans le script pour ne pas casser les tests B1 de `test_04_camera_tp.gd`. Elle n'est plus utilisée dans `_process` mais reste accessible via `CameraController.OFFSET`.
- Le yaw n'est pas wrappé en `[-π, +π]` dans le script de base (les flottants Godot supportent des angles > 2π sans problème de rendu) ; le wrap est une optimisation hors proto.

## Structure des scènes (.tscn)

`main.tscn` n'est pas modifié par cette feature. La structure de scène héritée de la feature 04 est inchangée :

```
Main : Node3D
│
├── WorldEnvironment : WorldEnvironment               (feature 02)
├── DirectionalLight3D : DirectionalLight3D           (feature 02)
├── Ground : MeshInstance3D                           (feature 02)
├── GroundCollider : StaticBody3D                     (feature 03)
├── Player : CharacterBody3D                          (feature 03)
├── CameraRig : Node3D                                (feature 04)
│     script : res://src/camera/camera_controller.gd
│     target : <NodePath vers Player>
│     └── Camera3D : Camera3D  (current = true)
└── ... (features 05, 06, 07, 08)
```

Le comportement de `CameraRig` change (formule sphérique), mais sa structure de nœuds dans la scène est inchangée.

## Données et constantes

Toutes les constantes et variables d'état sont déclarées dans `src/camera/camera_controller.gd`.

| Identifiant | Type | Valeur | Rôle |
|---|---|---|---|
| `OFFSET` | `Vector3` | `Vector3(0, 3, 6)` | Conservé pour rétrocompatibilité tests 04 — non utilisé dans _process feature 09 |
| `EYE_HEIGHT` | `float` | `1.6` | Hauteur du point visé (m) — hérité feature 04, inchangé |
| `ZOOM_DISTANCES` | `Array[float]` | `[6.708, 12.0, 18.0]` | Distances orbitales discrètes (m) pour les 3 niveaux de zoom |
| `DEFAULT_PITCH` | `float` | `0.4636` | Pitch initial ≈ atan2(3.0, 6.0) — rétrocompatible OFFSET |
| `DEFAULT_YAW` | `float` | `0.0` | Yaw initial — caméra dans l'axe +Z derrière la cible |
| `DEFAULT_ZOOM_LEVEL` | `int` | `0` | Niveau de zoom initial |
| `MOUSE_SENSITIVITY` | `float` | `0.003` | Sensibilité souris (rad/px) |
| `PITCH_MIN` | `float` | `-0.1745` | Pitch minimum : −10° en radians |
| `PITCH_MAX` | `float` | `1.2217` | Pitch maximum : +70° en radians |
| `_yaw` | `float` | init: `DEFAULT_YAW` | Angle de rotation horizontal courant |
| `_pitch` | `float` | init: `DEFAULT_PITCH` | Angle d'élévation courant |
| `_zoom_level` | `int` | init: `DEFAULT_ZOOM_LEVEL` | Niveau de zoom courant `[0, 2]` |
| `_right_mouse_held` | `bool` | init: `false` | Flag clic droit maintenu |

## Comportements attendus

Les tests de cette feature s'écrivent dans `tests/test_09_camera_orbitale.gd`. Chaque comportement ci-dessous est testable unitairement avec GUT sans charger `main.tscn`.

**B1.** `CameraController.ZOOM_DISTANCES` est un `Array[float]` de taille 3 et `ZOOM_DISTANCES[0]` est approximativement `6.708` (tolérance `0.001`).

**B2.** `CameraController.DEFAULT_PITCH` est approximativement égal à `atan2(3.0, 6.0)` (tolérance `0.0001`). Valeur numérique attendue ≈ `0.4636`.

**B3.** `CameraController.MOUSE_SENSITIVITY` est approximativement `0.003` (tolérance `0.0001`).

**B4.** `CameraController.PITCH_MIN` est approximativement `-0.1745` (tolérance `0.0001`) et `CameraController.PITCH_MAX` est approximativement `1.2217` (tolérance `0.0001`).

**B5 — Rétrocompatibilité positionnement.** Un `CameraController` instancié avec une cible factice à `Vector3(0, 0, 0)` (dans l'arbre de scène), `_yaw = 0.0`, `_pitch = DEFAULT_PITCH`, `_zoom_level = 0` : après `_process(0.016)`, `global_position` est approximativement `Vector3(0, 3, 6)` (tolérance `0.05` par composante — la légère imprécision de la formule sphérique par rapport au vecteur entier est acceptable).

**B6 — Clic droit press.** Construire un `InputEventMouseButton` avec `button_index = MOUSE_BUTTON_RIGHT`, `pressed = true`. Appeler `sut._unhandled_input(event)`. Vérifier : `sut._right_mouse_held == true` et `Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED`.

**B7 — Clic droit release.** Avec `_right_mouse_held` déjà à `true` : construire un `InputEventMouseButton` avec `button_index = MOUSE_BUTTON_RIGHT`, `pressed = false`. Appeler `sut._unhandled_input(event)`. Vérifier : `sut._right_mouse_held == false` et `Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE`.

**B8 — Mouvement souris avec clic droit maintenu.** Avec `sut._right_mouse_held = true`, `sut._yaw = 0.0`, `sut._pitch = 0.0` : construire un `InputEventMouseMotion` avec `relative = Vector2(100.0, 50.0)`. Appeler `sut._unhandled_input(event)`. Vérifier :
- `sut._yaw` est approximativement `0.0 - 100.0 * MOUSE_SENSITIVITY = -0.3` (tolérance `0.0001`)
- `sut._pitch` est approximativement `0.0 - 50.0 * MOUSE_SENSITIVITY = -0.15` (tolérance `0.0001`)

**B9 — Mouvement souris sans clic droit.** Avec `sut._right_mouse_held = false`, `sut._yaw = 0.5`, `sut._pitch = 0.2` : construire un `InputEventMouseMotion` avec `relative = Vector2(100.0, 50.0)`. Appeler `sut._unhandled_input(event)`. Vérifier : `sut._yaw == 0.5` et `sut._pitch == 0.2` (inchangés).

**B10 — Molette bas (zoom out).** Avec `sut._zoom_level = 0` : construire un `InputEventMouseButton` avec `button_index = MOUSE_BUTTON_WHEEL_DOWN`, `pressed = true`. Appeler `sut._unhandled_input(event)`. Vérifier : `sut._zoom_level == 1`.

**B11 — Molette haut (zoom in).** Avec `sut._zoom_level = 2` : construire un `InputEventMouseButton` avec `button_index = MOUSE_BUTTON_WHEEL_UP`, `pressed = true`. Appeler `sut._unhandled_input(event)`. Vérifier : `sut._zoom_level == 1`.

**B12 — Zoom out à la limite haute.** Avec `sut._zoom_level = 2` : envoyer `MOUSE_BUTTON_WHEEL_DOWN pressed`. Vérifier : `sut._zoom_level == 2` (pas de dépassement).

**B13 — Zoom in à la limite basse.** Avec `sut._zoom_level = 0` : envoyer `MOUSE_BUTTON_WHEEL_UP pressed`. Vérifier : `sut._zoom_level == 0` (pas de dépassement).

**B14 — Clic milieu (reset yaw + zoom).** Avec `sut._yaw = 1.57`, `sut._pitch = 0.8`, `sut._zoom_level = 2` : construire un `InputEventMouseButton` avec `button_index = MOUSE_BUTTON_MIDDLE`, `pressed = true`. Appeler `sut._unhandled_input(event)`. Vérifier :
- `sut._yaw == 0.0`
- `sut._zoom_level == 0`
- `sut._pitch == 0.8` (pitch conservé — inchangé)

**B15 — Position caméra avec yaw = PI/2.** Un `CameraController` instancié avec cible factice à `Vector3(0, 0, 0)`, `sut._yaw = PI / 2.0`, `sut._pitch = 0.0`, `sut._zoom_level = 0` (`dist = 6.708`) : après `_process(0.016)`, la composante `global_position.x` est approximativement `6.708` (tolérance `0.1`) et la composante `global_position.z` est approximativement `0.0` (tolérance `0.1`). La caméra est à droite de la cible.

**B16 — Distance euclidienne = ZOOM_DISTANCES[zoom_level].** Pour chaque `zoom_level` dans `[0, 1, 2]` : instancier un `CameraController` avec cible à `Vector3(0, 0, 0)`, assigner `sut._zoom_level = zoom_level`, appeler `_process(0.016)`. Vérifier que `sut.global_position.distance_to(Vector3(0, 0, 0))` est approximativement égal à `ZOOM_DISTANCES[zoom_level]` (tolérance `0.05`).

## Cas limites / erreurs

**CL1 — Pitch clampé au maximum.** Avec `sut._right_mouse_held = true`, `sut._pitch = PITCH_MAX - 0.01` : envoyer un `InputEventMouseMotion` avec `relative.y = -1000.0` (déplacement vers le haut excessif). Vérifier : `sut._pitch == PITCH_MAX` (clampé, pas de dépassement).

**CL2 — Pitch clampé au minimum.** Avec `sut._right_mouse_held = true`, `sut._pitch = PITCH_MIN + 0.01` : envoyer un `InputEventMouseMotion` avec `relative.y = 1000.0` (déplacement vers le bas excessif). Vérifier : `sut._pitch == PITCH_MIN` (clampé, pas de dépassement).

**CL3 — target null dans _process.** Avec `sut.target = null` et `sut.global_position = Vector3(1, 2, 3)` : appeler `sut._process(0.016)`. Aucun crash. Vérifier : `sut.global_position == Vector3(1, 2, 3)` (comportement hérité feature 04, inchangé).

**CL4 — delta = 0 dans _process.** Avec une cible valide à `Vector3(0, 0, 0)` : appeler `sut._process(0.0)`. Aucun crash. La position calculée est identique à `_process(0.016)` (formule indépendante de `delta`).

**CL5 — Multiple zoom out depuis niveau 0.** Depuis `sut._zoom_level = 0` : envoyer successivement `WHEEL_DOWN pressed` trois fois. Vérifier : après le premier, `_zoom_level == 1` ; après le second, `_zoom_level == 2` ; après le troisième, `_zoom_level == 2` (borné).

## Inputs Godot (Input Map)

Aucune nouvelle action n'est ajoutée dans `project.godot`. Les boutons de la souris (clic droit, molette, clic milieu) sont gérés directement via les types `InputEventMouseButton` et `InputEventMouseMotion` dans `_unhandled_input` — ils ne nécessitent pas de définition dans l'InputMap.

Les actions existantes (`move_forward`, `move_backward`, `move_left`, `move_right`, `interact`, `drive_forward`, `drive_backward`, `drive_left`, `drive_right`) restent inchangées.

## Assets consommés

Cette feature ne consomme aucun asset graphique. Aucun mock n'est requis.

| Chemin `res://` | Mock attendu | Usage |
|---|---|---|
| (aucun) | non | — |

## Impact sur les tests existants (`test_04_camera_tp.gd`)

Les tests de `test_04_camera_tp.gd` ne doivent pas être modifiés. La rétrocompatibilité est garantie par les invariants suivants, que l'implémentation feature 09 doit respecter :

| Test 04 | Condition de validité avec feature 09 |
|---------|---------------------------------------|
| B1 — `OFFSET == Vector3(0,3,6)` | La constante `OFFSET` est conservée dans le script (même si non utilisée dans `_process`). Toujours valide. |
| B2 — `EYE_HEIGHT == 1.6` | Constante inchangée. Toujours valide. |
| B3 — `target null` : pas de crash | `_process` retourne toujours si `target == null`. Toujours valide. |
| B4 — `target à (0,0,0)` → `global_position == (0,3,6)` | Valide **si et seulement si** `_yaw == DEFAULT_YAW (0.0)`, `_pitch == DEFAULT_PITCH (0.4636)`, `_zoom_level == DEFAULT_ZOOM_LEVEL (0)` au moment du test. Ces valeurs sont les valeurs initiales déclarées sur les variables `var` — garanties à l'instanciation. |
| B5 — `target à (10,0,-5)` → `global_position == (10,3,1)` | Même condition que B4. Valide car les variables d'état sont initialisées aux valeurs DEFAULT. |
| B6 — Orientation `look_at` | L'appel `$Camera3D.look_at(target_pos + Vector3(0, EYE_HEIGHT, 0))` est conservé à l'identique. Toujours valide. |
| B7 — Suivi instantané | Formule recalculée chaque frame. Toujours valide. |
| B8, B9, B10 — Structure `main.tscn` | `main.tscn` n'est pas modifié. Toujours valide. |
| B_TARGET — `CameraRig.target == Player` | Propriété `@export var target` et `_ready()` conservés. Toujours valide. |
| CL1 — `target null` | Inchangé. |
| CL2 — Cible même position | OFFSET non nul et `look_at` inchangé — pas de vecteur nul. Valide. |
| CL3 — `delta = 0` | Formule indépendante de delta. Valide. |
| CL4 — Une seule Camera3D active | Structure `main.tscn` inchangée. Valide. |
| CL5 — `target` hors arbre | Branche `target.position` conservée. Valide. |

**Attention du tester :** les tests B4 et B5 de `test_04_camera_tp.gd` instancient un nouveau `CameraController` via `CameraControllerScript.new()`. À l'instanciation, `_yaw`, `_pitch` et `_zoom_level` prennent leurs valeurs déclarées par `var` (`DEFAULT_YAW`, `DEFAULT_PITCH`, `DEFAULT_ZOOM_LEVEL`). Ces tests restent verts sans aucune modification.

## Dépendances

- **Spec 04 — Caméra troisième personne** : `CameraController` existant dans `src/camera/camera_controller.gd`. La feature 09 modifie ce fichier.
- **Spec 07 — Entrer / sortir d'un véhicule** : mécanisme de changement de `target`. Le script modifié ne réinitialise pas `_yaw`, `_pitch`, `_zoom_level` au changement de `target` — comportement garanti par l'absence de code de reset dans l'affectation de `target`.
- **`addons/gut/`** : addon GUT v9.6, déjà installé depuis la feature 01.
- Aucun autre addon autorisé.

## Critères d'acceptation

- [ ] `src/camera/camera_controller.gd` contient les 5 nouvelles constantes (`ZOOM_DISTANCES`, `DEFAULT_PITCH`, `DEFAULT_YAW`, `DEFAULT_ZOOM_LEVEL`, `MOUSE_SENSITIVITY`, `PITCH_MIN`, `PITCH_MAX`) et les 4 nouvelles variables d'état (`_yaw`, `_pitch`, `_zoom_level`, `_right_mouse_held`), reconnues sans erreur de parse par GDScript.
- [ ] `_process` utilise la formule sphérique avec `Vector3(0,0,dist).rotated(...)` — la ligne `global_position = target_pos + OFFSET` fixe est supprimée.
- [ ] `_unhandled_input` est présent et gère les quatre cas : clic droit press/release, mouvement souris conditionnel, molette haut/bas, clic milieu.
- [ ] `godot --path . res://main.tscn` se lance sans `ERROR:` ni `SCRIPT ERROR:` dans la console. À l'état initial, la caméra est positionnée à environ `Vector3(0, 3, 6)` derrière le joueur.
- [ ] En maintenant le clic droit et en bougeant la souris horizontalement, la caméra pivote autour du joueur. En relâchant le clic droit, le curseur réapparaît.
- [ ] La molette change le niveau de zoom de façon instantanée (distance visible change).
- [ ] Le clic milieu repositionne la caméra derrière le joueur (yaw=0) sans changer l'angle vertical.
- [ ] La commande `godot --headless -s res://addons/gut/gut_cmdln.gd -gdir=res://tests -gexit` retourne le code de sortie 0 (tous les tests de `test_09_camera_orbitale.gd` ET de `test_04_camera_tp.gd` passent au vert).
- [ ] Les 16 comportements attendus (B1 à B16) passent tous au vert dans GUT.
- [ ] Les 5 cas limites (CL1 à CL5) passent tous au vert dans GUT.

## Hors-périmètre

- Interpolation (lerp / smoothstep) de la rotation ou du zoom : hors proto v0.1, réservé à une feature future.
- Collision de caméra (la caméra ne traverse pas les murs) : hors proto v0.1.
- Sensibilité souris réglable dans un menu d'options : hors proto v0.1.
- Rotation automatique de la caméra derrière le joueur après inactivité : hors proto v0.1.
- Inversion de l'axe Y (option accessibilité) : hors proto v0.1.
- Wrap du yaw dans `[-π, +π]` : optimisation hors proto.
- Effets visuels liés à la caméra (motion blur, depth of field, FOV dynamique) : hors périmètre du proto.
- Gestion du pad / joystick : hors périmètre, clavier+souris uniquement.
- Libération du curseur lors d'une perte de focus de la fenêtre (alt-tab) : comportement Godot natif attendu mais non testé unitairement dans cette spec.
