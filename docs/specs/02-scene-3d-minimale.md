# Spec 02 — Scène 3D minimale (sol + ciel + lumière + caméra fixe)

## Contexte

- Design : `docs/design/02-scene-3d-minimale.md`
- Bon de commande graphique : `docs/assets/02-scene-3d-minimale.md`
- Dépendances de specs précédentes : **Spec 01 — Bootstrap projet** (`docs/specs/01-bootstrap.md`) — fournit `main.tscn` avec le nœud racine `Main : Node3D`, une `Camera3D` (position `Vector3(0, 1, 5)`, `current = true`) et un `WorldEnvironment` (fond uni `#222233`). Cette feature modifie ces trois nœuds existants et en ajoute deux nouveaux.

## Objectif fonctionnel

Transformer `main.tscn` d'un fond uni gris en une scène 3D visuelle minimale : un sol plan vert sombre de 200 × 200 m, un ciel procédural dégradé bleu, une lumière directionnelle chaude simulant le soleil, et la caméra repositionnée en hauteur avec vue plongeante sur l'origine. Aucune interaction, aucune physique, aucun input. Tout le code de construction des ressources est isolé dans `src/world/world_builder.gd` pour permettre des tests GUT purs sans instancier la scène complète.

## Arborescence cible

```
.
├── main.tscn                                   # modifié — nouvelle structure (voir section "Structure des scènes")
└── src/
    └── world/
        └── world_builder.gd                    # créé — WorldBuilder extends RefCounted, méthodes statiques pures
tests/
└── test_02_scene_3d_minimale.gd                # à écrire par le tester
assets/
├── environment/
│   └── ground/
│       ├── ground_plane.tres                   # non livré — mock PlaneMesh inline dans main.tscn
│       └── ground_grass.tres                   # non livré — mock StandardMaterial3D inline dans main.tscn
└── skybox/
    └── sky.tres                                # non livré — mock Sky + ProceduralSkyMaterial inline dans main.tscn
```

Notes :
- `src/world/world_builder.gd` est le **seul** fichier de production créé par cette feature.
- `main.tscn` est modifié (pas créé) : les nœuds hérités de la feature 01 sont conservés, modifiés ou complétés.
- Les dossiers `assets/environment/ground/` et `assets/skybox/` sont déclarés par le bon de commande mais leurs fichiers `.tres` ne sont pas livrés à ce stade.

## Interface publique (GDScript)

### `src/world/world_builder.gd`

```gdscript
class_name WorldBuilder
extends RefCounted

# --- Constantes exposées ---

const GROUND_SIZE: float = 200.0

const SKY_TOP_COLOR: Color = Color(0.306, 0.627, 1.0, 1.0)        # #4ea0ff
const SKY_HORIZON_COLOR: Color = Color(0.753, 0.847, 1.0, 1.0)    # #c0d8ff
const SKY_GROUND_COLOR: Color = Color(0.290, 0.486, 0.227, 1.0)   # #4a7c3a

const GROUND_ALBEDO: Color = Color(0.290, 0.486, 0.227, 1.0)      # #4a7c3a

const LIGHT_PITCH_RADIANS: float = -PI / 4.0   # -45 degrés autour de l'axe X

const CAMERA_POSITION: Vector3 = Vector3(0.0, 8.0, 15.0)
const CAMERA_LOOK_AT: Vector3 = Vector3(0.0, 0.0, 0.0)

# --- Méthodes statiques pures ---

static func build_sky_material() -> ProceduralSkyMaterial
static func build_ground_material() -> StandardMaterial3D
static func build_ground_mesh() -> PlaneMesh
static func build_directional_light_basis() -> Basis
static func build_camera_transform() -> Transform3D
```

**Détail de chaque méthode :**

#### `static func build_sky_material() -> ProceduralSkyMaterial`

Retourne une **nouvelle instance** de `ProceduralSkyMaterial` avec les propriétés suivantes :

