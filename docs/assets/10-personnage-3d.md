# Bon de commande 10 — Personnage 3D Mixamo (remplacement du mock capsule)

## Résumé

3 fichiers GLB Mixamo : 1 mesh humanoïde (T-Pose, with skin), 1 animation idle, 1 animation walk. Destination : `assets/characters/player/`. Le mock CapsuleMesh rouge `#d94a4a` déjà en place dans `scenes/player/player.tscn` est conservé tel quel tant que les GLB ne sont pas livrés.

## Arborescence cible

```
assets/
├── characters/
│   └── player/                          (déclaré en feature 03 — étendu ici)
│       ├── player.glb                   (déclaré en feature 03 — non livré, obsolète après feature 10)
│       ├── player_body.glb              (nouveau — mesh humanoïde T-Pose, with skin)
│       ├── player_idle.glb              (nouveau — animation idle squelettale)
│       └── player_walk.glb             (nouveau — animation walk In Place squelettale)
├── vehicles/                            (déclaré en feature 06 — inchangé)
│   └── car/
│       ├── car_body.glb
│       └── wheel.glb
├── environment/                         (déclaré en feature 02 — inchangé)
│   └── ground/
│       ├── ground_plane.tres
│       └── ground_grass.tres
├── materials/                           (déclaré en feature 03 — inchangé)
│   ├── characters/
│   │   └── player_mock.tres
│   ├── city/
│   │   └── ...
│   └── vehicles/
│       ├── car_body_mock.tres
│       └── car_wheel_mock.tres
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

Dossiers modifiés par ce bon de commande :
- `assets/characters/player/` (existant depuis feature 03 — 3 nouveaux fichiers GLB y sont ajoutés)

Aucun dossier nouveau n'est créé.

## Liste détaillée des assets

| Chemin Godot (res://) | Type | Format | Source | Livré ? | Notes techniques |
|-----------------------|------|--------|--------|---------|------------------|
| `res://assets/characters/player/player_body.glb` | Mesh 3D humanoïde + squelette | .glb | Mixamo (personnage) | non | T-Pose, With Skin, FBX Binary converti en GLB ; hauteur ~1.8 m, origine aux pieds (y = 0) ; < 10 000 tris |
| `res://assets/characters/player/player_idle.glb` | Animation squelettale idle | .glb | Mixamo (animation) | non | With Skin, FBX Binary, 30 FPS, In Place si disponible ; boucle ; durée typique 2–4 s |
| `res://assets/characters/player/player_walk.glb` | Animation squelettale walk | .glb | Mixamo (animation) | non | With Skin, FBX Binary, 30 FPS, In Place obligatoire ; boucle ; durée typique 1–2 s (cycle complet) |

Note : `res://assets/characters/player/player.glb` déclaré en feature 03 est désormais obsolète après livraison de `player_body.glb`. Il sera retiré de la scène lors de l'implémentation de cette feature. Il reste listé dans les bons de commande précédents pour traçabilité.

## Conventions de nommage

- snake_case pour tous les noms de fichiers.
- Suffixe `_body` pour le mesh statique T-Pose (distingué des animations).
- Suffixes `_idle`, `_walk` pour les animations (extensible en `_run`, `_jump` pour les features futures).
- Les fichiers FBX déposés dans `assets/import/` portent exactement le même nom que le GLB attendu : `player_body.fbx`, `player_idle.fbx`, `player_walk.fbx`.
- Suffixes de texture (si fournies par Mixamo) : `_albedo`, `_normal`, `_roughness`, `_metallic`, `_ao`.

## Budget polycount / mémoire

| Asset | Budget proto | Notes |
|-------|-------------|-------|
| `player_body.glb` — mesh humanoïde | < 10 000 tris | Low-poly Mixamo standard. Les modèles Mixamo sont typiquement entre 5 000 et 15 000 tris selon le personnage choisi. Préférer un modèle < 10 000 tris pour laisser de la marge aux PNJ futurs. |
| `player_idle.glb` — animation | ~60 Ko estimé | Données d'animation squelettale, pas de mesh supplémentaire |
| `player_walk.glb` — animation | ~30 Ko estimé | Données d'animation squelettale, pas de mesh supplémentaire |
| Texture albedo (si fournie) | max 1 024 × 1 024 px | Mixamo fournit parfois une texture avec le mesh ; la garder telle quelle, ne pas dépasser 1 024 |

## Mocks obligatoires en attendant les assets finaux

