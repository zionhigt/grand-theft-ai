# Spec 14 — Calibration physique véhicule (spawn sol + suspension + moteur)

## Contexte

- Design : `docs/design/14-calibration-physique-vehicule.md`
- Bon de commande graphique : `docs/assets/14-calibration-physique-vehicule.md` — n/a (feature purement technique, aucun asset)
- Dépendances de specs précédentes :
  - **Spec 06 — Voiture** (`docs/specs/06-voiture.md`) : fournit `scenes/vehicles/car.tscn`, structure `VehicleBody3D` + 4 `VehicleWheel3D`, position Y initiale du Car dans `main.tscn`.
  - **Spec 08 — Conduite** (`docs/specs/08-conduite.md`) : fournit `src/vehicles/car_controller.gd`, constante `ENGINE_FORCE`.
  - **Spec 13 — Intégration carrosserie GLB propre** (`docs/specs/13-carrosserie-glb-masquage-roues.md`) : introduit les valeurs buggées que cette feature corrige (`suspension_stiffness = 28000`, `damping_compression = 0.3`, `damping_relaxation = 0.5`, `suspension_max_force = 10000`, `Car.position.y = 0.6`).

## Objectif fonctionnel

Corriger quatre bugs physiques introduits progressivement dans les features 08 et 13 : la voiture spawne 50 cm dans le sol (oscillation infinie), les ressorts de suspension sont 4 700 fois trop raides, l'amortissement est trop faible, et la force moteur insuffisante pour un jeu arcade. Après cette feature, la voiture pose ses quatre roues au sol dès le premier frame, reste immobile au repos, et accélère de 0 à 50 km/h en environ 4 secondes.

## Arborescence cible

```
.
├── main.tscn                             # modifié — Car.position.y : 0.6 → 1.1
├── scenes/
│   └── vehicles/
│       └── car.tscn                      # modifié — 4 × VehicleWheel3D :
│                                         #   suspension_stiffness  : 28000.0 → 5.88
│                                         #   damping_compression   : 0.3     → 0.83
│                                         #   damping_relaxation    : 0.5     → 0.88
│                                         #   suspension_max_force  : 10000.0 → 6000.0
└── src/
    └── vehicles/
        └── car_controller.gd             # modifié — ENGINE_FORCE : 800.0 → 4000.0
```

Aucun fichier nouveau créé. Aucun asset nouveau ou modifié.

## Interface publique (GDScript)

### `src/vehicles/car_controller.gd`

Seule la constante `ENGINE_FORCE` change. Le reste de l'interface est inchangé par rapport à la spec 08.

```gdscript
class_name CarController
extends Node

# Modifié en feature 14 : 800.0 → 4000.0
# Justification : 4000 N / 1200 kg ≈ 3.3 m/s², 0→50 km/h en ~4 s (arcade GTA-like)
const ENGINE_FORCE: float = 4000.0

# Inchangé par rapport à la spec 08
const BRAKE_FORCE: float = 20.0
const MAX_STEERING: float = 0.4
const STEERING_SPEED: float = 5.0
```

Toutes les autres méthodes et signaux de `CarController` sont inchangés.

## Structure des scènes (.tscn)

### `scenes/vehicles/car.tscn` — 4 VehicleWheel3D

Seules les propriétés de suspension changent sur chacun des quatre nœuds `WheelFrontLeft`, `WheelFrontRight`, `WheelRearLeft`, `WheelRearRight`. La hiérarchie de nœuds est inchangée :

```
Car (VehicleBody3D)
├── CarBodyCollision (CollisionShape3D — BoxShape3D 4.0×1.5×2.0, inchangé)
├── CarBodyMesh (MeshInstance3D, inchangé)
├── CarVisuals (Node3D — car_visuals.gd, inchangé)
├── WheelFrontLeft (VehicleWheel3D)
│   └── WheelMesh (MeshInstance3D, visible=false, inchangé)
├── WheelFrontRight (VehicleWheel3D)
│   └── WheelMesh (MeshInstance3D, visible=false, inchangé)
├── WheelRearLeft (VehicleWheel3D)
│   └── WheelMesh (MeshInstance3D, visible=false, inchangé)
└── WheelRearRight (VehicleWheel3D)
    └── WheelMesh (MeshInstance3D, visible=false, inchangé)
```