| Propriété | Valeur |
|---|---|
| `sky_top_color` | `WorldBuilder.SKY_TOP_COLOR` — `Color(0.306, 0.627, 1.0)` |
| `sky_horizon_color` | `WorldBuilder.SKY_HORIZON_COLOR` — `Color(0.753, 0.847, 1.0)` |
| `ground_bottom_color` | `WorldBuilder.SKY_GROUND_COLOR` — `Color(0.290, 0.486, 0.227)` |
| `ground_horizon_color` | `WorldBuilder.SKY_GROUND_COLOR` — `Color(0.290, 0.486, 0.227)` |
| `sky_energy_multiplier` | `1.0` |
| `sun_angle_max` | `30.0` |
| `sun_curve` | `0.15` |

Chaque appel crée une instance distincte (pas de cache interne, pas de ressource partagée).

#### `static func build_ground_material() -> StandardMaterial3D`

Retourne une **nouvelle instance** de `StandardMaterial3D` avec :

| Propriété | Valeur |
|---|---|
| `albedo_color` | `WorldBuilder.GROUND_ALBEDO` — `Color(0.290, 0.486, 0.227)` |
| `roughness` | `1.0` |
| `shading_mode` | `BaseMaterial3D.SHADING_MODE_PER_PIXEL` |

Chaque appel crée une instance distincte.

#### `static func build_ground_mesh() -> PlaneMesh`

Retourne une **nouvelle instance** de `PlaneMesh` avec :

| Propriété | Valeur |
|---|---|
| `size` | `Vector2(200.0, 200.0)` |
| `subdivide_width` | `0` |
| `subdivide_depth` | `0` |

Chaque appel crée une instance distincte.

#### `static func build_directional_light_basis() -> Basis`

Retourne `Basis.from_euler(Vector3(WorldBuilder.LIGHT_PITCH_RADIANS, 0.0, 0.0))`, soit une rotation de -π/4 radians (-45°) autour de l'axe X uniquement. Aucune rotation sur Y ni Z.

#### `static func build_camera_transform() -> Transform3D`

Construit et retourne un `Transform3D` positionné en `WorldBuilder.CAMERA_POSITION` (`Vector3(0, 8, 15)`) et orienté de sorte que l'axe `-Z` de la basis (direction "forward" en Godot) pointe vers `WorldBuilder.CAMERA_LOOK_AT` (`Vector3(0, 0, 0)`).

Implémentation de référence :

```gdscript
static func build_camera_transform() -> Transform3D:
    var t := Transform3D()
    t.origin = CAMERA_POSITION
    t = t.looking_at(CAMERA_LOOK_AT, Vector3.UP)
    return t
```

La direction forward attendue (normalisée) est `(CAMERA_LOOK_AT - CAMERA_POSITION).normalized()` = `Vector3(0, -8, -15).normalized()`.

## Structure des scènes (.tscn)

### `main.tscn` (modifiée)

