# Bon de commande 20 — Refonte caméra TPS standard

## Résumé

Cette feature n'introduit aucun asset 3D, texture, son ou matériau nouveaux. Elle modifie exclusivement le script `src/camera/camera_controller.gd`. Le bon de commande documente les constantes visuelles de design (distances, vitesse de spring-back, sensibilité) qui font partie du contrat entre le designer et le specifier/developer.

## Arborescence cible

Aucun dossier `assets/` n'est créé ni modifié par cette feature. L'arborescence existante est inchangée.

```
assets/                          (inchangé — aucune modification)
├── characters/                  (inchangé)
├── vehicles/                    (inchangé)
├── environment/                 (inchangé)
├── textures/                    (inchangé)
├── materials/                   (inchangé)
├── audio/                       (inchangé)
├── ui/                          (inchangé)
└── skybox/                      (inchangé)
```

## Liste détaillée des assets

Aucun asset à produire.

| Chemin Godot (res://) | Type | Format | Source | Livré ? | Notes techniques |
|-----------------------|------|--------|--------|---------|------------------|
| — | — | — | — | — | Aucun asset requis |

## Conventions de nommage

Sans objet pour cette feature.

## Budget polycount / mémoire

Sans objet. Cette feature est exclusivement comportementale (logique GDScript, zéro asset).

## Mocks obligatoires en attendant les assets finaux

Aucun mock requis — aucun asset visuel à substituer.

## Paramètres de design (contrat designer → specifier/developer)

Ces valeurs sont la source de vérité pour l'implémentation. Le specifier doit les reprendre comme constantes nommées dans la spec technique ; le developer ne doit pas les modifier sans accord du designer.

### Distances de zoom (ZOOM_DISTANCES)

Inchangées depuis la feature 09 :

| Niveau | Distance | Usage |
|--------|----------|-------|
| 0 | 3.0 m | Vue proche (défaut au démarrage) |
| 1 | 4.5 m | Vue intermédiaire |
| 2 | 6.708 m | Vue éloignée (≈ sqrt(3²+6²), cohérence feature 04) |

### Vitesse de spring-back (SPRING_RATE)

| Paramètre | Valeur | Type | Description |
|-----------|--------|------|-------------|
| `SPRING_RATE` | `5.0` | float | Coefficient du `lerp_angle` appliqué chaque frame : `_yaw = lerp_angle(_yaw, home_yaw, SPRING_RATE * delta)`. À 60 FPS, réduit l'écart de ~8 % par frame, soit ~99 % de retour en ~1 s pour un swipe de 90°. |

Justification : 5.0 est un compromis entre réactivité (ne pas laisser la caméra traîner longtemps) et douceur (ne pas donner l'impression d'un snap brutal). Valeur ajustable dans une future feature "options".

### Sensibilité souris (MOUSE_SENSITIVITY)

| Paramètre | Valeur | Type | Description |
|-----------|--------|------|-------------|
| `MOUSE_SENSITIVITY` | `0.003` | float rad/px | Inchangé depuis feature 09. ≈ 0.17°/pixel, soit ≈ 60° pour 350 pixels de déplacement. |

### Bornes de pitch (PITCH_MIN / PITCH_MAX)

| Paramètre | Valeur | Degrés | Description |
|-----------|--------|--------|-------------|
| `PITCH_MIN` | `-0.1745` rad | −10° | Inchangé depuis feature 09. Vue rasante, caméra quasi-sol. |
| `PITCH_MAX` | `1.2217` rad | +70° | Inchangé depuis feature 09. Vue plongeante, personnage visible en bas d'écran. |

### Hauteur de cible (EYE_HEIGHT)

| Paramètre | Valeur | Description |
|-----------|--------|-------------|
| `EYE_HEIGHT` | `1.6` m | Inchangé depuis feature 04. Point visé = `target.global_position + Vector3(0, 1.6, 0)`. |

### Calcul du yaw home

```
home_yaw = target.global_transform.basis.get_euler().y + PI
```

Le `+ PI` (180°) place la caméra derrière la cible. Sans ce `+ PI`, la caméra serait devant la cible.

Cette formule est valable pour le personnage (`CharacterBody3D`) et pour la voiture (`VehicleBody3D`) sans distinction.

### Comportement du spring par état

| État | Spring actif ? | Yaw propagé à PlayerController |
|------|---------------|-------------------------------|
| Mode normal (pas de clic droit) | Oui — `_yaw` lerp vers `home_yaw` | Oui — `_yaw` courant (en cours de convergence) |
| Mode orbite (clic droit maintenu) | Non — `_yaw` modifié par la souris | Oui — `_yaw` orbital |
| Cible = VehicleBody3D | Identique selon clic droit | Non — `has_method("set_camera_yaw")` = false |

### Suppression du reset clic molette

| Comportement supprimé | Comportement en feature 20 |
|-----------------------|---------------------------|
| Clic molette → reset yaw=0 + zoom=0 | Clic molette → aucun effet |

### Pitch home

Le pitch n'a pas de valeur "home" en feature 20. Il reste à la valeur définie par le dernier clic droit de l'utilisateur. Le spring-back ne concerne que le yaw.

Justification : le pitch est un confort personnel du joueur (vue haute ou basse). Le ramener automatiquement perturberait la préférence de vue. Seul le yaw (derrière / côté / devant) bénéficie du retour automatique.

## Hors-périmètre

- Aucun asset graphique à produire : modèles 3D, textures, matériaux, sons, icônes UI.
- La section Mixamo est omise (aucun asset Mixamo commandé).
- Le dossier `assets/import/` n'est pas concerné.
