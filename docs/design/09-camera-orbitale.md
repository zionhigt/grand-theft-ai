# Design 09 — Caméra orbitale

## Pitch (1 phrase)

Le joueur contrôle librement l'angle de vue de la caméra en maintenant le clic droit pour faire pivoter, en tournant la molette pour changer de niveau de zoom, et en cliquant la molette pour réinitialiser la vue.

## Pourquoi cette feature (valeur joueur)

La caméra fixe héritée de la feature 04 colle derrière le joueur sans jamais se réorienter. Le joueur ne peut pas regarder sur les côtés, inspecter l'environnement autour de lui, ni anticiper ce qui se trouve derrière ou sur le côté de son personnage. La caméra orbitale résout ce problème fondamental : elle donne au joueur une agentivité sur le point de vue, ce qui est le standard de tout TPS moderne (GTA, The Witcher, Zelda). C'est une nécessité pour rendre la conduite et la navigation en ville confortables.

## Description détaillée

### État initial

Au démarrage, la caméra se positionne à sa position habituelle héritée de la feature 04 :

- OFFSET `(0, 3, 6)` depuis la cible → distance orbitale de départ ≈ 6.7 m (sqrt(3²+6²) ≈ 6.708 m)
- Yaw = 0° (axe de rotation horizontal autour de la cible, plan XZ)
- Pitch = 26.57° (angle vertical reproduisant exactement OFFSET `(0, 3, 6)` → atan2(3, 6) ≈ 26.57°)
- Niveau de zoom = 0 (le plus proche des trois niveaux)

La position de la caméra est donc calculée par angles (yaw, pitch, distance) et non plus par vecteur OFFSET fixe. Les deux formulations sont équivalentes à l'état initial.

### Rotation orbitale (clic droit maintenu + déplacement souris)

**Déclenchement :** Le joueur maintient le bouton droit de la souris enfoncé.

**Comportement pendant la rotation :**