Les GLB Mixamo ne sont pas encore livrés. Le mock existant (CapsuleMesh rouge `#d94a4a`) déjà en place dans `scenes/player/player.tscn` depuis la feature 03 est conservé sans modification tant que les GLB ne sont pas livrés.

| Asset cible | Nœud Godot mock (déjà en place) | Forme | Dimensions | Couleur (hex) | Commentaire à conserver |
|-------------|--------------------------------|-------|------------|---------------|------------------------|
| `res://assets/characters/player/player_body.glb` | `MeshInstance3D` avec `CapsuleMesh` (existant dans `scenes/player/player.tscn`) | capsule | h = 1.8 m, r = 0.4 m | #d94a4a | `# MOCK — à remplacer par res://assets/characters/player/player_body.glb` |
| `res://assets/characters/player/player_idle.glb` | `AnimationPlayer` présent mais sans piste (ou piste vide nommée "idle") | n/a | n/a | n/a | `# MOCK — animation idle absente, à remplir depuis res://assets/characters/player/player_idle.glb` |
| `res://assets/characters/player/player_walk.glb` | `AnimationPlayer` présent mais sans piste (ou piste vide nommée "walk") | n/a | n/a | n/a | `# MOCK — animation walk absente, à remplir depuis res://assets/characters/player/player_walk.glb` |

Règle : si `_anim_player == null` ou si l'animation demandée n'existe pas, `player_controller.gd` ignore silencieusement l'appel d'animation. Le jeu reste lançable et jouable (le personnage se déplace, sans animation visible tant que les GLB ne sont pas livrés).

## Section Mixamo — Instructions de téléchargement

| Nom du fichier GLB attendu | Nom du FBX à déposer | Catégorie Mixamo | Termes de recherche | Réglages export | Description |
|----------------------------|----------------------|-------------------|---------------------|-----------------|-------------|
| `player_body.glb` | `player_body.fbx` | Characters | "Kachujin", "Michelle", "Remy", "Adam", "Xbot", ou tout humanoïde low-poly | With Skin, FBX Binary, T-Pose | Mesh du personnage sans animation — choisir un personnage humanoïde, de préférence < 10 000 tris. Préférer un personnage avec une silhouette lisible de loin (GTA-like). |
| `player_idle.glb` | `player_idle.fbx` | Animations > Idle | "idle", "breathing idle", "standing idle" | With Skin, FBX Binary, 30 FPS, In Place si disponible | Animation idle debout — respiration légère. Durée recommandée : 2 à 4 secondes, boucle fluide. Utiliser le même personnage que pour `player_body.fbx` (sélectionner le personnage avant de chercher l'animation). |
| `player_walk.glb` | `player_walk.fbx` | Animations > Walking | "standard walk", "walking", "normal walk" | With Skin, FBX Binary, 30 FPS, **In Place obligatoire** | Animation de marche avant — le personnage marche sur place, le déplacement est géré par le script. In Place est impératif pour éviter le glissement visuel. Utiliser le même personnage que pour `player_body.fbx`. |

Règle de nommage obligatoire : le FBX déposé dans `assets/import/` doit porter **exactement le même nom** que le GLB attendu (même nom, extension `.fbx`).

Rappel workflow complet :
1. Sur [mixamo.com](https://www.mixamo.com), sélectionner d'abord le personnage (onglet "Characters").
2. Télécharger le mesh en T-Pose : Format = FBX Binary, Skin = With Skin → nommer `player_body.fbx`.
3. Sélectionner l'animation "idle" (onglet "Animations") sur le même personnage → nommer `player_idle.fbx`.
4. Sélectionner l'animation "walk" In Place → nommer `player_walk.fbx`.
5. Déposer les 3 FBX dans `assets/import/`.
6. Invoquer l'agent `mixamo` pour conversion et placement.

## Hors-périmètre

- Animations run, sprint, saut, atterrissage, mort : non commandées.
- AnimationTree avec blend / transitions douces : non commandé (transitions instantanées pour le proto).
- Textures custom supplémentaires au-delà de ce que Mixamo fournit : non commandées.
- PNJ réutilisant le même rig : feature ultérieure.
- Mesh intérieur de voiture (le joueur est invisible en voiture) : non commandé.
- Sons de pas synchronisés aux animations : non commandés.
- `player.glb` (déclaré en feature 03) : remplacé par `player_body.glb` — l'ancien chemin `res://assets/characters/player/player.glb` est considéré obsolète dès livraison de cette feature.
