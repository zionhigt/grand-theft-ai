# Spec 15 — Correction géométrie roues VehicleBody3D (empattement axe Z)

## Contexte

- Design : `docs/design/15-correction-geometrie-roues.md`
- Bon de commande graphique : n/a (feature purement technique, aucun asset)
- Dépendances de specs précédentes :
  - **Spec 06 — Voiture** (`docs/specs/06-voiture.md`) : structure `car.tscn`, nœuds `VehicleBody3D` et `VehicleWheel3D` avec les positions incorrectes d'origine.
  - **Spec 08 — Conduite** (`docs/specs/08-conduite.md`) : flags `use_as_steering` et `use_as_traction`, inchangés par cette feature.
  - **Spec 13 — Carrosserie GLB** (`docs/specs/13-carrosserie-glb-masquage-roues.md`) : `car_visuals.gd`, méthode `_charger_carrosserie()` dans laquelle la rotation du GLB est ajoutée.
  - **Spec 14 — Calibration physique** (`docs/specs/14-calibration-physique-vehicule.md`) : valeurs de suspension et spawn Y à 1.1 m, toutes conservées inchangées.

## Objectif fonctionnel

Corriger les positions locales des quatre `VehicleWheel3D` dans `scenes/vehicles/car.tscn` pour que l'empattement soit aligné sur l'axe Z (avant = Z négatif, arrière = Z positif), conformément à la convention `VehicleBody3D` de Godot 4 (avance sur -Z local). Corriger simultanément la rotation du GLB `car_body.glb` dans `src/vehicles/car_visuals.gd` pour que le nez visuel du modèle pointe dans la direction de déplacement (-Z). Ces deux corrections suppriment la rotation permanente à droite et le comportement de flottaison.

## Arborescence cible

Seuls deux fichiers existants sont modifiés. Aucun fichier n'est créé.

```
scenes/
└── vehicles/
    └── car.tscn                   # MODIFIÉ — positions des 4 VehicleWheel3D
src/
└── vehicles/
    └── car_visuals.gd             # MODIFIÉ — rotation_degrees.y = 90.0 dans _charger_carrosserie()
tests/
    test_06_voiture.gd             # À METTRE À JOUR par le tester (voir §Impact sur tests existants)
```

## Interface publique (GDScript)

### `src/vehicles/car_visuals.gd` — class `CarVisuals`

Seule la méthode `_charger_carrosserie()` est modifiée. La signature et les autres méthodes restent inchangées.

```gdscript
class_name CarVisuals
extends Node3D

func _ready() -> void
func _charger_carrosserie() -> void   # MODIFIÉE : ajout de instance.rotation_degrees.y = 90.0
func _masquer_roues() -> void
func _calculer_aabb_recursive(noeud: Node) -> AABB
```

La modification dans `_charger_carrosserie()` consiste à ajouter, après la ligne `instance.position = -aabb.get_center() * scale_factor`, l'instruction suivante :

```gdscript
instance.rotation_degrees.y = 90.0
```

Cette ligne est ajoutée à l'intérieur du bloc `if aabb.size.length() > 0.001:`, après le calcul de position, avant la fermeture du bloc. Elle ne s'exécute que si le GLB est présent et que l'AABB est valide.

## Structure des scènes (.tscn)

### `scenes/vehicles/car.tscn` — modifications des positions de roues

Arbre de nœuds inchangé dans sa structure. Seules les propriétés `position` des quatre `VehicleWheel3D` changent :