Propriétés modifiées sur chaque `VehicleWheel3D` (identiques pour les 4 roues) :

| Propriété | Ancienne valeur (feature 13) | Nouvelle valeur (feature 14) |
|-----------|------------------------------|------------------------------|
| `suspension_stiffness` | 28000.0 | **5.88** |
| `damping_compression` | 0.3 | **0.83** |
| `damping_relaxation` | 0.5 | **0.88** |
| `suspension_max_force` | 10000.0 | **6000.0** |
| `wheel_rest_length` | 0.25 | 0.25 (inchangé) |
| `wheel_radius` | 0.35 | 0.35 (inchangé) |

### `main.tscn` — nœud Car

```
Main (Node3D)
└── Car (VehicleBody3D, instance de scenes/vehicles/car.tscn)
    position : Vector3(5.0, 1.1, 5.0)   # y : 0.6 → 1.1
```

Tous les autres nœuds de `main.tscn` sont inchangés.

## Données et constantes

### Calcul justifiant spawn y = 1.1

Chaque `VehicleWheel3D` est positionné à `y = −0.5` en espace local du `VehicleBody3D` :

```
contact_sol_local = wheel_y_local − wheel_rest_length − wheel_radius
                  = −0.5 − 0.25 − 0.35
                  = −1.1 m
```

Pour que ce contact soit exactement à `y = 0` (plan du sol `WorldBoundaryShape3D`), l'origine du `VehicleBody3D` doit être à `y = 1.1 m` en coordonnées monde. Avec `y = 0.6` (feature 13), le contact sol réel est à `0.6 − 1.1 = −0.5 m`, soit 50 cm sous le sol, provoquant une pénétration continue dans la `WorldBoundary` et des oscillations infinies.

### Tableau récapitulatif des constantes

| Identifiant | Fichier | Valeur | Unité |
|-------------|---------|--------|-------|
| `ENGINE_FORCE` | `car_controller.gd` | **4000.0** | N |
| `BRAKE_FORCE` | `car_controller.gd` | 20.0 (inchangé) | N |
| `MAX_STEERING` | `car_controller.gd` | 0.4 (inchangé) | rad |
| `suspension_stiffness` | `car.tscn` (4 roues) | **5.88** | — |
| `damping_compression` | `car.tscn` (4 roues) | **0.83** | — |
| `damping_relaxation` | `car.tscn` (4 roues) | **0.88** | — |
| `suspension_max_force` | `car.tscn` (4 roues) | **6000.0** | N |
| `wheel_rest_length` | `car.tscn` (4 roues) | 0.25 (inchangé) | m |
| `wheel_radius` | `car.tscn` (4 roues) | 0.35 (inchangé) | m |
| Car position Y | `main.tscn` | **1.1** | m |

## Comportements attendus

Chaque comportement est testable unitairement avec GUT.

1. **B1** — `CarController.ENGINE_FORCE == 4000.0` : instancier `src/vehicles/car_controller.gd`, lire la constante `ENGINE_FORCE`, vérifier qu'elle vaut `4000.0`.

2. **B2** — `suspension_stiffness` des 4 roues == 5.88 : charger `scenes/vehicles/car.tscn`, instancier, lire `suspension_stiffness` sur chacun des nœuds `WheelFrontLeft`, `WheelFrontRight`, `WheelRearLeft`, `WheelRearRight` (tolérance 0.001).

3. **B3** — `damping_compression` des 4 roues == 0.83 : même procédure, lire `damping_compression` (tolérance 0.001).

4. **B4** — `damping_relaxation` des 4 roues == 0.88 : même procédure, lire `damping_relaxation` (tolérance 0.001).

5. **B5** — `suspension_max_force` des 4 roues == 6000.0 : même procédure, lire `suspension_max_force` (tolérance 0.1).

6. **B6** — `Car.position.y` dans `main.tscn` == 1.1 : charger `main.tscn`, instancier, récupérer le nœud `Car` (enfant direct), vérifier `car.position.y ≈ 1.1` (tolérance 0.001). Les composantes `x` et `z` restent à 5.0 (inchangées).

7. **B7** — `wheel_rest_length` des 4 roues reste 0.25 : vérifier que la modification n'a pas altéré `wheel_rest_length` (tolérance 0.001). Test de non-régression.

8. **B8** — `wheel_radius` des 4 roues reste 0.35 : vérifier que la modification n'a pas altéré `wheel_radius` (tolérance 0.001). Test de non-régression.

