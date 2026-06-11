# Spec 06 — Voiture (mesh + corps physique de base)

## Contexte

- Design : `docs/design/06-voiture.md`
- Bon de commande graphique : `docs/assets/06-voiture.md`
- Dépendances de specs précédentes :
  - **Spec 01 — Bootstrap projet** (`docs/specs/01-bootstrap.md`) : fournit `project.godot` et `main.tscn` (nœud racine `Main : Node3D`).
  - **Spec 02 — Scène 3D minimale** (`docs/specs/02-scene-3d-minimale.md`) : fournit le sol physique `GroundCollider : StaticBody3D` (WorldBoundaryShape3D, y = 0) sur lequel la voiture repose.
  - **Spec 03 — Personnage joueur** (`docs/specs/03-personnage-joueur.md`) : fournit le `Player : CharacterBody3D` (CapsuleShape3D rayon 0.4 m, hauteur 1.8 m). La voiture cohabite avec ce nœud — leurs `CollisionShape3D` respectifs interagissent nativement via la physique Godot. Spawn joueur à `Vector3(0, 0.9, 0)`, spawn voiture à `Vector3(5, 0.75, 5)` — aucun chevauchement.
  - **Spec 04 — Caméra TP** (`docs/specs/04-camera-tp.md`) : la `CameraRig` suit le joueur. Aucune modification requise par cette feature.
  - **Spec 05 — Ville minimale** (`docs/specs/05-ville-minimale.md`) : fournit `scenes/city/city.tscn` instancié dans `main.tscn`. La voiture est posée sur le sol étendu, en dehors des emprise des bâtiments.

## Objectif fonctionnel

Introduire une voiture statique dans `main.tscn` via la scène réutilisable `scenes/vehicles/car.tscn`. La voiture est un `VehicleBody3D` Godot natif posé sur quatre roues (`VehicleWheel3D`), avec une carrosserie visible (BoxMesh rouge) et un `CollisionShape3D` actif. Elle obéit à la gravité, sert d'obstacle physique au personnage et constitue le socle obligatoire des features 07 (entrée/sortie) et 08 (conduite). Aucun script GDScript n'est requis : la physique est intégralement gérée par le moteur Godot via `VehicleBody3D`.

## Arborescence cible

```
.
├── main.tscn                                        # modifié — nœud Car (instance car.tscn) ajouté
├── scenes/
│   └── vehicles/
│       └── car.tscn                                 # créé — scène réutilisable du véhicule
├── tests/
│   └── test_06_voiture.gd                           # à écrire par le tester
└── assets/
    ├── vehicles/
    │   └── car/
    │       ├── car_body.glb                         # non livré — mock BoxMesh inline dans car.tscn
    │       └── wheel.glb                            # non livré — mock CylinderMesh inline (×4) dans car.tscn
    └── materials/
        └── vehicles/
            ├── car_body_mock.tres                   # non livré — mock StandardMaterial3D inline
            └── car_wheel_mock.tres                  # non livré — mock StandardMaterial3D inline
```

Notes :
- Aucun script `.gd` de production n'est créé par cette feature (voir section suivante).
- `scenes/vehicles/car.tscn` est la seule scène créée.
- `main.tscn` est modifié (pas recréé) : tous les nœuds hérités des features 01 à 05 sont conservés intacts.
- Les dossiers `assets/vehicles/car/` et `assets/materials/vehicles/` sont déclarés mais leurs fichiers finaux ne sont pas livrés à ce stade.
- Le dossier `scenes/vehicles/` est nouveau et doit être créé.

## Interface publique (GDScript)

### Décision : aucun script GDScript pour cette feature

La scène `car.tscn` n'embarque pas de script. Le comportement physique du `VehicleBody3D` (gravité, repos sur suspensions, réponse aux collisions) est intégralement géré par le moteur Godot nativement.

**Justification** : en feature 06, la voiture est un objet passif — `engine_force`, `brake` et `steering` restent à `0.0`. Écrire un script `CarController` maintenant serait anticiper la feature 08 et produire du code non couvert par des tests. Le bon de commande graphique mentionne `res://src/vehicles/car_controller.gd` comme destination du script futur, mais son écriture est explicitement déléguée à la feature 08. La scène `car.tscn` reserve l'emplacement du script par un commentaire dans sa description.

