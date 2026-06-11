# Bon de commande 07 — Entrer / sortir d'un véhicule (touche E)

## Résumé

Aucun asset 3D nouveau. Un nœud `Area3D` avec `SphereShape3D` (rayon 3.0 m) est ajouté à `scenes/vehicles/car.tscn` comme mock de la zone d'interaction. Un `CanvasLayer > Label` optionnel est déclaré en GDScript pur (police par défaut Godot, aucun fichier PNG). Tous les éléments visuels de cette feature sont soit réutilisés depuis les features 03 et 06, soit construits en primitives Godot.

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
├── materials/                           (déclaré en feature 03 — inchangé)
│   ├── characters/
│   │   └── player_mock.tres
│   ├── city/                            (déclaré en feature 05 — inchangé)
│   │   └── ...
│   └── vehicles/                        (déclaré en feature 06 — inchangé)
│       ├── car_body_mock.tres
│       └── car_wheel_mock.tres
├── vehicles/                            (déclaré en feature 06 — inchangé)
│   └── car/
│       ├── car_body.glb
│       └── wheel.glb
├── city/                                (déclaré en feature 05 — inchangé)
│   └── buildings/
│       └── ...
├── skybox/                              (déclaré en feature 02 — inchangé)
│   └── sky.tres
├── textures/                            (réservé — inchangé)
├── audio/                               (réservé — inchangé)
│   ├── sfx/
│   └── music/
└── ui/                                  (réservé — inchangé)
```

Aucun dossier nouveau dans `assets/` n'est créé par cette feature. L'arborescence est identique à celle déclarée par le bon de commande 06.

## Liste détaillée des assets

| Chemin Godot (res://) | Type | Format | Source | Livré ? | Notes techniques |
|-----------------------|------|--------|--------|---------|------------------|
| — | — | — | — | — | Aucun asset binaire nouveau requis pour cette feature |

Cette feature ne requiert aucun fichier asset supplémentaire sous `assets/`. Toutes les ressources visuelles et physiques nouvelles sont des nœuds de scène Godot purs (pas de fichier `.glb`, `.png`, `.tres`, `.ogg`).

Détail des éléments de scène nouveaux (pas des assets au sens strict, mais listés pour exhaustivité) :

| Nœud / Ressource de scène | Type Godot | Emplacement | Notes |
|---------------------------|-----------|-------------|-------|
| `InteractionZone : Area3D` | Nœud de scène | enfant de `Car` dans `scenes/vehicles/car.tscn` | Zone de détection de proximité joueur |
| `InteractionZone/CollisionShape3D` | Nœud de scène | enfant de `InteractionZone` | `SphereShape3D` rayon 3.0 m |
| `GameState : Node` | Nœud de scène | enfant de `Main` dans `main.tscn` | script `res://src/core/game_state.gd` |
| `HUD : CanvasLayer` (optionnel) | Nœud de scène | enfant de `Main` dans `main.tscn` | overlay 2D, visible conditionnellement |
| `HUD/InteractLabel : Label` (optionnel) | Nœud de scène | enfant de `HUD` | texte `"E : Entrer"`, police par défaut Godot |

## Conventions de nommage

- snake_case pour tous les noms de fichiers et dossiers (inchangé depuis feature 01).
- Nœuds de scène en PascalCase (convention Godot).
- Scripts GDScript : `src/core/game_state.gd` pour `GameState`.
- Aucun suffixe de texture requis pour cette feature.

## Budget polycount / mémoire

| Catégorie | Impact feature 07 |
|-----------|-------------------|
| Polycount nouveau | 0 tris (aucun mesh ajouté) |
| Mémoire assets binaires | 0 octets (aucun fichier binaire ajouté) |
| `Area3D` + `SphereShape3D` | forme analytique Godot, 0 octets de mesh |
| `Label` 2D optionnel | ~200 octets de données de scène, police Godot par défaut |
| Script `game_state.gd` | quelques Ko de GDScript compilé |

Contrainte globale : cette feature n'alourdit pas le budget visuel.

## Mocks obligatoires en attendant les assets finaux

Aucun asset marqué "Livré ? = non" dans le tableau ci-dessus. Cette feature n'introduit aucun asset cible non livré.

Les nœuds de scène Godot listés ci-dessous remplacent la notion de "mock" pour cette feature : ils sont les représentations définitives des éléments visuels et physiques de la mécanique, sans asset binaire en attente.

| Elément fonctionnel | Nœud Godot | Forme | Dimensions | Couleur (hex) | Commentaire à inscrire |
|--------------------|------------|-------|------------|---------------|------------------------|
| Zone de détection de proximité | `Area3D` + `CollisionShape3D` (SphereShape3D) | sphère | rayon = 3.0 m | n/a (invisible) | `# Zone d'interaction joueur/voiture — rayon 3.0 m` |
| Prompt d'interaction (optionnel) | `CanvasLayer > Label` | texte 2D | police par défaut, taille 24 pt | blanc #ffffff sur fond semi-transparent | `# MOCK — à remplacer par res://assets/ui/hud/interact_prompt.tscn si un asset UI est commandé` |

L'`Area3D` de détection n'a pas de représentation visuelle en jeu (aucun `MeshInstance3D` associé). Elle est purement logique. Aucun mock primitif visuel n'est nécessaire.

## Hors-périmètre

- Sons d'interaction (ouverture/fermeture de portière, bruit de montée) : hors proto v0.1. Aucun fichier audio dans `assets/audio/sfx/` ne sera commandé pour cette feature.
- Texture ou sprite pour le prompt d'interaction (icône de touche E stylisée) : hors proto. La police par défaut Godot suffit.
- Modèle 3D intérieur de voiture (volant, siège conducteur visible) : hors proto. Le joueur disparaît simplement.
- Asset UI dédié (`res://assets/ui/hud/`) : ce dossier n'est pas formellement créé par cette feature. Si un asset UI est commandé plus tard (feature 08 ou polish), le bon de commande correspondant déclarera `assets/ui/hud/` comme dossier nouveau.
- Animation de transition entrée/sortie : hors proto v0.1.
