# Spec 13 — Intégration carrosserie GLB propre (masquage roues redondantes)

## Contexte

- Design : `docs/design/13-carrosserie-glb-masquage-roues.md`
- Bon de commande graphique : `docs/assets/13-carrosserie-glb-masquage-roues.md`
- Dépendances de specs précédentes :
  - **Spec 06 — Voiture** (`docs/specs/06-voiture.md`) : fournit `scenes/vehicles/car.tscn` avec `VehicleBody3D`, 4 `VehicleWheel3D`, `CarBodyMesh : MeshInstance3D`, nœud `CarVisuals : Node3D` avec script `src/vehicles/car_visuals.gd`. Chaque `VehicleWheel3D` contient un enfant `WheelMesh : MeshInstance3D` (CylinderMesh mock). `car_visuals.gd` expose `_charger_carrosserie()` et `_charger_roues()`.
  - **Spec 08 — Conduite** (`docs/specs/08-conduite.md`) : fournit `src/vehicles/car_controller.gd`, paramètres physiques de conduite (`engine_force`, `brake`, `steering`). Les `VehicleWheel3D` restent les acteurs physiques de traction, freinage, direction.
  - **Spec 10 — Personnage 3D Mixamo** (`docs/specs/10-personnage-3d.md`) : précédente intégration GLB par code — pattern de référence.

## Objectif fonctionnel

Supprimer l'affichage redondant des roues visuelles : `car_body.glb` (déjà chargé dans `CarBodyMesh`) contient les roues visuelles intégrées, les quatre nœuds `WheelMesh` (CylinderMesh) sont donc masqués (`visible = false`) au lieu de recevoir un GLB supplémentaire. La fonction `_charger_roues()` est renommée `_masquer_roues()` et `wheel.glb` n'est plus chargé. Simultanément, les paramètres de suspension de `car.tscn` sont recalibrés pour qu'une voiture de 1 200 kg repose franchement sur ses roues, et la position Y de spawn dans `main.tscn` est ajustée en conséquence.

## Arborescence cible

```
.
├── main.tscn                                  # modifié — position Y du nœud Car : 0.75 → 0.6
├── scenes/
│   └── vehicles/
│       └── car.tscn                           # modifié — suspension_stiffness, suspension_rest_length,
│                                              #           suspension_max_force, damping_compression,
│                                              #           damping_relaxation sur les 4 VehicleWheel3D
└── src/
    └── vehicles/
        └── car_visuals.gd                     # modifié — _charger_roues() renommée _masquer_roues(),
                                               #           suppression du load("wheel.glb"),
                                               #           WheelMesh.visible = false
```

Aucun fichier nouveau créé. Aucun asset nouveau. `assets/vehicles/car/wheel.glb` reste physiquement sur disque (ne pas supprimer : invaliderait les `.import` Godot) mais n'est plus chargé par aucun script.

## Interface publique (GDScript)

### `src/vehicles/car_visuals.gd`

```gdscript
class_name CarVisuals
extends Node3D

func _ready() -> void:
    _charger_carrosserie()
    _masquer_roues()

func _charger_carrosserie() -> void:
    # Inchangé par rapport à la feature 06/10 :
    # charge res://assets/vehicles/car/car_body.glb comme enfant de CarBodyMesh,
    # applique auto-scale AABB pour ramener la plus grande dimension à 4.0 m.

func _masquer_roues() -> void:
    # Remplace _charger_roues(). Ne charge PLUS wheel.glb.
    # Pour chacun des 4 VehicleWheel3D parents (WheelFrontLeft, WheelFrontRight,
    # WheelRearLeft, WheelRearRight) :
    #   récupère l'enfant WheelMesh (MeshInstance3D)
    #   si trouvé : WheelMesh.visible = false
    #               # MASQUE — roue visuelle intégrée dans car_body.glb
    # Si un WheelMesh est absent : continuer sans erreur.

func _calculer_aabb_recursive(noeud: Node) -> AABB:
    # Inchangé — utilisé par _charger_carrosserie().
```

Signature de la méthode renommée :

```gdscript
func _masquer_roues() -> void
```

La méthode `_charger_roues()` est **supprimée**. Aucune autre méthode publique ni signal n'est ajouté.