9. **B9** — `BRAKE_FORCE` reste 20.0 : instancier `car_controller.gd`, vérifier `BRAKE_FORCE == 20.0`. Test de non-régression.

## Cas limites / erreurs

1. **CL1** — Spawn décalé : si `Car.position.y` est modifié à une valeur différente de 1.1 (ex : 0.6), le `VehicleBody3D` ne doit pas crasher. Godot ne lève pas d'exception sur une position invalide — le comportement est visuel (oscillations), pas un crash. Pas de test de régression nécessaire au-delà de B6.

2. **CL2** — `BRAKE_FORCE` inchangé : la spec 14 ne touche pas `BRAKE_FORCE`. Le developer ne doit pas modifier cette constante. Vérifié par B9.

3. **CL3** — Valeurs de suspension identiques sur les 4 roues : les quatre `VehicleWheel3D` doivent avoir exactement les mêmes valeurs. Un oubli sur l'une des roues produirait un comportement physique asymétrique. Les tests B2–B5 et B7–B8 couvrent explicitement chacune des 4 roues.

4. **CL4** — `wheel_friction_slip` inchangé à 10.5 : la spec 14 ne touche pas cette propriété. Test de non-régression.

## Inputs Godot (Input Map)

Aucun changement. Toutes les actions de conduite (`drive_forward`, `drive_backward`, `drive_left`, `drive_right`) restent celles définies en feature 08.

## Assets consommés et intégration par code

Aucun asset nouveau ou modifié. Cette feature ne consomme pas d'asset graphique.

## Impact sur les tests existants — TESTS QUI CASSENT

### Impact critique : feature 14 invalide des tests existants des features 13 et 06

Le developer doit **mettre à jour** les tests cassés dans le même commit que l'implémentation. Le tester (agent `tester`) écrit les nouveaux tests de la feature 14 dans `tests/test_14_calibration_physique_vehicule.gd`. Les tests cassés dans les fichiers existants doivent être corrigés par le developer avant de valider.

---

#### `tests/test_13_carrosserie_glb_masquage_roues.gd` — 5 tests cassés

| Fonction de test | Ligne | Valeur attendue (feature 13) | Nouvelle valeur (feature 14) | Action requise |
|------------------|-------|------------------------------|------------------------------|----------------|
| `test_suspension_stiffness_est_28000_sur_les_quatre_roues` | 135–152 | `28000.0` | `5.88` | Mettre à jour `assert_almost_eq(w.suspension_stiffness, 28000.0, 0.1, ...)` → `assert_almost_eq(w.suspension_stiffness, 5.88, 0.001, ...)` et mettre à jour le nom de la fonction et les commentaires |
| `test_suspension_max_force_est_10000_sur_les_quatre_roues` | 188–205 | `10000.0` | `6000.0` | Mettre à jour `assert_almost_eq(w.suspension_max_force, 10000.0, 0.1, ...)` → `assert_almost_eq(w.suspension_max_force, 6000.0, 0.1, ...)` et mettre à jour le nom de la fonction et les commentaires |
| `test_car_dans_main_tscn_a_position_y_0_6` | 213–227 | `0.6` | `1.1` | Mettre à jour `assert_almost_eq(car.position.y, 0.6, 0.001, ...)` → `assert_almost_eq(car.position.y, 1.1, 0.001, ...)` et mettre à jour le nom de la fonction et les commentaires |
| `test_damping_compression_est_0_3_sur_les_quatre_roues` | 296–313 | `0.3` | `0.83` | Mettre à jour `assert_almost_eq(w.damping_compression, 0.3, 0.001, ...)` → `assert_almost_eq(w.damping_compression, 0.83, 0.001, ...)` et mettre à jour les commentaires |
| `test_damping_relaxation_est_0_5_sur_les_quatre_roues` | 319–336 | `0.5` | `0.88` | Mettre à jour `assert_almost_eq(w.damping_relaxation, 0.5, 0.001, ...)` → `assert_almost_eq(w.damping_relaxation, 0.88, 0.001, ...)` et mettre à jour les commentaires |

---

#### `tests/test_06_voiture.gd` — 2 tests cassés

