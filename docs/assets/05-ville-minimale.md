# Bon de commande 05 — Ville minimale (sol étendu + bâtiments cubiques)

## Résumé

8 mocks bâtiments (MeshInstance3D + BoxMesh + StandardMaterial3D), 8 matériaux mock StandardMaterial3D, 8 CollisionShape3D (BoxShape3D, déclarés en scène). Aucun asset binaire livré à ce stade. Tous les éléments visuels sont couverts par des primitives Godot. Les futurs assets `.glb` de bâtiments sont pré-déclarés sous `assets/city/buildings/`.

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
│   └── city/                            (nouveau sous-dossier)
│       ├── batiment_grey_dark.tres      (mock StandardMaterial3D — proto)
│       ├── batiment_grey_medium.tres    (mock StandardMaterial3D — proto)
│       ├── batiment_grey_light.tres     (mock StandardMaterial3D — proto)
│       ├── batiment_beige_dark.tres     (mock StandardMaterial3D — proto)
│       ├── batiment_beige_medium.tres   (mock StandardMaterial3D — proto)
│       └── batiment_beige_light.tres    (mock StandardMaterial3D — proto)
├── city/                                (nouveau dossier)
│   └── buildings/                       (nouveau sous-dossier)
│       ├── batiment_1.glb               (futur mesh bâtiment 1 — non livré)
│       ├── batiment_2.glb               (futur mesh bâtiment 2 — non livré)
│       ├── batiment_3.glb               (futur mesh bâtiment 3 — non livré)
│       ├── batiment_4.glb               (futur mesh bâtiment 4 — non livré)
│       ├── batiment_5.glb               (futur mesh bâtiment 5 — non livré)
│       ├── batiment_6.glb               (futur mesh bâtiment 6 — non livré)
│       ├── batiment_7.glb               (futur mesh bâtiment 7 — non livré)
│       └── batiment_8.glb               (futur mesh bâtiment 8 — non livré)
├── skybox/                              (déclaré en feature 02 — inchangé)
│   └── sky.tres
├── textures/                            (réservé pour les futures textures de façades)
├── vehicles/                            (réservé pour feature 06)
├── audio/                               (réservé)
│   ├── sfx/
│   └── music/
└── ui/                                  (réservé)
```

Dossiers **nouvellement déclarés** par ce bon de commande :
- `assets/city/` (nouveau)
- `assets/city/buildings/` (nouveau)
- `assets/materials/city/` (nouveau sous-dossier dans `assets/materials/` existant)

## Liste détaillée des assets

| Chemin Godot (res://) | Type | Format | Source | Livré ? | Notes techniques |
|-----------------------|------|--------|--------|---------|------------------|
| `res://assets/city/buildings/batiment_1.glb` | Mesh 3D bâtiment | .glb | à produire (artiste 3D) | non | 6 × 12 × 6 m, origine au centre-bas (y = 0), low-poly façade, max 500 tris |
| `res://assets/city/buildings/batiment_2.glb` | Mesh 3D bâtiment | .glb | à produire (artiste 3D) | non | 8 × 8 × 8 m, origine au centre-bas (y = 0), low-poly façade, max 500 tris |
| `res://assets/city/buildings/batiment_3.glb` | Mesh 3D bâtiment | .glb | à produire (artiste 3D) | non | 5 × 6 × 10 m, origine au centre-bas (y = 0), low-poly façade, max 500 tris |
| `res://assets/city/buildings/batiment_4.glb` | Mesh 3D bâtiment | .glb | à produire (artiste 3D) | non | 10 × 5 × 6 m, origine au centre-bas (y = 0), low-poly façade, max 500 tris |
| `res://assets/city/buildings/batiment_5.glb` | Mesh 3D bâtiment | .glb | à produire (artiste 3D) | non | 6 × 10 × 6 m, origine au centre-bas (y = 0), low-poly façade, max 500 tris |
| `res://assets/city/buildings/batiment_6.glb` | Mesh 3D bâtiment | .glb | à produire (artiste 3D) | non | 7 × 7 × 7 m, origine au centre-bas (y = 0), low-poly façade, max 500 tris |
| `res://assets/city/buildings/batiment_7.glb` | Mesh 3D bâtiment | .glb | à produire (artiste 3D) | non | 4 × 14 × 4 m, origine au centre-bas (y = 0), low-poly façade, max 500 tris |
| `res://assets/city/buildings/batiment_8.glb` | Mesh 3D bâtiment | .glb | à produire (artiste 3D) | non | 12 × 4 × 5 m, origine au centre-bas (y = 0), low-poly façade, max 500 tris |
| `res://assets/materials/city/batiment_grey_dark.tres` | Matériau StandardMaterial3D | .tres | généré en GDScript/éditeur | non | albedo_color = #7a7a7a, shading_mode = SHADING_MODE_PER_PIXEL |
| `res://assets/materials/city/batiment_grey_medium.tres` | Matériau StandardMaterial3D | .tres | généré en GDScript/éditeur | non | albedo_color = #888888, shading_mode = SHADING_MODE_PER_PIXEL |
| `res://assets/materials/city/batiment_grey_light.tres` | Matériau StandardMaterial3D | .tres | généré en GDScript/éditeur | non | albedo_color = #9a9a9a, shading_mode = SHADING_MODE_PER_PIXEL |
| `res://assets/materials/city/batiment_beige_dark.tres` | Matériau StandardMaterial3D | .tres | généré en GDScript/éditeur | non | albedo_color = #b0a090, shading_mode = SHADING_MODE_PER_PIXEL |
| `res://assets/materials/city/batiment_beige_medium.tres` | Matériau StandardMaterial3D | .tres | généré en GDScript/éditeur | non | albedo_color = #b8a888, shading_mode = SHADING_MODE_PER_PIXEL |
| `res://assets/materials/city/batiment_beige_light.tres` | Matériau StandardMaterial3D | .tres | généré en GDScript/éditeur | non | albedo_color = #c0b0a0, shading_mode = SHADING_MODE_PER_PIXEL |