**Stratégie de navigation vers WheelMesh :** `_masquer_roues()` utilise
`get_node_or_null("../" + nom + "/WheelMesh")` ou la forme équivalente
`get_node_or_null("../" + nom)` suivi de `.get_node_or_null("WheelMesh")`.
Dans les deux cas, le chemin traverse le parent commun (`Car`, ancêtre du nœud
`CarVisuals`) pour atteindre les `VehicleWheel3D` qui sont des frères de
`CarVisuals`. Le code d'origine utilisait `get_node_or_null("../" + nom)` comme
`VehicleWheel3D`, puis `.get_node_or_null("WheelMesh")` — ce schéma est
conservé.

## Structure des scènes (.tscn)

### `scenes/vehicles/car.tscn` (modifiée)

Seuls les paramètres de suspension des 4 `VehicleWheel3D` changent. La
structure des nœuds est inchangée.

```
Car : VehicleBody3D
  mass = 1200.0
  CarBodyCollision : CollisionShape3D        (inchangé)
  CarBodyMesh : MeshInstance3D               (inchangé — car_body.glb chargé par CarVisuals)
  WheelFrontLeft : VehicleWheel3D
    position = Vector3(-1.0, -0.5, 0.8)     (inchangé)
    use_as_steering = true                   (inchangé)
    use_as_traction = false                  (inchangé)
    wheel_radius = 0.35                      (inchangé)
    suspension_stiffness = 28000.0           # MODIFIÉ (était 5.88)
    suspension_rest_length = 0.25            # MODIFIÉ (était 0.3 défaut Godot)
    suspension_travel = 0.2                  (inchangé)
    suspension_max_force = 10000.0           # MODIFIÉ (était défaut Godot)
    damping_compression = 0.3               # MODIFIÉ (était 0.83 défaut Godot)
    damping_relaxation = 0.5                # MODIFIÉ (était 0.88 défaut Godot)
    wheel_friction_slip = 10.5              (inchangé)
    WheelMesh : MeshInstance3D
      visible = false                        # résultat de _masquer_roues() dans _ready()
      # MASQUE — roue visuelle intégrée dans car_body.glb
      (CylinderMesh conservé dans la scène — nœud dormant)
  WheelFrontRight : VehicleWheel3D           (mêmes modifications que WheelFrontLeft)
  WheelRearLeft : VehicleWheel3D             (mêmes modifications)
  WheelRearRight : VehicleWheel3D            (mêmes modifications)
  CarVisuals : Node3D
    script = res://src/vehicles/car_visuals.gd
  InteractionZone : Area3D                   (inchangé — feature 07)
    CollisionShape3D : CollisionShape3D      (inchangé)
```

Note : la propriété `visible = false` sur `WheelMesh` est positionnée par code
dans `_ready()` de `car_visuals.gd`, **pas** stockée dans la scène `.tscn`.
La scène `.tscn` ne contient que les nouvelles valeurs numériques de suspension.

### `main.tscn` (modifiée — position Y du Car)

```
Main : Node3D
  ...                    (tous nœuds hérités features 01–12 inchangés)
  Car : VehicleBody3D    (instance scenes/vehicles/car.tscn)
    transform = Transform3D(1,0,0, 0,1,0, 0,0,1, 5, 0.6, 5)
    # MODIFIÉ : y = 0.6 (était 0.75)
    # Justification : wheel_radius (0.35) + suspension_rest_length (0.25) = 0.60
```

## Données et constantes

### Paramètres de suspension — communs aux 4 VehicleWheel3D dans `car.tscn`

| Propriété | Ancienne valeur | Nouvelle valeur | Unité | Justification |
|-----------|----------------|-----------------|-------|---------------|
| `suspension_stiffness` | 5.88 | 28 000.0 | N/m | 1 200 kg / 4 roues = 300 kg/roue ; F = 300 × 9.8 = 2 940 N ; compression cible ~10 cm → k = 2940 / 0.10 = 29 400 ≈ 28 000 arcade |
| `suspension_rest_length` | 0.3 (défaut) | 0.25 | m | Cohérent avec wheel_radius = 0.35 m |
| `suspension_travel` | 0.2 | 0.2 | m | Inchangé |
| `suspension_max_force` | (défaut) | 10 000.0 | N | Plafond force suspension |
| `damping_compression` | 0.83 (défaut) | 0.3 | — | Moins rebondissant, sensation arcade |
| `damping_relaxation` | 0.88 (défaut) | 0.5 | — | Retour suspension plus amorti |
| `wheel_friction_slip` | 10.5 | 10.5 | — | Inchangé |

### Position spawn Car dans `main.tscn`

| Propriété | Ancienne valeur | Nouvelle valeur |
|-----------|----------------|-----------------|
| `position.y` (nœud Car) | 0.75 | 0.6 |