```
Car (VehicleBody3D)
├── CarBodyCollision (CollisionShape3D)           — inchangé
├── CarBodyMesh (MeshInstance3D)                  — inchangé
├── WheelFrontLeft (VehicleWheel3D)
│   position = Vector3(-0.8, -0.5, -1.0)         # AVANT : Vector3(-1.0, -0.5, 0.8)
│   use_as_steering = true                        — inchangé
│   use_as_traction = false                       — inchangé
│   └── WheelMesh (MeshInstance3D)                — inchangé
├── WheelFrontRight (VehicleWheel3D)
│   position = Vector3(0.8, -0.5, -1.0)          # AVANT : Vector3(-1.0, -0.5, -0.8)
│   use_as_steering = true                        — inchangé
│   use_as_traction = false                       — inchangé
│   └── WheelMesh (MeshInstance3D)                — inchangé
├── WheelRearLeft (VehicleWheel3D)
│   position = Vector3(-0.8, -0.5, 1.0)          # AVANT : Vector3(1.0, -0.5, 0.8)
│   use_as_steering = false                       — inchangé
│   use_as_traction = true                        — inchangé
│   └── WheelMesh (MeshInstance3D)                — inchangé
├── WheelRearRight (VehicleWheel3D)
│   position = Vector3(0.8, -0.5, 1.0)           # AVANT : Vector3(1.0, -0.5, -0.8)
│   use_as_steering = false                       — inchangé
│   use_as_traction = true                        — inchangé
│   └── WheelMesh (MeshInstance3D)                — inchangé
├── CarVisuals (Node3D — script car_visuals.gd)   — inchangé
└── InteractionZone (Area3D)                      — inchangé
```

## Données et constantes

### Justification des axes

`VehicleBody3D` dans Godot 4 avance sur son axe **-Z local**. La convention physique correcte est :

| Axe | Rôle | Valeur |
|-----|------|--------|
| X | Voie (gauche/droite) | X < 0 = gauche, X > 0 = droite |
| Y | Hauteur de la roue | -0.5 (inchangé depuis feature 14) |
| Z | Empattement (avant/arrière) | Z < 0 = avant, Z > 0 = arrière |

### Tableau des nouvelles positions

| Roue | Ancienne position (feature 06) | Nouvelle position (feature 15) | Raisonnement |
|------|-------------------------------|-------------------------------|--------------|
| WheelFrontLeft  | `Vector3(-1.0, -0.5,  0.8)` | `Vector3(-0.8, -0.5, -1.0)` | Avant = Z−, gauche = X− |
| WheelFrontRight | `Vector3(-1.0, -0.5, -0.8)` | `Vector3( 0.8, -0.5, -1.0)` | Avant = Z−, droite = X+ |
| WheelRearLeft   | `Vector3( 1.0, -0.5,  0.8)` | `Vector3(-0.8, -0.5,  1.0)` | Arrière = Z+, gauche = X− |
| WheelRearRight  | `Vector3( 1.0, -0.5, -0.8)` | `Vector3( 0.8, -0.5,  1.0)` | Arrière = Z+, droite = X+ |

### Métriques géométriques

| Grandeur | Valeur |
|----------|--------|
| Empattement (|Z_avant − Z_arrière|) | 2.0 m |
| Voie (|X_gauche − X_droite|) | 1.6 m |
| Hauteur roue (Y local) | -0.5 m (inchangé) |

### Rotation du GLB carrosserie

| Propriété | Valeur avant | Valeur après | Justification |
|-----------|-------------|-------------|---------------|
| `instance.rotation_degrees.y` | 0.0° (implicite — non défini) | 90.0° | `car_body.glb` exporté nez vers -X ; +90° autour de Y aligne le nez sur -Z |

### Paramètres inchangés (feature 14)

| Paramètre | Valeur |
|-----------|--------|
| `wheel_radius` | 0.35 m |
| `wheel_rest_length` | 0.25 m |
| `suspension_stiffness` | 5.88 |
| `suspension_max_force` | 6000.0 N |
| `damping_compression` | 0.83 |
| `damping_relaxation` | 0.88 |
| `wheel_friction_slip` | 10.5 |
| Spawn Y de Car dans `main.tscn` | 1.1 m |

## Comportements attendus

