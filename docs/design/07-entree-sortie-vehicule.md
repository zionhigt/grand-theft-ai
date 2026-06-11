# Design 07 — Entrer / sortir d'un véhicule (touche E)

## Pitch (1 phrase)

Le joueur appuie sur E pour monter dans la voiture quand il est suffisamment proche, et appuie à nouveau sur E pour en descendre à côté.

## Pourquoi cette feature (valeur joueur)

Sans cette mécanique, la voiture introduite en feature 06 est un simple obstacle décoratif. L'entrée/sortie est le verrou qui transforme l'objet voiture en élément de gameplay interactif. C'est le prérequis immédiat de la feature 08 (conduite). Une fois cette feature en place, le joueur peut passer du mode piéton au mode conducteur et revenir, ce qui constitue le coeur de l'expérience GTA.

## Description détaillée

### Vue d'ensemble

La feature repose sur trois concepts : la détection de proximité, la possession du contrôleur actif, et la gestion de l'état global du jeu.

Un nœud central `GameState` (script GDScript, singleton ou nœud dans `main.tscn`) maintient l'état courant du mode joueur sous forme d'un enum `PlayerMode` à deux valeurs : `ON_FOOT` et `IN_VEHICLE`. Cet état conditionne quels contrôleurs sont actifs.

### Détection de proximité (zone d'interaction)

La voiture expose une zone d'interaction matérialisée par un `Area3D` nommé `InteractionZone`, enfant du `VehicleBody3D`. Cette zone est une sphère de rayon **3.0 m** centrée sur le nœud `VehicleBody3D`. Elle détecte l'entrée et la sortie du `CharacterBody3D` du joueur via les signaux `body_entered` et `body_exited`.

Quand le joueur est dans la zone, une variable booléenne `player_near` est mise à `true` sur le script de la voiture. Quand il en sort, elle repasse à `false`.

Cette approche `Area3D` est préférée à un test de distance manuel dans `_process` pour deux raisons : elle est testable unitairement (on peut vérifier les signaux Godot), et elle est alignée avec le paradigme événementiel de Godot.

### Touche E : logique de branchement

