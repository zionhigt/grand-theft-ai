# Design 02 — Scène 3D minimale (sol + ciel + lumière + caméra fixe)

## Pitch (1 phrase)

Le joueur lance `main.tscn` et découvre pour la première fois un espace 3D vivant : un sol herbeux étendu sous un ciel dégradé bleu, baigné d'une lumière directionnelle chaude, vu depuis une caméra fixe légèrement en hauteur.

## Pourquoi cette feature (valeur joueur)

La feature 01 n'affiche qu'un fond uni gris — l'univers du jeu n'existe pas encore. Cette feature pose le cadre visuel minimal qui donnera l'impression d'un monde : horizon visible, ciel coloré, sol éclairé. C'est le premier moment où le joueur ressent qu'il est "quelque part". Sans ce cadre, les features suivantes (personnage, bâtiments, voitures) n'ont pas de monde dans lequel s'inscrire.

## Description détaillée

À l'issue de cette feature, `main.tscn` présente la scène suivante :

**Sol**
Un plan de 200 × 200 mètres centré sur l'origine (0, 0, 0), rendu avec un matériau de couleur verte sombre (#4a7c3a). Aucune interaction physique n'est requise à cette étape (pas de CollisionShape). Il sert uniquement de repère visuel d'échelle et d'horizon bas.

**Ciel**
Le `WorldEnvironment` existant (ajouté en feature 01 avec un fond uni) est remplacé par un ciel procédural Godot (`ProceduralSkyMaterial`) avec un dégradé visible :
- Couleur zénith (top) : #4ea0ff (bleu ciel franc)
- Couleur horizon : #c0d8ff (bleu très pâle, presque blanc)
- Couleur sol du ciel (sous l'horizon) : #4a7c3a (vert sombre, cohérent avec le sol du monde)

Ce ciel procédural constitue le mock du futur asset HDRI. Il est intégré inline dans la ressource `Environment` de la scène, en attendant un fichier `.tres` séparé.

**Lumière directionnelle**
Un nœud `DirectionalLight3D` simule le soleil :
- Position logique : nœud placé n'importe où (une lumière directionnelle n'a pas de position de source), rotation de -45° autour de l'axe X (rayon lumineux descendant en diagonale vers le sol, depuis l'avant-droit du joueur).
- Énergie : 1.0
- Couleur : #fff4e0 (blanc légèrement chaud, évoque la lumière de fin d'après-midi)
- Ombres désactivées pour cette feature (simplification — aucune performance à gérer encore).

**Caméra fixe**
La `Camera3D` héritée de la feature 01 (position `Vector3(0, 1, 5)`) est repositionnée pour donner une vue plongeante légère sur la scène :
- Position : `Vector3(0, 8, 15)` — 8 mètres de hauteur, 15 mètres en arrière de l'origine.
- Orientation : la caméra regarde vers l'origine `Vector3(0, 0, 0)`, ce qui correspond approximativement à une rotation de -25° à -30° autour de l'axe X. L'horizon est visible dans le tiers supérieur de l'écran.
- Propriété `current = true`.
- Aucun script — la caméra est entièrement statique.

La scène finale est purement visuelle. Aucune interaction, aucun gameplay.

## Contrôles / inputs

Aucun. Cette feature n'introduit aucun mapping de touche ni aucune réponse à un input clavier ou souris. Le jeu reste une image fixe animée uniquement par la lumière.

## Feedback joueur

**Visuel**
- Le joueur voit immédiatement un espace 3D reconnaissable : un sol vert qui s'étend jusqu'à l'horizon, un ciel dégradé du bleu pâle à l'horizon vers le bleu soutenu au zénith.
- La lumière directionnelle éclaire le sol et crée un contraste doux entre les zones tournées vers la source lumineuse et celles tournées ailleurs — le sol n'est plus une couleur plate uniforme.
- La caméra en hauteur donne une perspective légèrement aérienne qui évoque immédiatement le style GTA vue de dessus/derrière.

**Sonore**
Aucun son à cette étape.

**Mouvement de caméra**
Aucun — caméra statique.

## Règles et limites

| Paramètre | Valeur | Raison |
|-----------|--------|--------|
| Taille du sol | 200 × 200 m | Assez grand pour ne pas voir les bords depuis la caméra initiale, assez petit pour ne pas alourdir le rendu proto |
| Position caméra | Vector3(0, 8, 15) | Horizon visible dans le cadre, sol lisible, style "vue GTA" esquissée |
| Angle caméra (rotation X) | environ -28° (via look_at vers l'origine) | Horizon dans le tiers supérieur de l'écran |
| Énergie lumière | 1.0 | Valeur standard Godot, pas de surexposition |
| Ombres | désactivées | Simplification proto — à activer en feature 05 si nécessaire |
| Couleur sol (mock) | #4a7c3a | Vert sombre lisible, évoque une prairie urbaine |
| Top sky | #4ea0ff | Bleu ciel journée claire |
| Horizon sky | #c0d8ff | Transition douce, pas de rupture brutale |
| Ground sky | #4a7c3a | Cohérence avec la couleur du sol réel |

## Dépendances de design

- **Feature 01 — Bootstrap projet** : fournit `main.tscn` avec le nœud racine `Node3D`, une `Camera3D` et un `WorldEnvironment`. Cette feature 02 modifie ces trois nœuds et en ajoute deux (`MeshInstance3D` pour le sol, `DirectionalLight3D`).

## Hors-périmètre

- Toute physique sur le sol (CollisionShape, StaticBody3D) : feature 03 (le personnage a besoin d'un sol physique).
- Bâtiments, props, détails de ville : feature 05.
- Texture réelle du sol (image `.png` tileable) : à commander dans un bon de commande ultérieur ou dans la feature 05.
- Asset HDRI / skybox panoramique haute qualité : hors proto v0.1.
- Lumière ambiante (GI, SSAO, SSIL) : hors proto v0.1.
- Brouillard (Fog) : hors proto v0.1.
- Ombres portées : hors proto v0.1 (sauf décision contraire du specifier).
- Toute interaction clavier ou gameplay.