Les comportements B1–B4 sont testables directement sur `car.tscn` instancié sans `add_child` (propriétés statiques de la scène). Les comportements B5 et B6 nécessitent `add_child_autofree` pour que `_ready()` s'exécute.

1. **B1** — `WheelFrontLeft.position` vaut `Vector3(-0.8, -0.5, -1.0)` (tolérance 0.001 par composante).
2. **B2** — `WheelFrontRight.position` vaut `Vector3(0.8, -0.5, -1.0)` (tolérance 0.001 par composante).
3. **B3** — `WheelRearLeft.position` vaut `Vector3(-0.8, -0.5, 1.0)` (tolérance 0.001 par composante).
4. **B4** — `WheelRearRight.position` vaut `Vector3(0.8, -0.5, 1.0)` (tolérance 0.001 par composante).
5. **B5** — `WheelFrontLeft.use_as_steering == true` et `WheelFrontLeft.use_as_traction == false` ; `WheelFrontRight.use_as_steering == true` et `WheelFrontRight.use_as_traction == false` ; `WheelRearLeft.use_as_steering == false` et `WheelRearLeft.use_as_traction == true` ; `WheelRearRight.use_as_steering == false` et `WheelRearRight.use_as_traction == true` — ces flags sont inchangés.
6. **B6** — Après `add_child_autofree(car)` (donc après `_ready()`), si `car_body.glb` est présent et que `CarBodyMesh` a au moins un enfant, le premier enfant `Node3D` de `CarBodyMesh` a `rotation_degrees.y` approximativement égal à 90.0 (tolérance 0.1°).

## Cas limites / erreurs

1. **CL1 — GLB absent** : si `res://assets/vehicles/car/car_body.glb` n'est pas chargeable (`load()` retourne `null`), `_charger_carrosserie()` retourne tôt avant d'atteindre la ligne `instance.rotation_degrees.y = 90.0`. Aucun crash ne doit se produire. Le nœud `CarBodyMesh` reste sans enfant GLB.
2. **CL2 — Symétrie X** : `WheelFrontLeft.position.x` doit être l'opposé de `WheelFrontRight.position.x` (-0.8 et +0.8). De même, `WheelRearLeft.position.x` doit être l'opposé de `WheelRearRight.position.x` (-0.8 et +0.8). La somme des positions X des deux roues d'un même essieu doit valoir 0.0 (tolérance 0.001).
3. **CL3 — Y inchangé** : les quatre roues conservent `position.y == -0.5`. La correction d'axe ne touche pas la hauteur.
4. **CL4 — Empattement uniforme** : `WheelFrontLeft.position.z == WheelFrontRight.position.z == -1.0` et `WheelRearLeft.position.z == WheelRearRight.position.z == 1.0`. Les deux roues d'un même essieu partagent exactement le même Z.

## Inputs Godot (Input Map)

Aucun nouvel input. Les actions de conduite définies en feature 08 (`move_forward`, `move_back`, `turn_left`, `turn_right`) restent inchangées.

## Assets consommés et intégration par code

| Chemin `res://...` | Statut | Intégration GDScript |
|--------------------|--------|----------------------|
| `res://assets/vehicles/car/car_body.glb` | livré (feature 13) | `load()` dans `_charger_carrosserie()` ; après `instance.position = -aabb.get_center() * scale_factor`, ajouter `instance.rotation_degrees.y = 90.0` |

Aucun nouvel asset. La feature modifie uniquement la façon dont l'instance du GLB existant est orientée après chargement.

## Impact sur tests existants

### Tests à mettre à jour par le tester

Le test suivant dans `tests/test_06_voiture.gd` vérifie les **anciennes** positions de roues et doit être mis à jour pour refléter les nouvelles valeurs :

