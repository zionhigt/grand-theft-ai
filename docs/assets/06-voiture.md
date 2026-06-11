# Bon de commande 06 — Voiture (mesh + corps physique de base)

## Résumé

1 mesh carrosserie low-poly (mock BoxMesh, futur `.glb`), 1 mesh roue low-poly (mock CylinderMesh, futur `.glb`), 2 matériaux StandardMaterial3D mock (carrosserie rouge vif, roue gris foncé). Aucun asset binaire livré à ce stade. Tous les éléments visuels sont couverts par des primitives Godot.

## Arborescence cible

```
assets/
├── characters/                          (déclaré en feature 03 — inchangé)
│   └── player/
│       └── player.glb
├── environment/                         (déclaré en feature 02 — inchangé)
│   └── ground/
│       ├── ground_plane.tres
│       └── ground_grass.tres
├── materials/                           (déclaré en feature 03 — étendu ici)
│   ├── characters/
│   │   └── player_mock.tres
│   ├── city/                            (déclaré en feature 05 — inchangé)
│   │   ├── batiment_grey_dark.tres
│   │   ├── batiment_grey_medium.tres
│   │   ├── batiment_grey_light.tres
│   │   ├── batiment_beige_dark.tres
│   │   ├── batiment_beige_medium.tres
│   │   └── batiment_beige_light.tres
│   └── vehicles/                        (nouveau sous-dossier)
│       ├── car_body_mock.tres           (mock StandardMaterial3D — rouge vif)
│       └── car_wheel_mock.tres          (mock StandardMaterial3D — gris foncé)
├── city/                                (déclaré en feature 05 — inchangé)
│   └── buildings/
│       └── ...
├── vehicles/                            (nouveau dossier — réservé en feature 05, déclaré ici)
│   └── car/                             (nouveau sous-dossier)
│       ├── car_body.glb                 (futur mesh carrosserie — non livré)
│       └── wheel.glb                    (futur mesh roue — non livré)
├── skybox/                              (déclaré en feature 02 — inchangé)
│   └── sky.tres
├── textures/                            (réservé — inchangé)
├── audio/                               (réservé — inchangé)
│   ├── sfx/
│   └── music/
└── ui/                                  (réservé — inchangé)
```

Dossiers **nouvellement déclarés** par ce bon de commande :
- `assets/vehicles/` (dossier principal — réservé en feature 05, formellement déclaré ici)
- `assets/vehicles/car/` (nouveau sous-dossier)
- `assets/materials/vehicles/` (nouveau sous-dossier dans `assets/materials/` existant)

## Liste détaillée des assets

