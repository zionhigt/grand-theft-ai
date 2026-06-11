# Spec 17 — Corrections véhicule : orientation GLB, ENGINE_FORCE, BRAKE_FORCE

## Contexte

- Design : `docs/design/17-correction-orientation-glb-vitesse.md`
- Bon de commande : n/a (aucun asset graphique)
- Dépendances de specs :
  - Spec 08 (`docs/specs/08-conduite.md`) — définit `ENGINE_FORCE`, `BRAKE_FORCE` et leur usage dans `_physics_process`
  - Spec 13 (`docs/specs/13-carrosserie-glb-masquage-roues.md`) — définit `_charger_carrosserie()` et la rotation du GLB
  - Spec 14 (`docs/specs/14-calibration-physique-vehicule.md`) — établit `ENGINE_FORCE = 4000.0` et `BRAKE_FORCE = 20.0` comme valeurs de départ
  - Spec 15 (`docs/specs/15-correction-geometrie-roues.md`) — introduit le test B6 vérifiant `rotation_degrees.y ≈ 90.0`, qui devient obsolète avec cette spec

## Objectif fonctionnel

Corriger trois valeurs mal calibrées dans le code du véhicule : le modèle GLB carrosserie est affiché à l'envers (rotation Y +90° au lieu de -90°), le moteur est trop faible pour un arcade GTA-like (4000 N au lieu de 8000 N), et le frein n'a aucun effet mesurable (20.0 au lieu de 80.0). Ces trois corrections touchent exactement deux fichiers de production existants, sans création de nouveau fichier.

## Arborescence cible

Aucun fichier créé. Deux fichiers modifiés, un test créé.

```
src/
  vehicles/
    car_visuals.gd          [MODIFIÉ — ligne rotation_degrees.y : +90.0 → -90.0]
    car_controller.gd       [MODIFIÉ — ENGINE_FORCE : 4000.0 → 8000.0 ; BRAKE_FORCE : 20.0 → 80.0]
tests/
  test_17_correction_orientation_glb_vitesse.gd   [CRÉÉ par tester]
```

Fichiers de tests existants dont des assertions doivent être mises à jour par le developer lors de l'implémentation :

```
tests/
  test_08_conduite.gd                         [à corriger : B1 (4000.0→8000.0), B2 (20.0→80.0)]
  test_14_calibration_physique_vehicule.gd    [à corriger : B1 (4000.0→8000.0), B9 (20.0→80.0)]
  test_15_correction_geometrie_roues.gd       [à corriger : B6 (90.0→-90.0)]
```

## Interface publique (GDScript)

### `src/vehicles/car_visuals.gd`

```
class_name CarVisuals
extends Node3D

func _ready() -> void
func _charger_carrosserie() -> void
func _calculer_aabb_recursive(noeud: Node) -> AABB
```

Aucun changement de signature. Seule la valeur littérale de `rotation_degrees.y` change à l'intérieur de `_charger_carrosserie()`.

### `src/vehicles/car_controller.gd`

```
class_name CarController
extends Node

const ENGINE_FORCE: float = 8000.0
const BRAKE_FORCE: float = 80.0
const MAX_STEERING: float = 0.4
const STEERING_SPEED: float = 5.0
const FORWARD_SPEED_THRESHOLD: float = 0.5

@export var game_state_path: NodePath
@export var car_body_path: NodePath

func _ready() -> void
func _physics_process(delta: float) -> void
```

Seules les valeurs des constantes `ENGINE_FORCE` et `BRAKE_FORCE` changent. La logique de `_physics_process` est inchangée.

## Structure des scènes (.tscn)

Aucune scène n'est créée ni modifiée par cette feature. Les corrections sont purement scriptées.

## Données et constantes

### Constantes modifiées dans `src/vehicles/car_controller.gd`