```
Main : Node3D                                    (nœud racine hérité de la feature 01 — inchangé)
│
├── WorldEnvironment : WorldEnvironment          (nœud hérité de la feature 01 — modifié)
│     environment = Environment (resource inline)
│       background_mode = Environment.BG_SKY
│       sky = Sky (resource inline)
│         sky_material = ProceduralSkyMaterial (resource inline)
│           sky_top_color     = Color(0.306, 0.627, 1.0)
│           sky_horizon_color = Color(0.753, 0.847, 1.0)
│           ground_bottom_color  = Color(0.290, 0.486, 0.227)
│           ground_horizon_color = Color(0.290, 0.486, 0.227)
│           sky_energy_multiplier = 1.0
│           sun_angle_max = 30.0
│           sun_curve = 0.15
│     # MOCK — à remplacer par res://assets/skybox/sky.tres (HDRI futur)
│
├── DirectionalLight3D : DirectionalLight3D      (nœud nouveau)
│     light_color = Color(1.0, 0.957, 0.878, 1.0)   # #fff4e0
│     light_energy = 1.0
│     shadow_enabled = false
│     basis = Basis.from_euler(Vector3(-PI/4, 0, 0))
│     # rotation_degrees = Vector3(-45, 0, 0) — nœud de scène, pas d'asset associé
│
├── Ground : MeshInstance3D                      (nœud nouveau)
│     position = Vector3(0, 0, 0)
│     mesh = PlaneMesh (resource inline)
│       size = Vector2(200, 200)
│       subdivide_width = 0
│       subdivide_depth = 0
│     material_override = StandardMaterial3D (resource inline)
│       albedo_color = Color(0.290, 0.486, 0.227, 1.0)   # #4a7c3a
│       roughness = 1.0
│       shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
│     # MOCK — à remplacer par res://assets/environment/ground/ground_plane.tres
│     #        + res://assets/environment/ground/ground_grass.tres
│
└── Camera3D : Camera3D                          (nœud hérité de la feature 01 — repositionné)
      current = true
      position = Vector3(0, 8, 15)
      # look_at(Vector3(0, 0, 0), Vector3.UP) — orientation vers l'origine
      # rotation résultante approximative : Vector3(-28°, 0°, 0°) (via looking_at)
      # Nœud de scène — pas d'asset associé
```

Notes de structure :
- Tous les nœuds enfants sont placés directement sous `Main` (pas de sous-groupage).
- L'ordre des enfants dans l'arbre : `WorldEnvironment`, `DirectionalLight3D`, `Ground`, `Camera3D`.
- Les ressources `Environment`, `Sky`, `ProceduralSkyMaterial`, `PlaneMesh`, `StandardMaterial3D` sont toutes **inline** (pas de fichiers `.tres` séparés à ce stade).
- `WorldEnvironment` n'a pas de nœud enfant : l'`Environment` est une propriété de ressource, pas un nœud fils.
- La `Camera3D` ne porte aucun script. Son orientation est configurée statiquement via l'éditeur Godot (propriété `transform`) en appliquant `look_at(Vector3(0,0,0))`.

## Données et constantes

Toutes les constantes sont déclarées dans `src/world/world_builder.gd` et accessibles via `WorldBuilder.<NOM>`.

