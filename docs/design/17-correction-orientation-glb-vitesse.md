# Design 17 — Corrections véhicule : orientation GLB, vitesse moteur, frein

## Pitch (1 phrase)

Corriger trois bugs de tuning sur la voiture : le modèle GLB est affiché à l'envers (rotation Y +90° au lieu de -90°), le moteur est trop faible (4000 N au lieu de 8000 N) et le frein est quasi nul (20 N au lieu de 80 N).

## Pourquoi cette feature (valeur joueur)

Sans ces corrections, le jeu est injouable en véhicule :

- La voiture semble "inclinée" ou orientée à l'envers — le joueur voit la porte avant passager au lieu du capot depuis la vue caméra par défaut.
- La voiture accélère si lentement que la conduite est décevante et peu réactive.
- Le frein n'a aucun effet mesurable : impossible de ralentir ou de s'arrêter proprement.

Ces trois bugs ont la même racine que les corrections précédentes (features 13–16) : des constantes de départ mal calibrées et une rotation d'import GLB incorrecte.

## Description détaillée

### Bug 1 — Rotation GLB incorrecte (origine des bugs 2 et 3 visuels)

Le fichier `car_body.glb` a son axe avant orienté vers **-X** (nez du modèle dans la direction -X dans l'espace du GLB). Le nœud `VehicleBody3D` avance dans la direction **-Z** de Godot.

Pour aligner -X → -Z, il faut une rotation de **-90°** autour de Y.

La valeur actuellement codée est `+90°`, ce qui aligne -X → **+Z**, c'est-à-dire que le nez pointe vers l'arrière du VehicleBody3D. Résultat visible : le modèle est rendu à l'envers ; la caméra orbitale au yaw neutre (0°) regarde vers +Z et voit donc la porte avant passager au lieu du capot.

Fichier concerné : `src/vehicles/car_visuals.gd`, fonction `_charger_carrosserie()`.

Correction : `instance.rotation_degrees.y = -90.0`

### Bug 2 — Moteur trop faible

`ENGINE_FORCE = 4000 N` pour une masse de 1200 kg donne une accélération de 3.3 m/s². Pour un jeu arcade de style GTA, la cible est 0→100 km/h en environ 3 secondes, soit ~9.3 m/s² → ENGINE_FORCE ≈ 8000–11 000 N.

La correction retenue est `ENGINE_FORCE = 8000.0 N`, équivalent à ~6.7 m/s², ce qui offre une sensation arcade sans être irréaliste.

Fichier concerné : `src/vehicles/car_controller.gd`.

### Bug 3 — Frein quasi nul

`BRAKE_FORCE = 20 N` applique une décélération de 0.017 m/s² — imperceptible. Un freinage arcade efficace nécessite une décélération de l'ordre de 6–10 m/s², soit `BRAKE_FORCE ≈ 8 000–12 000 N`. La correction retenue est `BRAKE_FORCE = 80.0` selon la convention GDScript/VehicleBody3D où la valeur est une pression de frein normalisée (0–1 scale interne Godot), ou si l'implémentation utilise une force brute, le specifier précisera l'unité exacte.

Note : le `specifier` doit vérifier l'unité de `BRAKE_FORCE` dans `src/vehicles/car_controller.gd` — si c'est une force en Newton, la valeur correcte est ~8000 ; si c'est un facteur adimensionnel, elle doit être ajustée en conséquence. Le diagnostic initial propose 80.0 comme point de départ raisonnable pour une correction significative.

Fichier concerné : `src/vehicles/car_controller.gd`.

## Contrôles / inputs

Aucune modification des contrôles. Les touches restent :

| Touche | Effet |
|--------|-------|
| Z / W | Accélérer (appliquer ENGINE_FORCE) |
| S | Freiner / marche arrière (appliquer BRAKE_FORCE) |
| Q / A | Braquer gauche |
| D | Braquer droite |
| Clic milieu | Réinitialiser la caméra derrière le véhicule (doit viser le capot après correction) |

## Feedback joueur

- Après la correction de rotation : la caméra orbitale en position neutre montre le capot et le capot avant du véhicule. L'inclinaison visuelle disparaît.
- Après la correction du moteur : le véhicule atteint 100 km/h en environ 3–5 secondes, avec une sensation de puissance arcade immédiate dès la première pression de touche.
- Après la correction du frein : le véhicule décélère visiblement en 2–4 secondes depuis 60 km/h jusqu'à l'arrêt complet.
- Aucun nouvel effet sonore ou visuel particulier n'est requis — les feedbacks existants (moteur, physique) suffisent.

## Règles et limites

| Paramètre | Valeur avant | Valeur après | Unité |
|-----------|-------------|-------------|-------|
| `rotation_degrees.y` du GLB carrosserie | +90.0 | -90.0 | degrés |
| `ENGINE_FORCE` | 4000.0 | 8000.0 | N (VehicleBody3D) |
| `BRAKE_FORCE` | 20.0 | 80.0 | (à confirmer par specifier) |

- La masse du véhicule reste 1200 kg (inchangée).
- Les autres paramètres physiques (suspension, friction, empattement) restent inchangés.
- Ces valeurs sont des constantes (`const`) en haut de script, facilement réglables.

## Dépendances de design

- 06 — Voiture (mesh + corps physique de base) : définit `VehicleBody3D` et les constantes physiques.
- 08 — Conduite (accélérer, freiner, tourner) : définit `ENGINE_FORCE` et `BRAKE_FORCE` et leur usage.
- 13 — Intégration carrosserie GLB : définit `_charger_carrosserie()` et la rotation du GLB.
- 14 — Calibration physique véhicule : établit les valeurs de base des constantes physiques.
- 15 — Correction géométrie roues : corrige l'axe Z des roues.
- 16 — Suppression des WheelMesh fantômes : nettoie les maillages redondants.

## Hors-périmètre

- Aucun nouvel asset graphique ou sonore.
- Pas de modification du comportement de braquage ou de la suspension.
- Pas de modification de la caméra orbitale elle-même (les scripts caméra features 09 et 11 sont inchangés).
- Pas de refactoring des scripts au-delà des trois constantes/lignes ciblées.
- La valeur numérique finale de `BRAKE_FORCE` (unité exacte) est laissée à la discrétion du `specifier` qui inspectera le code existant.