| Constante | Valeur avant | Valeur après | Unité | Justification |
|-----------|-------------|-------------|-------|---------------|
| `ENGINE_FORCE` | 4000.0 | 8000.0 | N (Newton) | 8000 N / 1200 kg ≈ 6.7 m/s² — sensation arcade immédiate, 0→100 km/h en ~4 s |
| `BRAKE_FORCE` | 20.0 | 80.0 | valeur directement affectée à `VehicleBody3D.brake` | multiplié par 4 — décélération arcade perceptible ; valeur ajustable si comportement encore insuffisant en jeu |

**Note sur l'unité de `BRAKE_FORCE`** : dans `_physics_process`, la ligne `_car_body.brake = BRAKE_FORCE` affecte directement la propriété `brake` de `VehicleBody3D`. En Godot 4, `VehicleBody3D.brake` est une force de freinage en Newton appliquée sur chaque roue active. La valeur 80.0 N est le point de départ retenu ; elle peut être affinée par le developer si le ressenti en jeu reste insuffisant — la spec fixe le minimum à 80.0 pour que les tests passent.

### Constante modifiée dans `src/vehicles/car_visuals.gd`

| Champ | Valeur avant | Valeur après | Unité | Justification |
|-------|-------------|-------------|-------|---------------|
| `instance.rotation_degrees.y` | +90.0 | -90.0 | degrés | voir justification mathématique ci-dessous |

## Justification mathématique de la rotation -90° vs +90°

Le modèle `car_body.glb` est exporté avec son axe avant orienté vers **-X** dans l'espace local du GLB. Le nœud `VehicleBody3D` de Godot avance dans la direction **-Z** de son repère local (convention Godot : avant = -Z).

Pour aligner l'axe -X du GLB sur l'axe -Z de Godot, on applique une rotation autour de Y :

- Rotation **+90°** autour de Y : transforme -X → **+Z**. Cela aligne le nez du modèle vers l'arrière du VehicleBody3D. La caméra orbitale en position neutre (yaw 0°, regardant vers +Z) voit la porte arrière passager au lieu du capot.
- Rotation **-90°** autour de Y : transforme -X → **-Z**. Cela aligne le nez du modèle sur l'avant du VehicleBody3D. La caméra orbitale en position neutre voit le capot et le pare-choc avant — comportement attendu.

La correction est donc : `instance.rotation_degrees.y = -90.0`.

## Comportements attendus

Les comportements sont testables unitairement avec GUT sans physique simulée (simples lectures de propriétés et constantes).

**B1** — Après appel de `_charger_carrosserie()` sur une instance de `CarVisuals` ajoutée à la scène avec `car_body.glb` présent, le premier enfant `Node3D` de `CarBodyMesh` a `rotation_degrees.y ≈ -90.0` (tolérance 0.1°).

**B2** — `CarController.ENGINE_FORCE == 8000.0` : instancier `src/vehicles/car_controller.gd`, lire la constante, vérifier `assert_eq(ctrl.ENGINE_FORCE, 8000.0)`.

**B3** — `CarController.BRAKE_FORCE == 80.0` : instancier `src/vehicles/car_controller.gd`, lire la constante, vérifier `assert_eq(ctrl.BRAKE_FORCE, 80.0)`.

**B4** — Quand `drive_backward` est pressé et `forward_speed >= FORWARD_SPEED_THRESHOLD`, `_car_body.brake` reçoit la valeur `80.0` (non-régression du comportement de freinage avec la nouvelle constante).

**B5** — `CarController.MAX_STEERING`, `STEERING_SPEED` et `FORWARD_SPEED_THRESHOLD` sont inchangés (non-régression) : respectivement 0.4, 5.0 et 0.5.

## Cas limites / erreurs

**CL1** — GLB absent (`car_body.glb` non chargeable) : `_charger_carrosserie()` retourne tôt sans atteindre la ligne `rotation_degrees.y`. Aucun crash. La propriété `rotation_degrees.y` n'est jamais lue ni écrite sur un nœud inexistant. Ce comportement est hérité de la spec 13 — le test CL1 de `test_15_correction_geometrie_roues.gd` couvre déjà ce cas.

