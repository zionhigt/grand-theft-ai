# Spec 11 — Alignement personnage-caméra (clic droit, axe horizontal)

## Contexte

- Design : `docs/design/11-alignement-camera-personnage.md`
- Bon de commande graphique : `docs/assets/11-alignement-camera-personnage.md` — aucun asset graphique (n/a)
- Dépendances de specs précédentes :
  - **Spec 09 — Caméra orbitale** (`docs/specs/09-camera-orbitale.md`) : fournit `CameraController` dans `src/camera/camera_controller.gd` avec `_yaw`, `_right_mouse_held`, `_process`, `_unhandled_input` et la propriété `@export var target: Node3D`. Cette feature 11 **modifie** ce script existant.
  - **Spec 03 — Personnage joueur** (`docs/specs/03-personnage-joueur.md`) : fournit `PlayerController` dans `src/player/player_controller.gd` avec `rotate_toward_direction`, `_physics_process`, et `_state`. Cette feature 11 **modifie** ce script existant.
  - **Spec 07 — Entrer / sortir d'un véhicule** (`docs/specs/07-entree-sortie-vehicule.md`) : le `CameraController` peut avoir pour cible un `VehicleBody3D`. La feature 11 introduit une garde sur le type de cible avant de propager `camera_yaw`.

## Objectif fonctionnel

Quand le joueur maintient le clic droit et déplace la souris horizontalement, le personnage (`PlayerController`) tourne pour s'aligner sur l'axe Y (horizontal) de la caméra, en plus de la rotation orbitale déjà assurée par `CameraController`. Ce couplage est limité à l'axe horizontal (le pitch n'affecte pas le personnage), n'est propagé que si la cible de la caméra est un `PlayerController`, et est silencieusement inopérant si le joueur se déplace en même temps (WASD, direction non nulle).

## Arborescence cible

```
.
├── src/
│   ├── camera/
│   │   └── camera_controller.gd    # modifié — ajout de get_yaw(), propagation camera_yaw dans _process
│   └── player/
│       └── player_controller.gd    # modifié — ajout de set_camera_yaw(), rotate_toward_camera(),
│                                   #            CAMERA_ALIGN_SPEED, _camera_yaw, _camera_yaw_dirty
└── tests/
    └── test_11_alignement_camera_personnage.gd  # à écrire par le tester (nouveau fichier)
```

Notes :
- Aucune scène `.tscn` n'est créée ni modifiée par cette feature.
- `main.tscn` reste inchangé (la propagation passe par référence de code, pas par la structure de scène).
- Aucun asset ni mock n'est ajouté.

## Interface publique (GDScript)

### `src/camera/camera_controller.gd` (modifié)

Les éléments hérités des features 04 et 09 sont **conservés sans modification**. Les ajouts sont :

```gdscript
# --- Nouvelle méthode publique (feature 11) ---

func get_yaw() -> float:
    # Retourne la valeur courante de _yaw.
    # Utilisé par les tests et par tout code externe qui souhaite connaître l'orientation
    # horizontale de la caméra sans accéder directement à la variable privée.
    return _yaw
```

Modification de `_process` (feature 11, ajout en fin de corps, après le calcul de position) :

```gdscript
func _process(_delta: float) -> void:
    if target == null:
        return
    var target_pos: Vector3 = target.global_position if target.is_inside_tree() else target.position
    var dist: float = ZOOM_DISTANCES[_zoom_level]
    var orbit: Vector3 = Vector3(0.0, 0.0, dist).rotated(Vector3.RIGHT, -_pitch).rotated(Vector3.UP, _yaw)
    global_position = target_pos + orbit
    $Camera3D.look_at(target_pos + Vector3(0.0, EYE_HEIGHT, 0.0), Vector3.UP)
    # --- Feature 11 : propagation du yaw vers le PersonnageJoueur ---
    if _right_mouse_held and target.has_method("set_camera_yaw"):
        target.set_camera_yaw(_yaw)
```

