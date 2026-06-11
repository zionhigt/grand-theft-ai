# Spec 05 — Ville minimale (sol étendu + bâtiments cubiques)

## Contexte

- Design : `docs/design/05-ville-minimale.md`
- Bon de commande graphique : `docs/assets/05-ville-minimale.md`
- Dépendances de specs précédentes :
  - **Spec 01 — Bootstrap projet** (`docs/specs/01-bootstrap.md`) : fournit `project.godot` et `main.tscn` (nœud racine `Main : Node3D`).
  - **Spec 02 — Scène 3D minimale** (`docs/specs/02-scene-3d-minimale.md`) : fournit le sol `Ground : MeshInstance3D` (PlaneMesh 200 × 200 m) à y = 0, la lumière directionnelle, le ciel procédural. Cette feature 05 instancie `city.tscn` dans la même `main.tscn` sans modifier ces nœuds.
  - **Spec 03 — Personnage joueur** (`docs/specs/03-personnage-joueur.md`) : fournit le `Player : CharacterBody3D` (CapsuleShape3D rayon 0.4 m, hauteur 1.8 m) utilisant `move_and_slide()`. Les `StaticBody3D` des bâtiments arrêteront le personnage sans aucune modification du script `PlayerController`.
  - **Spec 04 — Caméra TP** (`docs/specs/04-camera-tp.md`) : fournit le `CameraRig` qui suit le joueur. Aucune modification requise.

## Objectif fonctionnel

Introduire une ville embryonnaire dans `main.tscn` : huit bâtiments cubiques (`StaticBody3D` + `BoxShape3D` + `BoxMesh`) de dimensions et couleurs variées, disposés manuellement autour de l'origine, regroupés dans une scène dédiée `scenes/city/city.tscn` instanciée dans `main.tscn`. Chaque bâtiment constitue un obstacle physique solide que le personnage ne peut pas traverser. Aucun script dynamique n'est nécessaire — la scène est entièrement déclarative. Cette feature ne modifie pas le sol, la lumière, le ciel, le personnage ni la caméra.

## Arborescence cible

```
.
├── main.tscn                                   # modifié — nœud City (instance city.tscn) ajouté
├── scenes/
│   └── city/
│       └── city.tscn                           # créé — scène City avec 8 StaticBody3D
├── tests/
│   └── test_05_ville_minimale.gd               # à écrire par le tester
└── assets/
    ├── city/
    │   └── buildings/
    │       ├── batiment_1.glb                  # non livré — mock BoxMesh inline dans city.tscn
    │       ├── batiment_2.glb                  # non livré — mock BoxMesh inline dans city.tscn
    │       ├── batiment_3.glb                  # non livré — mock BoxMesh inline dans city.tscn
    │       ├── batiment_4.glb                  # non livré — mock BoxMesh inline dans city.tscn
    │       ├── batiment_5.glb                  # non livré — mock BoxMesh inline dans city.tscn
    │       ├── batiment_6.glb                  # non livré — mock BoxMesh inline dans city.tscn
    │       ├── batiment_7.glb                  # non livré — mock BoxMesh inline dans city.tscn
    │       └── batiment_8.glb                  # non livré — mock BoxMesh inline dans city.tscn
    └── materials/
        └── city/
            ├── batiment_grey_dark.tres         # non livré — mock StandardMaterial3D inline
            ├── batiment_grey_medium.tres       # non livré — mock StandardMaterial3D inline
            ├── batiment_grey_light.tres        # non livré — mock StandardMaterial3D inline
            ├── batiment_beige_dark.tres        # non livré — mock StandardMaterial3D inline
            ├── batiment_beige_medium.tres      # non livré — mock StandardMaterial3D inline
            └── batiment_beige_light.tres       # non livré — mock StandardMaterial3D inline
```