**CL2** — `delta == 0.0` passé à `_physics_process` : `_car_body.brake` reçoit `BRAKE_FORCE` (80.0) si `drive_backward` est pressé et que la vitesse est suffisante. Aucun crash, comportement identique à `delta > 0.0` pour les affectations directes (non dépendantes du delta).

**CL3** — `_car_body == null` ou `_game_state == null` : `_physics_process` retourne immédiatement sans crash. Comportement hérité de la spec 08, inchangé.

## Impact sur les tests existants

Cette feature modifie des valeurs de constantes et une ligne de rotation qui sont déjà vérifiées dans des tests existants. Ces tests doivent être mis à jour par le developer lors de l'implémentation, simultanément aux corrections de production.

### `tests/test_15_correction_geometrie_roues.gd` — fonction `test_instance_glb_carrosserie_a_rotation_y_90_apres_ready()`

Test B6 de la feature 15. Vérifie actuellement `rotation_degrees.y ≈ 90.0`. Après la correction, la valeur sera `-90.0` et ce test échouera.

**Correction requise** : changer la valeur attendue de `90.0` à `-90.0` et mettre à jour le message d'assertion.

Ligne concernée :
```gdscript
# AVANT
assert_almost_eq(rot_y, 90.0, 0.1,
    "B6 : L'instance GLB de CarBodyMesh doit avoir rotation_degrees.y ≈ 90.0° (feature 15 : nez -X → nez -Z)")
# APRÈS
assert_almost_eq(rot_y, -90.0, 0.1,
    "B6 : L'instance GLB de CarBodyMesh doit avoir rotation_degrees.y ≈ -90.0° (feature 17 : nez -X → nez -Z, correction orientation)")
```

### `tests/test_14_calibration_physique_vehicule.gd` — fonctions `test_engine_force_vaut_4000()` et `test_brake_force_reste_20()`

- Test B1 vérifie `ENGINE_FORCE == 4000.0` → cassé, la nouvelle valeur est 8000.0.
- Test B9 vérifie `BRAKE_FORCE == 20.0` → cassé, la nouvelle valeur est 80.0.

**Corrections requises** :

Fonction `test_engine_force_vaut_4000()` (renommer si souhaité) :
```gdscript
# AVANT
assert_eq(valeur, 4000.0,
    "B1 : ENGINE_FORCE doit valoir 4000.0 N (feature 14 : 800.0 → 4000.0)")
# APRÈS
assert_eq(valeur, 8000.0,
    "B1 : ENGINE_FORCE doit valoir 8000.0 N (feature 17 : 4000.0 → 8000.0)")
```

Fonction `test_brake_force_reste_20()` (renommer si souhaité) :
```gdscript
# AVANT
assert_eq(valeur, 20.0,
    "B9 : BRAKE_FORCE doit rester à 20.0 N (non-régression feature 14)")
# APRÈS
assert_eq(valeur, 80.0,
    "B9 : BRAKE_FORCE doit valoir 80.0 (feature 17 : 20.0 → 80.0)")
```

### `tests/test_08_conduite.gd` — fonctions `test_constante_engine_force_vaut_4000()` et `test_constante_brake_force_vaut_20()`

- Test B1 vérifie `ENGINE_FORCE == 4000.0` → cassé.
- Test B2 vérifie `BRAKE_FORCE == 20.0` → cassé.

**Corrections requises** :

Fonction `test_constante_engine_force_vaut_4000()` :
```gdscript
# AVANT
assert_eq(valeur, 4000.0,
    "ENGINE_FORCE doit valoir 4000.0 N (feature 14 : 800.0 → 4000.0)")
# APRÈS
assert_eq(valeur, 8000.0,
    "ENGINE_FORCE doit valoir 8000.0 N (feature 17 : 4000.0 → 8000.0)")
```

