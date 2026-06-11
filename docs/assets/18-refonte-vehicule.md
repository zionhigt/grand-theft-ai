# Bon de commande 18 — Refonte complète du véhicule

## Résumé

1 asset requis : `assets/vehicles/car/car_body.glb` — **déjà livré** depuis la feature 13. Aucun nouvel asset à produire ni à télécharger.

`wheel.glb` est **définitivement supprimé** du projet par cette feature : il n'apparaît plus dans aucun bon de commande, aucune liste d'assets, aucun script. Sa suppression physique du disque est du ressort de l'agent `mixamo`.

## Arborescence cible

Aucun nouveau dossier créé. L'arborescence `assets/vehicles/car/` est inchangée sur le disque.

```
assets/
└── vehicles/
    └── car/
        └── car_body.glb   (PRESENT — livré, intégré, inchangé)
```

`wheel.glb` ne figure plus dans cette arborescence. Il est supprimé de toute référence projet à partir de cette feature.

## Liste détaillée des assets

| Chemin Godot (res://) | Type | Format | Source | Livré ? | Notes techniques |
|-----------------------|------|--------|--------|---------|------------------|
| `res://assets/vehicles/car/car_body.glb` | Mesh 3D carrosserie complète avec roues visuelles intégrées | .glb | Livré (feature 13) | **oui** | Nœud racine : `car_body` (à confirmer par inspection runtime). Rotation d'import : `rotation_degrees.y = -90.0` pour aligner nez modèle (-X GLB) → direction -Z du VehicleBody3D. Scale : auto via AABB pour longueur ~4.0 m. Chargé dans `_ready()` via `preload()` ou `load()`. Pas d'AnimationPlayer ni de Skeleton3D attendus (mesh statique). |

## Suppression formelle de wheel.glb

`res://assets/vehicles/car/wheel.glb` est **supprimé du projet** à partir de cette feature.

- Il ne doit plus figurer dans aucun script (`load()`, `preload()`, variable de chemin).
- Il ne doit plus figurer dans aucune scène `.tscn` (nœud enfant, propriété de ressource).
- Il ne doit plus figurer dans aucun bon de commande graphique futur.
- Sa suppression physique du disque (fichier `.glb` + fichier `.import` associé) est déléguée à l'agent `mixamo`, qui le marquera comme `SUPPRIME` dans `docs/assets/ASSETS-STATUS.md`.

## Conventions de nommage

Reprend les conventions établies au bon de commande 06 :
- snake_case pour tous les noms de fichiers et de nœuds.
- Extension `.glb` pour les meshes 3D.
- Suffixes `_albedo`, `_normal`, `_roughness`, `_metallic`, `_ao` pour les textures futures.

## Budget polycount / mémoire

| Catégorie | Valeur |
|-----------|--------|
| `car_body.glb` | Déjà en mémoire depuis la feature 13 — ~26 Mo sur disque, budget inchangé |
| `wheel.glb` | Supprimé — 0 Mo consommé au runtime |
| Mocks BoxMesh (fallback) | 12 triangles, négligeable |

## Mocks obligatoires en attendant les assets finaux

`car_body.glb` est déjà livré. Le mock BoxMesh ci-dessous est un **fallback runtime** activé uniquement si le fichier GLB est introuvable au chargement de la scène (cas de régression ou d'environnement sans assets).

| Asset cible | Nœud Godot mock | Forme | Dimensions | Couleur (hex) | Commentaire à inscrire |
|-------------|-----------------|-------|------------|---------------|------------------------|
| `res://assets/vehicles/car/car_body.glb` | `MeshInstance3D` avec `BoxMesh` | box | 4.0 × 1.5 × 2.0 m | #cc2222 | `# MOCK — à remplacer par res://assets/vehicles/car/car_body.glb` |

Le fallback est activé dans `_ready()` par une vérification d'existence :

```gdscript
if ResourceLoader.exists(CAR_BODY_GLB):
    var body_scene = load(CAR_BODY_GLB)
    var body_instance = body_scene.instantiate()
    body_instance.rotation_degrees.y = -90.0
    $CarBodyMesh.add_child(body_instance)
else:
    push_warning("car_body.glb introuvable — mock BoxMesh actif")
    # MOCK — à remplacer par res://assets/vehicles/car/car_body.glb
    var mock = MeshInstance3D.new()
    var box = BoxMesh.new()
    box.size = Vector3(4.0, 1.5, 2.0)
    mock.mesh = box
    var mat = StandardMaterial3D.new()
    mat.albedo_color = Color(0.8, 0.133, 0.133)
    mock.material_override = mat
    $CarBodyMesh.add_child(mock)
```

## Structure interne du GLB attendue pour le code d'intégration

Le `developer` doit pouvoir intégrer `car_body.glb` sans ouvrir l'éditeur Godot. Voici ce qui est attendu :

| Élément | Valeur attendue | Remarque |
|---------|----------------|----------|
| Nœud racine du GLB (après `instantiate()`) | `car_body` (nom probable) | À confirmer par `print(body_instance.name)` au runtime si nécessaire |
| AnimationPlayer | aucun | Mesh statique, pas d'animation |
| Skeleton3D | aucun | Pas de rig |
| Roues visuelles | intégrées dans le mesh | Pas de sous-nœuds séparés pour les roues |
| Axe avant du modèle dans l'espace GLB | -X | Corriger avec `rotation_degrees.y = -90.0` |
| Échelle approximative brute | variable selon export | Normaliser via AABB : `scale = Vector3.ONE * (4.0 / aabb.size.x)` |

## Section Mixamo — Instructions de téléchargement

Sans objet. `car_body.glb` est déjà livré et n'est pas un asset Mixamo. Aucun téléchargement requis.

## Hors-périmètre

- Production ou modification de `car_body.glb` : déjà livré, aucune modification du fichier GLB.
- Texture de carrosserie (couleur de peinture, normal map) : hors proto v0.1.
- `wheel.glb` : définitivement supprimé, ne sera jamais commandé à nouveau dans ce projet.
- Animation de rotation des roues visuelles : hors proto v0.1.
- Assets audio (son moteur, son de freinage) : hors périmètre de cette feature.
- HUD ou overlays UI (vitesse, indicateur de carburant) : hors proto v0.1.
- Véhicules supplémentaires (moto, camion, etc.) : hors proto v0.1.
