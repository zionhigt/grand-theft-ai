# Design 18 — Refonte complète du véhicule

## Pitch (1 phrase)

Réécriture from scratch du véhicule : le joueur appuie sur E pour entrer dans la voiture, conduit avec WASD/ZQSD, et appuie à nouveau sur E pour sortir — le tout sans les régressions accumulées par les corrections successives des features 06 à 17.

## Pourquoi cette feature (valeur joueur)

Après 12 itérations correctrices (features 06 à 17), le véhicule reste non fonctionnel : bugs d'orientation, physique instable, interactions entrée/sortie cassées, roues fantômes. Continuer à patcher le code existant est une impasse. Cette feature efface cette dette technique et livre un véhicule jouable, fiable et maintenable.

La valeur joueur est immédiate : pour la première fois depuis le début du projet, le joueur peut entrer dans la voiture, la conduire et en sortir sans planter le jeu.

## Ce que cette feature remplace

Les features suivantes sont **supersédées** et leur implémentation (scripts, scènes, tests) sera intégralement remplacée par cette feature 18 :

| Feature | Titre | Statut après feature 18 |
|---------|-------|------------------------|
| 06 | Voiture (mesh + corps physique de base) | supersédée |
| 07 | Entrer / sortir d'un véhicule (touche E) | supersédée |
| 08 | Conduite (accélérer, freiner, tourner) | supersédée |
| 13 | Intégration carrosserie GLB propre | supersédée |
| 14 | Calibration physique véhicule | supersédée |
| 15 | Correction géométrie roues VehicleBody3D | supersédée |
| 16 | Suppression des WheelMesh fantômes | supersédée |
| 17 | Corrections orientation GLB, vitesse moteur, frein | supersédée |

Les tests de ces features (test_06, test_07, test_08, test_14, test_15, test_16, test_17) sont **supprimés** par l'agent `tester`, qui créera un unique fichier `tests/test_18_refonte_vehicule.gd` couvrant l'ensemble des comportements véhicule.

## Description détaillée

### Architecture cible

La scène véhicule est reconstruite proprement autour d'un `VehicleBody3D`. Elle comprend :

- **`VehicleBody3D`** : racine physique, masse 1200 kg. **Pas de script sur ce nœud** — le script `car_controller.gd` vit dans `main.tscn` comme nœud séparé, pas sur la voiture.
- **`CarBodyMesh` (`MeshInstance3D`)** : affiche le mesh de carrosserie. Charge `car_body.glb` au runtime via `preload()` dans `_ready()`. Fallback BoxMesh si le GLB n'est pas trouvé.
- **Quatre `VehicleWheel3D`** : WheelFrontLeft, WheelFrontRight, WheelRearLeft, WheelRearRight. Pas de `MeshInstance3D` enfant (les roues visuelles sont intégrées dans `car_body.glb`).
- **`PlayerExitPoint` (`Marker3D`)** : positionné à 2.5 m sur l'axe +X (côté conducteur) et à 0.5 m de hauteur. Le joueur y réapparaît à la sortie du véhicule.

### Entrée dans le véhicule

1. Lorsque le joueur presse E et qu'un `VehicleBody3D` est à moins de 4 m, le personnage est **masqué** (`visible = false`) et **détaché** de l'arbre physique (collision désactivée).
2. Le signal `entered_vehicle` est émis.
3. La caméra orbitale bascule sa cible du personnage vers la voiture. Le `target` de la caméra est mis à jour en GDScript sans recourir à l'éditeur.
4. Le joueur prend le contrôle du `VehicleBody3D` : les inputs WASD/ZQSD sont redirigés vers `car_controller.gd`.

### Conduite

Les inputs sont lus dans `_physics_process()` de `car_controller.gd` :

- **Z / W** (`drive_forward`) : `engine_force = ENGINE_FORCE` (accélération avant)
- **S** (`drive_backward`) + vitesse ≥ 0.5 m/s : `brake = BRAKE_FORCE`, `engine_force = 0` (freinage)
- **S** (`drive_backward`) + vitesse < 0.5 m/s : `engine_force = -ENGINE_FORCE`, `brake = 0` (marche arrière)
- **Q / A** (`drive_left`) : interpolation `steering` vers `+MAX_STEERING` (braquage gauche)
- **D** (`drive_right`) : interpolation `steering` vers `-MAX_STEERING` (braquage droite)
- Aucune touche directionnelle : `steering` revient progressivement à 0, `engine_force = 0`

### Paramètres physiques

