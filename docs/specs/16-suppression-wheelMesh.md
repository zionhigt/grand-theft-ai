# Spec 16 — Suppression des WheelMesh fantômes (roues CylinderMesh dépréciées)

## Contexte

- Design : `docs/design/16-suppression-wheelMesh.md`
- Bon de commande graphique : `docs/assets/16-suppression-wheelMesh.md`
- Dépendances de specs précédentes :
  - **Spec 06 — Voiture** (`docs/specs/06-voiture.md`) : a créé les nœuds `WheelMesh : MeshInstance3D` (CylinderMesh mock) enfants des quatre `VehicleWheel3D` dans `scenes/vehicles/car.tscn`, ainsi que `car_visuals.gd` avec `_charger_roues()`.
  - **Spec 13 — Intégration carrosserie GLB** (`docs/specs/13-carrosserie-glb-masquage-roues.md`) : a renommé `_charger_roues()` en `_masquer_roues()`, masqué les `WheelMesh` via `visible = false`, déclaré `wheel.glb` déprécié. Les nœuds `WheelMesh` ont été conservés physiquement dans la scène — c'est ce que la feature 16 corrige.
  - **Spec 14 — Calibration physique véhicule** (`docs/specs/14-calibration-physique-vehicule.md`) : a modifié les paramètres de suspension (`suspension_stiffness`, `suspension_max_force`, `damping_compression`, `damping_relaxation`). Ces valeurs restent intactes.
  - **Spec 15 — Correction géométrie roues** (`docs/specs/15-correction-geometrie-roues.md`) : a corrigé les positions locales des `VehicleWheel3D`. Ces positions restent intactes.

## Objectif fonctionnel

Supprimer définitivement les quatre nœuds `WheelMesh : MeshInstance3D` (CylinderMesh + StandardMaterial3D) enfants des `VehicleWheel3D` dans `scenes/vehicles/car.tscn`, et supprimer la méthode `_masquer_roues()` et son appel dans `src/vehicles/car_visuals.gd`. Ces nœuds sont des mocks de la feature 06 rendus dormants par la feature 13 — leur suppression nette élimine la dette technique sans aucun effet visuel en jeu, `car_body.glb` fournissant déjà les roues visuelles.

## Arborescence cible

```
.
├── scenes/
│   └── vehicles/
│       └── car.tscn        # modifié — 4 nœuds WheelMesh supprimés + 8 sous-ressources inline supprimées
└── src/
    └── vehicles/
        └── car_visuals.gd  # modifié — méthode _masquer_roues() supprimée, appel dans _ready() supprimé
```