Notes :
- Aucun script `.gd` de production n'est créé par cette feature (voir section "API GDScript").
- `scenes/city/city.tscn` est la seule scène créée.
- `main.tscn` est modifié (pas recréé) : les nœuds hérités des features 01, 02, 03 et 04 sont conservés intacts.
- Les dossiers `assets/city/buildings/` et `assets/materials/city/` sont déclarés par le bon de commande mais leurs fichiers ne sont pas livrés.

## Interface publique (GDScript)

### Décision : aucun script GDScript pour cette feature

La scène `city.tscn` n'embarque pas de script. Tous les bâtiments sont des nœuds statiques déclaratifs (`StaticBody3D` sans script), dont le comportement physique est intégralement géré par le moteur Godot (collision native entre `StaticBody3D` et `CharacterBody3D` via `move_and_slide()`).

**Justification** : aucune logique dynamique n'est requise — pas de génération procédurale, pas de spawn à l'exécution, pas d'état à changer. Ajouter un script `CityBuilder` pour simplement instancier des nœuds déjà présents dans la scène serait de la complexité sans bénéfice, et rendrait les tests plus fragiles. La scène suffit.

Si une logique de ville procédurale est introduite dans une feature ultérieure, un script sera ajouté à ce moment-là.

## Structure des scènes (.tscn)

### `scenes/city/city.tscn` (créée)

Nœud racine : `City : Node3D` (aucun script).

Les huit bâtiments sont des enfants directs de `City`. Chaque bâtiment suit le pattern suivant (voir tableau de données pour les valeurs par bâtiment) :

```
City : Node3D
│
├── Batiment1 : StaticBody3D
│     position = Vector3(20, 0, 20)
│     │
│     ├── CollisionShape3D : CollisionShape3D
│     │     shape = BoxShape3D
│     │       size = Vector3(6, 12, 6)
│     │     position = Vector3(0, 6, 0)       # centre de la box à mi-hauteur (hauteur/2 = 6)
│     │     # Nœud de scène — aucun asset associé
│     │
│     └── MeshInstance3D : MeshInstance3D
│           mesh = BoxMesh
│             size = Vector3(6, 12, 6)
│           material_override = StandardMaterial3D
│             albedo_color = Color(0.541, 0.541, 0.541, 1.0)   # #8a8a8a
│             shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
│           position = Vector3(0, 6, 0)       # bas du mesh à y=0, haut à y=12
│           # MOCK — à remplacer par res://assets/city/buildings/batiment_1.glb
│           # MOCK — matériau à remplacer par res://assets/materials/city/batiment_grey_medium.tres
│
├── Batiment2 : StaticBody3D
│     position = Vector3(-25, 0, 15)
│     [même structure — voir tableau de données]
│
...
└── Batiment8 : StaticBody3D
      position = Vector3(-20, 0, 35)
      [même structure — voir tableau de données]
```

**Règles communes à tous les bâtiments :**
- Le `StaticBody3D` est posé à y = 0 (niveau du sol de la feature 02).
- Le `CollisionShape3D` (BoxShape3D) et le `MeshInstance3D` (BoxMesh) sont tous deux décalés de `hauteur / 2` sur l'axe Y local, de sorte que la face inférieure soit exactement à y = 0.
- `size` du `BoxShape3D` = `size` du `BoxMesh` = dimensions réelles du bâtiment.
- Aucun script sur aucun nœud de la scène.
- Les ombres restent désactivées (cohérence avec la feature 02 : `shadow_enabled = false` sur la `DirectionalLight3D` existante — non modifiée ici).

### `main.tscn` (modifiée — ajout d'un nœud)

