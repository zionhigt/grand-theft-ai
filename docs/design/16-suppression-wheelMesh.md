# Design 16 — Suppression des WheelMesh fantômes (roues CylinderMesh dépréciées)

## Pitch (1 phrase)

Supprimer entièrement les quatre nœuds `WheelMesh` (CylinderMesh + StandardMaterial3D) qui existent à l'intérieur des `VehicleWheel3D` mais n'ont plus aucun rôle visuel depuis l'intégration de `car_body.glb` (feature 13).

## Pourquoi cette feature (valeur joueur)

Les roues CylinderMesh ont été créées comme mocks de proto (feature 06) avant que `car_body.glb` ne fournisse des roues visuelles intégrées. La feature 13 les a masquées (`visible = false`) mais ne les a pas supprimées. Ces nœuds dormants constituent :

- une dette technique explicite (nœuds morts dans la hiérarchie de scène),
- une ambiguïté de maintenance (un développeur peut croire qu'ils servent à quelque chose),
- un code mort dans `car_visuals.gd` (`_masquer_roues()` et son appel dans `_ready()`).

La suppression nette de ces nœuds et du code associé rend la scène plus lisible, le script plus court, et élimine tout risque de confusion future.

Le joueur ne voit aucun changement visuel : `car_body.glb` fournit déjà les roues visuelles correctement. L'effet est invisible en jeu mais bénéfique pour la qualité du code.

## Description détaillée

### Nœuds à supprimer dans `scenes/vehicles/car.tscn`

Chacun des quatre `VehicleWheel3D` contient un enfant `WheelMesh : MeshInstance3D` portant un `CylinderMesh` et un `StandardMaterial3D`. Ces quatre sous-nœuds doivent être supprimés de la scène. Les `VehicleWheel3D` eux-mêmes (physique) restent intacts.

Avant :
```
WheelFrontLeft : VehicleWheel3D
└── WheelMesh : MeshInstance3D    # visible=false, CylinderMesh (mock déprécié)

WheelFrontRight : VehicleWheel3D
└── WheelMesh : MeshInstance3D    # visible=false, CylinderMesh (mock déprécié)

WheelRearLeft : VehicleWheel3D
└── WheelMesh : MeshInstance3D    # visible=false, CylinderMesh (mock déprécié)

WheelRearRight : VehicleWheel3D
└── WheelMesh : MeshInstance3D    # visible=false, CylinderMesh (mock déprécié)
```

Après :
```
WheelFrontLeft : VehicleWheel3D    # inchangé (physique)
WheelFrontRight : VehicleWheel3D   # inchangé (physique)
WheelRearLeft : VehicleWheel3D     # inchangé (physique)
WheelRearRight : VehicleWheel3D    # inchangé (physique)
```

### Code à supprimer dans `src/vehicles/car_visuals.gd`

1. La méthode `_masquer_roues()` dans son intégralité.
2. L'appel à `_masquer_roues()` dans `_ready()`.

Aucune autre méthode (`_charger_carrosserie()`, `_ready()` sans l'appel) n'est modifiée.

### `wheel.glb` dans `assets/vehicles/car/`

Le fichier `wheel.glb` est déjà déclaré déprécié depuis le bon de commande 13. Cette feature formalise la dépréciation complète : le bon de commande 16 le liste comme déprécié à archiver. L'agent `mixamo` mettra à jour `docs/assets/ASSETS-STATUS.md` en conséquence.

## Contrôles / inputs

Sans objet. Cette feature est purement technique (nettoyage de scène et de code). Aucun nouveau contrôle.

## Feedback joueur

Aucun changement visible pour le joueur. La voiture a le même aspect qu'après la feature 13 — les roues visuelles proviennent de `car_body.glb`. La suppression est transparente en jeu.

## Règles et limites

- Les quatre nœuds `VehicleWheel3D` sont conservés intégralement (ils portent la physique de suspension et de traction). Seuls leurs enfants `WheelMesh` sont supprimés.
- `main.tscn` n'est pas modifié.
- `_charger_carrosserie()` dans `car_visuals.gd` n'est pas modifiée.
- Les paramètres physiques de la voiture (suspension, moteur, etc.) ne sont pas modifiés.
- `wheel.glb` n'est pas supprimé du disque par le `developer` (le fichier `.import` Godot associé peut devenir orphelin sinon) — c'est l'agent `mixamo` qui archive / nettoie ce fichier.

## Dépendances de design

- **Feature 06** — Voiture (mesh + corps physique de base) : a créé les nœuds `WheelMesh` CylinderMesh.
- **Feature 13** — Intégration carrosserie GLB (masquage roues redondantes) : a masqué ces nœuds et déclaré `wheel.glb` déprécié. Le design 16 finalise ce travail.

## Hors-périmètre

- Animation des roues visuelles (rotation en fonction de la vitesse) : hors proto.
- Textures de la carrosserie ou des roues visuelles de `car_body.glb`.
- Modification des paramètres de physique VehicleBody3D / VehicleWheel3D.
- Suppression physique du fichier `wheel.glb` du disque par le `developer`.
- Toute autre modification de `main.tscn`.