| Paramètre | Valeur | Unité |
|-----------|--------|-------|
| Masse véhicule | 1200 | kg |
| `ENGINE_FORCE` | 8000 | N |
| `BRAKE_FORCE` | 80 | N |
| `MAX_STEERING` | 0.4 | radians (~22.9°) |
| `STEERING_SPEED` | 5.0 | (facteur lerp) |
| `FORWARD_SPEED_THRESHOLD` | 0.5 | m/s |
| Empattement (axe Z) | 2.0 | m (±1.0 m avant/arrière) |
| Voie (axe X) | 1.6 | m (demi-voie : ±0.8 m) |
| Position Y des roues | -0.5 | m (sous le centre du VehicleBody3D) |
| `suspension_stiffness` | 5.88 | valeur de référence démo Godot 4 (⚠ ne pas utiliser N/m) |
| `wheel_rest_length` | 0.25 | m |
| `suspension_travel` | 0.2 | m |
| `damping_compression` | 0.83 | |
| `damping_relaxation` | 0.88 | |
| `suspension_max_force` | 6000 | N |
| `wheel_friction_slip` | 10.5 | |
| Rayon roue (physique) | 0.35 | m |

### Sortie du véhicule

1. Le joueur presse E depuis l'intérieur du véhicule.
2. Le personnage est repositionné à `PlayerExitPoint` (2.5 m sur +X, hauteur 0.5 m par rapport au sol).
3. Le personnage redevient visible, sa collision est réactivée.
4. La caméra orbitale rebascule sa cible sur le personnage.
5. Le signal `exited_vehicle` est émis.

### Intégration de `car_body.glb`

Le GLB est chargé par code dans `_ready()` de `car_visuals.gd` (script attaché au nœud `CarVisuals` dans `car.tscn`) :

```
const CAR_BODY_GLB = "res://assets/vehicles/car/car_body.glb"
```

- Nœud racine du GLB : `car_body` (ou équivalent — le developer doit inspecter au runtime si nécessaire).
- Le GLB est instancié et ajouté comme enfant de `CarBodyMesh`.
- Rotation locale appliquée au GLB : `rotation_degrees.y = -90.0` pour aligner le nez du modèle (axe -X du GLB) avec la direction -Z du `VehicleBody3D`.
- Scale : ajusté automatiquement via AABB pour que la longueur totale du modèle soit approximativement 4.0 m.
- Si le GLB est introuvable au runtime (fichier absent), le `CarBodyMesh` reste avec son BoxMesh fallback et log un avertissement : `push_warning("car_body.glb introuvable — mock BoxMesh actif")`.

## Contrôles / inputs

| Touche | Mode piéton | Mode conducteur |
|--------|------------|-----------------|
| Z / W | Avancer | Accélérer |
| S | Reculer | Freiner / marche arrière |
| Q / A | Aller à gauche | Braquer gauche |
| D | Aller à droite | Braquer droite |
| E | Entrer dans le véhicule proche (<4 m) | Sortir du véhicule |
| Clic droit souris | Aligner personnage / caméra | Réinitialiser caméra derrière capot |
| Molette souris | Zoom caméra | Zoom caméra |

## Feedback joueur

- **Entrée** : le personnage disparaît instantanément, la caméra glisse en douceur vers la voiture (interpolation sur 0.2 s).
- **Conduite** : la voiture répond immédiatement à la première frame d'input. L'accélération est perceptible dès la pression de Z/W. Le braquage est progressif et proportionnel au temps de maintien de la touche (clamp sur `MAX_STEERING_ANGLE`).
- **Freinage** : la décélération est nette, visible en 2–3 secondes depuis 60 km/h.
- **Sortie** : le personnage réapparaît à gauche de la voiture, la caméra rebascule immédiatement.
- **Fallback mock** : si `car_body.glb` est absent, un avertissement apparaît dans la console Godot et un BoxMesh rouge est visible — le jeu reste jouable.

## Règles et limites

- La détection d'entrée utilise une `Area3D` ou un calcul de distance directe (distance au `VehicleBody3D` < 4 m) — le specifier choisit l'implémentation.
- Un seul véhicule dans la scène pour le proto v0.1.
- La vitesse n'est pas affichée (pas de HUD dans cette feature).
- Pas d'animation de rotation des roues visuelles.
- Le joueur ne peut pas entrer dans le véhicule si le véhicule est en mouvement (vitesse > 2 m/s) — sécurité anti-bug.
- Le joueur ne peut pas sortir du véhicule si la vitesse est > 10 m/s — sécurité anti-projectile.

## Dépendances de design

- **02** — Scène 3D minimale : fournit le sol et l'environnement physique.
- **03** — Personnage joueur déplaçable : fournit le `CharacterBody3D` du joueur et ses contrôles.
- **04 / 09 / 11 / 12** — Caméra orbitale et déplacement camera-relatif : la caméra doit pouvoir changer de cible dynamiquement.

## Hors-périmètre

- Animation de rotation des roues visuelles en fonction de la vitesse.
- Son moteur (SFX) — feature ultérieure.
- HUD vitesse — feature ultérieure.
- PNJ conducteurs ou véhicules supplémentaires.
- Dommages/collisions destructibles.
- Physique avancée (anti-roll bar, centre de gravité variable).
- Suppression physique du fichier `wheel.glb` du disque (rôle de l'agent `mixamo` uniquement).