```
Main : Node3D                                    (nœud racine — inchangé)
│
├── WorldEnvironment : WorldEnvironment          (hérité feature 02 — inchangé)
├── DirectionalLight3D : DirectionalLight3D      (hérité feature 02 — inchangé)
├── Ground : MeshInstance3D                      (hérité feature 02 — inchangé)
├── GroundCollider : StaticBody3D                (hérité feature 03 — inchangé)
│     └── CollisionShape3D : CollisionShape3D
├── Player : CharacterBody3D                     (hérité feature 03 — inchangé, instance player.tscn)
├── CameraRig : Node3D                           (hérité feature 04 — inchangé, script CameraController)
│     └── Camera3D : Camera3D
└── City : Node3D                                (nœud nouveau — instance de scenes/city/city.tscn)
      # Instancié depuis res://scenes/city/city.tscn
      # Contient les 8 StaticBody3D bâtiments
```

Notes de structure :
- `City` est ajouté **après** `CameraRig` dans l'ordre des enfants de `Main`.
- `City` est instancié comme scène externe (instance de `res://scenes/city/city.tscn`), pas inline.
- Aucun des nœuds existants n'est modifié ou déplacé.
- La position de `City` dans `main.tscn` est `Vector3(0, 0, 0)` (origine) — les positions des bâtiments sont définies localement dans `city.tscn`.

## Données et constantes

Aucune constante GDScript n'est introduite (pas de script). Les valeurs ci-dessous sont déclarées dans la scène `city.tscn`.

### Tableau complet des 8 bâtiments

| Nom nœud | position StaticBody3D | size BoxMesh / BoxShape3D | décalage Y (mesh + shape) | albedo_color (float) | albedo_color (hex) | matériau mock cible |
|----------|-----------------------|--------------------------|--------------------------|----------------------|--------------------|---------------------|
| Batiment1 | `Vector3(20, 0, 20)` | `Vector3(6, 12, 6)` | `position.y = 6` | `Color(0.541, 0.541, 0.541, 1.0)` | #8a8a8a | `batiment_grey_medium.tres` |
| Batiment2 | `Vector3(-25, 0, 15)` | `Vector3(8, 8, 8)` | `position.y = 4` | `Color(0.690, 0.627, 0.565, 1.0)` | #b0a090 | `batiment_beige_dark.tres` |
| Batiment3 | `Vector3(30, 0, -20)` | `Vector3(5, 6, 10)` | `position.y = 3` | `Color(0.604, 0.604, 0.604, 1.0)` | #9a9a9a | `batiment_grey_light.tres` |
| Batiment4 | `Vector3(-15, 0, -30)` | `Vector3(10, 5, 6)` | `position.y = 2.5` | `Color(0.784, 0.722, 0.604, 1.0)` | #c8b89a | `batiment_beige_light.tres` |
| Batiment5 | `Vector3(40, 0, 5)` | `Vector3(6, 10, 6)` | `position.y = 5` | `Color(0.478, 0.478, 0.478, 1.0)` | #7a7a7a | `batiment_grey_dark.tres` |
| Batiment6 | `Vector3(-40, 0, -10)` | `Vector3(7, 7, 7)` | `position.y = 3.5` | `Color(0.722, 0.659, 0.533, 1.0)` | #b8a888 | `batiment_beige_medium.tres` |
| Batiment7 | `Vector3(10, 0, -40)` | `Vector3(4, 14, 4)` | `position.y = 7` | `Color(0.533, 0.533, 0.533, 1.0)` | #888888 | `batiment_grey_medium.tres` |
| Batiment8 | `Vector3(-20, 0, 35)` | `Vector3(12, 4, 5)` | `position.y = 2` | `Color(0.753, 0.690, 0.627, 1.0)` | #c0b0a0 | `batiment_beige_light.tres` |

**Convention de décalage Y** : le `StaticBody3D` est posé à y = 0. Le `MeshInstance3D` et le `CollisionShape3D` enfants ont leur `position.y` local égal à `hauteur / 2`, de sorte que la face inférieure du BoxMesh / BoxShape3D coïncide exactement avec y = 0 (niveau du sol).

### Constantes de validation (utilisées dans les tests GUT)

