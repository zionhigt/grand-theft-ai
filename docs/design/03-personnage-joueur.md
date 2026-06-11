# Design 03 — Personnage joueur déplaçable (ZQSD/WASD)

## Pitch (1 phrase)

Le joueur appuie sur une touche directionnelle et son personnage se déplace immédiatement dans le monde 3D, orienté dans la direction du mouvement, avec une collision solide contre le sol.

## Pourquoi cette feature (valeur joueur)

Le monde existe (feature 02) mais il est vide et inerte. Cette feature introduit la présence du joueur dans le monde : un corps visible, déplaçable, qui répond aux touches. C'est le premier moment d'agentivité — le joueur peut "être quelque part" et aller "vers quelque chose". Sans elle, aucune des features suivantes (caméra TP, entrée voiture, exploration de la ville) n'a de sens.

## Description détaillée

### Le personnage

Un personnage humanoïde représenté pour l'instant par une capsule colorée (mock). Il est instancié dans `main.tscn` à sa position de spawn, debout sur le sol.

Le personnage est un nœud `CharacterBody3D`. Il possède :
- un `CollisionShape3D` de forme `CapsuleShape3D` (hauteur 1.8 m, rayon 0.4 m) pour la physique ;
- un `MeshInstance3D` avec `CapsuleMesh` (mock visuel, même dimensions) ;
- un script `player_controller.gd` attaché au `CharacterBody3D`.

### Spawn du personnage

Le personnage apparaît au point `Vector3(0, 0.9, 0)` — soit les pieds posés exactement à y = 0 (surface du sol), l'origine du `CharacterBody3D` est au centre de la capsule donc décalée de +0.9 m en Y (moitié de la hauteur).

### Déplacement

Quand le joueur maintient une touche directionnelle, le personnage se déplace à **5 m/s** dans la direction correspondante, relativement à l'orientation du monde (pas encore de caméra TP en feature 03).

La direction de déplacement est calculée dans le plan horizontal (XZ). Le personnage ne peut pas voler ni sauter à ce stade.

La gravité de Godot (`ProjectSettings.gravity`) est appliquée en permanence pour maintenir le personnage au sol. Valeur : **9.8 m/s²** (valeur par défaut Godot).

La méthode `move_and_slide()` de `CharacterBody3D` gère les collisions contre le sol et les futurs obstacles.

### Orientation du personnage

Quand le joueur se déplace, le mesh du personnage (et le nœud entier) se tourne progressivement vers la direction du déplacement. La rotation se fait sur l'axe Y uniquement (pas d'inclinaison). Le personnage se retourne en **8 rotations/seconde** (rotation_speed = 8.0 rad/s), ce qui donne un effet de pivot naturel sans être brusque.

Quand le joueur relâche toutes les touches, le personnage s'arrête immédiatement (aucun glissement d'inertie à ce stade — le prototype vise la réactivité).

### États d'animation (visuels, pas de Spine/AnimTree)

À ce stade il n'y a pas d'animation squelettale. Les états sont conceptuels, tracés dans un `AnimationPlayer` vide ou une simple variable d'état :

- **Idle** : le joueur ne presse aucune touche directionnelle. Vitesse = 0. Le mesh reste immobile.
- **Walk** : le joueur presse au moins une touche directionnelle. Vitesse = 5 m/s. Le mesh avance dans la direction choisie.

### Collision avec le sol

Le sol de la feature 02 (`MeshInstance3D` avec `PlaneMesh`) ne possède pas de corps physique. La feature 03 ajoute un `StaticBody3D` + `CollisionShape3D` (forme `WorldBoundaryShape3D` ou `BoxShape3D` 200 × 0.1 × 200) sous le plan de sol, de sorte que le personnage s'y pose.

Le sol physique est ajouté directement dans `main.tscn` comme enfant du nœud sol existant (ou en nœud séparé `GroundCollider`), sans modifier les assets du bon de commande 02.

### Relation avec la caméra fixe (feature 02)

La `Camera3D` fixe de la feature 02 reste en place pour cette feature. Le joueur sera visible dans le champ de la caméra depuis sa position de spawn `Vector3(0, 0, 0)` et pourra se déplacer jusqu'aux bords du cadre. La caméra ne suit pas encore le joueur — ce sera la feature 04.

