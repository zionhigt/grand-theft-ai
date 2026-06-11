# Spec 12 — Déplacement camera-relatif (ZQSD orienté caméra)

## Contexte

- Design : `docs/design/12-deplacement-camera-relatif.md`
- Bon de commande graphique : `docs/assets/12-deplacement-camera-relatif.md` — aucun asset graphique (n/a)
- Dépendances de specs précédentes :
  - **Spec 11 — Alignement personnage-caméra** (`docs/specs/11-alignement-camera-personnage.md`) : fournit `PlayerController._camera_yaw`, `PlayerController._camera_yaw_dirty`, `PlayerController.set_camera_yaw()`, et la propagation conditionnelle `if _right_mouse_held` dans `CameraController._process`. La feature 12 **modifie** ces deux scripts existants.
  - **Spec 09 — Caméra orbitale** (`docs/specs/09-camera-orbitale.md`) : fournit `CameraController._yaw` (angle horizontal de la caméra), source du référentiel de déplacement.
  - **Spec 03 — Personnage joueur** (`docs/specs/03-personnage-joueur.md`) : fournit `PlayerController.compute_input_direction()`, modifiée par cette feature.
  - **Spec 07 — Entrer / sortir d'un véhicule** (`docs/specs/07-entree-sortie-vehicule.md`) : le `has_method` check garantit que les véhicules ne sont pas affectés.

## Objectif fonctionnel

Les touches ZQSD/WASD déplacent le personnage dans le référentiel de la caméra : "avancer" propulse toujours vers la direction horizontale où pointe la caméra, quelle que soit la rotation de celle-ci. Deux modifications minimales suffisent : (1) la propagation du yaw de `CameraController` vers `PlayerController` devient permanente (chaque frame, sans condition de clic droit) ; (2) `compute_input_direction()` applique une rotation autour de l'axe Y par le yaw caméra avant de retourner le vecteur de direction.

## Arborescence cible

```
.
├── src/
│   ├── camera/
│   │   └── camera_controller.gd    # modifié — retrait de la condition _right_mouse_held
│   │                               #           sur la propagation set_camera_yaw dans _process
│   └── player/
│       └── player_controller.gd    # modifié — compute_input_direction() applique
│                                   #           raw.rotated(Vector3.UP, _camera_yaw)
└── tests/
    └── test_12_deplacement_camera_relatif.gd   # à écrire par le tester (nouveau fichier)
```

Notes :
- Aucune scène `.tscn` n'est créée ni modifiée.
- Aucun asset ni mock n'est ajouté.
- `test_11_alignement_camera_personnage.gd` doit être modifié par le tester feature 12 (voir §Impact sur tests existants).

## Interface publique (GDScript)

### `src/camera/camera_controller.gd` (modifié)

Seul `_process` est modifié. Toutes les autres méthodes, constantes et variables sont inchangées.

**Avant (feature 11) :**

```gdscript
func _process(_delta: float) -> void:
    if target == null:
        return
    var target_pos: Vector3 = target.global_position if target.is_inside_tree() else target.position
    var dist: float = ZOOM_DISTANCES[_zoom_level]
    var orbit: Vector3 = Vector3(0.0, 0.0, dist).rotated(Vector3.RIGHT, -_pitch).rotated(Vector3.UP, _yaw)
    global_position = target_pos + orbit
    $Camera3D.look_at(target_pos + Vector3(0.0, EYE_HEIGHT, 0.0), Vector3.UP)
    # Feature 11 : propagation du yaw vers le PersonnageJoueur
    if _right_mouse_held and target.has_method("set_camera_yaw"):
        target.set_camera_yaw(_yaw)
```

**Après (feature 12) — diff minimal, une seule ligne modifiée :**

```gdscript
func _process(_delta: float) -> void:
    if target == null:
        return
    var target_pos: Vector3 = target.global_position if target.is_inside_tree() else target.position
    var dist: float = ZOOM_DISTANCES[_zoom_level]
    var orbit: Vector3 = Vector3(0.0, 0.0, dist).rotated(Vector3.RIGHT, -_pitch).rotated(Vector3.UP, _yaw)
    global_position = target_pos + orbit
    $Camera3D.look_at(target_pos + Vector3(0.0, EYE_HEIGHT, 0.0), Vector3.UP)
    # Feature 12 : propagation permanente du yaw (sans condition _right_mouse_held)
    if target.has_method("set_camera_yaw"):
        target.set_camera_yaw(_yaw)
```

