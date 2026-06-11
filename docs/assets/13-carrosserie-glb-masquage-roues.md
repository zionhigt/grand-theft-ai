# Bon de commande 13 — Intégration carrosserie GLB propre (masquage roues redondantes)

## Résumé

Aucun nouvel asset à produire. Cette feature réutilise `car_body.glb` déjà livré (statut OK dans le registre). Elle déclare `wheel.glb` comme déprécié. Les modifications sont purement dans les scripts et la scène.

## Arborescence cible

Aucun nouveau dossier créé. L'arborescence sous `assets/vehicles/car/` reste inchangée.

```
assets/
└── vehicles/
    └── car/
        ├── car_body.glb   (PRESENT — livré, déjà intégré, aucune modification)
        └── wheel.glb      (PRESENT — DEPRECIE par cette feature, fichier conservé physiquement)
```

## Liste détaillée des assets

| Chemin Godot (res://) | Type | Format | Source | Livré ? | Notes techniques |
|-----------------------|------|--------|--------|---------|------------------|
| `res://assets/vehicles/car/car_body.glb` | Mesh 3D carrosserie complète (avec roues intégrées) | .glb | Déjà livré | **oui** | Nœud racine : `car_body` (ou équivalent selon export). Contient les roues visuelles intégrées. Chargé dans `CarBodyMesh` via `car_visuals.gd`. Aucune modification de chargement requise. |
| `res://assets/vehicles/car/wheel.glb` | Mesh 3D roue séparée | .glb | Déjà livré | **DEPRECIE** | Ne plus charger dans `car_visuals.gd`. Le fichier reste sur disque pour ne pas invalider les `.import` Godot, mais aucun nœud de scène ne l'utilise. |

## Conventions de nommage

Aucune nouvelle convention. Reprend celles du bon de commande 06 :
- snake_case, extension `.glb` pour les meshes.
- Suffixes `_albedo`, `_normal`, `_roughness`, `_metallic`, `_ao` pour les textures futures.

## Budget polycount / mémoire

Aucun nouvel asset binaire commandé. Budget inchangé depuis le bon de commande 06.

| Catégorie | Valeur |
|-----------|--------|
| `car_body.glb` | Déjà en mémoire (chargé feature 06) — ~26 Mo sur disque |
| `wheel.glb` | Déchargé — plus aucune référence active (~11 Mo libérés au runtime) |

## Mocks obligatoires en attendant les assets finaux

Aucun mock nécessaire : `car_body.glb` est livré et intégré. Les quatre `WheelMesh` (`MeshInstance3D` CylinderMesh) qui servaient de mocks pour `wheel.glb` sont désormais simplement masqués (`visible = false`) — ils ne sont plus des mocks actifs, ils deviennent des nœuds dormants conservés pour la structure de scène sans impact visuel.

| Asset cible | Nœud Godot | Action requise | Commentaire à inscrire |
|-------------|-----------|---------------|------------------------|
| `WheelFrontLeft/WheelMesh` | `MeshInstance3D` (CylinderMesh) | `visible = false` dans `_ready()` de `car_visuals.gd` | `# MASQUE — roue visuelle intégrée dans car_body.glb` |
| `WheelFrontRight/WheelMesh` | `MeshInstance3D` (CylinderMesh) | `visible = false` dans `_ready()` de `car_visuals.gd` | `# MASQUE — roue visuelle intégrée dans car_body.glb` |
| `WheelRearLeft/WheelMesh` | `MeshInstance3D` (CylinderMesh) | `visible = false` dans `_ready()` de `car_visuals.gd` | `# MASQUE — roue visuelle intégrée dans car_body.glb` |
| `WheelRearRight/WheelMesh` | `MeshInstance3D` (CylinderMesh) | `visible = false` dans `_ready()` de `car_visuals.gd` | `# MASQUE — roue visuelle intégrée dans car_body.glb` |

## Modifications de scène et de scripts requises

### `scenes/vehicles/car.tscn` — paramètres VehicleWheel3D à modifier

Les quatre `VehicleWheel3D` doivent recevoir les nouvelles valeurs de suspension. Ces modifications sont dans la scène `.tscn`, pas dans un asset binaire.

| Nœud | Propriété | Ancienne valeur | Nouvelle valeur |
|------|-----------|----------------|-----------------|
| WheelFrontLeft, WheelFrontRight, WheelRearLeft, WheelRearRight | `suspension_stiffness` | 5.88 | 28 000.0 |
| WheelFrontLeft, WheelFrontRight, WheelRearLeft, WheelRearRight | `suspension_rest_length` | 0.3 (défaut) | 0.25 |
| WheelFrontLeft, WheelFrontRight, WheelRearLeft, WheelRearRight | `suspension_travel` | 0.2 | 0.2 (inchangé) |
| WheelFrontLeft, WheelFrontRight, WheelRearLeft, WheelRearRight | `suspension_max_force` | (défaut) | 10 000.0 |
| WheelFrontLeft, WheelFrontRight, WheelRearLeft, WheelRearRight | `damping_compression` | 0.83 (défaut) | 0.3 |
| WheelFrontLeft, WheelFrontRight, WheelRearLeft, WheelRearRight | `damping_relaxation` | 0.88 (défaut) | 0.5 |

### `main.tscn` — position de spawn du Car

| Nœud | Propriété | Ancienne valeur | Nouvelle valeur |
|------|-----------|----------------|-----------------|
| `Car` (instance de `scenes/vehicles/car.tscn`) | `transform` | `... 5, 0.75, 5` | `... 5, 0.6, 5` |

### `src/vehicles/car_visuals.gd` — fonction `_charger_roues()`

La fonction `_charger_roues()` doit :
1. Ne **plus** charger `wheel.glb`.
2. Récupérer chaque nœud `WheelMesh` enfant des quatre `VehicleWheel3D` et le passer en `visible = false`.

Pseudo-code attendu :

```gdscript
func _masquer_roues() -> void:
    var noms_roues := ["WheelFrontLeft", "WheelFrontRight", "WheelRearLeft", "WheelRearRight"]
    for nom in noms_roues:
        var wheel_node = get_parent().get_node_or_null(nom + "/WheelMesh")
        if wheel_node:
            wheel_node.visible = false
            # MASQUE — roue visuelle intégrée dans car_body.glb
```

La fonction `_charger_roues()` peut être renommée `_masquer_roues()` dans la spec — le designer laisse ce choix au specifier.

## Section Mixamo — Instructions de téléchargement

Aucun asset Mixamo commandé dans cette feature.

## Hors-périmètre

- Production ou modification de `car_body.glb` : déjà livré, aucune modification du fichier GLB.
- Animation des roues visuelles du GLB (rotation en fonction de la vitesse) : hors proto.
- Suppression physique de `wheel.glb` du disque : laissé à l'appréciation de l'utilisateur, ne pas supprimer automatiquement (invaliderait les fichiers `.import` Godot).
- Ajout de textures à la carrosserie.
- Physique avancée (anti-roll bar, centre de gravité).