| Fonction de test | Ligne | Valeur attendue (feature 13) | Nouvelle valeur (feature 14) | Action requise |
|------------------|-------|------------------------------|------------------------------|----------------|
| `test_noeud_car_dans_main_tscn_est_positionne_a_5_0_6_5` | 213–222 | `car.position.y == 0.6` | `1.1` | Mettre à jour `assert_almost_eq(car.position.y, 0.6, 0.001, ...)` → `assert_almost_eq(car.position.y, 1.1, 0.001, ...)`, mettre à jour le nom de la fonction, le commentaire de doc et le message d'assertion. La position X et Z (5.0) restent inchangées. |
| `test_spawn_voiture_ne_chevauche_pas_spawn_joueur` | 283–289 | `spawn_voiture := Vector3(5.0, 0.6, 5.0)` | `Vector3(5.0, 1.1, 5.0)` | Mettre à jour la variable locale `spawn_voiture` de `Vector3(5.0, 0.6, 5.0)` à `Vector3(5.0, 1.1, 5.0)`. La distance reste supérieure à 1.4 m (distance effective ~7.14 m >> 1.4 m). |

---

#### `tests/test_08_conduite.gd` — 1 test cassé

| Fonction de test | Ligne | Valeur attendue (feature 08) | Nouvelle valeur (feature 14) | Action requise |
|------------------|-------|------------------------------|------------------------------|----------------|
| `test_constante_engine_force_vaut_800` | 92–101 | `ENGINE_FORCE == 800.0` | `4000.0` | Mettre à jour `assert_eq(valeur, 800.0, ...)` → `assert_eq(valeur, 4000.0, ...)`, mettre à jour le nom de la fonction (`test_constante_engine_force_vaut_4000`) et les commentaires de doc. |

---

### Synthèse des modifications à apporter aux fichiers de tests existants

Le developer doit modifier les lignes suivantes dans les tests existants, en même temps qu'il modifie les fichiers de production :

- `tests/test_08_conduite.gd` : fonction `test_constante_engine_force_vaut_800` → renommer en `test_constante_engine_force_vaut_4000`, valeur 800.0 → 4000.0.
- `tests/test_06_voiture.gd` : fonction `test_noeud_car_dans_main_tscn_est_positionne_a_5_0_6_5` → renommer, valeur y 0.6 → 1.1 ; fonction `test_spawn_voiture_ne_chevauche_pas_spawn_joueur` → `spawn_voiture.y` 0.6 → 1.1.
- `tests/test_13_carrosserie_glb_masquage_roues.gd` : fonctions B6, B8, B9, `test_damping_compression_est_0_3...`, `test_damping_relaxation_est_0_5...` → nouvelles valeurs.

## Dépendances

- Spec 06 — `docs/specs/06-voiture.md` (structure `car.tscn`)
- Spec 08 — `docs/specs/08-conduite.md` (`car_controller.gd`, `ENGINE_FORCE`)
- Spec 13 — `docs/specs/13-carrosserie-glb-masquage-roues.md` (valeurs corrigées)
- Addon GUT `addons/gut/` (tests unitaires)

## Critères d'acceptation

- [ ] `tests/test_14_calibration_physique_vehicule.gd` existe et tous ses tests passent au vert sous GUT.
- [ ] Les tests modifiés dans `test_08_conduite.gd`, `test_06_voiture.gd`, `test_13_carrosserie_glb_masquage_roues.gd` passent au vert (valeurs mises à jour).
- [ ] La commande `Godot_v4.6.2-stable_win64_console.exe --headless -s res://addons/gut/gut_cmdln.gd -gdir=res://tests -gexit` retourne le code 0 (zéro test rouge dans l'ensemble de la suite).
- [ ] `main.tscn` est ouvrable dans l'éditeur sans erreur.
- [ ] `Godot_v4.6.2-stable_win64_console.exe --path . res://main.tscn` lance le jeu sans erreur console.

## Hors-périmètre

- Animation de rotation des roues.
- Sons moteur, freinage, suspension.
- Anti-roll bar, centre de gravité, physique avancée.
- Plusieurs véhicules.
- Modifications visuelles de la carrosserie.
- Comportement sur terrain non plat ou obstacles.
- Toute modification des constantes `BRAKE_FORCE`, `MAX_STEERING`, `STEERING_SPEED`.
- Toute modification des propriétés `wheel_friction_slip`, `wheel_radius`, `wheel_rest_length`, `suspension_travel`.
