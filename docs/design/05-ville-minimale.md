# Design 05 — Ville minimale (sol étendu + bâtiments cubiques)

## Pitch (1 phrase)

Le joueur explore un environnement urbain embryonnaire : huit bâtiments cubiques gris et beige dispersés autour du point de spawn, avec lesquels il entre en collision physique, donnant pour la première fois la sensation d'évoluer dans une ville.

## Pourquoi cette feature (valeur joueur)

Le monde existe (feature 02), le personnage s'y déplace (feature 03), la caméra le suit (feature 04) — mais l'espace est entièrement vide. Sans repères architecturaux, il est impossible de percevoir sa propre vitesse, sa position relative ou l'échelle de l'environnement. Les bâtiments cubiques remplissent trois rôles simultanés : repères visuels d'échelle, obstacles physiques qui rendent le déplacement tactiquement intéressant, et premières briques d'une ville crédible. C'est le passage d'un terrain vague à un quartier.

## Description détaillée

### Sol

Le `PlaneMesh` 200 × 200 m vert de la feature 02 est conservé tel quel — il n'est pas remplacé ni agrandi. La feature 05 n'ajoute pas de nouveau sol.

### Bâtiments

Huit bâtiments cubiques (mocks `BoxMesh` + `StaticBody3D` + `BoxShape3D`) sont disposés manuellement autour de l'origine. Chaque bâtiment est un nœud `StaticBody3D` enfant d'une scène dédiée `scenes/city/city.tscn`. Cette scène est instanciée dans `main.tscn` comme enfant du nœud racine `Node3D`.

Chaque bâtiment est structuré ainsi :

```
StaticBody3D  (nom : BatimentN)
  CollisionShape3D
    shape = BoxShape3D
      size = Vector3(largeur, hauteur, profondeur)   # en mètres
  MeshInstance3D
    mesh = BoxMesh
      size = Vector3(largeur, hauteur, profondeur)
    material_override = StandardMaterial3D
      albedo_color = <couleur hex>
    position = Vector3(0, hauteur/2, 0)   # origine du mesh au bas du bâtiment
  position = Vector3(x, 0, z)   # position au sol
# MOCK — à remplacer par res://assets/city/buildings/batiment_N.glb
```

L'origine du `StaticBody3D` est à y = 0 (niveau du sol). Le `MeshInstance3D` est décalé de `hauteur/2` en Y pour que le bâtiment repose sur le sol sans s'enfoncer.

### Disposition des bâtiments

Les positions sont choisies manuellement pour simuler un bloc urbain dispersé autour du point de spawn (0, 0, 0), en laissant un espace libre d'au moins 10 m autour du spawn pour que le joueur ne spawn pas à l'intérieur d'un bâtiment.

| Bâtiment | Dimensions (l × h × p en m) | Position XZ (centre au sol) | Couleur | Description visuelle |
|----------|-----------------------------|-----------------------------|---------|----------------------|
| Batiment1 | 6 × 12 × 6 | (20, 0, 20) | #8a8a8a | Tour résidentielle grise |
| Batiment2 | 8 × 8 × 8 | (-25, 0, 15) | #b0a090 | Bloc beige trapu |
| Batiment3 | 5 × 6 × 10 | (30, 0, -20) | #9a9a9a | Immeuble de bureau gris clair |
| Batiment4 | 10 × 5 × 6 | (-15, 0, -30) | #c8b89a | Entrepôt beige allongé |
| Batiment5 | 6 × 10 × 6 | (40, 0, 5) | #7a7a7a | Tour grise foncée |
| Batiment6 | 7 × 7 × 7 | (-40, 0, -10) | #b8a888 | Bâtiment commercial beige |
| Batiment7 | 4 × 14 × 4 | (10, 0, -40) | #888888 | Gratte-ciel étroit gris |
| Batiment8 | 12 × 4 × 5 | (-20, 0, 35) | #c0b0a0 | Bâtiment bas étendu beige clair |

Toutes les positions sont en mètres depuis l'origine. La hauteur Y du `StaticBody3D` est 0 (posé sur le sol) ; le mesh est décalé de hauteur/2 en Y.

### Scène `city.tscn`

La scène `scenes/city/city.tscn` contient :
- un nœud racine `Node3D` nommé `City` ;
- les huit nœuds `StaticBody3D` enfants directs, chacun nommé `BatimentN` (N de 1 à 8).

Cette scène est instanciée dans `main.tscn` via un nœud `City` ajouté comme enfant du nœud racine, après les nœuds existants (sol, lumière, WorldEnvironment, joueur).

### Collision

