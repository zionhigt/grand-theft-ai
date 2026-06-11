# Design 08 — Conduite (accélérer, freiner, tourner)

## Pitch (1 phrase)

Quand le joueur est dans la voiture, il la pilote au clavier : accélération, freinage et direction sont appliqués directement à l'API physique native `VehicleBody3D` de Godot.

## Pourquoi cette feature (valeur joueur)

C'est la dernière brique du prototype v0.1. Sans elle, monter dans la voiture (feature 07) n'a aucun intérêt : le joueur se retrouve prisonnier d'un objet immobile. La conduite transforme la voiture en moyen de déplacement, boucle la promesse GTA minimale (se déplacer à pied ET en voiture dans une ville), et clôt la liste des critères du prototype jouable.

## Description détaillée

### Vue d'ensemble

Un script `CarController` est attaché au nœud `Car : VehicleBody3D` dans `scenes/vehicles/car.tscn`. Ce script lit les actions d'entrée de conduite (déclarées dans l'Input Map de `project.godot`) et les traduit en valeurs physiques via les propriétés natives `engine_force`, `brake` et `steering` du `VehicleBody3D`.

Le script n'est actif (ne lit les inputs) que lorsque `GameState.player_mode == GameState.PlayerMode.IN_VEHICLE`. Hors de ce mode, toutes les forces sont remises à zéro immédiatement pour que la voiture s'arrête naturellement.

### Accélération

L'action `drive_forward` (touche W ou Z) applique une force motrice positive sur l'axe avant du véhicule via `engine_force`. La force est constante pendant que la touche est maintenue : `engine_force = ENGINE_FORCE` (800.0 N). Lorsque la touche est relâchée et qu'aucune action de freinage n'est active, `engine_force` repasse à `0.0`. Aucune gestion de vitesse maximale explicite n'est nécessaire pour le proto : la résistance aérodynamique intégrée de Godot limite naturellement la vitesse.

### Freinage / marche arrière

L'action `drive_backward` (touche S) remplit deux rôles selon la vitesse courante :

- Si la voiture avance (vitesse linéaire positive dans le sens de déplacement) : `brake = BRAKE_FORCE` (20.0 N), `engine_force = 0.0`. La voiture décélère progressivement jusqu'à l'arrêt.
- Si la voiture est déjà arrêtée ou roule en marche arrière : `engine_force = -ENGINE_FORCE` (force négative), `brake = 0.0`. La voiture recule.

Pour le proto, la distinction avant/arrière est faite par un simple test sur le produit scalaire de la vitesse linéaire et de l'axe avant global du `VehicleBody3D` : si ce produit est positif et supérieur à un seuil (0.5 m/s), la voiture avance et on freine ; sinon, on recule.

### Direction

L'action `drive_left` (touche A ou Q) et `drive_right` (touche D) pilotent la propriété `steering` du `VehicleBody3D`. La valeur cible est ±`MAX_STEERING` (0.4 rad ≈ 22,9°). Pour éviter les changements de direction brutaux, `steering` est interpolé vers la valeur cible à chaque frame via `lerp(steering, target_steering, STEERING_SPEED * delta)`, où `STEERING_SPEED = 5.0`. Si aucune touche de direction n'est pressée, `steering` revient à `0.0` par la même interpolation (retour au neutre).

Les roues avant sont directrices (`use_as_steering = true` sur `WheelFrontLeft` et `WheelFrontRight` — défini en feature 06). Les roues arrière sont motrices (`use_as_traction = true` sur `WheelRearLeft` et `WheelRearRight`). Le `CarController` pilote uniquement les propriétés de haut niveau `steering` et `engine_force` du `VehicleBody3D` — Godot distribue automatiquement les forces aux bonnes roues.

### Activation conditionnelle