Le script `res://src/vehicles/car_controller.gd` sera créé en feature 08, avec `class_name CarController extends VehicleBody3D`.

## Structure des scènes (.tscn)

### `scenes/vehicles/car.tscn` (créée)

```
Car : VehicleBody3D                                  (nœud racine, pas de script en feature 06)
  mass = 1200.0
  # Script futur : res://src/vehicles/car_controller.gd — à créer en feature 08

  CarBodyCollision : CollisionShape3D
    shape = BoxShape3D
      size = Vector3(4.0, 1.5, 2.0)
    position = Vector3(0, 0, 0)
    # Nœud de scène — pas d'asset associé

  CarBodyMesh : MeshInstance3D
    mesh = BoxMesh
      size = Vector3(4.0, 1.5, 2.0)
    material_override = StandardMaterial3D
      albedo_color = Color(0.8, 0.1, 0.1, 1.0)      # #cc1a1a
      shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
    position = Vector3(0, 0, 0)
    # MOCK — à remplacer par res://assets/vehicles/car/car_body.glb
    # MOCK — matériau à remplacer par res://assets/materials/vehicles/car_body_mock.tres

  WheelFrontLeft : VehicleWheel3D
    position = Vector3(-1.0, -0.5, 0.8)
    use_as_steering = true
    use_as_traction = false
    wheel_radius = 0.35
    suspension_travel = 0.2
    suspension_stiffness = 5.88
    wheel_friction_slip = 10.5

    MeshInstance3D : MeshInstance3D
      mesh = CylinderMesh
        top_radius = 0.35
        bottom_radius = 0.35
        height = 0.3
      material_override = StandardMaterial3D
        albedo_color = Color(0.2, 0.2, 0.2, 1.0)    # #333333
        shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
      rotation_degrees = Vector3(0, 0, 90)           # cylindre couché — axe Z = axe de rotation roue
      # MOCK — à remplacer par res://assets/vehicles/car/wheel.glb
      # MOCK — matériau à remplacer par res://assets/materials/vehicles/car_wheel_mock.tres

  WheelFrontRight : VehicleWheel3D
    position = Vector3(-1.0, -0.5, -0.8)
    use_as_steering = true
    use_as_traction = false
    wheel_radius = 0.35
    suspension_travel = 0.2
    suspension_stiffness = 5.88
    wheel_friction_slip = 10.5

    MeshInstance3D : MeshInstance3D
      mesh = CylinderMesh
        top_radius = 0.35
        bottom_radius = 0.35
        height = 0.3
      material_override = StandardMaterial3D
        albedo_color = Color(0.2, 0.2, 0.2, 1.0)    # #333333
        shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
      rotation_degrees = Vector3(0, 0, 90)
      # MOCK — à remplacer par res://assets/vehicles/car/wheel.glb
      # MOCK — matériau à remplacer par res://assets/materials/vehicles/car_wheel_mock.tres

  WheelRearLeft : VehicleWheel3D
    position = Vector3(1.0, -0.5, 0.8)
    use_as_steering = false
    use_as_traction = true
    wheel_radius = 0.35
    suspension_travel = 0.2
    suspension_stiffness = 5.88
    wheel_friction_slip = 10.5

    MeshInstance3D : MeshInstance3D
      mesh = CylinderMesh
        top_radius = 0.35
        bottom_radius = 0.35
        height = 0.3
      material_override = StandardMaterial3D
        albedo_color = Color(0.2, 0.2, 0.2, 1.0)    # #333333
        shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
      rotation_degrees = Vector3(0, 0, 90)
      # MOCK — à remplacer par res://assets/vehicles/car/wheel.glb
      # MOCK — matériau à remplacer par res://assets/materials/vehicles/car_wheel_mock.tres

  WheelRearRight : VehicleWheel3D
    position = Vector3(1.0, -0.5, -0.8)
    use_as_steering = false
    use_as_traction = true
    wheel_radius = 0.35
    suspension_travel = 0.2
    suspension_stiffness = 5.88
    wheel_friction_slip = 10.5

    MeshInstance3D : MeshInstance3D
      mesh = CylinderMesh
        top_radius = 0.35
        bottom_radius = 0.35
        height = 0.3
      material_override = StandardMaterial3D
        albedo_color = Color(0.2, 0.2, 0.2, 1.0)    # #333333
        shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
      rotation_degrees = Vector3(0, 0, 90)
      # MOCK — à remplacer par res://assets/vehicles/car/wheel.glb
      # MOCK — matériau à remplacer par res://assets/materials/vehicles/car_wheel_mock.tres
```