- Le curseur de souris est capturé (mode `MOUSE_MODE_CAPTURED`) : il devient invisible et ses déplacements ne dépassent pas les bords de l'écran. Les déplacements relatifs continuent d'être reçus via `_input`.
- Chaque pixel de déplacement horizontal de la souris fait varier le **yaw** (rotation autour de l'axe Y du monde) de `sensibilité_souris` radians.
  - Déplacement souris vers la droite → yaw diminue (la caméra pivote vers la droite autour de la cible)
  - Déplacement souris vers la gauche → yaw augmente (la caméra pivote vers la gauche)
  - Le yaw est libre à 360°, sans borne.
- Chaque pixel de déplacement vertical de la souris fait varier le **pitch** (angle d'élévation) de `sensibilité_souris` radians.
  - Déplacement souris vers le bas → pitch diminue (la caméra descend et regarde plus horizontalement)
  - Déplacement souris vers le haut → pitch augmente (la caméra monte et plonge vers la cible)
  - Le pitch est borné : `PITCH_MIN = -10°` à `PITCH_MAX = 70°` (voir section Règles et limites).

**Relâchement :** Quand le joueur relâche le clic droit, le curseur est libéré (mode `MOUSE_MODE_VISIBLE`) et réapparaît à sa position d'avant la capture.

**Formule de position :** La position mondiale de la caméra est calculée à partir de la position de la cible, du yaw, du pitch et de la distance :

```
offset_x = distance * cos(pitch) * sin(yaw)
offset_y = distance * sin(pitch)
offset_z = distance * cos(pitch) * cos(yaw)
camera_position = target.global_position + Vector3(offset_x, offset_y, offset_z)
```

La caméra regarde toujours vers `target.global_position + Vector3(0, EYE_HEIGHT, 0)` (identique à la feature 04, EYE_HEIGHT = 1.6 m).

### Zoom molette (molette haut / molette bas)

Trois niveaux de zoom discrets, numérotés 0 (le plus proche) à 2 (le plus éloigné) :

| Niveau | Distance orbitale | Commentaire |
|--------|------------------|-------------|
| 0      | 6.7 m            | Distance initiale héritée de OFFSET `(0, 3, 6)` — valeur exacte : sqrt(3²+6²) ≈ 6.708 m, arrondie à 6.7 m |
| 1      | 12.0 m           | Vue intermédiaire — donne le contexte environnemental |
| 2      | 18.0 m           | Vue large — idéale pour les poursuites en voiture |

- **Molette vers le haut** (zoom in) : passe au niveau inférieur (ex. 2 → 1 → 0). En niveau 0, aucun effet.
- **Molette vers le bas** (zoom out) : passe au niveau supérieur (ex. 0 → 1 → 2). En niveau 2, aucun effet.
- Le changement de distance est instantané (pas d'interpolation au stade proto).

### Réinitialisation (clic milieu / bouton molette enfoncé)

Un clic sur le bouton central de la souris (molette enfoncée) réinitialise :

- **Yaw** → 0 (caméra derrière la cible)
- **Zoom** → niveau 0 (distance 6.7 m)
- **Pitch** → non réinitialisé (l'utilisateur garde son angle vertical)

La réinitialisation est instantanée, sans animation.

**Justification du choix de ne pas réinitialiser le pitch :** Le pitch par défaut (26.57°) est fonctionnel mais le joueur peut volontairement le modifier pour voir mieux (ex. pitch élevé pour surveiller une zone en contrebas). Le réinitialiser serait perçu comme intrusif. Le reset vise surtout à recadrer la caméra derrière le joueur après une rotation de yaw.

### Comportement lors du changement de cible

Quand la cible change (joueur entre dans un véhicule, feature 07), le yaw, le pitch et le niveau de zoom sont **conservés**. La caméra continue d'orbiter autour de la nouvelle cible avec le même angle de vue. Cela évite une rupture visuelle abrupte.

### Sensibilité souris

Valeur initiale : `MOUSE_SENSITIVITY = 0.003` rad/px.

Cette valeur est une constante de classe réglable. Elle produit une rotation d'environ 0.17° par pixel, soit ≈ 60° pour un déplacement de 350 pixels — ce qui est confortable sur un écran 1080p standard. Elle sera ajustable via les options du jeu dans une feature future.

## Contrôles / inputs

| Entrée | Action |
|--------|--------|
| Clic droit maintenu + déplacement souris horizontal | Rotation yaw de la caméra (pivote autour de la cible) |
| Clic droit maintenu + déplacement souris vertical | Rotation pitch de la caméra (monte / descend) |
| Relâcher clic droit | Libère le curseur, fin de la rotation |
| Molette haut | Zoom in — passe au niveau de zoom inférieur (distance réduite) |
| Molette bas | Zoom out — passe au niveau de zoom supérieur (distance accrue) |
| Clic milieu (molette enfoncée) | Reset yaw = 0 et zoom = niveau 0 |

Aucune touche clavier n'est affectée par cette feature. Les touches de déplacement joueur (ZQSD/WASD) et les autres actions restent inchangées.

## Feedback joueur

**Visuel :**

- Pendant la rotation : le curseur disparaît immédiatement lors de l'appui sur le clic droit. La scène entière pivote autour du personnage de façon fluide (calculée chaque frame).
- Lors du zoom : la scène saute instantanément à la nouvelle distance.
- Lors du reset : la caméra se repositionne instantanément derrière la cible.
- Aucune interpolation ni effet de lissage au stade proto.

**Sonore :** Aucun son prévu pour cette feature.

**Curseur :** Le curseur est capturé uniquement pendant la rotation (clic droit maintenu). Hors rotation, il reste visible et libre pour interagir avec d'éventuels éléments d'interface.

## Règles et limites

| Paramètre | Valeur | Unité | Justification |
|-----------|--------|-------|---------------|
| `PITCH_MIN` | -10° (−0.1745 rad) | degrés | Empêche la caméra de regarder vers le haut depuis le dessous (caméra quasi-sol). Permet quand même une légère vue rasante pour les poursuites. |
| `PITCH_MAX` | 70° (1.2217 rad) | degrés | Empêche la caméra de regarder presque verticalement vers le bas. À 70° le personnage est encore visible dans le bas de l'écran. |
| `YAW_MIN` / `YAW_MAX` | aucune borne | — | Yaw libre à 360°, wrappé dans [−π, +π] pour éviter les dépassements flottants. |
| `MOUSE_SENSITIVITY` | 0.003 | rad/px | Sensibilité initiale raisonnable, ≈ 0.17°/px. |
| `ZOOM_LEVELS` | [6.7, 12.0, 18.0] | mètres | Trois distances orbitales discrètes. |
| `ZOOM_DEFAULT` | niveau 0 (6.7 m) | — | Distance de départ identique à l'OFFSET actuel. |
| `PITCH_DEFAULT` | 26.57° (0.4636 rad) | degrés | atan2(3, 6) — reproduit exactement l'OFFSET `(0, 3, 6)` de la feature 04. |
| `EYE_HEIGHT` | 1.6 | mètres | Hérité de la feature 04, inchangé. |

**Cohérence avec la feature 04 :** À l'état initial (yaw=0, pitch=26.57°, distance=6.7 m), la position de la caméra calculée par les formules orbitales est identique à `target.global_position + Vector3(0, 3, 6)`. La feature 09 est rétrocompatible avec la feature 04 à l'état initial.

**Capture du curseur et focus :** La capture du curseur (`Input.set_mouse_mode(MOUSE_MODE_CAPTURED)`) ne s'applique que pendant la rotation. Si la fenêtre Godot perd le focus (alt-tab), le curseur doit être libéré.

## Dépendances de design

- **Feature 04 — Caméra troisième personne** : fournit le `CameraController` (classe, constantes OFFSET, EYE_HEIGHT, propriété `target`) que la feature 09 étend. La feature 09 modifie le comportement de `_process` et ajoute la gestion des inputs souris.
- **Feature 07 — Entrer / sortir d'un véhicule** : fournit le mécanisme de changement de cible (`target` du `CameraController`). La feature 09 doit conserver le yaw/pitch/zoom lors de ce changement.

## Hors-périmètre

- Interpolation (lerp/smoothstep) de la rotation ou du zoom : hors proto v0.1, réservé à une feature future.
- Collision de caméra (la caméra ne passe pas à travers les murs) : hors proto v0.1.
- Sensibilité souris réglable dans un menu d'options : hors proto v0.1.
- Rotation automatique de la caméra derrière le joueur après inactivité : hors proto v0.1.
- Inversion de l'axe Y (option accessibilité) : hors proto v0.1.
- Effets visuels liés à la caméra (motion blur, depth of field, FOV dynamique) : hors périmètre du proto.
- Gestion du pad / joystick : hors périmètre, clavier+souris uniquement.