Calcul : `wheel_radius` (0.35) + `suspension_rest_length` (0.25) = **0.60 m**.

## Comportements attendus

Les comportements B1 à B5 sont testables unitairement avec GUT dans
`tests/test_13_carrosserie_glb_masquage_roues.gd`.

**B1.** La méthode `_charger_roues` n'existe plus dans `CarVisuals` : une
instance de `CarVisuals` (via `load("res://src/vehicles/car_visuals.gd").new()`)
ne répond pas à `has_method("_charger_roues")`.
```gdscript
var cv := load("res://src/vehicles/car_visuals.gd").new()
assert_false(cv.has_method("_charger_roues"))
```

**B2.** La méthode `_masquer_roues` existe dans `CarVisuals` :
```gdscript
var cv := load("res://src/vehicles/car_visuals.gd").new()
assert_true(cv.has_method("_masquer_roues"))
```

**B3.** Après `_ready()` (via `add_child_autofree`), les 4 `WheelMesh` ont
`visible == false`. Le test charge `car.tscn`, ajoute l'instance à l'arbre
(ce qui déclenche `_ready()` sur `CarVisuals`), puis vérifie :
```gdscript
var car := load("res://scenes/vehicles/car.tscn").instantiate()
add_child_autofree(car)
for nom in ["WheelFrontLeft", "WheelFrontRight", "WheelRearLeft", "WheelRearRight"]:
    var wm := car.get_node_or_null(nom + "/WheelMesh") as MeshInstance3D
    assert_not_null(wm)
    assert_false(wm.visible, "WheelMesh de %s doit être invisible après _ready()" % nom)
```

**B4.** Après `_ready()`, `CarBodyMesh` contient au moins un enfant `Node3D`
(l'instance GLB `car_body.glb` chargée par `_charger_carrosserie()`) :
```gdscript
var car := load("res://scenes/vehicles/car.tscn").instantiate()
add_child_autofree(car)
var mi := car.get_node_or_null("CarBodyMesh") as MeshInstance3D
assert_not_null(mi)
assert_gt(mi.get_child_count(), 0)
```

**B5.** Aucun appel à `load("res://assets/vehicles/car/wheel.glb")` ne subsiste
dans le source de `car_visuals.gd`. Ce comportement est vérifié statiquement par
le tester en lisant le fichier source — le test GUT correspondant lit le source
du script et vérifie l'absence de la chaîne `"wheel.glb"` :
```gdscript
var src := FileAccess.open("res://src/vehicles/car_visuals.gd", FileAccess.READ)
assert_not_null(src)
var content := src.get_as_text()
src.close()
assert_false("wheel.glb" in content,
    "car_visuals.gd ne doit plus contenir de référence à wheel.glb")
```

**B6.** Les 4 `VehicleWheel3D` de `car.tscn` ont `suspension_stiffness == 28000.0`
(tolérance 0.1) :
```gdscript
var car := load("res://scenes/vehicles/car.tscn").instantiate()
add_child_autofree(car)
for nom in ["WheelFrontLeft", "WheelFrontRight", "WheelRearLeft", "WheelRearRight"]:
    var w := car.get_node_or_null(nom) as VehicleWheel3D
    assert_almost_eq(w.suspension_stiffness, 28000.0, 0.1)
```

**B7.** Les 4 `VehicleWheel3D` ont `suspension_rest_length == 0.25` (tolérance
0.001) :
```gdscript
for nom in ["WheelFrontLeft", "WheelFrontRight", "WheelRearLeft", "WheelRearRight"]:
    var w := car.get_node_or_null(nom) as VehicleWheel3D
    assert_almost_eq(w.suspension_rest_length, 0.25, 0.001)
```

**B8.** Les 4 `VehicleWheel3D` ont `suspension_max_force == 10000.0` (tolérance
0.1) :
```gdscript
for nom in ["WheelFrontLeft", "WheelFrontRight", "WheelRearLeft", "WheelRearRight"]:
    var w := car.get_node_or_null(nom) as VehicleWheel3D
    assert_almost_eq(w.suspension_max_force, 10000.0, 0.1)
```

**B9.** Le nœud `Car` dans `main.tscn` a `position.y ≈ 0.6` (tolérance 0.001) :
```gdscript
var main := load("res://main.tscn").instantiate()
add_child_autofree(main)
var car := main.get_node_or_null("Car")
assert_not_null(car)
assert_almost_eq(car.position.y, 0.6, 0.001)
```

## Cas limites / erreurs

**CL1.** `WheelMesh` absent : si l'un des `VehicleWheel3D` ne possède pas
d'enfant nommé `"WheelMesh"`, `_masquer_roues()` continue la boucle sans
lever d'erreur (`get_node_or_null` retourne `null`, le `if` protège l'accès).
Aucun crash, aucun `ERROR:` dans la console.