La modification exacte : suppression de `_right_mouse_held and` dans la condition. La vérification `has_method` reste obligatoire pour éviter les erreurs quand la cible est un véhicule.

---

### `src/player/player_controller.gd` (modifié)

Seule `compute_input_direction` est modifiée. Toutes les autres méthodes, constantes et variables (y compris celles introduites par la feature 11) sont inchangées.

**Avant (feature 03/11) :**

```gdscript
func compute_input_direction() -> Vector3:
    var direction := Vector3.ZERO
    direction.x += Input.get_action_strength("move_right")
    direction.x -= Input.get_action_strength("move_left")
    direction.z -= Input.get_action_strength("move_forward")
    direction.z += Input.get_action_strength("move_backward")
    if direction.length() > 0.0:
        direction = direction.normalized()
    return direction
```

**Après (feature 12) — diff minimal, une seule ligne ajoutée avant le `return` :**

```gdscript
func compute_input_direction() -> Vector3:
    var raw := Vector3.ZERO
    raw.x += Input.get_action_strength("move_right")
    raw.x -= Input.get_action_strength("move_left")
    raw.z -= Input.get_action_strength("move_forward")
    raw.z += Input.get_action_strength("move_backward")
    if raw.length() > 0.0:
        raw = raw.normalized()
    return raw.rotated(Vector3.UP, _camera_yaw)
```