**Note :** `target.has_method("set_camera_yaw")` est le mécanisme de duck typing GDScript retenu. Il évite un `is PlayerController` qui créerait un couplage dur entre `CameraController` et `PlayerController`, et il échoue silencieusement si la cible est un `VehicleBody3D` ou tout autre nœud sans cette méthode.

---

### `src/player/player_controller.gd` (modifié)

Les éléments hérités des features 03 et 10 sont **conservés sans modification**. Les ajouts sont :

```gdscript
# --- Nouvelles constantes (feature 11) ---

const CAMERA_ALIGN_SPEED: float = 15.0
# Vitesse d'alignement du personnage sur le yaw de la caméra, en rad/s.
# Valeur élevée pour un couplage quasi-instantané (évite l'artefact de "snap" dur
# tout en suivant la caméra sans retard perceptible).

# --- Nouvelles variables d'état (feature 11) ---

var _camera_yaw: float = 0.0
# Dernière valeur de yaw transmise par le CameraController via set_camera_yaw().
# Utilisée par rotate_toward_camera() pour calculer la rotation cible.

var _camera_yaw_dirty: bool = false
# true dès que set_camera_yaw() est appelé dans la frame courante.
# Remis à false dans _physics_process() après consommation (ou si direction != ZERO).
# Garantit que rotate_toward_camera() n'est appelé que lorsque le CameraController
# a effectivement transmis un nouveau yaw dans cette frame.

# --- Nouvelles méthodes publiques (feature 11) ---

func set_camera_yaw(yaw: float) -> void:
    # Enregistre le yaw horizontal de la caméra et lève le flag _camera_yaw_dirty.
    # Appelée par CameraController._process() quand _right_mouse_held == true et
    # que la cible possède cette méthode.
    # Aucun effet immédiat sur rotation.y — l'application est différée à _physics_process.
    _camera_yaw = yaw
    _camera_yaw_dirty = true

func rotate_toward_camera(camera_yaw: float, delta: float) -> void:
    # Fait pivoter le nœud (rotation.y) vers camera_yaw à la vitesse CAMERA_ALIGN_SPEED.
    # Utilise lerp_angle pour éviter le saut angulaire lors du passage ±PI.
    # Ne modifie que rotation.y. Ne touche pas rotation.x ni rotation.z.
    rotation.y = lerp_angle(rotation.y, camera_yaw, clamp(CAMERA_ALIGN_SPEED * delta, 0.0, 1.0))
```

Modification de `_physics_process` (feature 11, ajout conditionnel après `rotate_toward_direction`, avant `move_and_slide`) :

```gdscript
func _physics_process(delta: float) -> void:
    var direction := compute_input_direction()
    if not is_on_floor():
        apply_gravity(delta)
    apply_movement(direction)
    rotate_toward_direction(direction, delta)
    # --- Feature 11 : alignement sur le yaw caméra si idle et flag levé ---
    if direction == Vector3.ZERO and _camera_yaw_dirty:
        rotate_toward_camera(_camera_yaw, delta)
    _camera_yaw_dirty = false
    move_and_slide()
    _state = "walk" if direction != Vector3.ZERO else "idle"
    _update_animation()
```

**Notes importantes :**

- `_camera_yaw_dirty` est remis à `false` **inconditionnellement** à chaque frame physique, après consommation éventuelle. Cela signifie que si `CameraController._process` (frame de rendu) n'appelle pas `set_camera_yaw` dans cette frame (clic droit relâché), le flag reste à `false` et `rotate_toward_camera` n'est pas appelé.
- La remise à `false` est effectuée **après** l'appel conditionnel à `rotate_toward_camera` pour consommer le flag de la frame courante.
- Quand `direction != Vector3.ZERO`, `rotate_toward_direction` prend le dessus. Le flag est consommé (remis à `false`) sans que `rotate_toward_camera` soit appelé — la direction de marche absorbe la rotation.
- L'ordre `rotate_toward_direction` → `rotate_toward_camera` conditionnel → `_camera_yaw_dirty = false` garantit que les deux méthodes ne s'appliquent jamais simultanément sur la même frame.
- Le pitch de la caméra (`_pitch` dans `CameraController`) n'est jamais transmis au `PlayerController` — seul `_yaw` est propagé.