Le joueur peut sortir du champ de vision ; c'est attendu et acceptable pour le proto 03.

## Contrôles / inputs

Les actions Godot InputMap suivantes sont déclarées dans `project.godot` :

| Action Godot | Touches associées | Effet |
|---|---|---|
| `move_forward` | Z (AZERTY), W (QWERTY) | Déplacement vers l'avant (axe -Z monde) |
| `move_backward` | S | Déplacement vers l'arrière (axe +Z monde) |
| `move_left` | Q (AZERTY), A (QWERTY) | Déplacement vers la gauche (axe -X monde) |
| `move_right` | D | Déplacement vers la droite (axe +X monde) |

Les deux layouts AZERTY et QWERTY sont mappés simultanément sur les mêmes actions : `move_forward` accepte à la fois `KEY_Z` et `KEY_W`, `move_left` accepte à la fois `KEY_Q` et `KEY_A`. Ainsi le jeu fonctionne sur tout clavier sans configuration.

Aucune touche de saut. Aucune touche de sprint. Aucune souris.

## Feedback joueur

### Visuel

- Le personnage (capsule rouge vif `#d94a4a`) est visible dès le lancement, posé au centre du sol vert.
- Dès qu'une touche est pressée, le personnage se déplace sans délai perceptible.
- Le personnage pivote progressivement vers la direction de marche, ce qui renforce la sensation de présence physique.
- La caméra fixe permet de voir le personnage se déplacer dans l'espace ; lorsqu'il s'éloigne, sa taille décroît naturellement (perspective 3D).

### Sonore

Aucun son à cette étape.

### Mouvement de caméra

Aucun — la caméra reste fixe (feature 04).

## Règles et limites

| Paramètre | Valeur | Raison |
|-----------|--------|--------|
| Vitesse de déplacement | 5 m/s | Assez rapide pour traverser la scène visible en ~5 s, assez lent pour rester contrôlable |
| Vitesse de rotation | 8.0 rad/s | Pivot fluide sans être lent (< 1 s pour un demi-tour complet) |
| Gravité | 9.8 m/s² | Valeur par défaut Godot — cohérente avec la physique future des voitures |
| Inertie au sol | aucune | Le personnage s'arrête net à relâcher les touches — réactivité proto |
| Hauteur personnage (CollisionShape) | 1.8 m | Taille humaine standard |
| Rayon personnage (CollisionShape) | 0.4 m | Légèrement plus large que le réalisme pour éviter les coins de collision |
| Origine du CharacterBody3D | centre de la capsule, soit y = 0.9 m au spawn | Convention Godot CharacterBody3D |
| Spawn position | Vector3(0, 0.9, 0) | Pieds à y=0 (surface du sol) |
| Axe de rotation du mesh | Y uniquement | Pas d'inclinaison, mouvement plan |
| up_direction (CharacterBody3D) | Vector3(0, 1, 0) | Gravité verticale standard |
| floor_max_angle | 45° (π/4 rad) | Valeur par défaut Godot — tolérance aux petits reliefs |

## Dépendances de design

- **Feature 01 — Bootstrap projet** : fournit `project.godot` et `main.tscn` (nœud racine `Node3D`, `WorldEnvironment`, `Camera3D`).
- **Feature 02 — Scène 3D minimale** : fournit le sol (`MeshInstance3D` + `PlaneMesh`), le ciel procédural et la `DirectionalLight3D`. Cette feature 03 ajoute le corps physique du sol (StaticBody3D) et le nœud personnage dans la même scène `main.tscn`.

## Hors-périmètre

- Animations squelettales (marche, idle animée) : hors proto v0.1. Le mesh reste statique.
- Sprint (touche Shift) : à définir dans une feature ultérieure si nécessaire.
- Saut : hors périmètre — le proto n'a pas de plateforme ni d'escalier.
- Collision avec les bâtiments : feature 05 (les bâtiments n'existent pas encore). Les CollisionShape des bâtiments seront gérés dans le bon de commande 05.
- Orientation du personnage relative à la caméra (look direction caméra → mouvement) : sera introduit en feature 04 lorsque la caméra TP existera.
- Entrée dans un véhicule : feature 07.
- Sons de pas : hors proto v0.1.
- HUD (barre de vie, minimap, etc.) : hors proto v0.1.
