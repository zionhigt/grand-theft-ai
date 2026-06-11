# Design 14 — Calibration physique véhicule (spawn sol + suspension + moteur)

## Pitch (1 phrase)

Corriger quatre bugs physiques critiques qui rendent la voiture injouable : hauteur de spawn incorrecte, raideur de suspension excessive, amortissement trop faible et force moteur insuffisante.

## Pourquoi cette feature (valeur joueur)

Depuis la feature 13, la voiture tremble, flotte, oscille sans s'arrêter et avance très lentement. Le joueur ne peut pas conduire normalement. La cause est une accumulation de quatre erreurs de calibration introduites progressivement dans les features précédentes. Cette feature corrige chaque bug avec une valeur justifiée et testable, pour obtenir une voiture qui pose ses roues au sol dès le premier frame, reste immobile au repos, et accélère avec la vivacité attendue d'un jeu arcade GTA-like.

## Description détaillée

### Bug 1 — Hauteur de spawn incorrecte (CRITIQUE)

Dans `car.tscn`, chaque `VehicleWheel3D` est positionné à `y = −0.5` en coordonnées locales. Le contact sol réel se calcule ainsi :

```
contact_sol_local = wheel_y − wheel_rest_length − wheel_radius
                  = −0.5 − 0.25 − 0.35
                  = −1.1 m
```

Pour que ce contact soit exactement à `y = 0` (le sol), l'origine du `VehicleBody3D` doit être à `y = 1.1 m`. Or `main.tscn` spawne le Car à `y = 0.6` (valeur issue de la feature 13). Résultat :

- Contact sol réel : `0.6 − 1.1 = −0.5 m` → les roues pénètrent 50 cm dans le sol.
- Le bas du `BoxShape3D` (demi-hauteur 0.75 m) est à `0.6 − 0.75 = −0.15 m` : il pénètre la `WorldBoundary`.
- La `WorldBoundary` pousse le corps vers le haut, les ressorts poussent les roues vers le bas. Les deux forces s'opposent indéfiniment → oscillation infinie visible comme un "mesh invisible en dessous".

**Fix : position Y du Car dans `main.tscn` → 1.1 m.**

### Bug 2 — suspension_stiffness = 28 000 trop élevé

La feature 13 a introduit `suspension_stiffness = 28 000` en calculant avec des unités N/m standard. Or les unités internes du moteur physique Bullet/Godot ne sont pas des N/m standards : la valeur effective est multipliée par le moteur avant application. Le démo officiel Godot 4 VehicleBody3D utilise `suspension_stiffness = 5.88` pour une voiture de 800–1 200 kg. 28 000 est environ 4 700 fois trop élevé, ce qui rend les ressorts instantanément rigides et provoque des rebonds permanents.

**Fix : suspension_stiffness = 5.88 (valeur de référence du démo officiel Godot 4).**

### Bug 3 — damping_compression et damping_relaxation trop faibles

La feature 13 a fixé `damping_compression = 0.3` et `damping_relaxation = 0.5`, en dessous des valeurs par défaut Godot (0.83 et 0.88). Un amortissement faible amplifie les oscillations au lieu de les dissiper.

**Fix : damping_compression = 0.83, damping_relaxation = 0.88 (valeurs par défaut Godot).**

### Bug 4 — ENGINE_FORCE = 800 N insuffisant

800 N / 1 200 kg = 0.67 m/s². Pour atteindre 50 km/h il faut ~21 secondes. Dans un jeu arcade GTA-like, l'accélération attendue est de 3 à 4 m/s² (0 à 50 km/h en 3–4 secondes), ce qui correspond à 4 000–5 000 N pour 1 200 kg.

**Fix : ENGINE_FORCE = 4 000 N.**

### Bug 5 — suspension_max_force = 10 000 à revenir au défaut

La feature 13 avait fixé `suspension_max_force = 10 000`. La valeur par défaut Godot est 6 000. Une valeur trop élevée ne clippe pas directement les oscillations, mais peut interférer avec la stabilisation physique. Revenir à la valeur par défaut pour ne pas masquer d'autres problèmes.

**Fix : suspension_max_force = 6 000 (valeur par défaut Godot).**

## Contrôles / inputs

Aucun nouveau contrôle. Les commandes de conduite restent celles de la feature 08 :

| Touche | Effet |
|--------|-------|
| Z / W (ou flèche haut) | Accélérer (engine_force positif) |
| S / flèche bas | Freiner / reculer (brake puis engine_force négatif) |
| Q / A (ou flèche gauche) | Tourner à gauche (steering positif) |
| D / flèche droite | Tourner à droite (steering négatif) |

## Feedback joueur

- **Au spawn** : la voiture pose immédiatement ses quatre roues au sol. Aucun rebond, aucune oscillation visible dans les premières secondes.
- **Au repos** : la voiture reste parfaitement immobile, moteur coupé, sans trembler.
- **À l'accélération** : la voiture part franchement dès l'appui sur Z/W. 0 à ~50 km/h en environ 3–4 secondes. Sensation arcade nette.
- **En virage** : le comportement reste celui de la feature 08. La correction ne modifie pas la direction.
- **Absence de régression** : entrer/sortir (E), caméra orbitale, personnage à pied — tout continue de fonctionner.

## Règles et limites

| Paramètre | Valeur feature 13 (bugguée) | Valeur feature 14 (corrigée) | Justification |
|-----------|----------------------------|------------------------------|---------------|
| Position Y spawn Car dans `main.tscn` | 0.6 m | **1.1 m** | contact_sol = wheel_y − rest_length − wheel_radius = −0.5 − 0.25 − 0.35 = −1.1 → spawn à 1.1 |
| `suspension_stiffness` | 28 000 | **5.88** | Valeur démo officiel Godot 4 VehicleBody3D |
| `damping_compression` | 0.3 | **0.83** | Valeur par défaut Godot, amortissement suffisant |
| `damping_relaxation` | 0.5 | **0.88** | Valeur par défaut Godot, retour suspension amorti |
| `suspension_max_force` | 10 000 N | **6 000 N** | Valeur par défaut Godot |
| `suspension_rest_length` | 0.25 m | **0.25 m** | Inchangé |
| `suspension_travel` | 0.2 m | **0.2 m** | Inchangé |
| `wheel_friction_slip` | 10.5 | **10.5** | Inchangé |
| `wheel_radius` | 0.35 m | **0.35 m** | Inchangé |
| `ENGINE_FORCE` dans `car_controller.gd` | 800 N | **4 000 N** | 4 000 / 1 200 kg ≈ 3.3 m/s², 0→50 km/h en ~4 s |
| Masse voiture | 1 200 kg | **1 200 kg** | Inchangé |

## Dépendances de design

- Feature 06 — Voiture (mesh + corps physique de base) : structure `car.tscn`, `VehicleBody3D`, `VehicleWheel3D`.
- Feature 08 — Conduite : script `car_controller.gd`, constante `ENGINE_FORCE`.
- Feature 13 — Intégration carrosserie GLB propre : introduit les valeurs buggées que cette feature corrige.

## Hors-périmètre

- Animation de rotation des roues.
- Sons moteur, freinage, suspension.
- Anti-roll bar, centre de gravité, physique avancée.
- Plusieurs véhicules.
- Modifications visuelles de la carrosserie.
- Comportement sur terrain non plat ou obstacles.
