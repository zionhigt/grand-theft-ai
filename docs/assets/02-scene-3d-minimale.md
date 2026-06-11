# Bon de commande 02 — Scène 3D minimale (sol + ciel + lumière + caméra fixe)

## Résumé

2 ressources matériau/mesh pour le sol (mock PlaneMesh + StandardMaterial3D), 1 ressource Sky procédurale pour le ciel (mock ProceduralSkyMaterial inline). Aucun asset binaire livré à ce stade — tout est couvert par des primitives Godot. La lumière et la caméra sont des nœuds nus sans asset associé.

## Arborescence cible

```
assets/
├── environment/
│   └── ground/
│       ├── ground_plane.tres          (mesh PlaneMesh — mock proto, à remplacer par mesh sculpté)
│       └── ground_grass.tres          (matériau StandardMaterial3D — mock proto, à remplacer par texture albedo)
└── skybox/
    └── sky.tres                       (ressource Sky avec ProceduralSkyMaterial — mock proto, à remplacer par HDRI)
```

Ces deux dossiers (`assets/environment/ground/` et `assets/skybox/`) sont **nouvellement déclarés** par ce bon de commande. Aucun autre bon de commande ne les avait créés avant.

## Liste détaillée des assets

| Chemin Godot (res://) | Type | Format | Source | Livré ? | Notes techniques |
|-----------------------|------|--------|--------|---------|------------------|
| `res://assets/environment/ground/ground_plane.tres` | Mesh (PlaneMesh) | .tres | généré en GDScript/éditeur | non | plan de 200 × 200 m, subdivisions 1 × 1, origine au centre (y = 0) |
| `res://assets/environment/ground/ground_grass.tres` | Matériau (StandardMaterial3D) | .tres | généré en GDScript/éditeur | non | albedo_color = #4a7c3a, aucune texture à ce stade, shading_mode = SHADING_MODE_PER_PIXEL |
| `res://assets/skybox/sky.tres` | Ressource Sky | .tres | généré en GDScript/éditeur | non | Sky avec ProceduralSkyMaterial (top #4ea0ff, horizon #c0d8ff, ground #4a7c3a) |

Note : la `DirectionalLight3D` et la `Camera3D` repositionnée sont des nœuds de scène sans fichier asset associé — ils ne figurent pas dans ce tableau.

## Conventions de nommage

- snake_case pour tous les noms de fichiers.
- Suffixes de texture attendus (pour les assets finaux futurs) : `_albedo`, `_normal`, `_roughness`, `_metallic`, `_ao`.
- Exemple futur : `ground_grass_albedo.png`, `ground_grass_normal.png`.
- Les fichiers `.tres` portent le nom de l'objet qu'ils représentent, sans suffixe de type (`ground_plane.tres` et non `ground_plane_mesh.tres`).

## Budget polycount / mémoire

| Asset | Budget proto | Budget final estimé |
|-------|-------------|---------------------|
| Sol (PlaneMesh) | 2 tris (1 × 1 subdivision) | 200–800 tris (tesselation légère pour déformation future) |
| Matériau sol | 0 texture (couleur flat) | 1 texture albedo 1024 × 1024 px tileable |
| Sky (ProceduralSkyMaterial) | 0 octets de texture | HDRI panoramique 2048 × 1024 px (.hdr ou .exr) |

Contraintes globales de la feature : rendu léger, aucune texture chargée, aucune ombre calculée.

## Mocks obligatoires en attendant les assets finaux

| Asset cible | Nœud Godot mock | Forme | Dimensions | Couleur (hex) | Commentaire à inscrire |
|-------------|-----------------|-------|------------|---------------|------------------------|
| `res://assets/environment/ground/ground_plane.tres` + `res://assets/environment/ground/ground_grass.tres` | `MeshInstance3D` avec `PlaneMesh` et `StandardMaterial3D` | plan | 200 × 200 m (size_x = 200, size_z = 200, y = 0) | #4a7c3a (albedo_color) | `# MOCK — à remplacer par res://assets/environment/ground/ground_plane.tres + ground_grass.tres` |
| `res://assets/skybox/sky.tres` | `WorldEnvironment` avec `Environment` embarquant `Sky` + `ProceduralSkyMaterial` inline | ciel procédural | n/a | top #4ea0ff / horizon #c0d8ff / ground #4a7c3a | `# MOCK — à remplacer par res://assets/skybox/sky.tres (HDRI futur)` |

### Détail des paramètres mock

**Sol — `MeshInstance3D` avec `PlaneMesh`**

```
MeshInstance3D
  mesh = PlaneMesh
    size = Vector2(200, 200)
    subdivide_width = 0
    subdivide_depth = 0
  material_override = StandardMaterial3D
    albedo_color = Color(0.290, 0.486, 0.227, 1.0)   # #4a7c3a
    shading_mode = SHADING_MODE_PER_PIXEL
  position = Vector3(0, 0, 0)
# MOCK — à remplacer par res://assets/environment/ground/ground_plane.tres + ground_grass.tres
```

**Ciel — `WorldEnvironment` avec `ProceduralSkyMaterial`**

```
WorldEnvironment
  environment = Environment
    background_mode = ENV_BG_SKY
    sky = Sky
      sky_material = ProceduralSkyMaterial
        sky_top_color    = Color(0.306, 0.627, 1.000, 1.0)   # #4ea0ff
        sky_horizon_color = Color(0.753, 0.847, 1.000, 1.0)  # #c0d8ff
        ground_bottom_color = Color(0.290, 0.486, 0.227, 1.0) # #4a7c3a
        ground_horizon_color = Color(0.290, 0.486, 0.227, 1.0) # #4a7c3a (continuité)
        sun_angle_max = 30.0
        sun_curve = 0.15
# MOCK — à remplacer par res://assets/skybox/sky.tres (HDRI futur)
```

**Lumière directionnelle — nœud nu, aucun asset**

```
DirectionalLight3D
  rotation_degrees = Vector3(-45, 0, 0)
  light_color = Color(1.000, 0.957, 0.878, 1.0)   # #fff4e0
  light_energy = 1.0
  shadow_enabled = false
# Nœud de scène — pas d'asset associé
```

**Caméra repositionnée — nœud nu, aucun asset**

```
Camera3D
  position = Vector3(0, 8, 15)
  # look_at(Vector3(0, 0, 0)) appliqué lors de _ready() ou via l'éditeur
  # rotation résultante approximative : Vector3(-28, 0, 0) degrés
  current = true
# Nœud de scène hérité de la feature 01 — repositionné, pas d'asset associé
```

## Hors-périmètre

- Texture albedo réelle du sol (`ground_grass_albedo.png`, tileable 1024 × 1024) : à commander dans la feature 05 (ville minimale) ou plus tard.
- Textures normal / roughness / AO du sol : hors proto v0.1.
- Asset HDRI panoramique pour le ciel : hors proto v0.1.
- CollisionShape / StaticBody3D pour le sol : feature 03 (personnage déplaçable).
- Tout asset audio (ambiance, vent, etc.) : non commandé.
- Assets des bâtiments, props de ville, véhicules : features 05 et 06.