**CL2.** `car_body.glb` absent : si l'asset `res://assets/vehicles/car/car_body.glb`
est manquant, `_charger_carrosserie()` retourne tôt (le `if packed == null: return`
existant) sans affecter `_masquer_roues()`. Les 4 `WheelMesh` sont quand même
masqués. Aucun crash.

**CL3.** Les nœuds `VehicleWheel3D` frères de `CarVisuals` sont accessibles
via `get_node_or_null("../" + nom)`. Si le nœud `CarVisuals` n'est pas enfant
de `Car` (arbre de scène anormal), `get_node_or_null` retourne `null` et la
boucle passe — pas de crash.

**CL4.** Le fichier `wheel.glb` reste présent dans `assets/vehicles/car/` sur
disque : le test GLB5 de `test_06_voiture.gd` (qui vérifie que `wheel.glb`
est chargeable) continue de passer au vert. Ceci est attendu : `wheel.glb` est
déprécié (plus utilisé par le code) mais pas supprimé.

## Inputs Godot (Input Map)

Aucun nouveau mapping d'entrée. Tous les contrôles de conduite restent ceux
de la feature 08 (`drive_forward`, `drive_backward`, `drive_left`, `drive_right`).

## Assets consommés et intégration par code

| Chemin `res://...` | Statut | Intégration GDScript |
|--------------------|--------|----------------------|
| `res://assets/vehicles/car/car_body.glb` | livré (ASSETS-STATUS OK) | `_charger_carrosserie()` inchangée : `load(...).instantiate()` attaché comme enfant de `CarBodyMesh` dans `_ready()`, auto-scale AABB vers 4.0 m |
| `res://assets/vehicles/car/wheel.glb` | livré — **DEPRECIE** | Plus chargé par `car_visuals.gd`. Fichier conservé sur disque. Aucune référence active dans les scripts après cette feature. |

Les quatre `WheelMesh : MeshInstance3D` (CylinderMesh) restent dans `car.tscn`
comme nœuds dormants. Commentaire à inscrire au-dessus de chaque `WheelMesh`
(en `editor_description` dans la scène ou commentaire dans le script) :
```
# MASQUE — roue visuelle intégrée dans car_body.glb
```

## Impact sur les tests existants (test_06, test_07, test_08)

### `tests/test_06_voiture.gd`

Les tests suivants testaient `_charger_roues()` et `wheel.glb`. Ils deviennent
**invalides** avec la feature 13 et doivent être mis à jour ou supprimés par
le `tester` lors de la rédaction de `test_13_...gd` :

| Nom du test | Raison de l'invalidation |
|-------------|--------------------------|
| `test_chaque_roue_wheel_mesh_possede_un_enfant_glb_apres_ready` | Attendait un enfant GLB dans `WheelMesh` — désormais `WheelMesh.get_child_count() == 0` et `visible == false` |
| `test_chaque_roue_wheel_mesh_premier_enfant_est_valide_apres_ready` (GLB7) | Même raison |
| `test_glb_wheel_est_chargeable_depuis_assets` (GLB5) | Reste **vert** car `wheel.glb` est conservé sur disque — pas d'invalidation |
| `test_wheel_mesh_a_rotation_zero_apres_ready` (BUG5) | Devient inutile : `WheelMesh.visible = false`, la rotation n'a plus d'importance visuelle. Le test passerait encore si `_masquer_roues()` n'écrase pas `rotation`, mais il est sémantiquement obsolète |
| `test_instance_glb_roue_a_rotation_z_90_apres_ready` (ROUE_ROT) | Invalide : aucune instance GLB n'est ajoutée à `WheelMesh` — `mesh_roue.get_child_count() == 0` |