À chaque appui sur la touche `E` (action `interact` dans l'Input Map Godot), le script qui gère l'interaction évalue l'état courant :

- Si `PlayerMode == ON_FOOT` et `player_near == true` : déclencher l'entrée dans la voiture.
- Si `PlayerMode == IN_VEHICLE` : déclencher la sortie de la voiture.
- Sinon : aucune action (le joueur appuie sur E mais n'est pas assez proche — aucun feedback en v0.1).

L'appui sur E est détecté dans `_unhandled_input` ou `_input` du nœud `Main` (ou du script `GameState`), pas dans le script du joueur ni dans le script de la voiture séparément, afin de centraliser la logique de transition d'état.

### Entrer dans la voiture

Séquence lors de l'entrée :

1. `PlayerMode` passe à `IN_VEHICLE`.
2. Le script du joueur (`PlayerController`) est désactivé : `player.set_process_input(false)` et `player.set_physics_process(false)`. Le `CharacterBody3D` du joueur est rendu invisible : `player_mesh.visible = false`. Le corps physique du joueur ne doit pas interférer avec la physique de la voiture — il est masqué mais reste dans l'arbre de scène.
3. La `CameraRig` reçoit une nouvelle cible : elle commence à suivre le `VehicleBody3D` au lieu du `CharacterBody3D`. La cible est changée dynamiquement via une propriété `target` exposée par le script `CameraController` (déjà prévu en feature 04).
4. Les inputs de conduite deviennent actifs (feature 08 les utilisera : en feature 07, la voiture ne bouge pas encore sous les inputs du joueur, mais la structure de possession est en place).

### Sortir de la voiture

Séquence lors de la sortie :

1. Calcul de la position de spawn du joueur : côté gauche de la voiture, à une distance de **2.5 m** du centre du `VehicleBody3D` sur l'axe local Z (axe de largeur). Si cette position est à l'intérieur d'un `CollisionShape3D` (bâtiment, mur), la même logique tente le côté droit. En proto v0.1, on prend directement le côté gauche sans test d'obstruction — la ville est suffisamment ouverte.
2. Le joueur est repositionné à la position calculée, décalé vers le haut de **1.0 m** (hauteur de spawn piéton au-dessus du sol, identique au spawn initial défini en feature 03).
3. Le script du joueur (`PlayerController`) est réactivé : `player.set_process_input(true)` et `player.set_physics_process(true)`. Le mesh du joueur redevient visible.
4. La `CameraRig` reprend le joueur comme cible (`target = player`).
5. `PlayerMode` repasse à `ON_FOOT`.

### Nœud GameState et structure de scène

Un nœud `GameState` de type `Node` avec script `res://src/core/game_state.gd` est ajouté comme enfant de `Main` dans `main.tscn`. Il expose :

- `var player_mode: PlayerMode` (enum)
- `func enter_vehicle(car: VehicleBody3D) -> void`
- `func exit_vehicle() -> void`
- `var current_vehicle: VehicleBody3D` (null si `ON_FOOT`)

Ce nœud est la source de vérité de l'état de possession. Il ne gère pas la physique ni les inputs directement : il appelle les méthodes des autres nœuds (`Player`, `CameraRig`, `Car`).

### Prompt d'interaction (nice-to-have v0.1)

Afficher un `Label` 2D en overlay ("E : Entrer") quand `player_near == true` et `PlayerMode == ON_FOOT` est un **nice-to-have** pour v0.1. Ce feedback améliore la lisibilité mais n'est pas bloquant pour la mécanique. Si ce label est implémenté en feature 07, il est rendu via un `CanvasLayer > Label` dans la scène principale, avec le texte "E : Entrer" visible uniquement quand la condition est vraie. Aucune image PNG n'est requise : police par défaut Godot suffit pour le proto.

Cette partie est **optionnelle** pour le developer en feature 07. Si elle est implémentée, elle figure dans la spec 07. Sinon, elle est reportée.

## Contrôles / inputs

| Touche | Action Godot | Effet |
|--------|-------------|-------|
| E | `interact` | Si proche de la voiture et à pied : entrer dans la voiture. Si dans la voiture : en sortir. |
| Aucune autre touche nouvelle | — | Les inputs ZQSD/WASD et souris restent assignés aux actions existantes. |

L'action `interact` est déclarée dans l'Input Map Godot (`project.godot`) avec la touche `E` comme binding principal.

## Feedback joueur

### Visuel

- Lors de l'entrée : le mesh du joueur disparaît (visible = false). La caméra glisse doucement vers la voiture comme nouvelle cible (le `CameraController` fait déjà une interpolation via `lerp` en feature 04 — aucune modification requise, juste un changement de cible).
- Lors de la sortie : le mesh du joueur réapparaît à côté de la voiture. La caméra reprend le joueur.
- Prompt optionnel : un `Label` 2D blanc sur fond semi-transparent noir, texte `"E : Entrer"`, position en bas au centre de l'écran, visible uniquement quand `player_near && player_mode == ON_FOOT`.

### Sonore

Aucun son pour cette feature (proto v0.1). Les sons d'ouverture/fermeture de portière sont hors périmètre.

### Caméra

La `CameraRig` (feature 04) suit déjà sa propriété `target` via `lerp`. Changer `target` de `Player` à `Car` et inversement suffit. Pas de modification du script `CameraController` si sa propriété `target` est déjà assignable dynamiquement.

## Règles et limites

| Paramètre | Valeur | Justification |
|-----------|--------|---------------|
| Rayon de la zone d'interaction (`InteractionZone`) | 3.0 m | Assez grand pour que le joueur n'ait pas à être collé à la voiture, assez petit pour être intentionnel. Voiture = 4.0 × 2.0 m, donc 3.0 m couvre tout le périmètre carrosserie + un pas de recul. |
| Distance de spawn à la sortie (côté gauche) | 2.5 m du centre, axe Z local | Suffit pour dégager le joueur de la carrosserie (largeur = 2.0 m, demi-largeur = 1.0 m, marge = 1.5 m). |
| Hauteur de spawn joueur à la sortie | +1.0 m sur l'axe Y mondial | Identique au spawn initial (feature 03) — garantit que le joueur n'est pas sous le sol. |
| Délai entre deux appuis sur E | 0 (aucun cooldown) | Pour le proto, un seul véhicule, la double-pression accidentelle est improbable. Un cooldown peut être ajouté en polish. |
| Visibilité du joueur dans la voiture | mesh invisible, physique désactivée | Simplifié : pas d'animation d'assise. Le joueur "disparaît" dans la voiture (acceptable pour le proto). |
| Nombre de véhicules interactifs | 1 (unique instance de `car.tscn`) | Hors proto : plusieurs voitures avec logique de sélection de la plus proche. |

## Dépendances de design

- **01 — Bootstrap** : projet Godot 4.6 opérationnel, Input Map accessible.
- **02 — Scène 3D minimale** : `main.tscn` avec sol physique.
- **03 — Personnage joueur** : `Player : CharacterBody3D` avec script `PlayerController`, spawn à `Vector3(0, 0.9, 0)`.
- **04 — Caméra troisième personne** : `CameraRig` avec propriété `target` dynamiquement assignable.
- **06 — Voiture** : `Car : VehicleBody3D` dans `main.tscn`, scène `scenes/vehicles/car.tscn`.

## Hors-périmètre

- Conduite (accélérer, freiner, tourner) : feature 08. En feature 07, monter dans la voiture ne la fait pas bouger sous les inputs du joueur.
- Sons de portière, d'entrée, de sortie : hors proto v0.1.
- Animation du joueur s'asseyant : hors proto v0.1. Le joueur disparaît sans transition.
- Sélection de la voiture la plus proche quand plusieurs voitures sont présentes : hors proto v0.1.
- Cinématique d'entrée (caméra qui s'approche, porte qui s'ouvre) : hors proto.
- Affichage d'une jauge de carburant ou d'un compteur de vitesse : feature 08 ou hors proto.
- PNJ pouvant occuper la voiture : hors proto.
- Verrouillage de la voiture (impossible d'y entrer si déjà volée par un PNJ) : hors proto.
- Dommages de collision lors de la sortie : hors proto.