Aucun fichier créé. Aucun fichier supprimé. `assets/vehicles/car/wheel.glb` reste sur disque (sa suppression physique est du ressort de l'agent `mixamo`).

## Interface publique (GDScript)

### `src/vehicles/car_visuals.gd`

```gdscript
class_name CarVisuals
extends Node3D

# Script d'intégration GLB par code — CLAUDE.md règle 6
# Charge car_body.glb dans _ready().

func _ready() -> void:
    _charger_carrosserie()

func _charger_carrosserie() -> void:
    # Inchangé — charge res://assets/vehicles/car/car_body.glb comme enfant de CarBodyMesh,
    # applique auto-scale AABB pour ramener la plus grande dimension à 4.0 m.
    ...

func _calculer_aabb_recursive(noeud: Node) -> AABB:
    # Inchangé
    ...
```

Méthodes supprimées :
- `_masquer_roues()` — supprimée entièrement (corps + signature).

Méthodes conservées sans modification :
- `_charger_carrosserie() -> void`
- `_calculer_aabb_recursive(noeud: Node) -> AABB`

## Structure des scènes (.tscn)

### `scenes/vehicles/car.tscn` — arbre après modification

```
Car : VehicleBody3D
├── CarBodyCollision : CollisionShape3D      (inchangé — BoxShape3D 4×1.5×2)
├── CarBodyMesh : MeshInstance3D             (inchangé — BoxMesh mock + car_body.glb via code)
├── WheelFrontLeft : VehicleWheel3D          (inchangé — paramètres physiques intacts)
│   # PAS d'enfant WheelMesh (supprimé)
├── WheelFrontRight : VehicleWheel3D         (inchangé — paramètres physiques intacts)
│   # PAS d'enfant WheelMesh (supprimé)
├── WheelRearLeft : VehicleWheel3D           (inchangé — paramètres physiques intacts)
│   # PAS d'enfant WheelMesh (supprimé)
├── WheelRearRight : VehicleWheel3D          (inchangé — paramètres physiques intacts)
│   # PAS d'enfant WheelMesh (supprimé)
├── CarVisuals : Node3D                      (inchangé — script car_visuals.gd)
└── InteractionZone : Area3D                 (inchangé)
    └── CollisionShape3D : CollisionShape3D  (inchangé — SphereShape3D rayon 3.0)
```

**Sous-ressources supprimées de `car.tscn`** (8 au total) :

| ID sub_resource | Type | Rôle | Nœud parent |
|-----------------|------|------|-------------|
| `CylinderMesh_wfl` | CylinderMesh | mesh de WheelMesh FL | `WheelFrontLeft/WheelMesh` |
| `Mat_wheel_fl` | StandardMaterial3D | matériau de WheelMesh FL | `WheelFrontLeft/WheelMesh` |
| `CylinderMesh_wfr` | CylinderMesh | mesh de WheelMesh FR | `WheelFrontRight/WheelMesh` |
| `Mat_wheel_fr` | StandardMaterial3D | matériau de WheelMesh FR | `WheelFrontRight/WheelMesh` |
| `CylinderMesh_wrl` | CylinderMesh | mesh de WheelMesh RL | `WheelRearLeft/WheelMesh` |
| `Mat_wheel_rl` | StandardMaterial3D | matériau de WheelMesh RL | `WheelRearLeft/WheelMesh` |
| `CylinderMesh_wrr` | CylinderMesh | mesh de WheelMesh RR | `WheelRearRight/WheelMesh` |
| `Mat_wheel_rr` | StandardMaterial3D | matériau de WheelMesh RR | `WheelRearRight/WheelMesh` |

Les sous-ressources `BoxShape3D_body`, `BoxMesh_body`, `Mat_body`, `SphereShape3D_interaction` restent inchangées.

## Données et constantes

Aucune nouvelle constante. Toutes les valeurs physiques des `VehicleWheel3D` restent identiques à celles établies par les features 14 et 15 :

| Propriété | Valeur | Établie par |
|-----------|--------|-------------|
| `wheel_radius` | 0.35 | feature 06 |
| `suspension_stiffness` | 5.88 | feature 14 |
| `suspension_max_force` | 6000.0 | feature 14 |
| `wheel_rest_length` | 0.25 | feature 14 |
| `suspension_travel` | 0.2 | feature 06 |
| `damping_compression` | 0.83 | feature 14 |
| `damping_relaxation` | 0.88 | feature 14 |
| `wheel_friction_slip` | 10.5 | feature 06 |

## Comportements attendus

1. **B1** — `CarVisuals` n'a pas de méthode `_masquer_roues` : `CarVisuals.new().has_method("_masquer_roues") == false`.
2. **B2** — L'appel `_masquer_roues()` n'est plus dans `_ready()` : vérifié indirectement par B1 (si la méthode n'existe pas, elle ne peut pas être appelée) et par lecture statique du source.
3. **B3** — `WheelFrontLeft` n'a aucun enfant dans `car.tscn` : `car.get_node("WheelFrontLeft").get_child_count() == 0`.
4. **B4** — `WheelFrontRight` n'a aucun enfant : `car.get_node("WheelFrontRight").get_child_count() == 0`.
5. **B5** — `WheelRearLeft` n'a aucun enfant : `car.get_node("WheelRearLeft").get_child_count() == 0`.
6. **B6** — `WheelRearRight` n'a aucun enfant : `car.get_node("WheelRearRight").get_child_count() == 0`.
7. **B7** — `_charger_carrosserie()` existe toujours et fonctionne : après `add_child_autofree(car)`, `car.get_node("CarBodyMesh").get_child_count() > 0` (instance GLB ajoutée).
8. **B8** — Le source de `car_visuals.gd` ne contient plus la chaîne `"_masquer_roues"` : vérifiable par `FileAccess` en lecture statique.

## Cas limites / erreurs

- **CL1** — Recherche de `"WheelMesh"` sur un `VehicleWheel3D` retourne `null` : `get_node_or_null("WheelMesh") == null`. Aucun crash attendu car `car_visuals.gd` ne fait plus cette recherche après suppression de `_masquer_roues()`.
- **CL2** — `car.tscn` s'instancie sans erreur et sans warning dans `--headless` : la suppression des nœuds ne laisse aucune référence pendante (les `[sub_resource]` supprimés n'étaient référencés que par les nœuds `WheelMesh` eux-mêmes).
- **CL3** — Les paramètres physiques des quatre `VehicleWheel3D` restent inchangés après la suppression de leurs enfants `WheelMesh` : les propriétés de physique sont portées par le nœud `VehicleWheel3D`, pas par ses enfants.

## Inputs Godot (Input Map)

Sans objet. Cette feature est un nettoyage purement technique.

## Assets consommés et intégration par code

| Chemin `res://...` | Statut | Intégration GDScript |
|--------------------|--------|----------------------|
| `res://assets/vehicles/car/car_body.glb` | livré | `load(...).instantiate()` attaché sous `CarBodyMesh` dans `_charger_carrosserie()` — inchangé |
| `res://assets/vehicles/car/wheel.glb` | DEPRECIE | Non chargé depuis feature 13. Fichier physique conservé sur disque jusqu'à archivage par l'agent `mixamo`. Aucune référence dans `car_visuals.gd` après cette feature. |

## Impact critique sur les tests existants

### `tests/test_13_carrosserie_glb_masquage_roues.gd`

Les tests suivants **cassent** après implémentation de la feature 16, car ils supposent l'existence des nœuds `WheelMesh` et/ou de la méthode `_masquer_roues()` :

| Nom de la fonction de test | Ligne(s) problématique(s) | Raison de la casse |
|---------------------------|---------------------------|-------------------|
| `test_masquer_roues_existe_dans_car_visuals()` | ligne 58 : `assert_true(cv.has_method("_masquer_roues"), ...)` | `_masquer_roues()` supprimée → `has_method` retourne `false` → assertion échoue |
| `test_wheel_mesh_invisible_apres_ready()` | ligne 79 : `car.get_node_or_null(nom + "/WheelMesh")` puis ligne 81 : `assert_not_null(wm, ...)` | `WheelMesh` supprimé → `get_node_or_null` retourne `null` → `assert_not_null` échoue |
| `test_masquer_roues_ne_crashe_pas_si_wheel_mesh_absent()` | ligne 257 : `car.get_node_or_null(nom + "/WheelMesh")` ; test sémantiquement obsolète | `_masquer_roues()` n'existe plus — toute la logique du test est sans objet |
| `test_wheel_mesh_masque_independamment_de_car_body_glb()` | ligne 287 : `car.get_node_or_null(nom + "/WheelMesh")` ; ligne 290 : `assert_eq(nb_masques, 4, ...)` | `WheelMesh` supprimé → `get_node_or_null` retourne `null` → `nb_masques` reste 0 → assertion échoue |

Le test `test_carbodymesh_a_un_enfant_node3d_apres_ready()` (B4) reste valide.
Les tests B6, B7, B8, B9, damping, friction_slip restent valides (portent sur les `VehicleWheel3D` et `main.tscn`, pas sur `WheelMesh`).

**Le tester doit corriger `test_13_carrosserie_glb_masquage_roues.gd`** :
- `test_masquer_roues_existe_dans_car_visuals()` → inverser : `assert_false(cv.has_method("_masquer_roues"), ...)` (cohérent avec B1 de la feature 16).
- `test_wheel_mesh_invisible_apres_ready()` → supprimer ou remplacer par un test vérifiant que `get_node_or_null(nom + "/WheelMesh") == null`.
- `test_masquer_roues_ne_crashe_pas_si_wheel_mesh_absent()` → supprimer (sans objet).
- `test_wheel_mesh_masque_independamment_de_car_body_glb()` → supprimer (sans objet).

### `tests/test_06_voiture.gd`

Les tests suivants **cassent** :

| Nom de la fonction de test | Ligne(s) problématique(s) | Raison de la casse |
|---------------------------|---------------------------|-------------------|
| `test_chaque_roue_wheel_mesh_est_invisible_et_sans_enfant_apres_ready()` | ligne 356 : `roue.get_node_or_null("WheelMesh")` ; ligne 357 : `assert_not_null(wheel_mesh, ...)` | `WheelMesh` supprimé → `assert_not_null` échoue |
| `test_chaque_roue_wheel_mesh_n_a_aucun_enfant_glb_apres_ready()` | ligne 520 : `roue.get_node_or_null("WheelMesh")` ; ligne 521 : `assert_not_null(wheel_mesh, ...)` | `WheelMesh` supprimé → `assert_not_null` échoue |

**Le tester doit corriger `test_06_voiture.gd`** :
- `test_chaque_roue_wheel_mesh_est_invisible_et_sans_enfant_apres_ready()` → remplacer par une assertion que `get_child_count() == 0` sur chaque `VehicleWheel3D` directement.
- `test_chaque_roue_wheel_mesh_n_a_aucun_enfant_glb_apres_ready()` → idem, ou fusionner avec le comportement B3–B6 de la feature 16.

Le commentaire d'architecture aux lignes 402–408 (mentionnant `WheelMesh`) doit aussi être mis à jour en commentaire uniquement (pas un test, pas bloquant pour GUT).

## Dépendances

- `addons/gut/` — framework de test GUT v9.6 (déjà présent).
- Aucun autre addon.

## Critères d'acceptation

- [ ] `tests/test_16_suppression_wheelMesh.gd` passe au vert sous GUT headless.
- [ ] `tests/test_13_carrosserie_glb_masquage_roues.gd` passe au vert après correction par le tester.
- [ ] `tests/test_06_voiture.gd` passe au vert après correction par le tester.
- [ ] La commande `Godot_v4.6.2-stable_win64_console.exe --headless -s res://addons/gut/gut_cmdln.gd -gdir=res://tests -gexit` retourne le code 0 (tous tests verts).
- [ ] `godot --path . res://main.tscn` lance le jeu sans erreur dans la console (la voiture s'affiche, `car_body.glb` visible, aucun artefact CylinderMesh).
- [ ] `scenes/vehicles/car.tscn` ouvert dans l'éditeur Godot ne montre aucun nœud `WheelMesh` sous les `VehicleWheel3D`.
- [ ] `src/vehicles/car_visuals.gd` ne contient plus la chaîne `_masquer_roues`.
- [ ] L'en-tête du fichier `car_visuals.gd` ne mentionne plus le masquage des roues.

## Hors-périmètre

- Animation des roues visuelles (rotation en fonction de la vitesse).
- Modification des paramètres physiques `VehicleBody3D` / `VehicleWheel3D`.
- Suppression physique de `wheel.glb` du disque (rôle de l'agent `mixamo`).
- Modification de `main.tscn`.
- Toute modification des features 01 à 15 au-delà des corrections de tests listées ci-dessus.
