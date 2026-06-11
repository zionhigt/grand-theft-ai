# Design 15 — Correction géométrie roues VehicleBody3D (empattement axe Z)

## Pitch (1 phrase)

Corriger le placement des quatre `VehicleWheel3D` dans `car.tscn` pour que l'empattement soit aligné sur l'axe Z (avant = Z négatif, arrière = Z positif) et non sur l'axe X, ce qui supprime la rotation permanente à droite et le comportement de flottaison, et aligner visuellement la carrosserie GLB avec la nouvelle géométrie physique.

## Pourquoi cette feature (valeur joueur)

Depuis les features précédentes, la voiture tourne invariablement vers la droite dès qu'on appuie sur l'accélérateur, et flotte légèrement dans les airs malgré la calibration de la feature 14. Le joueur ne peut pas conduire en ligne droite : la voiture est fondamentalement injouable. La cause est une erreur de conception géométrique datant de la feature 06 : les roues "avant" et "arrière" sont toutes situées sur le même côté gauche ou droit de la voiture (axe X), au lieu d'être séparées avant/arrière sur l'axe Z. Cette feature est un correctif de fond qui débloque la jouabilité de la conduite.

## Description détaillée

### Cause racine

`VehicleBody3D` dans Godot 4 avance sur son axe **-Z local** (axe mondial -Z quand rotation Y = 0). La traction et la direction sont calculées par Godot en fonction de la position relative des roues selon cet axe. La convention correcte est :

- **Empattement** le long de **Z** : avant à Z négatif, arrière à Z positif.
- **Voie (track)** le long de **X** : gauche à X négatif, droite à X positif.
- **Hauteur** le long de **Y** : même valeur pour toutes les roues (-0.5 local).

### Positions actuelles (incorrectes — feature 06)

| Roue | Position actuelle | Problème |
|------|-------------------|---------|
| WheelFrontLeft | `Vector3(-1.0, -0.5, 0.8)` | X=-1.0 = côté "avant" → les deux "front" sont à gauche |
| WheelFrontRight | `Vector3(-1.0, -0.5, -0.8)` | X=-1.0 = même côté que FrontLeft — pas à droite |
| WheelRearLeft | `Vector3(1.0, -0.5, 0.8)` | X=+1.0 = côté "arrière" → les deux "rear" sont à droite |
| WheelRearRight | `Vector3(1.0, -0.5, -0.8)` | X=+1.0 = même côté que RearLeft — pas à gauche |

Résultat : Godot calcule la traction moteur sur les deux roues "arrière" qui sont toutes les deux à droite du centre. L'effort net est asymétrique → rotation permanente à droite. Par ailleurs, les roues directrices ("avant") sont toutes à gauche et leurs signaux de steering s'appliquent de façon biaisée.

### Positions corrigées

| Roue | Position corrigée | Raisonnement |
|------|-------------------|--------------|
| WheelFrontLeft | `Vector3(-0.8, -0.5, -1.0)` | X=-0.8 (gauche), Z=-1.0 (avant) |
| WheelFrontRight | `Vector3( 0.8, -0.5, -1.0)` | X=+0.8 (droite), Z=-1.0 (avant) |
| WheelRearLeft | `Vector3(-0.8, -0.5,  1.0)` | X=-0.8 (gauche), Z=+1.0 (arrière) |
| WheelRearRight | `Vector3( 0.8, -0.5,  1.0)` | X=+0.8 (droite), Z=+1.0 (arrière) |

- Empattement : 2.0 m (Z=-1.0 à Z=+1.0)
- Voie : 1.6 m (X=-0.8 à X=+0.8)
- Hauteur roues en Y : -0.5 (inchangé depuis feature 14)

### Calcul hauteur de spawn (inchangé)

Le calcul de la feature 14 reste valide avec les nouvelles positions :

```
contact_sol_local = wheel_y - rest_length - wheel_radius
                  = -0.5 - 0.25 - 0.35
                  = -1.1 m
```

Spawn Y dans `main.tscn` reste à **1.1 m** (valeur fixée par feature 14, non modifiée).

### Correction visuelle — rotation de la carrosserie GLB

`car_body.glb` a été exporté avec le nez de la voiture orienté dans la direction X négatif (car les roues "front" originales étaient à X=-1). Avec la géométrie corrigée, la voiture avance dans la direction **Z négatif**. Le GLB doit donc être tourné de **+90 degrés autour de Y** pour que son nez visuel pointe dans la même direction que le mouvement physique.

Cette rotation est appliquée dans la fonction `_charger_carrosserie()` de `src/vehicles/car_visuals.gd` en définissant `rotation_degrees.y = 90` sur le nœud `MeshInstance3D` qui porte le GLB de la carrosserie.

### Fichiers modifiés