### `main.tscn` (modifiée — ajout d'un nœud)

L'état actuel de `main.tscn` (après feature 05) est :

```
Main : Node3D
  WorldEnvironment : WorldEnvironment
  DirectionalLight3D : DirectionalLight3D
  Ground : MeshInstance3D
  GroundCollider : StaticBody3D
    CollisionShape3D : CollisionShape3D
  Player : CharacterBody3D          (instance scenes/player/player.tscn)
  CameraRig : Node3D                (script src/camera/camera_controller.gd)
    Camera3D : Camera3D
  City : Node3D                     (instance scenes/city/city.tscn)
```

Après feature 06, `main.tscn` contient en plus :

```
Main : Node3D
  ...                               (tous les nœuds précédents inchangés)
  Car : VehicleBody3D               (instance scenes/vehicles/car.tscn)
    position = Vector3(5, 0.75, 5)
```

Le nœud `Car` est instancié depuis `res://scenes/vehicles/car.tscn` et positionné en coordonnées monde à `Vector3(5, 0.75, 5)`. Il est ajouté après `City` dans l'ordre des enfants de `Main` (en dernier).

**Justification du spawn à y = 0.75** : le centre géométrique du `VehicleBody3D` est à mi-hauteur de la carrosserie (BoxMesh h = 1.5 m). La moitié de 1.5 m = 0.75 m. Avec les suspensions, la voiture reposera légèrement plus haut que ce point d'origine, mais y = 0.75 garantit que la voiture ne spawne pas sous le sol (y = 0) ni flottante (y >> 0.75). Le moteur physique ajustera la hauteur finale au premier tick.

## Données et constantes

Toutes les valeurs numériques sont définies directement dans `scenes/vehicles/car.tscn` (pas de script). Elles sont référencées ici pour la spec et les tests.

### VehicleBody3D (`Car`)

| Propriété | Valeur | Unité | Note |
|-----------|--------|-------|------|
| `mass` | 1200.0 | kg | Voiture compacte réaliste |
| `engine_force` | 0.0 | N | Pas de moteur — feature 08 |
| `brake` | 0.0 | N | Pas de frein actif — feature 08 |
| `steering` | 0.0 | rad | Pas de direction active — feature 08 |

### CarBodyCollision (CollisionShape3D > BoxShape3D)

| Propriété | Valeur | Unité |
|-----------|--------|-------|
| `size.x` | 4.0 | m (longueur) |
| `size.y` | 1.5 | m (hauteur) |
| `size.z` | 2.0 | m (largeur) |
| `position` | Vector3(0, 0, 0) | — centré sur le VehicleBody3D |

### CarBodyMesh (MeshInstance3D > BoxMesh)

| Propriété | Valeur |
|-----------|--------|
| `mesh.size` | Vector3(4.0, 1.5, 2.0) |
| `material_override.albedo_color` | Color(0.8, 0.1, 0.1, 1.0) = #cc1a1a |

### VehicleWheel3D — commun aux 4 roues

| Propriété | Valeur | Unité | Note |
|-----------|--------|-------|------|
| `wheel_radius` | 0.35 | m | Cohérent avec la hauteur de la carrosserie |
| `suspension_travel` | 0.2 | m | Course de suspension |
| `suspension_stiffness` | 5.88 | — | Valeur Godot par défaut |
| `wheel_friction_slip` | 10.5 | — | Valeur Godot par défaut |

### Positions locales des roues (coordonnées relatives au VehicleBody3D)

