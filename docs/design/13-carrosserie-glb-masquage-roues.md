# Design 13 — Intégration carrosserie GLB propre (masquage roues redondantes)

## Pitch (1 phrase)

Utiliser la carrosserie GLB fournie avec ses roues visuelles intégrées, masquer les nœuds `WheelMesh` redondants, et recalibrer la physique de suspension pour que la voiture pose ses quatre roues franchement sur le sol et réponde correctement aux commandes.

## Pourquoi cette feature (valeur joueur)

Aujourd'hui la voiture affiche des roues en double : le GLB `car_body.glb` contient déjà des roues peintes et l'ancien code charge en plus `wheel.glb` sur chaque `VehicleWheel3D`. Le résultat visuel est incohérent. Par ailleurs, `suspension_stiffness = 5.88` N/m est physiquement absurde pour une masse de 1 200 kg : la voiture s'enfonce dans le sol ou rebondit de manière incontrôlable. Cette feature corrige les deux problèmes d'un seul mouvement : le joueur voit enfin une voiture cohérente qui spawne proprement au sol et se conduit normalement.

## Description détaillée

### Visuel

- `car_body.glb` est déjà chargé dans `CarBodyMesh` via `car_visuals.gd`. Ce GLB contient la carrosserie et les roues visuelles intégrées. Aucune modification n'est nécessaire sur le chargement du GLB.
- Les quatre nœuds `WheelMesh` (enfants de chaque `VehicleWheel3D`) sont rendus invisibles (`visible = false`) dès le `_ready()` de `car_visuals.gd`. `wheel.glb` n'est plus chargé.
- Résultat : une seule représentation visuelle de la voiture, celle du GLB, sans doublon de roues.

### Physique — réétalonnage de la suspension

La voiture pèse 1 200 kg, répartis sur 4 roues = 300 kg par roue, soit ~2 940 N par roue (g = 9.8 m/s²).

Pour une compression d'équilibre de la suspension raisonnable à environ 5 cm (0.05 m) :

    suspension_stiffness = F / x = 2 940 / 0.05 ≈ 58 800 N/m

Valeur retenue : **28 000 N/m** par roue (amortissement plus souple pour le gameplay arcade, compression d'équilibre ~10 cm sur 20 cm de débattement).

Paramètres recalibrés dans `car.tscn` :

| Propriété | Ancienne valeur | Nouvelle valeur | Justification |
|-----------|----------------|-----------------|---------------|
| `suspension_stiffness` | 5.88 N/m | 28 000 N/m | Tient 1 200 kg, compression ~10 cm |
| `suspension_rest_length` | (défaut Godot 0.3 m) | 0.25 m | Cohérent avec wheel_radius=0.35 |
| `suspension_travel` | 0.2 m | 0.2 m | Conservé |
| `suspension_max_force` | (défaut) | 10 000 N | Plafond force suspension |
| `damping_compression` | (défaut 0.83) | 0.3 | Moins rebondissant, sensation arcade |
| `damping_relaxation` | (défaut 0.88) | 0.5 | Retour suspension plus amorti |
| `wheel_friction_slip` | 10.5 | 10.5 | Conservé |

### Positionnement initial du Car dans `main.tscn`

Avec `wheel_radius = 0.35 m` et `suspension_rest_length = 0.25 m`, le bas de la carrosserie (origin VehicleBody3D) se trouve approximativement à :

    y_sol = wheel_radius + suspension_rest_length ≈ 0.35 + 0.25 = 0.60 m

La position de spawn dans `main.tscn` est ajustée à `y = 0.6` (au lieu de 0.75) pour que la voiture ne flotte pas ni ne plonge dès le premier frame de physique.

### Dépréciation de `wheel.glb`

`wheel.glb` existe dans `assets/vehicles/car/` mais n'est plus utilisé par aucun script. Le fichier n'est pas supprimé (cela casse les `.import` Godot), mais `car_visuals.gd` cesse de le charger. Le bon de commande 13 le déclare explicitement comme **déprécié**.

## Contrôles / inputs

Aucun nouveau contrôle. La feature est transparente pour le joueur. Les commandes de conduite restent celles de la feature 08 :

| Touche | Effet |
|--------|-------|
| Z / W (ou flèche haut) | Accélérer (engine_force positif) |
| S / flèche bas | Freiner / reculer (brake, puis engine_force négatif) |
| Q / A (ou flèche gauche) | Tourner à gauche (steering positif) |
| D / flèche droite | Tourner à droite (steering négatif) |

## Feedback joueur

- **Visuel** : la voiture s'affiche avec sa carrosserie GLB complète, une seule fois, sans doublon de roues flottantes. La silhouette est celle d'une vraie voiture low-poly.
- **Physique perçue** : la voiture repose calmement sur ses roues dès le spawn, sans rebond ni enfoncement dans le sol. En conduite, les suspensions absorbent légèrement les irrégularités.
- **Absence de régression** : entrer/sortir avec E, caméra orbitale, déplacement du personnage — tout continue de fonctionner.

## Règles et limites

| Paramètre | Valeur |
|-----------|--------|
| Masse voiture | 1 200 kg (inchangé) |
| `wheel_radius` | 0.35 m (inchangé) |
| `suspension_stiffness` | 28 000 N/m |
| `suspension_rest_length` | 0.25 m |
| `suspension_travel` | 0.2 m |
| `suspension_max_force` | 10 000 N |
| `damping_compression` | 0.3 |
| `damping_relaxation` | 0.5 |
| `wheel_friction_slip` | 10.5 (inchangé) |
| Position Y spawn Car | 0.6 m |
| `wheel.glb` utilisé | non (déprécié, fichier conservé) |
| Animations de roues | hors périmètre (pas d'animation pour les roues dans ce prototype) |

## Dépendances de design

- Feature 06 — Voiture (mesh + corps physique de base) : structure `car.tscn`, `VehicleBody3D`, `VehicleWheel3D`, `CarBodyMesh`.
- Feature 08 — Conduite : script `car_controller.gd`, paramètres `engine_force`, `brake`, `steering`.
- `car_visuals.gd` (produit en feature 06/10) : fonctions `_charger_carrosserie()` et `_charger_roues()` à modifier.

## Hors-périmètre

- Animation de rotation des roues (les roues du GLB ne tournent pas — intentionnel pour le proto).
- Remplacement du GLB `car_body.glb` par un autre modèle.
- Textures de carrosserie (`_albedo`, `_normal`, etc.).
- Sons moteur ou de suspension.
- Plusieurs véhicules ou modèles de voitures.
- Physique de collision latérale ou tonneaux.