Note : les `CollisionShape3D` (BoxShape3D) et les `StaticBody3D` de chaque bâtiment sont des nœuds de scène sans fichier asset associé — ils ne figurent pas dans ce tableau.

## Conventions de nommage

- snake_case pour tous les noms de fichiers et dossiers.
- Bâtiments : `batiment_N.glb` (N = numéro 1–8).
- Matériaux mock : `batiment_<couleur>_<intensité>.tres` (ex. `batiment_grey_dark.tres`).
- Suffixes de texture attendus pour les assets finaux futurs : `_albedo`, `_normal`, `_roughness`, `_metallic`, `_ao`.
- Exemples futurs : `batiment_facade_brick_albedo.png`, `batiment_facade_brick_normal.png`.
- Les fichiers `.tres` portent le nom de la couleur/catégorie représentée, sans suffixe de type.

## Budget polycount / mémoire

| Catégorie | Budget proto (mock) | Budget final estimé |
|-----------|---------------------|---------------------|
| Bâtiment mesh (par unité) | 12 tris (BoxMesh Godot = 2 tris × 6 faces) | < 500 tris (façade low-poly avec détails minimes) |
| 8 bâtiments total | 96 tris | < 4 000 tris |
| Matériaux mock (par unité) | 0 octets de texture (couleur flat) | 1 texture albedo 512 × 512 px tileable par couleur de façade |
| CollisionShape (BoxShape3D, par unité) | shape analytique, 0 polycount | identique (shape physique, pas de mesh) |
| Scène city.tscn complète | < 100 octets de données de scène | < 50 Ko (meshes + textures compressées) |

Contrainte globale pour le proto : aucune texture chargée, tout en couleurs flat. Rendu négligeable en termes de performance.

## Mocks obligatoires en attendant les assets finaux

| Asset cible | Nœud Godot mock | Forme | Dimensions (l × h × p) | Couleur (hex) | Position (XZ) | Commentaire à inscrire |
|-------------|-----------------|-------|------------------------|---------------|---------------|------------------------|
| `res://assets/city/buildings/batiment_1.glb` | `MeshInstance3D` avec `BoxMesh` | box | 6 × 12 × 6 m | #8a8a8a | (20, 0, 20) | `# MOCK — à remplacer par res://assets/city/buildings/batiment_1.glb` |
| `res://assets/city/buildings/batiment_2.glb` | `MeshInstance3D` avec `BoxMesh` | box | 8 × 8 × 8 m | #b0a090 | (-25, 0, 15) | `# MOCK — à remplacer par res://assets/city/buildings/batiment_2.glb` |
| `res://assets/city/buildings/batiment_3.glb` | `MeshInstance3D` avec `BoxMesh` | box | 5 × 6 × 10 m | #9a9a9a | (30, 0, -20) | `# MOCK — à remplacer par res://assets/city/buildings/batiment_3.glb` |
| `res://assets/city/buildings/batiment_4.glb` | `MeshInstance3D` avec `BoxMesh` | box | 10 × 5 × 6 m | #c8b89a | (-15, 0, -30) | `# MOCK — à remplacer par res://assets/city/buildings/batiment_4.glb` |
| `res://assets/city/buildings/batiment_5.glb` | `MeshInstance3D` avec `BoxMesh` | box | 6 × 10 × 6 m | #7a7a7a | (40, 0, 5) | `# MOCK — à remplacer par res://assets/city/buildings/batiment_5.glb` |
| `res://assets/city/buildings/batiment_6.glb` | `MeshInstance3D` avec `BoxMesh` | box | 7 × 7 × 7 m | #b8a888 | (-40, 0, -10) | `# MOCK — à remplacer par res://assets/city/buildings/batiment_6.glb` |
| `res://assets/city/buildings/batiment_7.glb` | `MeshInstance3D` avec `BoxMesh` | box | 4 × 14 × 4 m | #888888 | (10, 0, -40) | `# MOCK — à remplacer par res://assets/city/buildings/batiment_7.glb` |
| `res://assets/city/buildings/batiment_8.glb` | `MeshInstance3D` avec `BoxMesh` | box | 12 × 4 × 5 m | #c0b0a0 | (-20, 0, 35) | `# MOCK — à remplacer par res://assets/city/buildings/batiment_8.glb` |