**Tests conservés sans modification :**
- GLB1 (`test_car_tscn_contient_un_noeud_car_visuals_node3d`) — inchangé
- GLB2 (`test_car_visuals_possede_un_script_attache`) — inchangé
- GLB3 (`test_vehiclebody3d_racine_n_a_toujours_pas_de_script`) — inchangé
- GLB4 (`test_glb_car_body_est_chargeable_depuis_assets`) — inchangé
- GLB5 (`test_glb_wheel_est_chargeable_depuis_assets`) — inchangé (wheel.glb conservé sur disque)
- GLB6 (`test_carbodymesh_premier_enfant_est_un_node3d_apres_ready`) — inchangé
- SCALE1, SCALE2 — inchangés
- B1–B13, CL1–CL5 (structure scène, masse, positions roues, etc.) — inchangés
- B11 (position Car dans main.tscn) — **INVALIDE** : B11 vérifie `position.is_equal_approx(Vector3(5, 0.75, 5))`, la nouvelle valeur est `y = 0.6`. Ce test doit être mis à jour.

### `tests/test_07_entree_sortie_vehicule.gd`

Aucun test de `test_07` ne référence `_charger_roues`, `wheel.glb`, `WheelMesh`
ni les paramètres de suspension. Zéro impact.

### `tests/test_08_conduite.gd`

Aucun test de `test_08` ne référence ces éléments. Zéro impact.

### Résumé des tests à corriger dans `test_06_voiture.gd`

Le tester doit, dans `test_13_...gd` ou en annotant `test_06_voiture.gd` :
1. Remplacer `test_chaque_roue_wheel_mesh_possede_un_enfant_glb_apres_ready` par un test qui vérifie `WheelMesh.visible == false` et `WheelMesh.get_child_count() == 0`.
2. Remplacer `test_chaque_roue_wheel_mesh_premier_enfant_est_valide_apres_ready` (GLB7) par un test qui vérifie l'absence d'enfant dans `WheelMesh`.
3. Supprimer ou adapter `test_wheel_mesh_a_rotation_zero_apres_ready` (BUG5).
4. Supprimer `test_instance_glb_roue_a_rotation_z_90_apres_ready` (ROUE_ROT).
5. Mettre à jour B11 : `Vector3(5, 0.75, 5)` → `Vector3(5, 0.6, 5)`.

## Dépendances

- `docs/specs/06-voiture.md` : fournit la structure de `car.tscn` et l'interface initiale de `car_visuals.gd`.
- `docs/specs/08-conduite.md` : fournit `car_controller.gd` — non modifié par cette feature.
- `addons/gut/` : addon GUT v9.6. Aucun autre addon autorisé.

## Critères d'acceptation

- [ ] `src/vehicles/car_visuals.gd` ne contient plus de référence à `"wheel.glb"` ni d'appel à `_charger_roues`.
- [ ] `src/vehicles/car_visuals.gd` contient la méthode `_masquer_roues()` et l'appelle dans `_ready()`.
- [ ] Après `add_child_autofree(car)` sur une instance de `car.tscn`, les 4 nœuds `WheelMesh` ont `visible == false`.
- [ ] Après `add_child_autofree(car)` sur une instance de `car.tscn`, `CarBodyMesh` a au moins un enfant `Node3D` (GLB chargé par `_charger_carrosserie()`).
- [ ] `scenes/vehicles/car.tscn` : les 4 `VehicleWheel3D` ont `suspension_stiffness = 28000.0`, `suspension_rest_length = 0.25`, `suspension_max_force = 10000.0`, `damping_compression = 0.3`, `damping_relaxation = 0.5`.
- [ ] `main.tscn` : le nœud `Car` a `position.y ≈ 0.6`.
- [ ] `godot --path . res://main.tscn` se lance sans `ERROR:` ni `SCRIPT ERROR:` dans la console. La voiture s'affiche avec sa carrosserie GLB, sans roues cylindriques visibles en doublon.
- [ ] La commande headless GUT retourne le code 0 (tous les tests de `test_13_carrosserie_glb_masquage_roues.gd` passent au vert, et les tests de `test_06_voiture.gd` non invalidés restent verts).
- [ ] Les comportements B1 à B9 passent tous au vert dans GUT.
- [ ] Les cas limites CL1 à CL4 ne provoquent aucun crash ni `ERROR:` en mode headless.

## Hors-périmètre

- Animation de rotation des roues visuelles (les roues du GLB ne tournent pas dans ce prototype).
- Suppression physique de `wheel.glb` du disque (ne pas supprimer — invaliderait les `.import` Godot).
- Modification du GLB `car_body.glb` lui-même.
- Textures de carrosserie (`_albedo`, `_normal`, etc.).
- Sons moteur ou de suspension.
- Physique avancée (anti-roll bar, centre de gravité abaissé, différentiel).
- Plusieurs véhicules ou modèles différents.