Chaque bâtiment possède un `CollisionShape3D` avec un `BoxShape3D` de dimensions identiques au `BoxMesh`. Le joueur (CharacterBody3D, feature 03) ne peut donc pas traverser les bâtiments. La méthode `move_and_slide()` gère les rebonds de surface.

### Ombres

Les ombres restent désactivées sur la `DirectionalLight3D` pour cette feature (cohérence avec la feature 02). Elles pourront être activées dans une feature ultérieure si les performances le permettent.

## Contrôles / inputs

Aucun nouveau mapping de touche. Les contrôles du personnage (ZQSD/WASD, feature 03) restent inchangés. Le joueur constate que ses déplacements sont bloqués par les murs des bâtiments.

## Feedback joueur

### Visuel

- Dès le lancement, le joueur voit des masses cubiques colorées émerger du sol autour de lui, donnant immédiatement une impression de quartier urbain primitif.
- La hauteur variable des bâtiments (4 m à 14 m) crée une silhouette urbaine reconnaissable depuis n'importe quelle direction.
- Quand le joueur marche vers un bâtiment et s'y cogne, le personnage s'arrête net — preuve visuelle que les bâtiments sont physiquement solides.
- La caméra troisième personne (feature 04) passe derrière les bâtiments lorsque le joueur les longe, renforçant la perception de volume.

### Sonore

Aucun son à cette étape.

### Mouvement de caméra

Inchangé — la caméra TP de la feature 04 continue de fonctionner exactement comme avant. Aucune gestion d'occlusion ni de transparence des bâtiments n'est requise pour ce proto.

## Règles et limites

| Paramètre | Valeur | Raison |
|-----------|--------|--------|
| Nombre de bâtiments | 8 | Assez pour donner une impression de ville, assez peu pour rester léger |
| Hauteur minimale bâtiment | 4 m | Visible à l'écran depuis la caméra TP |
| Hauteur maximale bâtiment | 14 m | Imposant sans être disproportionné par rapport au personnage 1.8 m |
| Dimensions minimales au sol | 4 × 4 m | Assez grand pour bloquer physiquement le personnage (rayon 0.4 m) |
| Distance minimale au spawn | 10 m | Le joueur ne spawne pas dans un bâtiment |
| Distance maximale depuis l'origine | 50 m | Les bâtiments restent visibles depuis le spawn |
| Origine StaticBody3D | y = 0 (niveau du sol) | Le bâtiment repose sur le sol sans flotter ni s'enfoncer |
| Décalage mesh Y | hauteur / 2 | Centre du BoxMesh à mi-hauteur pour aligner le bas sur le sol |
| Ombres | désactivées | Cohérence avec feature 02 — simplification proto |
| Physique bâtiments | StaticBody3D + BoxShape3D | Suffisant pour bloquer CharacterBody3D et le futur VehicleBody3D |
| Scène dédiée | `scenes/city/city.tscn` | Séparation claire entre environnement et personnage/caméra dans `main.tscn` |

## Dépendances de design

- **Feature 01 — Bootstrap projet** : fournit `main.tscn` et `project.godot`.
- **Feature 02 — Scène 3D minimale** : fournit le sol `PlaneMesh` 200 × 200 m, le ciel et la lumière directionnelle. La feature 05 instancie `city.tscn` dans la même `main.tscn` sans modifier ces éléments.
- **Feature 03 — Personnage joueur déplaçable** : le `CharacterBody3D` du joueur est celui qui entre en collision avec les `StaticBody3D` des bâtiments. Le comportement de collision est intégralement géré par `move_and_slide()` déjà implémenté.
- **Feature 04 — Caméra troisième personne** : la caméra TP suit le joueur dans la ville. Aucune modification de la caméra n'est requise par cette feature.

## Hors-périmètre

- Génération procédurale de ville : hors proto v0.1 — les positions sont choisies manuellement.
- Textures de façade (brique, béton, verre) : hors proto v0.1 — couleurs flat uniquement.
- Toits détaillés, corniches, fenêtres : hors proto v0.1 — BoxMesh brut uniquement.
- Routes, trottoirs, marquages au sol : hors proto v0.1.
- Éclairage de nuit, lampadaires : hors proto v0.1.
- LOD (Level of Detail) : hors proto v0.1.
- Occlusion culling ou transparence caméra (caméra passant dans les murs) : hors proto v0.1.
- Plus de 8 bâtiments : hors proto v0.1.
- Props de ville (bancs, poubelles, arbres) : hors proto v0.1.
- Collisions entre la future voiture (feature 06) et les bâtiments : les `StaticBody3D` posés ici fonctionneront automatiquement avec le `VehicleBody3D` sans modification.
