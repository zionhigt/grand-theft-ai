# Bon de commande 03 — Personnage joueur déplaçable (ZQSD/WASD)

## Résumé

1 mesh personnage (mock CapsuleMesh + StandardMaterial3D en attendant le `.glb` final), 1 matériau StandardMaterial3D pour le mock, 1 ressource CollisionShape (CapsuleShape3D, déclarée en scène). Aucun asset binaire livré à ce stade. Tous les éléments visuels sont couverts par des primitives Godot.

## Arborescence cible

```
assets/
├── characters/
│   └── player/
│       └── player.glb              (futur mesh 3D personnage — non livré, mock en scène)
├── materials/
│   └── characters/
│       └── player_mock.tres        (StandardMaterial3D couleur #d94a4a — mock proto)
└── environment/                    (déclaré en feature 02 — inchangé)
    └── ground/
        ├── ground_plane.tres       (déclaré en feature 02)
        └── ground_grass.tres       (déclaré en feature 02)
```

Dossiers **nouvellement déclarés** par ce bon de commande :
- `assets/characters/` (nouveau)
- `assets/characters/player/` (nouveau)
- `assets/materials/` (nouveau)
- `assets/materials/characters/` (nouveau)

Le dossier `assets/environment/ground/` est hérité du bon de commande 02 et n'est pas modifié.

## Liste détaillée des assets

| Chemin Godot (res://) | Type | Format | Source | Livré ? | Notes techniques |
|-----------------------|------|--------|--------|---------|------------------|
| `res://assets/characters/player/player.glb` | Mesh 3D personnage | .glb | à produire (artiste 3D) | non | hauteur 1.8 m, rayon ~0.3 m, origine aux pieds (y = 0), UV unwrappé, max 5000 tris |
| `res://assets/materials/characters/player_mock.tres` | Matériau StandardMaterial3D | .tres | généré en GDScript/éditeur | non | albedo_color = #d94a4a, shading_mode = SHADING_MODE_PER_PIXEL, cull_mode = CULL_BACK |

Note : le `CollisionShape3D` (CapsuleShape3D) et le `StaticBody3D` du sol physique sont des nœuds de scène sans fichier asset associé — ils ne figurent pas dans ce tableau.

## Conventions de nommage

- snake_case pour tous les noms de fichiers et dossiers.
- Les meshes 3D finaux sont au format `.glb` (GLTF binaire, compatible Godot 4 natif).
- Les matériaux mock sont des fichiers `.tres` avec le suffixe `_mock` pour les distinguer des matériaux finaux.
- Suffixes de texture attendus pour les assets finaux futurs : `_albedo`, `_normal`, `_roughness`, `_metallic`, `_ao`.
- Exemple futur : `player_albedo.png`, `player_normal.png`.

## Budget polycount / mémoire

| Asset | Budget proto (mock) | Budget final estimé |
|-------|---------------------|---------------------|
| Personnage mesh (player.glb) | 0 tris (CapsuleMesh Godot, généré à la volée) | < 5 000 tris (low-poly humanoïde) |
| Matériau personnage mock | 0 octets de texture (couleur flat) | 1 texture albedo 1024 × 1024 px + normal 1024 × 1024 px |
| CapsuleShape3D (collision) | shape analytique, 0 polycount | identique (shape physique, pas de mesh) |

Contrainte globale : le personnage ne doit pas à lui seul dépasser 5 000 tris en version finale, pour permettre plusieurs instances PNJ futurs sans impact performance.

## Mocks obligatoires en attendant les assets finaux

| Asset cible | Nœud Godot mock | Forme | Dimensions | Couleur (hex) | Commentaire à inscrire |
|-------------|-----------------|-------|------------|---------------|------------------------|
| `res://assets/characters/player/player.glb` | `MeshInstance3D` avec `CapsuleMesh` | capsule | h = 1.8 m, r = 0.4 m (radius) | #d94a4a | `# MOCK — à remplacer par res://assets/characters/player/player.glb` |
| `res://assets/materials/characters/player_mock.tres` | `StandardMaterial3D` inline sur le `MeshInstance3D` | matériau flat | n/a | albedo #d94a4a | `# MOCK — à remplacer par res://assets/materials/characters/player_mock.tres` |

### Détail des paramètres mock

**Personnage — `CharacterBody3D` avec `CapsuleMesh` et `CapsuleShape3D`**

```
CharacterBody3D  (script : res://src/player/player_controller.gd)
  position = Vector3(0, 0.9, 0)    # pieds à y=0, centre capsule à y=0.9
  up_direction = Vector3(0, 1, 0)

  CollisionShape3D
    shape = CapsuleShape3D
      height = 1.8        # mètres, axe Y
      radius = 0.4        # mètres
    position = Vector3(0, 0, 0)   # déjà centré sur le CharacterBody3D

  MeshInstance3D
    mesh = CapsuleMesh
      height = 1.8
      radius = 0.4
    material_override = StandardMaterial3D
      albedo_color = Color(0.851, 0.290, 0.290, 1.0)   # #d94a4a
      shading_mode = SHADING_MODE_PER_PIXEL
      cull_mode = CULL_BACK
    position = Vector3(0, 0, 0)
    # MOCK — à remplacer par res://assets/characters/player/player.glb
    # MOCK — matériau à remplacer par res://assets/materials/characters/player_mock.tres
```

**Sol physique ajouté dans `main.tscn` — nœuds nus, aucun asset**

La feature 03 ajoute un corps physique sur le sol existant de la feature 02. Ce nœud n'est pas un asset mais un nœud de scène :

```
StaticBody3D   (nœud enfant du sol ou nœud frère "GroundCollider")
  CollisionShape3D
    shape = WorldBoundaryShape3D   # plan infini, origine y=0
    # Alternative acceptable : BoxShape3D(size = Vector3(200, 0.2, 200), position = Vector3(0, -0.1, 0))
  # Nœud de scène — pas d'asset associé
```

## Hors-périmètre

- Animations squelettales du personnage (idle, walk, run) : non commandées — hors proto v0.1.
- Textures du personnage (`player_albedo.png`, `player_normal.png`, etc.) : à commander dans une feature ultérieure si le mesh final est livré.
- Assets audio (sons de pas, impacts) : non commandés.
- Mesh et assets de PNJ (personnages non-joueurs) : features ultérieures.
- Mesh et assets de véhicule : feature 06.
- HUD / UI liés au personnage (barre de vie, nom, minimap) : hors proto v0.1.
- Texture réelle du sol (albedo tileable) : hors périmètre de cette feature, déclarée hors-périmètre en feature 02 et à commander en feature 05.