| Fichier | Fonction | Valeurs à corriger |
|---------|----------|--------------------|
| `tests/test_06_voiture.gd` | `test_positions_locales_des_quatre_roues_sont_correctes()` (test B7 de la spec 06) | Remplacer les assertions sur `(-1.0, -0.5, 0.8)`, `(-1.0, -0.5, -0.8)`, `(1.0, -0.5, 0.8)`, `(1.0, -0.5, -0.8)` par les nouvelles valeurs `(-0.8, -0.5, -1.0)`, `(0.8, -0.5, -1.0)`, `(-0.8, -0.5, 1.0)`, `(0.8, -0.5, 1.0)` |

### Tests non impactés

- `tests/test_06_voiture.gd` — tous les autres tests (B1–B6, B8–B13, CL1–CL5, GLB1–GLB7, SCALE1–SCALE2) : ne vérifient pas les positions de roues, restent valides.
- `tests/test_13_carrosserie_glb_masquage_roues.gd` — aucun test de position de roue. B1–B9, CL1–CL2 et les vérifications complémentaires restent valides.
- Tous les autres fichiers de tests (`test_03`, `test_04`, `test_05`, `test_07`, `test_08`, `test_09`, `test_10`, `test_11`, `test_12`, `test_14`) : aucun ne vérifie les positions des `VehicleWheel3D` dans `car.tscn`.

## Dépendances

- **Specs** : 06-voiture, 08-conduite, 13-carrosserie-glb-masquage-roues, 14-calibration-physique-vehicule.
- **Addons** : `addons/gut/` — GUT v9.6 (seul addon autorisé).
- **Assets** : `res://assets/vehicles/car/car_body.glb` — livré en feature 13, aucun nouvel asset.

## Critères d'acceptation

- [ ] `WheelFrontLeft.position == Vector3(-0.8, -0.5, -1.0)` dans `car.tscn` (tolérance 0.001).
- [ ] `WheelFrontRight.position == Vector3(0.8, -0.5, -1.0)` dans `car.tscn` (tolérance 0.001).
- [ ] `WheelRearLeft.position == Vector3(-0.8, -0.5, 1.0)` dans `car.tscn` (tolérance 0.001).
- [ ] `WheelRearRight.position == Vector3(0.8, -0.5, 1.0)` dans `car.tscn` (tolérance 0.001).
- [ ] `WheelFrontLeft.use_as_steering == true`, `WheelFrontLeft.use_as_traction == false`.
- [ ] `WheelFrontRight.use_as_steering == true`, `WheelFrontRight.use_as_traction == false`.
- [ ] `WheelRearLeft.use_as_steering == false`, `WheelRearLeft.use_as_traction == true`.
- [ ] `WheelRearRight.use_as_steering == false`, `WheelRearRight.use_as_traction == true`.
- [ ] Après `_ready()` avec `car_body.glb` présent : `CarBodyMesh.get_child(0).rotation_degrees.y ≈ 90.0°` (tolérance 0.1°).
- [ ] Avec `car_body.glb` absent : `_charger_carrosserie()` retourne sans crash.
- [ ] `test_06_voiture.gd::test_positions_locales_des_quatre_roues_sont_correctes()` passe au vert après mise à jour par le tester.
- [ ] Tous les tests existants autres que B7 de `test_06_voiture.gd` restent verts (aucune régression).
- [ ] `godot --headless -s res://addons/gut/gut_cmdln.gd -gdir=res://tests -gexit` retourne code 0.
- [ ] `godot --path . res://main.tscn` se lance sans erreur dans la console.

## Hors-périmètre

- Modification des valeurs de suspension (feature 14 — déjà fixées).
- Animation de rotation des roues visuelles pendant la conduite.
- Sons moteur, freinage, crissement de pneus.
- Anti-roll bar, centre de gravité, physique avancée.
- Plusieurs véhicules.
- Comportement sur terrain non plat.
- Modification du fichier `car_body.glb` ou de tout autre asset binaire.
- Modification de `main.tscn` (spawn Y inchangé à 1.1 m).
- Modification des scripts `car_controller.gd` (feature 08) ou de tout autre script que `car_visuals.gd`.
