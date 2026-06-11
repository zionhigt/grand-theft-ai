Cette feature n'a pas d'asset graphique. Statut Assets dans le cahier des charges = n/a.

---

## Précision contextuelle

Le script `res://src/vehicles/car_controller.gd` (`CarController extends VehicleBody3D`) introduit par cette feature est un script GDScript pur. Il ne requiert aucun fichier binaire (`.glb`, `.png`, `.ogg`, `.tres`) et ne déclare aucun nouveau dossier sous `assets/`.

L'arborescence `assets/` reste strictement identique à celle établie par le bon de commande 07 :

```
assets/
├── characters/
│   └── player/
│       └── player.glb                          (non livré — mock capsule feature 03)
├── environment/
│   └── ground/
│       ├── ground_plane.tres                   (non livré — mock PlaneMesh feature 02)
│       └── ground_grass.tres                   (non livré — mock StandardMaterial3D feature 02)
├── materials/
│   ├── characters/
│   │   └── player_mock.tres                    (non livré — inline feature 03)
│   ├── city/
│   │   └── ...                                 (non livrés — inlines feature 05)
│   └── vehicles/
│       ├── car_body_mock.tres                  (non livré — inline feature 06)
│       └── car_wheel_mock.tres                 (non livré — inline feature 06)
├── vehicles/
│   └── car/
│       ├── car_body.glb                        (non livré — mock BoxMesh feature 06)
│       └── wheel.glb                           (non livré — mock CylinderMesh feature 06)
├── city/
│   └── buildings/
│       └── ...                                 (non livrés — mocks CSGBox feature 05)
├── skybox/
│   └── sky.tres                                (non livré — mock WorldEnvironment feature 02)
├── textures/                                   (réservé — vide)
├── audio/
│   ├── sfx/                                    (réservé — vide)
│   └── music/                                  (réservé — vide)
└── ui/                                         (réservé — vide)
```

Aucun dossier nouveau n'est créé par cette feature. Aucun mock visuel supplémentaire n'est requis.

## Hors-périmètre

- Sons moteur, crissements de pneus, klaxon : hors proto v0.1. Aucun fichier sous `assets/audio/sfx/` ne sera commandé pour cette feature.
- Textures carrosserie et roues finales : à commander en même temps que les meshes `.glb` finaux, dans un bon de commande ultérieur.
- HUD de conduite (compteur de vitesse, jauge de carburant) : hors proto v0.1. Si un HUD est ajouté, il fera l'objet d'un bon de commande dédié déclarant `assets/ui/hud/`.