## Structure des scènes (.tscn)

Aucune scène n'est créée ni modifiée par cette feature. La structure de `main.tscn` héritée des features précédentes est inchangée :

```
Main : Node3D
│
├── WorldEnvironment : WorldEnvironment
├── DirectionalLight3D : DirectionalLight3D
├── Ground : MeshInstance3D
├── GroundCollider : StaticBody3D
├── Player : CharacterBody3D              (PlayerController — script modifié par feature 11)
├── Car : VehicleBody3D                   (cible possible de CameraController — non affectée)
├── GameState : Node                      (feature 07 — inchangé)
└── CameraRig : Node3D                    (CameraController — script modifié par feature 11)
      └── Camera3D : Camera3D
```

## Données et constantes

| Identifiant | Fichier | Type | Valeur | Rôle |
|---|---|---|---|---|
| `CAMERA_ALIGN_SPEED` | `player_controller.gd` | `float` | `15.0` | Vitesse d'alignement personnage sur le yaw caméra (rad/s) |
| `_camera_yaw` | `player_controller.gd` | `float` | init: `0.0` | Dernière valeur de yaw reçue de CameraController |
| `_camera_yaw_dirty` | `player_controller.gd` | `bool` | init: `false` | Flag : yaw reçu dans la frame courante et non encore consommé |

Les constantes et variables existantes de `CameraController` (`_yaw`, `_right_mouse_held`, `_process`, etc.) sont inchangées.

## Comportements attendus

Les tests de cette feature s'écrivent dans `tests/test_11_alignement_camera_personnage.gd`. Chaque comportement ci-dessous est testable unitairement avec GUT sans charger `main.tscn`.

**B1 — Constante CAMERA_ALIGN_SPEED.**
`PlayerController.CAMERA_ALIGN_SPEED == 15.0` — la constante de classe est exactement `15.0`.

**B2 — get_yaw retourne _yaw.**
Instancier un `CameraController` (`add_child_autofree`). Assigner `sut._yaw = 1.23`. Appeler `sut.get_yaw()`. Vérifier : résultat == `1.23`.

**B3 — set_camera_yaw lève le flag.**
Instancier un `PlayerController` (`add_child_autofree`). Appeler `sut.set_camera_yaw(0.785)`. Vérifier :
- `sut._camera_yaw` est approximativement `0.785` (tolérance `0.0001`)
- `sut._camera_yaw_dirty == true`

**B4 — rotate_toward_camera avec delta grand converge vers camera_yaw.**
Instancier un `PlayerController`. Assigner `sut.rotation.y = 0.0`. Appeler `sut.rotate_toward_camera(PI / 2.0, 10.0)` (delta très grand → facteur lerp clampé à 1.0). Vérifier : `sut.rotation.y` est approximativement `PI / 2.0` (tolérance `0.01 rad`). Vérifier que `sut.rotation.x == 0.0` et `sut.rotation.z == 0.0` (pas d'inclinaison).

**B5 — rotate_toward_camera avec delta petit effectue une rotation partielle.**
Instancier un `PlayerController`. Assigner `sut.rotation.y = 0.0`. Appeler `sut.rotate_toward_camera(PI, 0.016)` (delta = une frame à 60 fps). Vérifier : `sut.rotation.y > 0.0` et `sut.rotation.y < PI` (rotation partielle — pas encore à destination).

**B6 — rotate_toward_camera ne modifie pas rotation.x ni rotation.z.**
Instancier un `PlayerController`. Assigner `sut.rotation = Vector3(0.3, 0.0, 0.1)`. Appeler `sut.rotate_toward_camera(1.0, 10.0)`. Vérifier : `sut.rotation.x == 0.3` et `sut.rotation.z == 0.1` (inchangés).

**B7 — CameraController propage set_camera_yaw quand _right_mouse_held et cible PlayerController.**
Instancier un `CameraController` et un `PlayerController`. Assigner `cam.target = player`. Assigner `cam._yaw = 0.5`. Assigner `cam._right_mouse_held = true`. Ajouter les deux nœuds à l'arbre de test. Appeler `cam._process(0.016)`. Vérifier : `player._camera_yaw` est approximativement `0.5` (tolérance `0.0001`) et `player._camera_yaw_dirty == true`.

**B8 — CameraController ne propage pas quand _right_mouse_held est false.**
Instancier un `CameraController` et un `PlayerController`. Assigner `cam.target = player`. Assigner `cam._yaw = 0.5`. Assigner `cam._right_mouse_held = false`. Ajouter les deux nœuds à l'arbre. Appeler `cam._process(0.016)`. Vérifier : `player._camera_yaw_dirty == false` (inchangé depuis l'initialisation).