| Roue | Nom nœud | Position locale | use_as_steering | use_as_traction |
|------|----------|-----------------|-----------------|-----------------|
| Avant-gauche | `WheelFrontLeft` | Vector3(-1.0, -0.5, 0.8) | true | false |
| Avant-droite | `WheelFrontRight` | Vector3(-1.0, -0.5, -0.8) | true | false |
| Arrière-gauche | `WheelRearLeft` | Vector3(1.0, -0.5, 0.8) | false | true |
| Arrière-droite | `WheelRearRight` | Vector3(1.0, -0.5, -0.8) | false | true |

### Mesh roues (CylinderMesh, commun aux 4)

| Propriété | Valeur |
|-----------|--------|
| `top_radius` | 0.35 m |
| `bottom_radius` | 0.35 m |
| `height` | 0.3 m |
| `rotation_degrees` | Vector3(0, 0, 90) — cylindre couché sur l'axe Z |
| `material_override.albedo_color` | Color(0.2, 0.2, 0.2, 1.0) = #333333 |

### Position de spawn dans main.tscn

| Propriété | Valeur |
|-----------|--------|
| `position` (nœud Car dans main.tscn) | Vector3(5, 0.75, 5) |

## Comportements attendus

Chaque comportement est testable unitairement avec GUT dans `tests/test_06_voiture.gd`. Les tests B1 à B9 chargent uniquement `car.tscn`. Les tests B10 et B11 requièrent le chargement de `main.tscn`.

**B1.** `load("res://scenes/vehicles/car.tscn")` retourne une `PackedScene` non nulle, et `packed_scene.instantiate()` ne produit pas d'erreur — la scène se charge sans ressource manquante ni erreur de parse.

**B2.** Le nœud racine de l'instance est de type `VehicleBody3D` et s'appelle `"Car"` : `car.name == "Car"` et `car is VehicleBody3D`.

**B3.** L'instance contient un `CollisionShape3D` nommé `"CarBodyCollision"` dont la `shape` est de type `BoxShape3D` : `car.get_node("CarBodyCollision").shape is BoxShape3D == true`. La `BoxShape3D.size` vaut `Vector3(4.0, 1.5, 2.0)` (à 0.001 près sur chaque composante).

**B4.** L'instance contient exactement 4 enfants de type `VehicleWheel3D` :
```gdscript
var wheels = []
for child in car.get_children():
    if child is VehicleWheel3D:
        wheels.append(child)
assert_eq(wheels.size(), 4)
```

**B5.** Les deux roues avant (`WheelFrontLeft` et `WheelFrontRight`) ont `use_as_steering == true` et `use_as_traction == false` :
```gdscript
assert_true(car.get_node("WheelFrontLeft").use_as_steering)
assert_false(car.get_node("WheelFrontLeft").use_as_traction)
assert_true(car.get_node("WheelFrontRight").use_as_steering)
assert_false(car.get_node("WheelFrontRight").use_as_traction)
```

**B6.** Les deux roues arrière (`WheelRearLeft` et `WheelRearRight`) ont `use_as_traction == true` et `use_as_steering == false` :
```gdscript
assert_false(car.get_node("WheelRearLeft").use_as_steering)
assert_true(car.get_node("WheelRearLeft").use_as_traction)
assert_false(car.get_node("WheelRearRight").use_as_steering)
assert_true(car.get_node("WheelRearRight").use_as_traction)
```

**B7.** Les positions locales des 4 roues correspondent aux valeurs de la spec (tolérance 0.001 sur chaque composante) :
- `WheelFrontLeft.position` == Vector3(-1.0, -0.5, 0.8)
- `WheelFrontRight.position` == Vector3(-1.0, -0.5, -0.8)
- `WheelRearLeft.position` == Vector3(1.0, -0.5, 0.8)
- `WheelRearRight.position` == Vector3(1.0, -0.5, -0.8)

**B8.** La propriété `mass` du nœud racine `Car` vaut `1200.0` (à 0.01 près) : `car.mass == 1200.0`.

**B9.** Chacune des 4 roues a `wheel_radius == 0.35` et `suspension_travel == 0.2` (tolérance 0.001).