Fonction `test_constante_brake_force_vaut_20()` :
```gdscript
# AVANT
assert_eq(valeur, 20.0,
    "BRAKE_FORCE doit valoir 20.0 N")
# APRÈS
assert_eq(valeur, 80.0,
    "BRAKE_FORCE doit valoir 80.0 (feature 17 : 20.0 → 80.0)")
```

**Note pour le tester** : les tests B1, B2, B3 du nouveau fichier `test_17_correction_orientation_glb_vitesse.gd` couvrent les nouvelles valeurs cibles. Les corrections dans les fichiers 08, 14 et 15 sont effectuées par le developer lors de l'implémentation — le tester n'écrit que le nouveau fichier de tests.

## Inputs Godot (Input Map)

Aucune modification de l'Input Map. Les actions `drive_forward`, `drive_backward`, `drive_left`, `drive_right` existent déjà (feature 08).

## Assets consommés et intégration par code

| Chemin `res://...` | Statut | Intégration GDScript |
|--------------------|--------|----------------------|
| `res://assets/vehicles/car/car_body.glb` | livré (feature 13) | `load(...).instantiate()` attaché sous `CarBodyMesh` dans `_charger_carrosserie()` — inchangé, seule `rotation_degrees.y` est modifiée |

## Dépendances

- Spec 08 : `docs/specs/08-conduite.md` — définit la structure de `car_controller.gd`
- Spec 13 : `docs/specs/13-carrosserie-glb-masquage-roues.md` — définit `_charger_carrosserie()`
- Spec 14 : `docs/specs/14-calibration-physique-vehicule.md` — a établi les valeurs 4000.0 et 20.0
- Spec 15 : `docs/specs/15-correction-geometrie-roues.md` — contient le test B6 à corriger
- Addon GUT : `addons/gut/` (seul addon autorisé)

## Critères d'acceptation

- [ ] `CarController.ENGINE_FORCE == 8000.0` — `test_17 B2` vert
- [ ] `CarController.BRAKE_FORCE == 80.0` — `test_17 B3` vert
- [ ] Instance GLB `CarBodyMesh` enfant a `rotation_degrees.y ≈ -90.0` — `test_17 B1` vert (si `car_body.glb` présent)
- [ ] `test_15 B6` passe au vert après correction de la valeur attendue de `90.0` à `-90.0`
- [ ] `test_14 B1` passe au vert après correction de la valeur attendue de `4000.0` à `8000.0`
- [ ] `test_14 B9` passe au vert après correction de la valeur attendue de `20.0` à `80.0`
- [ ] `test_08 B1` passe au vert après correction de la valeur attendue de `4000.0` à `8000.0`
- [ ] `test_08 B2` passe au vert après correction de la valeur attendue de `20.0` à `80.0`
- [ ] `godot --headless -s res://addons/gut/gut_cmdln.gd -gdir=res://tests -gexit` retourne 0 (tous tests verts, y compris les tests des features 08, 14, 15 corrigés)
- [ ] `godot --path . res://main.tscn` lance le jeu sans erreur dans la console
- [ ] En jeu, la caméra orbitale en position neutre montre le capot avant du véhicule

## Hors-périmètre

- Aucune modification de la logique de `_physics_process` (accélération, freinage, braquage).
- Aucune modification des paramètres de suspension, du rayon des roues, de la friction.
- Aucune modification des scripts caméra (features 09, 11).
- Aucune modification de la masse du véhicule (reste 1200 kg dans `car.tscn`).
- Aucun nouvel asset graphique ou sonore.
- Aucune modification de l'Input Map.
- Le réglage fin de `BRAKE_FORCE` au-delà de 80.0 est laissé à la discrétion du developer si le comportement en jeu reste insuffisant — mais la valeur minimale spécifiée est 80.0.