| Chemin Godot (res://) | Type | Format | Source | Livré ? | Notes techniques |
|-----------------------|------|--------|--------|---------|------------------|
| `res://assets/vehicles/car/car_body.glb` | Mesh 3D carrosserie | .glb | à produire (artiste 3D) | non | 4.0 × 1.5 × 2.0 m (L × H × l), origine au centre géométrique, axe X = longueur, axe Z = largeur, axe Y = hauteur, max 3 000 tris |
| `res://assets/vehicles/car/wheel.glb` | Mesh 3D roue | .glb | à produire (artiste 3D) | non | rayon = 0.35 m, largeur = 0.3 m, axe de rotation = Z, origine au centre de la roue, max 500 tris |
| `res://assets/materials/vehicles/car_body_mock.tres` | Matériau StandardMaterial3D | .tres | généré en GDScript/éditeur | non | albedo_color = #cc1a1a, shading_mode = SHADING_MODE_PER_PIXEL |
| `res://assets/materials/vehicles/car_wheel_mock.tres` | Matériau StandardMaterial3D | .tres | généré en GDScript/éditeur | non | albedo_color = #333333, shading_mode = SHADING_MODE_PER_PIXEL |

Note : le `VehicleBody3D`, les `VehicleWheel3D`, et les `CollisionShape3D` sont des nœuds de scène sans fichier asset associé — ils ne figurent pas dans ce tableau.

## Conventions de nommage

- snake_case pour tous les noms de fichiers et dossiers.
- Meshes 3D finaux au format `.glb` (GLTF binaire, compatible Godot 4 natif).
- Matériaux mock : nom de l'objet + `_mock.tres` pour les distinguer des matériaux finaux.
- Suffixes de texture attendus pour les assets finaux futurs : `_albedo`, `_normal`, `_roughness`, `_metallic`, `_ao`.
- Exemples futurs : `car_body_albedo.png`, `car_body_normal.png`, `wheel_albedo.png`.

## Budget polycount / mémoire

| Catégorie | Budget proto (mock) | Budget final estimé |
|-----------|---------------------|---------------------|
| Carrosserie mesh (car_body.glb) | 12 tris (BoxMesh Godot) | < 3 000 tris (low-poly carrosserie avec détails vitrages) |
| Roue mesh (wheel.glb, par unité) | ~80 tris (CylinderMesh Godot, 20 segments) | < 500 tris (low-poly roue avec jante) |
| 4 roues total | ~320 tris | < 2 000 tris |
| Voiture complète | ~332 tris | < 5 000 tris |
| Matériaux mock (2 StandardMaterial3D) | 0 octets de texture (couleur flat) | 1 texture albedo 1 024 × 1 024 px par partie |
| CollisionShape3D (BoxShape3D) | shape analytique, 0 polycount | identique |
| Scène car.tscn complète | < 200 octets de données de scène | < 30 Ko (meshes + textures compressées) |

Contrainte globale pour le proto : aucune texture chargée, tout en couleurs flat.

## Mocks obligatoires en attendant les assets finaux

| Asset cible | Nœud Godot mock | Forme | Dimensions | Couleur (hex) | Commentaire à inscrire |
|-------------|-----------------|-------|------------|---------------|------------------------|
| `res://assets/vehicles/car/car_body.glb` | `MeshInstance3D` avec `BoxMesh` | box | 4.0 × 1.5 × 2.0 m (L × H × l) | #cc1a1a | `# MOCK — à remplacer par res://assets/vehicles/car/car_body.glb` |
| `res://assets/vehicles/car/wheel.glb` (×4) | `MeshInstance3D` avec `CylinderMesh` | cylindre | rayon = 0.35 m, hauteur = 0.3 m | #333333 | `# MOCK — à remplacer par res://assets/vehicles/car/wheel.glb` |
| `res://assets/materials/vehicles/car_body_mock.tres` | `StandardMaterial3D` inline | matériau flat | n/a | albedo #cc1a1a | `# MOCK — à remplacer par res://assets/materials/vehicles/car_body_mock.tres` |
| `res://assets/materials/vehicles/car_wheel_mock.tres` | `StandardMaterial3D` inline | matériau flat | n/a | albedo #333333 | `# MOCK — à remplacer par res://assets/materials/vehicles/car_wheel_mock.tres` |

### Structure de scène complète — `scenes/vehicles/car.tscn`

Le nœud racine de la scène est un `VehicleBody3D`. La structure ci-dessous est la référence pour le developer.

```
VehicleBody3D  (nom : Car, script : res://src/vehicles/car_controller.gd — à créer en feature 08)
  mass = 1200.0
  position = Vector3(5, 0.75, 5)   # spawn initial dans main.tscn

  CollisionShape3D  (nom : CarBodyCollision)
    shape = BoxShape3D
      size = Vector3(4.0, 1.5, 2.0)
    position = Vector3(0, 0, 0)    # centré sur le VehicleBody3D
  # Nœud de scène — pas d'asset associé

  MeshInstance3D  (nom : CarBodyMesh)
    mesh = BoxMesh
      size = Vector3(4.0, 1.5, 2.0)
    material_override = StandardMaterial3D
      albedo_color = Color(0.8, 0.1, 0.1, 1.0)   # #cc1a1a
      shading_mode = SHADING_MODE_PER_PIXEL
    position = Vector3(0, 0, 0)
    # MOCK — à remplacer par res://assets/vehicles/car/car_body.glb
    # MOCK — matériau à remplacer par res://assets/materials/vehicles/car_body_mock.tres

  VehicleWheel3D  (nom : WheelFrontLeft)
    position = Vector3(-1.0, -0.5, 0.8)
    use_as_steering = true
    use_as_traction = false
    wheel_radius = 0.35
    suspension_travel = 0.2
    MeshInstance3D
      mesh = CylinderMesh
        top_radius = 0.35
        bottom_radius = 0.35
        height = 0.3
      material_override = StandardMaterial3D
        albedo_color = Color(0.2, 0.2, 0.2, 1.0)   # #333333
        shading_mode = SHADING_MODE_PER_PIXEL
      rotation_degrees = Vector3(0, 0, 90)   # cylindre couché — axe Z = axe de rotation roue
      # MOCK — à remplacer par res://assets/vehicles/car/wheel.glb
      # MOCK — matériau à remplacer par res://assets/materials/vehicles/car_wheel_mock.tres

  VehicleWheel3D  (nom : WheelFrontRight)
    position = Vector3(-1.0, -0.5, -0.8)
    use_as_steering = true
    use_as_traction = false
    wheel_radius = 0.35
    suspension_travel = 0.2
    MeshInstance3D
      mesh = CylinderMesh
        top_radius = 0.35
        bottom_radius = 0.35
        height = 0.3
      material_override = StandardMaterial3D
        albedo_color = Color(0.2, 0.2, 0.2, 1.0)   # #333333
        shading_mode = SHADING_MODE_PER_PIXEL
      rotation_degrees = Vector3(0, 0, 90)
      # MOCK — à remplacer par res://assets/vehicles/car/wheel.glb
      # MOCK — matériau à remplacer par res://assets/materials/vehicles/car_wheel_mock.tres

  VehicleWheel3D  (nom : WheelRearLeft)
    position = Vector3(1.0, -0.5, 0.8)
    use_as_steering = false
    use_as_traction = true
    wheel_radius = 0.35
    suspension_travel = 0.2
    MeshInstance3D
      mesh = CylinderMesh
        top_radius = 0.35
        bottom_radius = 0.35
        height = 0.3
      material_override = StandardMaterial3D
        albedo_color = Color(0.2, 0.2, 0.2, 1.0)   # #333333
        shading_mode = SHADING_MODE_PER_PIXEL
      rotation_degrees = Vector3(0, 0, 90)
      # MOCK — à remplacer par res://assets/vehicles/car/wheel.glb
      # MOCK — matériau à remplacer par res://assets/materials/vehicles/car_wheel_mock.tres

  VehicleWheel3D  (nom : WheelRearRight)
    position = Vector3(1.0, -0.5, -0.8)
    use_as_steering = false
    use_as_traction = true
    wheel_radius = 0.35
    suspension_travel = 0.2
    MeshInstance3D
      mesh = CylinderMesh
        top_radius = 0.35
        bottom_radius = 0.35
        height = 0.3
      material_override = StandardMaterial3D
        albedo_color = Color(0.2, 0.2, 0.2, 1.0)   # #333333
        shading_mode = SHADING_MODE_PER_PIXEL
      rotation_degrees = Vector3(0, 0, 90)
      # MOCK — à remplacer par res://assets/vehicles/car/wheel.glb
      # MOCK — matériau à remplacer par res://assets/materials/vehicles/car_wheel_mock.tres
```

### Paramètres physiques VehicleBody3D (proto)

| Propriété | Valeur | Emplacement |
|-----------|--------|-------------|
| `mass` | 1 200.0 | VehicleBody3D |
| `engine_force` | 0.0 | VehicleBody3D (feature 08) |
| `brake` | 0.0 | VehicleBody3D (feature 08) |
| `steering` | 0.0 | VehicleBody3D (feature 08) |
| `wheel_radius` | 0.35 | chaque VehicleWheel3D |
| `suspension_travel` | 0.2 | chaque VehicleWheel3D |
| `suspension_stiffness` | 5.88 | chaque VehicleWheel3D (valeur Godot par défaut) |
| `wheel_friction_slip` | 10.5 | chaque VehicleWheel3D (valeur Godot par défaut) |

## Hors-périmètre

- Sons moteur, klaxon, crissement de pneus : non commandés (hors proto v0.1).
- Textures carrosserie et roues (`_albedo`, `_normal`, `_roughness`, `_metallic`, `_ao`) : à commander si les meshes finaux sont livrés.
- Phares, rétroviseurs, antenne, détails extérieurs : hors proto.
- Intérieur du véhicule (siège, volant, tableau de bord) : hors proto.
- Effets particules (fumée, poussière, échappement) : hors proto.
- Plusieurs modèles de voitures : hors proto v0.1 (un seul modèle).
- Dommages visuels et déformation de carrosserie : hors proto.
- LOD (Level of Detail) pour la voiture : hors proto.