**B10.** Chargement de `res://main.tscn` : le nœud `"Car"` existe dans l'arbre de `Main` (`main.get_node_or_null("Car") != null`) et est de type `VehicleBody3D` (`main.get_node("Car") is VehicleBody3D == true`).

**B11.** Le nœud `"Car"` dans `main.tscn` a sa `position` réglée à `Vector3(5, 0.75, 5)` (tolérance 0.001 sur chaque composante) : `main.get_node("Car").position.is_equal_approx(Vector3(5, 0.75, 5))`.

**B12.** Le nœud `"CarBodyCollision"` existe bien comme enfant direct du nœud `"Car"` dans `car.tscn` : `car.get_node_or_null("CarBodyCollision") != null`.

**B13.** Le nœud `"CarBodyMesh"` existe bien comme enfant direct du nœud `"Car"` dans `car.tscn` : `car.get_node_or_null("CarBodyMesh") != null` et `car.get_node("CarBodyMesh") is MeshInstance3D == true`.

## Cas limites / erreurs

**CL1.** La voiture ne possède aucun script attaché en feature 06 : `car.get_script() == null`. Si un script est accidentellement attaché, le test échoue. Cela garantit que feature 08 ne sera pas partiellement pré-implémentée.

**CL2.** Le `VehicleBody3D` sans `engine_force`, `brake` ni `steering` actifs ne produit aucun mouvement propre lors d'une simulation physique courte (quelques frames) : les valeurs `engine_force == 0.0`, `brake == 0.0`, `steering == 0.0` sont vérifiées statiquement sur l'instance chargée.

**CL3.** La position du spawn `Vector3(5, 0.75, 5)` ne chevauche pas le spawn du joueur `Vector3(0, 0.9, 0)` : la distance entre les deux points est supérieure à la demi-largeur de la carrosserie (1.0 m) + le rayon de la capsule du joueur (0.4 m). Distance effective ≈ 7.07 m >> 1.4 m — pas de chevauchement au démarrage.

**CL4.** La scène `car.tscn` se charge sans avertissement `ERROR:` ni `SCRIPT ERROR:` en mode `--headless`. Aucun asset externe n'est référencé : tous les meshes et matériaux sont inline (primitives Godot + `StandardMaterial3D` inline).

**CL5.** Instancier `car.tscn` deux fois dans le même arbre de scène de test ne produit pas de conflit de nom ni d'erreur — les instances sont indépendantes (pas de variable globale ni de singleton liés à la scène).

## Inputs Godot (Input Map)

Aucune action d'entrée nouvelle n'est introduite en feature 06. La voiture est passive.

Les actions futures (accélération, freinage, direction) seront déclarées dans la spec 08 — Conduite.
La touche `E` (interaction entrée/sortie) sera déclarée dans la spec 07 — Entrer/sortir.

## Assets consommés

