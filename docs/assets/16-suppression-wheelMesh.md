# Bon de commande 16 — Suppression des WheelMesh fantômes (roues CylinderMesh dépréciées)

## Résumé

Aucun nouvel asset à produire. Cette feature est un nettoyage de scène et de code. Elle formalise la dépréciation complète de `wheel.glb` (déjà déclaré déprécié au bon de commande 13) et confirme la suppression des sous-ressources associées (CylinderMesh + StandardMaterial3D) embarquées dans `car.tscn`.

## Arborescence cible

Aucun nouveau dossier créé ni supprimé. L'arborescence `assets/vehicles/car/` reste inchangée sur le disque. Le fichier `wheel.glb` n'est pas supprimé par le `developer` (risque d'orphelin `.import`). Sa suppression physique est du ressort de l'agent `mixamo`.

```
assets/
└── vehicles/
    └── car/
        ├── car_body.glb   (PRESENT — livré, intégré, inchangé)
        └── wheel.glb      (PRESENT sur disque — OFFICELLEMENT DEPRECIE, archivage par mixamo)
```

## Liste détaillée des assets

| Chemin Godot (res://) | Type | Format | Source | Livré ? | Notes techniques |
|-----------------------|------|--------|--------|---------|------------------|
| `res://assets/vehicles/car/car_body.glb` | Mesh 3D carrosserie + roues visuelles | .glb | Déjà livré | **oui** | Aucune modification. Contient les roues visuelles. Chargé par `car_visuals.gd::_charger_carrosserie()`. |
| `res://assets/vehicles/car/wheel.glb` | Mesh 3D roue séparée | .glb | Déjà livré | **DEPRECIE** | N'est plus chargé depuis la feature 13. Dépréciation formalisée par cette feature 16. Le fichier physique reste sur disque jusqu'à archivage par l'agent `mixamo`. |

## Conventions de nommage

Aucune nouvelle convention. Reprend celles établies au bon de commande 06 (snake_case, `.glb`, suffixes `_albedo` / `_normal` / etc. pour les textures).

## Budget polycount / mémoire

Aucun nouvel asset. Le budget runtime est celui de la feature 13 :

| Catégorie | Valeur |
|-----------|--------|
| `car_body.glb` | Présent en mémoire — inchangé |
| `wheel.glb` | Non chargé au runtime depuis la feature 13. Officiellement déprécié. |
| CylinderMesh (x4) | Supprimés de `car.tscn` — zéro triangle consommé |
| StandardMaterial3D (x4) | Supprimés de `car.tscn` — zéro draw call |

## Mocks obligatoires en attendant les assets finaux

Sans objet. Il n'y a aucun asset final à attendre. Les mocks CylinderMesh qui existent actuellement dans `car.tscn` sont précisément les objets à supprimer dans cette feature. Après suppression, aucun mock ni asset n'occupe les nœuds `WheelMesh` — ces nœuds n'existent plus.

## Modifications de scène et de scripts requises

### `scenes/vehicles/car.tscn` — suppression des 4 nœuds WheelMesh

Supprimer les sous-nœuds suivants (et toutes leurs sous-ressources inline `CylinderMesh` + `StandardMaterial3D`) :

| Nœud à supprimer | Parent | Type | Action |
|------------------|--------|------|--------|
| `WheelFrontLeft/WheelMesh` | `WheelFrontLeft : VehicleWheel3D` | `MeshInstance3D` | Supprimer le nœud et ses ressources inline |
| `WheelFrontRight/WheelMesh` | `WheelFrontRight : VehicleWheel3D` | `MeshInstance3D` | Supprimer le nœud et ses ressources inline |
| `WheelRearLeft/WheelMesh` | `WheelRearLeft : VehicleWheel3D` | `MeshInstance3D` | Supprimer le nœud et ses ressources inline |
| `WheelRearRight/WheelMesh` | `WheelRearRight : VehicleWheel3D` | `MeshInstance3D` | Supprimer le nœud et ses ressources inline |

Les nœuds `VehicleWheel3D` eux-mêmes et tous leurs paramètres de physique restent intacts.

### `src/vehicles/car_visuals.gd` — suppression de `_masquer_roues()`

Supprimer :

1. La méthode `_masquer_roues()` dans son intégralité.
2. L'appel `_masquer_roues()` dans `_ready()`.

`_charger_carrosserie()` et le reste de `_ready()` restent inchangés.

## Section Mixamo — Instructions de téléchargement

Sans objet. Aucun asset Mixamo commandé dans cette feature.

## Hors-périmètre

- Production de tout nouvel asset graphique.
- Modification de `car_body.glb`.
- Suppression physique de `wheel.glb` du disque (rôle de l'agent `mixamo`).
- Modification de `main.tscn`.
- Modification des paramètres physiques VehicleBody3D / VehicleWheel3D.
- Animation des roues visuelles de `car_body.glb`.