La modification exacte :
1. La variable locale est renommée `raw` (clarifie que c'est le vecteur pré-rotation — cosmétique, le tester peut valider indifféremment).
2. La ligne `return raw.rotated(Vector3.UP, _camera_yaw)` remplace `return direction`.

Quand `_camera_yaw == 0.0` (valeur initiale de la variable), `Vector3.rotated(Vector3.UP, 0.0)` retourne le vecteur inchangé — **rétrocompatibilité totale** avec les tests de la feature 03 qui n'ont jamais appelé `set_camera_yaw`.

## Structure des scènes (.tscn)

Aucune scène n'est créée ni modifiée par cette feature. La structure de `main.tscn` héritée des features précédentes est inchangée :

```
Main : Node3D
│
├── WorldEnvironment : WorldEnvironment
├── DirectionalLight3D : DirectionalLight3D
├── Ground : MeshInstance3D
├── GroundCollider : StaticBody3D
├── Player : CharacterBody3D          (PlayerController — script modifié par feature 12)
├── Car : VehicleBody3D               (cible possible de CameraController — non affectée)
├── GameState : Node                  (feature 07 — inchangé)
└── CameraRig : Node3D                (CameraController — script modifié par feature 12)
      └── Camera3D : Camera3D
```

## Données et constantes

Aucune nouvelle constante ni variable n'est introduite par cette feature. Les variables `_camera_yaw` et `_camera_yaw_dirty` de `PlayerController` existent déjà depuis la feature 11 et sont réutilisées sans modification.

| Identifiant | Fichier | Type | Valeur | Rôle |
|---|---|---|---|---|
| `_camera_yaw` | `player_controller.gd` | `float` | init: `0.0` | Yaw caméra courant — source de la rotation appliquée dans `compute_input_direction` |
| `_right_mouse_held` | `camera_controller.gd` | `bool` | runtime | La condition sur ce flag est **retirée** de la propagation — la variable reste présente pour la feature 09 (`_unhandled_input`) |

## Comportements attendus

Les tests de cette feature s'écrivent dans `tests/test_12_deplacement_camera_relatif.gd`. Chaque comportement ci-dessous est testable unitairement avec GUT sans charger `main.tscn`.

**B1 — Propagation permanente du yaw : `_right_mouse_held = false` ne bloque plus la propagation.**
Instancier un `CameraController` (avec `Camera3D` enfant) et un `PlayerController`. Assigner `cam.target = player`. Assigner `cam._yaw = 0.5`. Assigner `cam._right_mouse_held = false`. Ajouter les deux nœuds à l'arbre. Appeler `cam._process(0.016)`. Vérifier : `player._camera_yaw` est approximativement `0.5` (tolérance `0.0001`) et `player._camera_yaw_dirty == true`.

**B2 — Propagation permanente du yaw : `_right_mouse_held = true` propage toujours (comportement inchangé de B7/feature 11).**
Instancier un `CameraController` et un `PlayerController`. Assigner `cam.target = player`. Assigner `cam._yaw = 1.2`. Assigner `cam._right_mouse_held = true`. Ajouter les deux nœuds à l'arbre. Appeler `cam._process(0.016)`. Vérifier : `player._camera_yaw` est approximativement `1.2` (tolérance `0.0001`).

**B3 — Direction camera-relative, yaw = PI/2 (caméra à gauche du joueur) : "avancer" donne monde -X.**
Instancier un `PlayerController`. Appeler `player.set_camera_yaw(PI / 2.0)`. Simuler `move_forward` pressé (`Input.action_press("move_forward")`), autres actions relâchées. Appeler `dir = player.compute_input_direction()`. Vérifier : `dir.z` est approximativement `0.0` (tolérance `0.01`) et `dir.x` est approximativement `-1.0` (tolérance `0.01`). Relâcher `move_forward`.

**B4 — Direction camera-relative, yaw = 0 : "avancer" donne monde -Z (comportement identique à feature 03).**
Instancier un `PlayerController`. `_camera_yaw` est `0.0` par défaut — ne pas appeler `set_camera_yaw`. Simuler `move_forward` pressé. Appeler `dir = player.compute_input_direction()`. Vérifier : `dir.z` est approximativement `-1.0` (tolérance `0.01`) et `dir.x` est approximativement `0.0` (tolérance `0.01`). Relâcher `move_forward`.

**B5 — Direction camera-relative, yaw = PI : "avancer" donne monde +Z.**
Instancier un `PlayerController`. Appeler `player.set_camera_yaw(PI)`. Simuler `move_forward` pressé. Appeler `dir = player.compute_input_direction()`. Vérifier : `dir.z` est approximativement `1.0` (tolérance `0.01`) et `dir.x` est approximativement `0.0` (tolérance `0.01`). Relâcher `move_forward`.

**B6 — Vecteur nul inchangé par la rotation : aucun input → Vector3.ZERO.**
Instancier un `PlayerController`. Appeler `player.set_camera_yaw(PI / 3.0)`. Relâcher toutes les actions de déplacement. Appeler `dir = player.compute_input_direction()`. Vérifier : `dir == Vector3.ZERO` (la rotation d'un vecteur nul reste nulle).

**B7 — Normalisation avant rotation : diagonale camera-relative a une longueur ≈ 1.0.**
Instancier un `PlayerController`. Appeler `player.set_camera_yaw(PI / 4.0)`. Simuler `move_forward` et `move_right` pressés. Appeler `dir = player.compute_input_direction()`. Vérifier : `dir.length()` est approximativement `1.0` (tolérance `0.01`). Relâcher les deux actions.

**B8 — Rétrocompatibilité `_camera_yaw = 0` : `compute_input_direction` retourne le même résultat qu'avant feature 12.**
Instancier un `PlayerController`. Ne pas appeler `set_camera_yaw` (`_camera_yaw` reste à `0.0`). Simuler `move_right` pressé. Appeler `dir = player.compute_input_direction()`. Vérifier : `dir.x` est approximativement `1.0` (tolérance `0.01`) et `dir.z` est approximativement `0.0` (tolérance `0.01`). Relâcher `move_right`.

**B9 — Comportement véhicule : `CameraController` avec `VehicleBody3D` en target ne propage pas (has_method retourne false).**
Instancier un `CameraController` et un `VehicleBody3D`. Assigner `cam.target = vehicule`. Assigner `cam._right_mouse_held = false`. Ajouter les deux nœuds à l'arbre. Appeler `cam._process(0.016)`. Vérifier : aucun crash. Vérifier : `vehicule.has_method("set_camera_yaw") == false`.

**B10 — `compute_input_direction` : composante Y du vecteur retourné est toujours 0.0.**
Instancier un `PlayerController`. Appeler `player.set_camera_yaw(PI / 6.0)`. Simuler `move_forward` pressé. Appeler `dir = player.compute_input_direction()`. Vérifier : `dir.y` est approximativement `0.0` (tolérance `0.0001`) — la rotation autour de `Vector3.UP` ne crée pas de composante verticale. Relâcher `move_forward`.

## Cas limites / erreurs

**CL1 — `_camera_yaw = 0` : comportement identique à feature 03.**
Quand `PlayerController._camera_yaw` vaut `0.0`, `raw.rotated(Vector3.UP, 0.0)` retourne `raw` inchangé. Les tests B1 à CL6 de `test_03_personnage_joueur.gd` restent valides sans modification.

**CL2 — `_camera_yaw = PI` : les axes sont inversés monde.**
Avec yaw = PI, "avancer" (raw_z = -1) devient monde +Z, "droite" (raw_x = +1) devient monde -X. L'effet est que la caméra est derrière le joueur dans le sens opposé — comportement mathématiquement correct.

**CL3 — Cible véhicule : `has_method` retourne `false`, propagation silencieuse, pas de crash.**
Même sans la condition `_right_mouse_held`, le check `has_method("set_camera_yaw")` protège contre toute propagation vers un `VehicleBody3D`. Aucune erreur GDScript n'est levée.

**CL4 — `compute_input_direction` avec `raw = Vector3.ZERO` : `rotated(Vector3.UP, angle)` sur vecteur nul.**
GDScript — `Vector3.ZERO.rotated(Vector3.UP, 1.0)` retourne `Vector3.ZERO` sans erreur. La vérification `if raw.length() > 0.0` évite la division par zéro dans `normalized()` ; la rotation s'applique ensuite sur le vecteur zéro déjà traité.

**CL5 — `_camera_yaw` non mis à jour avant premier frame : valeur initiale 0.0.**
Au démarrage du jeu, `CameraController._process` appellera `set_camera_yaw(0.0)` dès la première frame (car `DEFAULT_YAW = 0.0`). Le comportement est identique à avant (déplacement en axes monde). Pas d'état incohérent.

**CL6 — Yaw très grand ou négatif : `rotated(Vector3.UP, angle)` est périodique.**
`Vector3.rotated` accepte tout angle réel — `_camera_yaw` peut s'accumuler librement (comme `_yaw` dans `CameraController`) sans nécessiter de normalisation dans `[−PI, PI]`. La rotation est correcte quelle que soit la magnitude de l'angle.

**CL7 — `CameraController.target = null` : guard `if target == null: return` précède la propagation.**
La propagation `if target.has_method(...)` est après le guard — jamais atteinte si `target == null`. Aucun changement de comportement par rapport à la feature 11.

## Inputs Godot (Input Map)

Aucune nouvelle action n'est ajoutée dans `project.godot`. Les actions existantes (`move_forward`, `move_backward`, `move_left`, `move_right`) restent inchangées. Leur sémantique gameplay change (orientation relative à la caméra) mais leur définition `[input]` est identique.

## Assets consommés et intégration par code

Cette feature ne consomme aucun asset graphique.

| Chemin `res://` | Statut | Intégration GDScript |
|---|---|---|
| (aucun) | n/a | — |

## Impact sur les tests existants

### `tests/test_11_alignement_camera_personnage.gd` — ACTION REQUISE DU TESTER

**B8 (`test_camera_controller_ne_propage_pas_si_clic_droit_non_maintenu`) — CE TEST CASSE INTENTIONNELLEMENT avec feature 12.**

Ce test vérifie que `CameraController` ne propage pas quand `_right_mouse_held = false`. Avec la feature 12, la propagation est permanente — ce test échouera après implémentation.

Le tester feature 12 **doit** modifier `test_11_alignement_camera_personnage.gd` :
- **Supprimer ou remplacer** `test_camera_controller_ne_propage_pas_si_clic_droit_non_maintenu` par un test qui vérifie le nouveau comportement : propagation effective même quand `_right_mouse_held = false`.
- Ce nouveau test correspond au B1 de la spec 12 (voir §Comportements attendus).

La décision recommandée est de **remplacer** le corps du test B8 existant (conserver le nom de fonction pour traçabilité GUT) avec la nouvelle assertion, ou bien de le supprimer et de laisser la couverture B1 de `test_12_deplacement_camera_relatif.gd` couvrir ce cas.

**B9 (`test_camera_controller_ne_propage_pas_vers_noeud_sans_set_camera_yaw`) — CE TEST RESTE VALIDE.**

Le check `has_method("set_camera_yaw")` est conservé. La propagation n'a pas lieu vers un nœud sans cette méthode, avec ou sans `_right_mouse_held`. B9 passe au vert après implémentation de la feature 12 sans aucune modification.

### `tests/test_03_personnage_joueur.gd` — aucune modification nécessaire

Tous les tests B1 à B15 et CL1 à CL6 restent valides. La modification de `compute_input_direction` introduit `raw.rotated(Vector3.UP, _camera_yaw)`. Comme `_camera_yaw` vaut `0.0` à l'initialisation et que les tests de la feature 03 n'appellent jamais `set_camera_yaw`, `rotated(Vector3.UP, 0.0)` retourne le vecteur inchangé — résultats identiques.

Attention particulière : les tests CL1 (`compute_input_direction_sans_input_retourne_zero`) restent valides car `Vector3.ZERO.rotated(Vector3.UP, 0.0) == Vector3.ZERO`.

### `tests/test_09_camera_orbitale.gd` — aucune modification nécessaire

La modification de `_process` dans `CameraController` porte uniquement sur le bloc de propagation (dernières lignes). Les tests B1 à B16 et CL1 à CL5 de la feature 09 vérifient le positionnement orbital et les variables d'état (`_yaw`, `_pitch`, `_zoom_level`), qui ne sont pas affectés. Les tests instanciant une cible `Node3D` ordinaire (sans `set_camera_yaw`) continueront à ignorer silencieusement la propagation via le `has_method` check.

### `tests/test_04_camera_tp.gd` — aucune modification nécessaire

Idem feature 09 : les tests de positionnement instancient des cibles sans `set_camera_yaw` — propagation ignorée silencieusement. Aucun effet de bord.

## Dépendances

- **Spec 03 — Personnage joueur** : `PlayerController.compute_input_direction()` dans `src/player/player_controller.gd`. La feature 12 modifie cette méthode.
- **Spec 09 — Caméra orbitale** : `CameraController._yaw` dans `src/camera/camera_controller.gd`. Source du référentiel de déplacement.
- **Spec 11 — Alignement personnage-caméra** : `CameraController._process` et `PlayerController._camera_yaw` / `set_camera_yaw()`. La feature 12 modifie le premier et réutilise les seconds.
- **Spec 07 — Entrer / sortir d'un véhicule** : `VehicleBody3D` comme cible possible de `CameraController`. La feature 12 maintient la garde `has_method`.
- **`addons/gut/`** : addon GUT v9.6, déjà installé depuis la feature 01.
- Aucun autre addon autorisé.

## Critères d'acceptation

- [ ] `src/camera/camera_controller.gd` : dans `_process`, la condition de propagation est `if target.has_method("set_camera_yaw"):` sans `_right_mouse_held and`.
- [ ] `src/player/player_controller.gd` : `compute_input_direction()` se termine par `return raw.rotated(Vector3.UP, _camera_yaw)` (ou formulation équivalente avec variable locale différente — seul le résultat est contractuel).
- [ ] `test_11_alignement_camera_personnage.gd` : le test B8 (`test_camera_controller_ne_propage_pas_si_clic_droit_non_maintenu`) est supprimé ou remplacé par un test vérifiant la propagation permanente.
- [ ] `tests/test_12_deplacement_camera_relatif.gd` existe et contient les tests B1 à B10 et CL1 à CL7 spécifiés.
- [ ] `godot --path . res://main.tscn` se lance sans `ERROR:` ni `SCRIPT ERROR:`. Après une rotation caméra (clic droit + souris), appuyer sur Z propulse le personnage dans la direction où pointe la caméra.
- [ ] Après rotation caméra à 90° (clic droit + swipe gauche), appuyer sur Z déplace le personnage vers la gauche de l'écran (pas vers "l'avant monde -Z").
- [ ] Quand la cible de la caméra est un véhicule, le clic droit et le mouvement souris ne produisent aucune erreur, et la conduite reste inchangée.
- [ ] La commande `godot --headless -s res://addons/gut/gut_cmdln.gd -gdir=res://tests -gexit` retourne le code de sortie 0 (tous les tests de toutes les suites passent au vert, y compris les tests modifiés de `test_11_alignement_camera_personnage.gd`).
- [ ] Les 10 comportements attendus (B1 à B10) de `test_12_deplacement_camera_relatif.gd` passent au vert.
- [ ] Les 7 cas limites (CL1 à CL7) de `test_12_deplacement_camera_relatif.gd` passent au vert.

## Hors-périmètre

- Déplacement camera-relatif en véhicule : la conduite reste pilotée par les axes locaux du véhicule (feature 08), non affectée.
- Déplacement influencé par le pitch de la caméra (personnage qui "monte" si la caméra regarde vers le bas) : hors périmètre — seul le yaw entre en jeu.
- Sensibilité ou accélération différente selon l'angle caméra : hors périmètre.
- Rotation automatique de la caméra derrière le joueur (auto-align inverse) : feature future.
- Lock-on / système de visée : hors proto v0.1.
- Gestion pad / joystick : hors périmètre, clavier + souris uniquement.
- Strafe animé (animation dédiée au déplacement latéral) : hors proto v0.1.