| Constante | Type | Valeur | Rôle |
|---|---|---|---|
| `GROUND_SIZE` | `float` | `200.0` | Côté du plan de sol passé à `PlaneMesh.size` (200 × 200 m) |
| `SKY_TOP_COLOR` | `Color` | `Color(0.306, 0.627, 1.0)` | Couleur zénith du ciel procédural (#4ea0ff) |
| `SKY_HORIZON_COLOR` | `Color` | `Color(0.753, 0.847, 1.0)` | Couleur horizon du ciel (#c0d8ff) |
| `SKY_GROUND_COLOR` | `Color` | `Color(0.290, 0.486, 0.227)` | Couleur sous l'horizon du ciel, cohérente avec le sol (#4a7c3a) |
| `GROUND_ALBEDO` | `Color` | `Color(0.290, 0.486, 0.227)` | Couleur albedo du matériau sol (#4a7c3a) |
| `LIGHT_PITCH_RADIANS` | `float` | `-PI / 4.0` | Rotation X de la lumière directionnelle (-45°) |
| `CAMERA_POSITION` | `Vector3` | `Vector3(0.0, 8.0, 15.0)` | Position de la caméra fixe |
| `CAMERA_LOOK_AT` | `Vector3` | `Vector3(0.0, 0.0, 0.0)` | Point cible du regard de la caméra |

Note : `SKY_GROUND_COLOR` et `GROUND_ALBEDO` partagent la même valeur hexadécimale (#4a7c3a) pour assurer la cohérence visuelle entre le sol du monde et le sol du ciel procédural.

## Comportements attendus

Chaque point est testable unitairement avec GUT dans `tests/test_02_scene_3d_minimale.gd`. Les tests 1 à 8 ne nécessitent pas d'instancier `main.tscn`. Les tests 9 à 12 requièrent un chargement de scène (mode headless admis).

1. `WorldBuilder.GROUND_SIZE == 200.0` — la constante est égale à exactement `200.0`.

2. `WorldBuilder.build_ground_mesh()` retourne un `PlaneMesh` (`mesh is PlaneMesh == true`) dont `size == Vector2(200.0, 200.0)`.

3. `WorldBuilder.build_ground_material()` retourne un `StandardMaterial3D` dont chaque composant de `albedo_color` est approximativement égal à `Color(0.290, 0.486, 0.227)` (tolérance `0.001` par composant, asserté avec `assert_almost_eq`).

4. `WorldBuilder.build_sky_material()` retourne un `ProceduralSkyMaterial` dont `sky_top_color` est approximativement `Color(0.306, 0.627, 1.0)` (tolérance `0.001` par composant).

5. `WorldBuilder.build_sky_material().sky_horizon_color` est approximativement `Color(0.753, 0.847, 1.0)` (tolérance `0.001` par composant).

6. `WorldBuilder.build_sky_material().ground_bottom_color` est approximativement `Color(0.290, 0.486, 0.227)` (tolérance `0.001` par composant).

7. `WorldBuilder.build_camera_transform().origin == Vector3(0.0, 8.0, 15.0)` — l'origine du transform est exactement la constante `CAMERA_POSITION`.

8. La direction "forward" de `WorldBuilder.build_camera_transform()` pointe vers l'origine : le vecteur `-basis.z` du transform retourné a un produit scalaire `> 0.99` avec `(Vector3(0,0,0) - Vector3(0,8,15)).normalized()` = `Vector3(0, -8, -15).normalized()`.

   Test par produit scalaire : `(-transform.basis.z).dot(expected_forward) > 0.99`.

9. `WorldBuilder.build_directional_light_basis().get_euler().x` est approximativement `-PI/4` (tolérance `0.001`).

10. **Test de scène headless** : charger `load("res://main.tscn")`, appeler `add_child_autofree(scene)`, et vérifier que les quatre enfants nommés `WorldEnvironment`, `DirectionalLight3D`, `Ground`, `Camera3D` existent (`scene.get_node_or_null("WorldEnvironment") != null`, etc.), et que `scene.get_node("Camera3D").current == true`.

11. Le nœud `Ground` (MeshInstance3D) a un `mesh` de classe `PlaneMesh` (`ground.mesh is PlaneMesh == true`) avec `ground.mesh.size == Vector2(200.0, 200.0)`.

12. `scene.get_node("WorldEnvironment").environment.background_mode == Environment.BG_SKY`, `environment.sky != null`, et `environment.sky.sky_material is ProceduralSkyMaterial == true`. De plus, `scene.get_node("DirectionalLight3D").light_energy == 1.0`.

## Cas limites / erreurs

1. **Instances distinctes (mesh)** : deux appels successifs à `WorldBuilder.build_ground_mesh()` retournent deux instances dont l'identité est différente (`is_same(mesh_a, mesh_b) == false`). La méthode ne cache pas de singleton de ressource.

2. **Instances distinctes (matériau)** : deux appels successifs à `WorldBuilder.build_ground_material()` retournent deux instances dont `is_same(mat_a, mat_b) == false`.

3. **Stabilité du transform caméra** : deux appels successifs à `WorldBuilder.build_camera_transform()` retournent des transforms vérifiant `t1.is_equal_approx(t2) == true`.

4. **Stabilité de la basis lumière** : deux appels successifs à `WorldBuilder.build_directional_light_basis()` retournent des bases vérifiant `b1.is_equal_approx(b2) == true`.

5. **Aucun crash en headless** : `WorldBuilder` étend `RefCounted`, aucune dépendance au moteur de rendu dans son constructeur implicite — instanciable depuis un test headless sans scène active.

## Inputs Godot (Input Map)

Aucun ajout pour cette feature. La section `[input]` de `project.godot` reste inchangée.

## Assets consommés

| Chemin `res://` | Mock attendu | Type mock | Usage dans la scène |
|---|---|---|---|
| `res://assets/environment/ground/ground_plane.tres` | oui | `PlaneMesh` inline sur le nœud `Ground` | Géométrie du sol 200 × 200 m |
| `res://assets/environment/ground/ground_grass.tres` | oui | `StandardMaterial3D` inline (`material_override` du nœud `Ground`) | Couleur albedo du sol #4a7c3a |
| `res://assets/skybox/sky.tres` | oui | `Sky` + `ProceduralSkyMaterial` inline dans la propriété `environment` du nœud `WorldEnvironment` | Ciel procédural dégradé bleu |

Tous les assets sont mockés inline dans `main.tscn`. Aucun fichier `.tres` externe n'est requis pour que la scène se lance.

## Dépendances

- **Spec 01 — Bootstrap projet** (`docs/specs/01-bootstrap.md`) : fournit `main.tscn` (nœud racine `Main`, `Camera3D`, `WorldEnvironment`) et `project.godot` valide. Cette spec 02 est une modification incrémentale de la scène issue de la spec 01.
- **`addons/gut/`** : addon GUT v9.4 ou supérieur, compatible Godot 4.6. Déjà installé depuis la feature 01.
- Aucun autre addon autorisé.

## Critères d'acceptation

- [ ] Le fichier `src/world/world_builder.gd` est présent, `class_name WorldBuilder` est reconnue par GDScript sans erreur de parse.
- [ ] La commande `godot --headless -s res://addons/gut/gut_cmdln.gd -gdir=res://tests -gexit` retourne le code de sortie 0 (tous les tests de `test_02_scene_3d_minimale.gd` passent au vert).
- [ ] `main.tscn` s'ouvre dans l'éditeur Godot 4.6 sans warning rouge ni erreur de ressource manquante.
- [ ] L'arbre de la scène dans l'éditeur affiche exactement : `Main > WorldEnvironment`, `Main > DirectionalLight3D`, `Main > Ground`, `Main > Camera3D`.
- [ ] `godot --path . res://main.tscn` se lance sans `ERROR:` ni `SCRIPT ERROR:` dans la console.
- [ ] Visuellement au lancement : ciel dégradé bleu (zénith soutenu vers horizon pâle), sol vert sombre continu, lumière directionnelle éclairant le sol (pas de teinte plate uniforme), horizon visible dans le cadre depuis la position caméra `Vector3(0, 8, 15)`.
- [ ] Le nœud `Ground` porte le commentaire `# MOCK — à remplacer par res://assets/environment/ground/ground_plane.tres + ground_grass.tres` dans la scène ou dans le script d'initialisation.
- [ ] Le nœud `WorldEnvironment` (ou son `sky_material`) porte le commentaire `# MOCK — à remplacer par res://assets/skybox/sky.tres (HDRI futur)`.
- [ ] Les 12 comportements attendus et les 5 cas limites de la spec passent tous au vert dans GUT.

## Hors-périmètre

- Toute physique sur le sol (`CollisionShape3D`, `StaticBody3D`) : réservé à la feature 03 (personnage déplaçable).
- Bâtiments, props, détails de ville : feature 05.
- Texture réelle du sol (`.png` tileable) : hors proto v0.1, à commander dans la feature 05 ou plus tard.
- Asset HDRI / skybox panoramique haute qualité (`sky.tres` final) : hors proto v0.1.
- Ombres portées (`shadow_enabled = true`) : hors proto v0.1 (désactivées par le design doc).
- Lumière ambiante (GI, SSAO, SSIL), brouillard (Fog), reflets d'écran : hors proto v0.1.
- Tout input clavier ou logique de gameplay.
- Caméra animée ou scriptée : feature 04.
- Les fichiers `.tres` finaux pour `ground_plane.tres`, `ground_grass.tres`, `sky.tres` : à livrer par le developer dans une itération ultérieure ou dans la feature correspondante.