### Détail des paramètres mock (structure Godot répétée pour chaque bâtiment)

Le pattern ci-dessous est répété 8 fois dans `scenes/city/city.tscn`, avec les dimensions, couleurs et positions du tableau ci-dessus. Le nœud racine `City` est un `Node3D`.

**Pattern bâtiment — exemple Batiment1 (6 × 12 × 6 m, #8a8a8a, position (20, 0, 20))**

```
StaticBody3D  (nom : Batiment1)
  position = Vector3(20, 0, 20)

  CollisionShape3D
    shape = BoxShape3D
      size = Vector3(6, 12, 6)
    position = Vector3(0, 6, 0)       # centre de la box à mi-hauteur
  # Nœud de scène — pas d'asset associé

  MeshInstance3D
    mesh = BoxMesh
      size = Vector3(6, 12, 6)
    material_override = StandardMaterial3D
      albedo_color = Color(0.541, 0.541, 0.541, 1.0)   # #8a8a8a
      shading_mode = SHADING_MODE_PER_PIXEL
    position = Vector3(0, 6, 0)       # bas du mesh à y=0, haut à y=12
  # MOCK — à remplacer par res://assets/city/buildings/batiment_1.glb
  # MOCK — matériau à remplacer par res://assets/materials/city/batiment_grey_medium.tres
```

**Récapitulatif complet des 8 bâtiments avec paramètres exacts**

| Nom nœud | position StaticBody3D | size BoxMesh/BoxShape3D | décalage Y mesh/shape | albedo_color | Matériau mock cible |
|----------|-----------------------|-------------------------|-----------------------|--------------|---------------------|
| Batiment1 | Vector3(20, 0, 20) | Vector3(6, 12, 6) | position Y = 6 | #8a8a8a — Color(0.541, 0.541, 0.541, 1.0) | batiment_grey_medium.tres |
| Batiment2 | Vector3(-25, 0, 15) | Vector3(8, 8, 8) | position Y = 4 | #b0a090 — Color(0.690, 0.627, 0.565, 1.0) | batiment_beige_dark.tres |
| Batiment3 | Vector3(30, 0, -20) | Vector3(5, 6, 10) | position Y = 3 | #9a9a9a — Color(0.604, 0.604, 0.604, 1.0) | batiment_grey_light.tres |
| Batiment4 | Vector3(-15, 0, -30) | Vector3(10, 5, 6) | position Y = 2.5 | #c8b89a — Color(0.784, 0.722, 0.604, 1.0) | batiment_beige_light.tres |
| Batiment5 | Vector3(40, 0, 5) | Vector3(6, 10, 6) | position Y = 5 | #7a7a7a — Color(0.478, 0.478, 0.478, 1.0) | batiment_grey_dark.tres |
| Batiment6 | Vector3(-40, 0, -10) | Vector3(7, 7, 7) | position Y = 3.5 | #b8a888 — Color(0.722, 0.659, 0.533, 1.0) | batiment_beige_medium.tres |
| Batiment7 | Vector3(10, 0, -40) | Vector3(4, 14, 4) | position Y = 7 | #888888 — Color(0.533, 0.533, 0.533, 1.0) | batiment_grey_medium.tres |
| Batiment8 | Vector3(-20, 0, 35) | Vector3(12, 4, 5) | position Y = 2 | #c0b0a0 — Color(0.753, 0.690, 0.627, 1.0) | batiment_beige_light.tres |

Note sur le décalage Y : le `StaticBody3D` est posé à y = 0 (sol). Le `MeshInstance3D` et le `CollisionShape3D` sont décalés de `hauteur / 2` en Y pour que la face inférieure du cube soit exactement à y = 0. Cette convention est cohérente avec la position du sol `PlaneMesh` de la feature 02 (y = 0).

## Hors-périmètre

- Textures de façade (brique, béton, enduit) : à commander dans une feature ultérieure, non commandées ici.
- Textures normal / roughness / AO des façades : hors proto v0.1.
- Routes, trottoirs, marquages au sol, décors urbains (arbres, bancs, lampadaires) : hors proto v0.1.
- LOD, occlusion culling, frustum culling manuel : hors proto v0.1.
- Plus de 8 bâtiments : hors proto v0.1.
- Mesh de toit détaillé, corniches, balcons, fenêtres : hors proto v0.1.
- Sounds (ambiance urbaine, réverbération) : non commandés.
- Assets pour les véhicules (feature 06) : non commandés ici.
- Texture albedo tileable du sol (mentionnée hors-périmètre en feature 02) : reste hors-périmètre — couleur flat maintenue.