| Chemin `res://` | Mock attendu | Type mock | Usage dans la scène |
|-----------------|-------------|-----------|---------------------|
| `res://assets/vehicles/car/car_body.glb` | oui | `MeshInstance3D` avec `BoxMesh` (4.0 × 1.5 × 2.0 m) dans `car.tscn` | Représentation visuelle de la carrosserie (rouge #cc1a1a) |
| `res://assets/materials/vehicles/car_body_mock.tres` | oui | `StandardMaterial3D` inline (`material_override` du `CarBodyMesh`) | Couleur albedo rouge vif #cc1a1a de la carrosserie mock |
| `res://assets/vehicles/car/wheel.glb` | oui (×4) | `MeshInstance3D` avec `CylinderMesh` (r=0.35, h=0.3) dans chaque `VehicleWheel3D` | Représentation visuelle de chaque roue (gris foncé #333333) |
| `res://assets/materials/vehicles/car_wheel_mock.tres` | oui (×4) | `StandardMaterial3D` inline (`material_override` du `MeshInstance3D` de chaque roue) | Couleur albedo gris foncé #333333 des roues mock |

Tous les assets sont mockés inline dans `scenes/vehicles/car.tscn`. Aucun fichier `.tres` ni `.glb` externe n'est requis pour que la scène se lance.

Les nœuds `MeshInstance3D` de carrosserie et de roues portent les commentaires suivants :
```
# MOCK — à remplacer par res://assets/vehicles/car/car_body.glb
# MOCK — matériau à remplacer par res://assets/materials/vehicles/car_body_mock.tres
```
et pour chaque roue :
```
# MOCK — à remplacer par res://assets/vehicles/car/wheel.glb
# MOCK — matériau à remplacer par res://assets/materials/vehicles/car_wheel_mock.tres
```

## Dépendances

- **Spec 01 — Bootstrap projet** : `project.godot` fonctionnel, GUT installé dans `addons/Gut-9.6.0/`.
- **Spec 02 — Scène 3D minimale** : `main.tscn` avec sol `GroundCollider` physique (WorldBoundaryShape3D, y = 0).
- **Spec 03 — Personnage joueur** : `Player : CharacterBody3D` dans `main.tscn`, spawn à `Vector3(0, 0.9, 0)`.
- **Spec 04 — Caméra TP** : `CameraRig` dans `main.tscn` (inchangé).
- **Spec 05 — Ville minimale** : `City : Node3D` (instance `city.tscn`) dans `main.tscn` (inchangé).
- **`addons/gut/`** : addon GUT v9.6, déjà installé depuis la feature 01. Aucun autre addon autorisé.

## Critères d'acceptation

- [ ] Le fichier `scenes/vehicles/car.tscn` est présent et s'ouvre dans l'éditeur Godot 4.6 sans erreur de ressource manquante.
- [ ] L'arbre de `car.tscn` dans l'éditeur affiche : `Car : VehicleBody3D` > `CarBodyCollision : CollisionShape3D`, `CarBodyMesh : MeshInstance3D`, `WheelFrontLeft : VehicleWheel3D`, `WheelFrontRight : VehicleWheel3D`, `WheelRearLeft : VehicleWheel3D`, `WheelRearRight : VehicleWheel3D`.
- [ ] Chaque `VehicleWheel3D` contient un `MeshInstance3D` avec un `CylinderMesh` orienté (rotation_degrees = Vector3(0, 0, 90)).
- [ ] `main.tscn` s'ouvre dans l'éditeur Godot 4.6 sans warning rouge. L'arbre affiche un nœud `Car : VehicleBody3D` parmi les enfants de `Main`.
- [ ] `godot --path . res://main.tscn` se lance sans `ERROR:` ni `SCRIPT ERROR:` dans la console. La carrosserie rouge et les quatre roues grises sont visibles à l'écran à côté du personnage.
- [ ] La voiture fait obstacle physique : le personnage ne traverse pas la carrosserie en marchant contre elle.
- [ ] La voiture obéit à la gravité : au démarrage elle repose sur ses suspensions au lieu de flotter.
- [ ] La commande `godot --headless -s res://addons/Gut-9.6.0/addons/gut/gut_cmdln.gd -gdir=res://tests -gexit` retourne le code de sortie 0 (tous les tests de `test_06_voiture.gd` passent au vert).
- [ ] Les 13 comportements attendus (B1 à B13) passent tous au vert dans GUT.
- [ ] Les 5 cas limites (CL1 à CL5) passent tous au vert dans GUT.
- [ ] Les dossiers `assets/vehicles/car/` et `assets/materials/vehicles/` sont créés (même vides des `.glb` finaux).

## Hors-périmètre

- Touche E pour entrer/sortir du véhicule : feature 07.
- Moteur, frein, direction, accélération (`engine_force`, `brake`, `steering`) : feature 08.
- Script `res://src/vehicles/car_controller.gd` : feature 08.
- Caméra adaptée à la conduite (zoom, offset) : feature 08.
- Sons moteur, klaxon, crissement de pneus : hors proto v0.1.
- Texture carrosserie peinte, reflets, vitrages translucides : hors proto.
- Plusieurs voitures dans la scène : hors proto v0.1 (une seule instance de `car.tscn`).
- Phares, rétroviseurs, antenne, détails de carrosserie : hors proto.
- Intérieur du véhicule (siège, volant, tableau de bord) : hors proto.
- LOD (Level of Detail) : hors proto.
- PNJ conducteurs, IA de circulation : hors proto v0.1.
- Dommages visuels, déformations : hors proto v0.1.