**B9 — CameraController ne propage pas vers une cible sans set_camera_yaw (véhicule).**
Instancier un `CameraController` et un `VehicleBody3D` (ou un `Node3D` quelconque sans la méthode `set_camera_yaw`). Assigner `cam.target = vehicle_node`. Assigner `cam._right_mouse_held = true`. Ajouter les nœuds à l'arbre. Appeler `cam._process(0.016)`. Vérifier : aucune erreur / crash. La cible ne possède pas `set_camera_yaw` — l'appel `has_method` retourne `false` et rien n'est propagé.

**B10 — Alignement appliqué en idle quand flag levé.**
Instancier un `PlayerController` (ajouté à l'arbre via `add_child_autofree`). Assigner `sut.rotation.y = 0.0`. Appeler `sut.set_camera_yaw(PI / 2.0)` (lève le flag). Ne pas appuyer sur aucun input de déplacement (`direction` sera `Vector3.ZERO`). Appeler `sut._physics_process(0.016)`. Vérifier : `sut.rotation.y > 0.0` (le personnage a commencé à tourner vers `PI/2`). Vérifier : `sut._camera_yaw_dirty == false` (flag consommé).

**B11 — Alignement non appliqué quand direction WASD non nulle.**
Instancier un `PlayerController` (ajouté à l'arbre). Appeler `sut.set_camera_yaw(PI / 2.0)` (flag levé). Simuler un input de déplacement : `Input.action_press("move_forward")`. Appeler `sut._physics_process(0.016)`. Vérifier : `sut._camera_yaw_dirty == false` (flag consommé sans appliquer `rotate_toward_camera`). Appeler `Input.action_release("move_forward")` en nettoyage.

**B12 — Flag remis à false après _physics_process même sans appel de set_camera_yaw.**
Instancier un `PlayerController`. Le flag `_camera_yaw_dirty` est `false` par défaut. Appeler `sut._physics_process(0.016)` sans appeler `set_camera_yaw`. Vérifier : `sut._camera_yaw_dirty == false` (invariant : toujours false après _physics_process).

**B13 — lerp_angle gère le passage ±PI sans saut angulaire.**
Instancier un `PlayerController`. Assigner `sut.rotation.y = PI - 0.05` (proche de +PI). Appeler `sut.rotate_toward_camera(-PI + 0.05, 0.016)` (cible juste de l'autre côté de ±PI). Vérifier : `absf(sut.rotation.y - (PI - 0.05)) < 0.5` (la rotation est partielle et ne saute pas de plusieurs radians).

## Cas limites / erreurs

**CL1 — Cible véhicule : pas de propagation, pas de crash.**
Quand `CameraController.target` est un nœud sans méthode `set_camera_yaw` (ex. `VehicleBody3D`) et `_right_mouse_held = true` : appeler `_process(0.016)` ne produit aucune erreur GDScript. La caméra continue d'orbiter normalement (son positionnement n'est pas affecté).

**CL2 — Direction WASD active : rotate_toward_camera non appelé.**
Quand `direction != Vector3.ZERO` dans `_physics_process`, `rotate_toward_camera` n'est jamais appelé, même si `_camera_yaw_dirty == true`. Le flag est remis à `false` sans consommation. La méthode `rotate_toward_direction` opère normalement.

**CL3 — Pitch ignoré.**
Le `CameraController` ne transmet jamais `_pitch` au `PlayerController`. La méthode `set_camera_yaw` reçoit uniquement un `float` de yaw — aucun moyen d'y faire passer le pitch par erreur. Vérifier que `rotate_toward_camera` et `set_camera_yaw` ne reçoivent ni ne lisent `_pitch`.

**CL4 — delta = 0 dans rotate_toward_camera.**
Appeler `rotate_toward_camera(1.0, 0.0)` : `clamp(15.0 * 0.0, 0.0, 1.0) = 0.0`, `lerp_angle(rotation.y, 1.0, 0.0) = rotation.y`. Aucune modification de `rotation.y`. Aucun crash.

**CL5 — set_camera_yaw appelé plusieurs fois dans la même frame.**
`CameraController._process` peut être appelé plusieurs fois entre deux `_physics_process` (si le taux de rendu dépasse le taux physique). Chaque appel écrase `_camera_yaw` avec la valeur la plus récente. Le flag reste `true`. `_physics_process` consomme la dernière valeur reçue — comportement correct (la valeur la plus fraîche l'emporte).

**CL6 — PlayerController sans CameraController (tests unitaires purs).**
Les méthodes `set_camera_yaw` et `rotate_toward_camera` peuvent être appelées directement sans `CameraController` — elles ne supposent pas l'existence d'un `CameraController` dans la scène. Pas de référence inverse vers `CameraController` dans `PlayerController`.

**CL7 — CameraController sans PlayerController en target (target null).**
Si `CameraController.target == null`, le retour immédiat existant dans `_process` garantit que la propagation n'est jamais tentée. Le code de propagation est après le guard `if target == null: return`.

## Inputs Godot (Input Map)

Aucune nouvelle action n'est ajoutée dans `project.godot`. La détection du clic droit est déjà gérée par `_unhandled_input` de `CameraController` via `InputEventMouseButton` (feature 09) — aucune action InputMap n'est nécessaire.

La propagation vers `PlayerController` utilise `Input.is_mouse_button_pressed` de manière indirecte : c'est le flag `_right_mouse_held` de `CameraController` (mis à jour dans `_unhandled_input`) qui conditionne l'appel à `set_camera_yaw`. Il n'y a pas d'appel direct à `Input.is_mouse_button_pressed` dans `PlayerController`.

Les actions existantes (`move_forward`, `move_backward`, `move_left`, `move_right`, `interact`, `drive_forward`, `drive_backward`, `drive_left`, `drive_right`) restent inchangées.

## Assets consommés et intégration par code

Cette feature ne consomme aucun asset graphique. Aucun mock n'est requis.

| Chemin `res://` | Statut | Intégration GDScript |
|---|---|---|
| (aucun) | n/a | — |

## Impact sur les tests existants

### `tests/test_09_camera_orbitale.gd`

Tous les tests B1 à B16 et CL1 à CL5 de la feature 09 restent valides. La modification de `_process` ajoute uniquement un bloc conditionnel **à la fin** du corps de la méthode, après les instructions de positionnement existantes. Les tests B5 à B16 qui vérifient `global_position` ou les variables d'état (`_yaw`, `_pitch`, `_zoom_level`, `_right_mouse_held`) ne sont pas affectés par cet ajout.

Attention particulière pour le tester : les tests B6 et B7 (clic droit press/release avec `_unhandled_input`) n'appellent pas `_process` — le bloc de propagation feature 11 n'est jamais déclenché dans ces tests, donc pas d'effet de bord.

### `tests/test_04_camera_tp.gd`

Tous les tests de la feature 04 restent valides (inchangés). La modification de `_process` n'affecte pas les tests de positionnement B4 et B5 car ceux-ci instancient une cible `Node3D` sans méthode `set_camera_yaw` — `has_method("set_camera_yaw")` retourne `false`, la propagation est sautée silencieusement.

### `tests/test_03_personnage_joueur.gd`

Les tests B1 à B15 et CL1 à CL6 de la feature 03 restent valides. Les méthodes publiques existantes (`apply_movement`, `apply_gravity`, `rotate_toward_direction`, `compute_input_direction`, `get_state`) sont inchangées. Les nouvelles variables `_camera_yaw` et `_camera_yaw_dirty` ont des valeurs initiales neutres (`0.0` et `false`) qui n'interfèrent avec aucun comportement existant.

Les tests B10 (état "walk"/"idle" via `apply_movement`) restent valides : la logique de `_state` dans `_physics_process` n'est pas modifiée.

## Dépendances

- **Spec 03 — Personnage joueur** : `PlayerController` dans `src/player/player_controller.gd`. La feature 11 modifie ce fichier.
- **Spec 09 — Caméra orbitale** : `CameraController` dans `src/camera/camera_controller.gd`. La feature 11 modifie ce fichier.
- **Spec 07 — Entrer / sortir d'un véhicule** : `VehicleBody3D` comme cible possible de `CameraController`. La feature 11 gère silencieusement ce cas via `has_method`.
- **`addons/gut/`** : addon GUT v9.6, déjà installé depuis la feature 01.
- Aucun autre addon autorisé.

## Critères d'acceptation

- [ ] `src/camera/camera_controller.gd` contient la méthode `get_yaw() -> float` reconnue sans erreur de parse par GDScript.
- [ ] `src/camera/camera_controller.gd` contient dans `_process`, après le `look_at`, le bloc de propagation conditionnel `if _right_mouse_held and target.has_method("set_camera_yaw")`.
- [ ] `src/player/player_controller.gd` contient la constante `CAMERA_ALIGN_SPEED : float = 15.0`, les variables `_camera_yaw: float` et `_camera_yaw_dirty: bool`, et les méthodes `set_camera_yaw(yaw: float) -> void` et `rotate_toward_camera(camera_yaw: float, delta: float) -> void`.
- [ ] `src/player/player_controller.gd` : `_physics_process` contient le bloc conditionnel `if direction == Vector3.ZERO and _camera_yaw_dirty` suivi de `rotate_toward_camera(...)`, puis `_camera_yaw_dirty = false`.
- [ ] `godot --path . res://main.tscn` se lance sans `ERROR:` ni `SCRIPT ERROR:` dans la console. En maintenant le clic droit et en déplaçant la souris horizontalement, le personnage tourne en même temps que la caméra (couplage visible à l'œil).
- [ ] En état idle, le personnage suit le yaw de la caméra quasi instantanément (latence < 1 frame visible à 60 fps).
- [ ] En marchant (WASD) et clic droit maintenu, le personnage avance dans la direction combinée caméra + touche — pas de conflit de rotation visible.
- [ ] Quand la caméra pointe sur un véhicule (`target = Car`), le clic droit et le mouvement souris ne produisent aucune erreur et la voiture ne tourne pas.
- [ ] La commande `godot --headless -s res://addons/gut/gut_cmdln.gd -gdir=res://tests -gexit` retourne le code de sortie 0 (tous les tests de `test_11_alignement_camera_personnage.gd`, `test_09_camera_orbitale.gd`, `test_04_camera_tp.gd` et `test_03_personnage_joueur.gd` passent au vert).
- [ ] Les 13 comportements attendus (B1 à B13) passent tous au vert dans GUT.
- [ ] Les 7 cas limites (CL1 à CL7) passent tous au vert dans GUT.

## Hors-périmètre

- Alignement du personnage avec le pitch de la caméra (inclinaison du corps en avant / en arrière) : hors périmètre.
- Rotation automatique de la caméra derrière le joueur après inactivité (auto-align inverse) : feature future.
- Couplage caméra → direction de tir / visée : hors proto v0.1.
- Réinitialisation de l'orientation du personnage via clic milieu : le clic milieu réinitialise le yaw de la caméra (feature 09), pas la rotation du personnage.
- Animation dédiée à la rotation sur place (pivot idle) : hors proto v0.1 — les animations "idle" et "walk" de la feature 10 sont conservées sans modification.
- Gestion du pad / joystick : hors périmètre, clavier + souris uniquement.
- Lissage (`lerp`) de la position de caméra : hors proto v0.1 (feature 09 — déjà spécifié hors périmètre).
