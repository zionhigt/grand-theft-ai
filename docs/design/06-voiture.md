# Design 06 — Voiture (mesh + corps physique de base)

## Pitch (1 phrase)

Une voiture statique apparaît dans la ville : obstacle physique solide monté sur quatre roues, prête à être conduite dans les features suivantes.

## Pourquoi cette feature (valeur joueur)

Sans voiture visible dans la scène, les features 07 (entrer/sortir) et 08 (conduite) n'ont rien sur quoi s'appuyer. Cette feature ancre l'objet voiture dans le monde physique : le joueur la voit, peut s'y cogner, et comprend immédiatement que c'est un véhicule. C'est le socle indispensable de toute la mécanique véhicule.

## Description détaillée

Une voiture est instanciée dans `main.tscn` via la scène dédiée `scenes/vehicles/car.tscn`. Elle est posée sur le sol à la position `Vector3(5, 0.75, 5)`, à proximité du point de spawn du joueur mais sans le bloquer.

La voiture est un `VehicleBody3D` Godot (nœud natif de physique véhicule). Ce choix est délibéré : `VehicleBody3D` est le nœud Godot 4 prévu pour la conduite. En l'utilisant dès la feature 06, les features 07 et 08 n'auront pas à restructurer la scène.

À ce stade (feature 06), aucun moteur n'est actif : `engine_force`, `brake`, `steering` restent à zéro. La voiture est donc immobile, mais elle obéit à la gravité et repose sur ses suspensions. Si le joueur vient la pousser, elle peut légèrement réagir (physique Godot active), mais elle ne se déplace pas seule.

La carrosserie est représentée par un `BoxMesh` de dimensions 4 × 1.5 × 2 m (longueur × hauteur × largeur) avec un `CollisionShape3D` (BoxShape3D) aux mêmes dimensions, centré à mi-hauteur du corps.

Quatre roues sont attachées comme nœuds `VehicleWheel3D` enfants du `VehicleBody3D`. Chaque roue possède un `MeshInstance3D` avec un `CylinderMesh` (rayon 0.35 m, hauteur 0.3 m) orienté correctement (axe Z = axe de rotation de la roue).

Positions des roues en coordonnées locales au `VehicleBody3D` :
- Avant-gauche : `Vector3(-1.0, -0.5, 0.8)`
- Avant-droit : `Vector3(-1.0, -0.5, -0.8)`
- Arrière-gauche : `Vector3(1.0, -0.5, 0.8)`
- Arrière-droit : `Vector3(1.0, -0.5, -0.8)`

Les roues avant sont configurées avec `use_as_steering = true`, les roues arrière avec `use_as_traction = true`. Ces flags ne produisent aucun effet en feature 06 (pas d'inputs), mais ils seront exploités en feature 08.

## Contrôles / inputs

Aucun contrôle propre à la voiture en feature 06. La voiture est un objet passif.

La touche E (interaction joueur/véhicule) sera implémentée en feature 07.

## Feedback joueur

- Visuel : la voiture est immédiatement visible à l'écran dès le lancement, carrosserie rouge vif (`#cc1a1a`) sur quatre roues gris foncé (`#333333`), à côté du personnage.
- Physique : si le joueur marche contre la voiture, celle-ci fait obstacle (collision effective). Elle peut légèrement rouler sous l'impact — comportement normal du `VehicleBody3D` avec gravité active.
- Pas de feedback sonore en feature 06.
- Pas de HUD ni d'icône d'interaction en feature 06 (feature 07).

## Règles et limites

| Paramètre | Valeur | Justification |
|-----------|--------|---------------|
| Masse du VehicleBody3D | 1 200 kg | Ordre de grandeur voiture compacte réaliste |
| engine_force | 0 | Pas de moteur — feature 08 |
| brake | 0 | Pas de frein actif — feature 08 |
| steering | 0 | Pas de direction active — feature 08 |
| Suspension max force (par roue) | 6 000 N | Valeur Godot par défaut acceptable pour le proto |
| Suspension travel | 0.2 m | Course de suspension suffisante pour amortir les irrégularités de sol |
| Suspension stiffness | 5.88 | Valeur Godot par défaut |
| Wheel friction slip | 10.5 | Valeur Godot par défaut, suffisante pour que la voiture ne glisse pas au sol |
| Position de spawn | Vector3(5, 0.75, 5) | À côté du joueur (spawn à l'origine), pas sur lui |
| Dimensions carrosserie | 4.0 × 1.5 × 2.0 m | L × H × l, proportions voiture compacte |
| Rayon roue | 0.35 m | Cohérent avec la hauteur de la carrosserie |
| Hauteur roue (cylindre) | 0.3 m | Épaisseur visuelle réaliste |
| Gravité Godot | valeur projet par défaut (9.8 m/s²) | Aucune surcharge de la feature |

## Dépendances de design

- **01 — Bootstrap** : projet Godot 4.6 opérationnel.
- **02 — Scène 3D minimale** : sol physique sur lequel la voiture repose.
- **03 — Personnage joueur** : joueur présent dans la scène pour valider la cohabitation.
- **05 — Ville minimale** : sol étendu et bâtiments — la voiture doit s'y intégrer sans flotter ni traverser le sol.

## Hors-périmètre

- Touche E pour entrer/sortir : feature 07.
- Moteur, frein, direction, accélération : feature 08.
- Sons moteur, klaxon, crissement de pneus : non commandés dans le proto v0.1.
- Texture carrosserie peinte, reflets, vitrages translucides : hors proto.
- Plusieurs voitures dans la scène : hors proto v0.1 (une seule instance).
- Phares, rétroviseurs, détails de carrosserie : hors proto.
- Caméra adaptée à la conduite (zoom, offset) : feature 08.
- PNJ conducteurs, IA de circulation : hors proto v0.1.
- Dommages visuels, déformations : hors proto v0.1.