| Fichier | Modification |
|---------|-------------|
| `scenes/vehicles/car.tscn` | Positions des 4 `VehicleWheel3D` corrigées |
| `src/vehicles/car_visuals.gd` | `rotation_degrees.y = 90` sur l'instance GLB carrosserie dans `_charger_carrosserie()` |

Aucune modification de `main.tscn`, `car_controller.gd`, ni des specs/tests existants portant sur la conduite ou la physique de suspension — seuls les tests de position de roue sont concernés.

## Contrôles / inputs

Aucun nouveau contrôle. Les commandes de conduite restent celles de la feature 08 :

| Touche | Effet |
|--------|-------|
| Z / W (ou flèche haut) | Accélérer (engine_force positif) |
| S / flèche bas | Freiner / reculer (brake puis engine_force négatif) |
| Q / A (ou flèche gauche) | Tourner à gauche (steering positif) |
| D / flèche droite | Tourner à droite (steering négatif) |
| E | Entrer / sortir du véhicule (feature 07, inchangé) |

## Feedback joueur

- **Au lancement** : la voiture est posée sur ses quatre roues, immobile, aucun glissement vers la droite ni oscillation.
- **À l'accélération** (Z/W) : la voiture avance en ligne droite selon l'axe -Z mondial. Aucune dérive au démarrage.
- **En virage** (Q/A, D) : les roues directrices (WheelFrontLeft et WheelFrontRight) sont maintenant à l'avant réel du véhicule. La direction répond symétriquement : tourner à gauche fait réellement tourner à gauche, tourner à droite fait réellement tourner à droite.
- **Visuel** : la carrosserie GLB est alignée avec le sens de déplacement. Le nez du modèle 3D pointe dans la direction où avance la voiture.
- **Absence de régression** : entrer/sortir (E), caméra orbitale, déplacement du personnage — tout continue de fonctionner.

## Règles et limites

| Paramètre | Valeur feature 14 (avant correction) | Valeur feature 15 (corrigée) | Justification |
|-----------|--------------------------------------|------------------------------|---------------|
| `WheelFrontLeft.position` | `Vector3(-1.0, -0.5, 0.8)` | `Vector3(-0.8, -0.5, -1.0)` | Avant = Z négatif, gauche = X négatif |
| `WheelFrontRight.position` | `Vector3(-1.0, -0.5, -0.8)` | `Vector3( 0.8, -0.5, -1.0)` | Avant = Z négatif, droite = X positif |
| `WheelRearLeft.position` | `Vector3( 1.0, -0.5, 0.8)` | `Vector3(-0.8, -0.5,  1.0)` | Arrière = Z positif, gauche = X négatif |
| `WheelRearRight.position` | `Vector3( 1.0, -0.5, -0.8)` | `Vector3( 0.8, -0.5,  1.0)` | Arrière = Z positif, droite = X positif |
| Empattement (longueur avant-arrière) | 2.0 m (sur axe X) | 2.0 m (sur axe Z) | Correction d'axe, distance inchangée |
| Voie (largeur gauche-droite) | 1.6 m (sur axe Z) | 1.6 m (sur axe X) | Correction d'axe, distance inchangée |
| Spawn Y Car dans `main.tscn` | 1.1 m | **1.1 m** (inchangé) | Calcul feature 14 toujours valide |
| `rotation_degrees.y` du GLB carrosserie | 0° | **90°** | Nez GLB orienté -X → correction pour pointer -Z |
| `suspension_stiffness` | 5.88 | **5.88** (inchangé depuis feature 14) | Aucune modification physique |
| `wheel_radius` | 0.35 m | **0.35 m** (inchangé) | Aucune modification |
| `wheel_y` local | -0.5 | **-0.5** (inchangé) | Aucune modification |

## Dépendances de design

- **Feature 06 — Voiture (mesh + corps physique de base)** : structure `car.tscn`, nœuds `VehicleBody3D` et `VehicleWheel3D`. Cette feature corrige les positions définies en feature 06.
- **Feature 08 — Conduite** : script `car_controller.gd`, flags `use_as_steering` et `use_as_traction`. Ces flags ne changent pas de roue mais sont maintenant appliqués aux bons nœuds géographiquement.
- **Feature 13 — Intégration carrosserie GLB** : `car_visuals.gd` et `_charger_carrosserie()`. Cette feature modifie la rotation du GLB chargé dans cette fonction.
- **Feature 14 — Calibration physique** : valeurs de suspension et spawn Y. Toutes ces valeurs sont conservées inchangées.

## Hors-périmètre

- Modification des valeurs de suspension (feature 14 — déjà fixées).
- Animation de rotation des roues visuelles.
- Sons moteur, freinage, crissement de pneus.
- Anti-roll bar, centre de gravité, physique avancée.
- Plusieurs véhicules.
- Comportement sur terrain non plat.
- Modification du fichier `car_body.glb` ou de tout autre asset binaire.
- Modification de `main.tscn` (sauf si le spawn Y doit être recalculé — il ne l'est pas ici).