`CarController` déclare une référence au `GameState` (par `NodePath` ou par recherche dans l'arbre de scène). Dans `_physics_process(delta)`, la première instruction vérifie `game_state.player_mode`. Si le mode n'est pas `IN_VEHICLE`, le script force `engine_force = 0.0`, `brake = 0.0` et retourne sans traiter les inputs. Cela garantit que la voiture n'est jamais contrôlable accidentellement quand le joueur est à pied.

### Sortie de véhicule en mouvement

Le joueur peut appuyer sur E pour sortir du véhicule même lorsque celui-ci est en mouvement (logique déjà implémentée en feature 07 : `GameState._unhandled_input` appelle `exit_vehicle()` sans vérification de vitesse). Lors de `exit_vehicle()`, `game_state` repositionne le joueur à côté de la voiture et réactive le `PlayerController`. La vitesse de la voiture n'est pas forcée à zéro : elle continue sur sa lancée et décélère naturellement. Le joueur est téléporté à la position calculée (côté gauche, 2.5 m du centre, +1.0 m en Y), sans prise en compte de la vitesse du véhicule au moment de la sortie — acceptable pour le proto.

### Coexistence avec GameState (feature 07)

`CarController` ne remplace pas `GameState`. Il est son complément : `GameState` gère les transitions d'état (entrer/sortir), `CarController` gère la physique de conduite pendant l'état `IN_VEHICLE`. Les deux scripts coexistent dans la scène et communiquent par lecture de `game_state.player_mode`.

## Contrôles / inputs

| Touche | Action Godot | Effet |
|--------|-------------|-------|
| W ou Z | `drive_forward` | Accélérer (engine_force = +ENGINE_FORCE) |
| S | `drive_backward` | Freiner si avance ; reculer si arrêté ou recule déjà |
| A ou Q | `drive_left` | Tourner à gauche (steering interpolé vers +MAX_STEERING) |
| D | `drive_right` | Tourner à droite (steering interpolé vers -MAX_STEERING) |
| E | `interact` | Sortir de la voiture (géré par GameState, feature 07 — inchangé) |

Les actions `drive_forward`, `drive_backward`, `drive_left`, `drive_right` sont nouvelles et doivent être déclarées dans l'Input Map de `project.godot`. Les bindings clavier :
- `drive_forward` : physical_keycode W (87) ET physical_keycode Z (122) pour AZERTY/QWERTY
- `drive_backward` : physical_keycode S (83)
- `drive_left` : physical_keycode A (65) ET physical_keycode Q (113) pour AZERTY/QWERTY
- `drive_right` : physical_keycode D (68)

Note : ces actions sont distinctes des actions de déplacement du joueur à pied (`move_forward`, `move_backward`, `move_left`, `move_right`) pour éviter tout conflit et faciliter le remapping futur.

## Feedback joueur

### Visuel

- La voiture se déplace physiquement dans la scène : le sol défile, les bâtiments bougent en perspective (effets de déplacement natifs de la caméra troisième personne, feature 04).
- Les roues se rotation-nent grâce à la physique intégrée de Godot (`VehicleBody3D` oriente automatiquement les `VehicleWheel3D` en fonction du `steering` et de la vitesse).
- La caméra troisième personne (feature 04) suit le `VehicleBody3D` qui est sa cible depuis `enter_vehicle()` — elle suit les virages et accélérations via l'interpolation `lerp` déjà en place.
- Aucun effet visuel supplémentaire (particules, trails) n'est requis pour le proto.

### Sonore

Aucun son pour cette feature (proto v0.1). Sons moteur, crissements de pneus et klaxon sont hors périmètre.

### Caméra

Aucune modification du script `CameraController` (feature 04). La cible est déjà le `VehicleBody3D` depuis feature 07. L'interpolation `lerp` existante produit un suivi fluide de la voiture en mouvement. Si l'offset ou la distance de suivi sont insuffisants pour la conduite, c'est un ajustement de paramètre dans `CameraController`, pas un nouveau comportement — le developer peut l'ajuster sans sortir du périmètre.

## Règles et limites

| Paramètre | Valeur | Justification |
|-----------|--------|---------------|
| `ENGINE_FORCE` | 800.0 N | Force motrice sur une voiture de 1 200 kg. Accélération ≈ 0.67 m/s². Suffisant pour un déplacement perceptible en quelques secondes. Ajustable par le developer. |
| `BRAKE_FORCE` | 20.0 N | Freinage progressif. Valeur basse volontaire pour le proto (freinage doux, réaliste pour un débutant). |
| `MAX_STEERING` | 0.4 rad (≈ 22.9°) | Angle maximum du volant. Assez grand pour virer dans les rues de la ville proto sans être incontrôlable à haute vitesse. |
| `STEERING_SPEED` | 5.0 | Facteur `lerp` par seconde. Le volant met ~0.2 s à atteindre l'angle max et revient au neutre en ~0.2 s. |
| Seuil marche avant/arrière | 0.5 m/s | Vitesse minimale en direction avant pour déclencher le freinage plutôt que la marche arrière. En dessous de ce seuil, `drive_backward` engendre la marche arrière. |
| Vitesse maximale (implicite) | non bornée explicitement | La résistance physique de Godot (`VehicleBody3D` + friction roues) limite naturellement la vitesse. Pour le proto, aucun cap explicite. |
| Masse voiture | 1 200.0 kg | Définie en feature 06 — inchangée. |
| `wheel_friction_slip` | 10.5 | Défini en feature 06 — inchangé. Donne suffisamment d'adhérence pour un contrôle arcade correct. |
| Sortie en mouvement | autorisée | La voiture continue après la sortie ; le joueur est téléporté sans danger particulier pour le proto. |
| Nombre de véhicules | 1 | Hors proto : plusieurs voitures. `CarController` n'est instancié qu'une fois. |

## Dépendances de design

- **01 — Bootstrap** : projet Godot 4.6, Input Map accessible (`project.godot`).
- **02 — Scène 3D minimale** : `main.tscn` avec sol physique.
- **03 — Personnage joueur** : `Player : CharacterBody3D` avec `PlayerController`, `set_physics_process` et `set_process_input`.
- **04 — Caméra troisième personne** : `CameraRig` avec propriété `target` dynamique, interpolation `lerp`.
- **06 — Voiture** : `Car : VehicleBody3D` avec 4 `VehicleWheel3D` configurés (roues avant directrices, roues arrière motrices), masse 1 200 kg.
- **07 — Entrer / sortir véhicule** : `GameState` avec `PlayerMode { ON_FOOT, IN_VEHICLE }`, méthodes `enter_vehicle` / `exit_vehicle`. État `IN_VEHICLE` est la condition d'activation de `CarController`.

## Hors-périmètre

- Sons moteur, klaxon, crissements de pneus : hors proto v0.1. Aucun fichier audio.
- Compteur de vitesse, jauge de carburant, HUD de conduite avancé : hors proto v0.1.
- Dommages de collision (visuels ou physiques) : hors proto v0.1.
- Nitro, turbo, boost : hors proto.
- Contrôle à la manette / gamepad : hors proto v0.1 (clavier uniquement).
- Frein à main / dérapage (handbrake) : hors proto.
- Transmission (gear shift, régime moteur) : hors proto. Modèle simplifié à force constante.
- Animation du volant visible dans l'habitacle : hors proto (joueur invisible dans la voiture, feature 07).
- Plusieurs voitures conduisibles simultanément : hors proto v0.1.
- IA de conduite pour les PNJ : hors proto.
- Détection de sortie de route, ralentissement sur herbe : hors proto.
- Caméra spéciale conduite (champ de vision modifié, effet de vitesse) : hors proto. La caméra de feature 04 suffit.