| Constante de test | Valeur |
|---|---|
| `BUILDING_COUNT` | `8` |
| `MIN_SPAWN_DISTANCE` | `10.0` m (distance minimale de tout bâtiment à l'origine) |
| `MAX_DISTANCE_FROM_ORIGIN` | `50.0` m (distance maximale du centre d'un bâtiment à l'origine en XZ) |
| `MIN_HEIGHT` | `4.0` m |
| `MAX_HEIGHT` | `14.0` m |

## Comportements attendus

Chaque point est testable unitairement avec GUT dans `tests/test_05_ville_minimale.gd`. Les tests B1 à B10 requièrent le chargement de `city.tscn`. Les tests B11 et B12 requièrent le chargement de `main.tscn`.

**B1.** `load("res://scenes/city/city.tscn")` retourne une ressource non nulle et son `instantiate()` ne retourne pas null — la scène se charge sans erreur.

**B2.** Le nœud racine de `city.tscn` s'appelle `"City"` et est de type `Node3D` :
```gdscript
var city = load("res://scenes/city/city.tscn").instantiate()
assert_eq(city.name, "City")
assert_true(city is Node3D)
```

**B3.** `city.tscn` contient exactement 8 enfants directs de type `StaticBody3D` — ni plus ni moins :
```gdscript
var bodies = city.get_children().filter(func(n): return n is StaticBody3D)
assert_eq(bodies.size(), 8)
assert_eq(city.get_child_count(), 8)
```

**B4.** Chaque `StaticBody3D` a exactement un enfant `CollisionShape3D` dont le `shape` est un `BoxShape3D` :
```gdscript
for body in bodies:
    var shapes = body.get_children().filter(func(n): return n is CollisionShape3D)
    assert_eq(shapes.size(), 1)
    assert_true(shapes[0].shape is BoxShape3D)
```

**B5.** Chaque `StaticBody3D` a exactement un enfant `MeshInstance3D` dont le `mesh` est un `BoxMesh` :
```gdscript
for body in bodies:
    var meshes = body.get_children().filter(func(n): return n is MeshInstance3D)
    assert_eq(meshes.size(), 1)
    assert_true(meshes[0].mesh is BoxMesh)
```

**B6.** Pour chaque bâtiment, la `size` du `BoxShape3D` est égale (à 0.001 près par composant) à la `size` du `BoxMesh` :
```gdscript
for body in bodies:
    var shape_size = body.get_node("CollisionShape3D").shape.size
    var mesh_size  = body.get_node("MeshInstance3D").mesh.size
    assert_almost_eq(shape_size.x, mesh_size.x, 0.001)
    assert_almost_eq(shape_size.y, mesh_size.y, 0.001)
    assert_almost_eq(shape_size.z, mesh_size.z, 0.001)
```

**B7.** Pour chaque bâtiment, la `position.y` locale du `CollisionShape3D` est égale (à 0.001 près) à `shape.size.y / 2.0` — le bas du BoxShape3D est exactement à y = 0 en espace local :
```gdscript
for body in bodies:
    var cs = body.get_node("CollisionShape3D")
    assert_almost_eq(cs.position.y, cs.shape.size.y / 2.0, 0.001)
```

**B8.** Pour chaque bâtiment, la `position.y` locale du `MeshInstance3D` est égale (à 0.001 près) à `mesh.size.y / 2.0` — le bas du BoxMesh est exactement à y = 0 en espace local :
```gdscript
for body in bodies:
    var mi = body.get_node("MeshInstance3D")
    assert_almost_eq(mi.position.y, mi.mesh.size.y / 2.0, 0.001)
```

**B9.** La `position.y` de chaque `StaticBody3D` est exactement `0.0` (posé sur le sol) :
```gdscript
for body in bodies:
    assert_almost_eq(body.position.y, 0.0, 0.001)
```

**B10.** La distance de chaque bâtiment à l'origine (en XZ) est comprise entre 10.0 m (distance minimale au spawn) et 50.0 m inclus :
```gdscript
for body in bodies:
    var dist_xz = Vector2(body.position.x, body.position.z).length()
    assert_true(dist_xz >= 10.0, "Bâtiment trop proche du spawn : " + body.name)
    assert_true(dist_xz <= 50.0, "Bâtiment trop loin de l'origine : " + body.name)
```

**B11.** La hauteur (composante Y de `BoxMesh.size`) de chaque bâtiment est comprise entre 4.0 m et 14.0 m inclus :
```gdscript
for body in bodies:
    var h = body.get_node("MeshInstance3D").mesh.size.y
    assert_true(h >= 4.0, "Bâtiment trop bas : " + body.name)
    assert_true(h <= 14.0, "Bâtiment trop haut : " + body.name)
```

**B12.** Chaque `MeshInstance3D` a un `material_override` non nul de type `StandardMaterial3D` :
```gdscript
for body in bodies:
    var mat = body.get_node("MeshInstance3D").material_override
    assert_not_null(mat)
    assert_true(mat is StandardMaterial3D)
```

**B13.** Test de scène `main.tscn` (headless) : `main.tscn` contient un enfant direct nommé `"City"` de type `Node3D` :
```gdscript
var main = load("res://main.tscn").instantiate()
add_child_autofree(main)
var city_node = main.get_node_or_null("City")
assert_not_null(city_node)
assert_true(city_node is Node3D)
```

**B14.** Test de scène `main.tscn` (headless) : le nœud `City` dans `main.tscn` contient exactement 8 enfants `StaticBody3D` (les bâtiments sont bien instanciés) :
```gdscript
var city_in_main = main.get_node("City")
var bodies_in_main = city_in_main.get_children().filter(func(n): return n is StaticBody3D)
assert_eq(bodies_in_main.size(), 8)
```

**B15.** Les nœuds hérités des features précédentes (`WorldEnvironment`, `DirectionalLight3D`, `Ground`, `GroundCollider`, `Player`, `CameraRig`) sont toujours présents et non nuls dans `main.tscn` après l'ajout de `City` :
```gdscript
for node_name in ["WorldEnvironment", "DirectionalLight3D", "Ground", "GroundCollider", "Player", "CameraRig"]:
    assert_not_null(main.get_node_or_null(node_name), "Nœud manquant : " + node_name)
```

## Cas limites / erreurs

**CL1.** `city.tscn` instanciée sans être ajoutée à l'arbre de scène (`instantiate()` seul, sans `add_child`) : l'appel ne produit aucune erreur Godot. Les nœuds enfants sont accessibles via `get_node()` et `get_children()`. Les `CollisionShape3D` et `BoxShape3D` sont accessibles sans arbre actif.

**CL2.** Un `BoxShape3D` dont la `size` serait `Vector3(0, 0, 0)` rend la collision non fonctionnelle (le personnage traverserait le bâtiment). La spec garantit des dimensions minimales de 4 × 4 m au sol et 4 m de hauteur — aucun composant de `size` ne peut être nul ou négatif. Le test B11 couvre la hauteur ; le developer doit s'assurer que les composantes X et Z sont aussi > 0.

**CL3.** Si la position du `City` nœud dans `main.tscn` n'est pas `Vector3(0, 0, 0)`, les bâtiments seraient décalés par rapport aux positions définies dans `city.tscn`. La spec impose `position = Vector3(0, 0, 0)` pour le nœud `City` instancié dans `main.tscn`. Le test B10 (distances au spawn) couvre ce cas indirectement.

**CL4.** Le `StaticBody3D` n'a pas de script : son `get_script()` doit retourner `null`. Un test peut vérifier que `body.get_script() == null` pour s'assurer qu'aucun script n'est accidentellement attaché.

**CL5.** Le joueur (CharacterBody3D rayon 0.4 m) spawn à `Vector3(0, 0.9, 0)`. Les bâtiments les plus proches (Batiment4 à XZ = (-15, -30), distance ~33 m ; Batiment7 à XZ = (10, -40), distance ~41 m en XZ) sont tous à plus de 10 m de l'origine. Aucun bâtiment ne chevauche le point de spawn — validé par le test B10.

## Inputs Godot (Input Map)

Aucun ajout pour cette feature. Les actions `move_forward`, `move_backward`, `move_left`, `move_right` de la feature 03 restent inchangées. La section `[input]` de `project.godot` n'est pas modifiée.

## Assets consommés

| Chemin `res://` | Mock attendu | Type mock | Usage dans la scène |
|---|---|---|---|
| `res://assets/city/buildings/batiment_1.glb` | oui | `MeshInstance3D` avec `BoxMesh(6,12,6)` inline dans `city.tscn` | Mesh visuel Batiment1 |
| `res://assets/city/buildings/batiment_2.glb` | oui | `MeshInstance3D` avec `BoxMesh(8,8,8)` inline dans `city.tscn` | Mesh visuel Batiment2 |
| `res://assets/city/buildings/batiment_3.glb` | oui | `MeshInstance3D` avec `BoxMesh(5,6,10)` inline dans `city.tscn` | Mesh visuel Batiment3 |
| `res://assets/city/buildings/batiment_4.glb` | oui | `MeshInstance3D` avec `BoxMesh(10,5,6)` inline dans `city.tscn` | Mesh visuel Batiment4 |
| `res://assets/city/buildings/batiment_5.glb` | oui | `MeshInstance3D` avec `BoxMesh(6,10,6)` inline dans `city.tscn` | Mesh visuel Batiment5 |
| `res://assets/city/buildings/batiment_6.glb` | oui | `MeshInstance3D` avec `BoxMesh(7,7,7)` inline dans `city.tscn` | Mesh visuel Batiment6 |
| `res://assets/city/buildings/batiment_7.glb` | oui | `MeshInstance3D` avec `BoxMesh(4,14,4)` inline dans `city.tscn` | Mesh visuel Batiment7 |
| `res://assets/city/buildings/batiment_8.glb` | oui | `MeshInstance3D` avec `BoxMesh(12,4,5)` inline dans `city.tscn` | Mesh visuel Batiment8 |
| `res://assets/materials/city/batiment_grey_dark.tres` | oui | `StandardMaterial3D` inline (albedo #7a7a7a) pour Batiment5 | Matériau mock gris foncé |
| `res://assets/materials/city/batiment_grey_medium.tres` | oui | `StandardMaterial3D` inline (albedo #8a8a8a) pour Batiment1, Batiment7 | Matériau mock gris moyen |
| `res://assets/materials/city/batiment_grey_light.tres` | oui | `StandardMaterial3D` inline (albedo #9a9a9a) pour Batiment3 | Matériau mock gris clair |
| `res://assets/materials/city/batiment_beige_dark.tres` | oui | `StandardMaterial3D` inline (albedo #b0a090) pour Batiment2 | Matériau mock beige foncé |
| `res://assets/materials/city/batiment_beige_medium.tres` | oui | `StandardMaterial3D` inline (albedo #b8a888) pour Batiment6 | Matériau mock beige moyen |
| `res://assets/materials/city/batiment_beige_light.tres` | oui | `StandardMaterial3D` inline (albedo #c8b89a / #c0b0a0) pour Batiment4, Batiment8 | Matériau mock beige clair |

Tous les assets sont mockés **inline** dans `scenes/city/city.tscn`. Aucun fichier `.tres` ni `.glb` externe n'est requis pour que la scène se charge et se lance. Chaque `MeshInstance3D` dans `city.tscn` porte les commentaires :
```
# MOCK — à remplacer par res://assets/city/buildings/batiment_N.glb
# MOCK — matériau à remplacer par res://assets/materials/city/batiment_<couleur>.tres
```

## Dépendances

- **Spec 01 — Bootstrap projet** : fournit `project.godot` et `main.tscn`.
- **Spec 02 — Scène 3D minimale** : fournit le sol 200 × 200 m à y = 0 sur lequel les bâtiments sont posés.
- **Spec 03 — Personnage joueur** : fournit le `CharacterBody3D` qui entre en collision avec les bâtiments via `move_and_slide()`.
- **Spec 04 — Caméra TP** : fournit le `CameraRig` — aucune modification requise.
- **`addons/gut/`** : addon GUT v9.4 ou supérieur, déjà installé. Aucun autre addon autorisé.

## Critères d'acceptation

- [ ] Le fichier `scenes/city/city.tscn` est présent et s'ouvre dans l'éditeur Godot 4.6 sans warning rouge ni erreur de ressource manquante.
- [ ] L'arbre de `city.tscn` dans l'éditeur affiche un nœud racine `City : Node3D` avec exactement 8 enfants `StaticBody3D` nommés `Batiment1` à `Batiment8`.
- [ ] Chaque `StaticBody3D` contient exactement un `CollisionShape3D` (BoxShape3D) et un `MeshInstance3D` (BoxMesh), tous deux décalés de `hauteur/2` sur Y.
- [ ] `main.tscn` s'ouvre dans l'éditeur Godot 4.6 sans warning rouge. L'arbre affiche `City` comme dernier enfant de `Main`, après `CameraRig`.
- [ ] `godot --path . res://main.tscn` se lance sans `ERROR:` ni `SCRIPT ERROR:` dans la console. Les 8 bâtiments cubiques colorés sont visibles depuis la caméra TP autour du personnage.
- [ ] Le personnage (ZQSD/WASD) est bloqué par les murs des bâtiments et ne peut pas les traverser.
- [ ] La commande `godot --headless -s res://addons/Gut-9.6.0/addons/gut/gut_cmdln.gd -gdir=res://tests -gexit` retourne le code de sortie 0 (tous les tests de `test_05_ville_minimale.gd` passent au vert).
- [ ] Les 15 comportements attendus (B1 à B15) passent tous au vert dans GUT.
- [ ] Les 5 cas limites (CL1 à CL5) sont couverts dans les tests GUT.
- [ ] Les dossiers `assets/city/buildings/` et `assets/materials/city/` sont créés (même vides ou avec des fichiers `.gitkeep`) pour respecter l'arborescence déclarée dans le bon de commande.
- [ ] Aucun nœud existant de `main.tscn` (WorldEnvironment, DirectionalLight3D, Ground, GroundCollider, Player, CameraRig) n'est modifié ni supprimé.

## Hors-périmètre

- Génération procédurale de ville : hors proto v0.1 — positions choisies manuellement dans `city.tscn`.
- Textures de façade (brique, béton, verre) : hors proto v0.1 — couleurs flat uniquement.
- Toits détaillés, corniches, fenêtres, balcons : hors proto v0.1 — BoxMesh brut uniquement.
- Routes, trottoirs, marquages au sol, props urbains : hors proto v0.1.
- Occlusion culling, transparence caméra, gestion de l'occlusion TP : hors proto v0.1.
- Ombres portées (`shadow_enabled = true`) : hors proto v0.1 — désactivées par cohérence avec feature 02.
- Éclairage de nuit, lampadaires : hors proto v0.1.
- LOD (Level of Detail) : hors proto v0.1.
- Plus de 8 bâtiments : hors proto v0.1.
- Script `CityBuilder` ou logique de ville dynamique : aucun script de production pour cette feature.
- Collisions entre la future voiture (feature 06) et les bâtiments : les `StaticBody3D` posés ici fonctionneront automatiquement avec le `VehicleBody3D` sans modification de cette feature.
- Agrandissement du sol au-delà de 200 × 200 m : le sol de la feature 02 est conservé tel quel.
