# Design 11 — Alignement personnage-caméra (clic droit, axe horizontal)

## Pitch (1 phrase)

Quand le joueur fait pivoter la caméra horizontalement avec le clic droit, le personnage tourne en même temps pour faire face à la direction de la caméra.

## Pourquoi cette feature (valeur joueur)

Depuis la feature 09, le clic droit déplace librement la caméra autour du personnage. Mais le personnage, lui, reste orienté vers la dernière direction de marche : il peut se retrouver à "regarder" dans une direction complètement opposée à la caméra. Quand le joueur relâche le clic droit et appuie ensuite sur une touche directionnelle, le personnage part d'abord dans sa vieille direction avant de se réorienter — ce qui produit un mouvement désorienté et peu intuitif.

Cette feature élimine ce décalage : dès que le joueur oriente la caméra vers une direction, le personnage se retourne aussi. Résultat : après un clic droit, la touche "avancer" envoie toujours le personnage dans la direction où la caméra pointe. C'est le comportement standard des TPS modernes (GTA V, Zelda BotW) et il est nécessaire pour que la navigation en ville soit lisible.

## Description détaillée

### Couplage yaw → rotation Y du personnage

Pendant que `_right_mouse_held` est `true` dans `CameraController` (clic droit maintenu), chaque changement de `_yaw` est propagé au `PlayerController` sous la forme d'un angle cible de rotation Y.

Le `PlayerController` expose une nouvelle propriété `camera_yaw: float`. Quand cette propriété est modifiée, le personnage adopte instantanément la même orientation horizontale que la caméra, indépendamment de toute direction de déplacement WASD.

Le couplage est **uniquement horizontal** : le pitch (angle vertical de la caméra) n'influence pas la rotation du personnage. Le personnage ne s'incline jamais en avant ou en arrière à cause de la caméra.

### Priorité entre alignement caméra et déplacement WASD

Deux cas :

**Cas A — Joueur immobile (état "idle") et clic droit maintenu :** Le personnage tourne pour s'aligner avec la caméra même sans déplacement. L'effet est visible immédiatement : le personnage pivote sur lui-même pendant que la caméra pivote, restant toujours face à la direction de la caméra.

**Cas B — Joueur en mouvement (état "walk") et clic droit maintenu :** La direction de déplacement est calculée dans le repère de la caméra (déjà le cas depuis la feature 03). La rotation vers la direction de marche (méthode `rotate_toward_direction`) prend le dessus : le personnage se tourne vers la direction effective de déplacement, pas vers le yaw de la caméra. Il n'y a pas de conflit — la direction de marche absorbe la rotation.

### Mécanisme de communication CameraController → PlayerController

Le `CameraController` détient déjà une référence à sa cible (`target`). Quand cette cible est le `Player` (pas un véhicule), le `CameraController` met à jour `target.camera_yaw` à chaque frame où `_right_mouse_held` est `true`.

La mise à jour de `camera_yaw` est effectuée dans le `_process` du `CameraController`, **après** le calcul du nouveau `_yaw`, via un appel de méthode ou une propriété exportée sur le `PlayerController`.

Quand la cible est un véhicule (feature 07), la mise à jour de `camera_yaw` n'est pas effectuée : les véhicules ne tournent pas avec la caméra (le volant pilote l'orientation).

### Application de la rotation dans PlayerController

Dans `_physics_process` du `PlayerController`, la logique de rotation est étendue :

- Si l'état est `"idle"` et `camera_yaw` a été mis à jour (flag interne `_camera_yaw_dirty` activé par le setter), le personnage tourne vers `camera_yaw` via `lerp_angle` avec une vitesse de rotation élevée (`CAMERA_ALIGN_SPEED = 15.0 rad/s`).
- Si l'état est `"walk"`, `rotate_toward_direction` prend le dessus et `_camera_yaw_dirty` est remis à `false`.

La vitesse d'alignement élevée (15 rad/s) garantit que la rotation suit quasi instantanément le clic droit, ce qui donne l'impression d'un couplage direct, sans le léger retard d'une interpolation lente.

### Comportement à la fin du clic droit

Quand le joueur relâche le clic droit :
- Le `CameraController` cesse de mettre à jour `camera_yaw`.
- Le `PlayerController` conserve la dernière orientation acquise — il ne "snappe" pas en arrière.
- La prochaine pression sur une touche directionnelle utilisera cette orientation comme base, ce qui est cohérent : le joueur a explicitement choisi cette direction.

### Absence d'effet sur la voiture

Quand le joueur est dans un véhicule (`target` du `CameraController` = `VehicleBody3D`), le `CameraController` ne tente pas de modifier `camera_yaw` sur la cible. La voiture garde sa propre logique de direction (feature 08). Le clic droit reste fonctionnel (la caméra pivote autour de la voiture) mais ne pilote pas la voiture.

## Contrôles / inputs

| Entrée | Action |
|--------|--------|
| Clic droit maintenu + déplacement souris horizontal gauche | La caméra et le personnage pivotent vers la gauche |
| Clic droit maintenu + déplacement souris horizontal droite | La caméra et le personnage pivotent vers la droite |
| Clic droit maintenu + déplacement souris vertical | La caméra monte ou descend — le personnage ne s'incline pas |
| Relâcher clic droit | La caméra et le personnage conservent leur orientation |
| Touches ZQSD / WASD (en déplacement) | La direction de marche prend le dessus sur l'alignement caméra |

Aucune nouvelle touche clavier n'est introduite par cette feature.

## Feedback joueur

**Visuel :**
- Pendant le clic droit : le personnage tourne en même temps que la caméra. Le décalage entre la direction de la caméra et la direction du personnage est nul. Le joueur voit toujours "l'arrière" du personnage face à lui.
- En état idle pendant le clic droit : le personnage pivote sur lui-même, comme s'il suivait le regard du joueur.
- En état walk pendant le clic droit : le personnage avance dans la direction de la combinaison caméra + touche directionnelle — le comportement existant est inchangé.
- À la fin du clic droit : aucun mouvement supplémentaire, l'orientation est figée.

**Sonore :** Aucun son ajouté par cette feature.

**Mouvement de caméra :** Inchangé par rapport à la feature 09 — la caméra orbitale pivot autour du personnage exactement comme avant.

## Règles et limites

| Paramètre | Valeur | Unité | Justification |
|-----------|--------|-------|---------------|
| `CAMERA_ALIGN_SPEED` | 15.0 | rad/s | Rotation quasi-instantanée mais pas un snap dur — évite un artefact visuel de téléportation angulaire |
| Axe de couplage | Y uniquement | — | Seule la rotation horizontale est couplée ; le pitch n'affecte jamais le personnage |
| Cible véhicule | ignorée | — | Le clic droit ne pilote pas la voiture |
| Etat "walk" | priorité déplacement | — | `rotate_toward_direction` écrase l'alignement caméra si le joueur se déplace |
| Cible sans propriété `camera_yaw` | silencieux | — | Le `CameraController` vérifie si la cible possède la propriété avant de l'écrire (duck typing GDScript : `if target.has_method("set_camera_yaw")`) |

## Dépendances de design

- **Feature 09 — Caméra orbitale** : fournit `CameraController` avec `_yaw`, `_right_mouse_held`, et la cible `target`. Cette feature étend le `_process` existant.
- **Feature 03 — Personnage joueur** : fournit `PlayerController` avec `rotate_toward_direction` et la gestion de l'état "idle" / "walk". Cette feature étend `_physics_process` et ajoute la propriété `camera_yaw`.
- **Feature 07 — Entrer / sortir d'un véhicule** : le `CameraController` doit discriminer entre une cible `Player` et une cible `VehicleBody3D` avant de propager `camera_yaw`.

## Hors-périmètre

- Alignement du personnage avec le pitch de la caméra (inclinaison du corps) : hors périmètre.
- Rotation automatique de la caméra derrière le joueur après inactivité (auto-align inverse) : feature future.
- Couplage caméra → direction de tir (visée) : hors proto v0.1.
- Réinitialisation de l'orientation du personnage via clic milieu : la feature 09 définit le reset yaw comme uniquement une réinitialisation de la caméra ; l'orientation du personnage n'est pas concernée.
- Gestion du pad / joystick : hors périmètre, clavier + souris uniquement.
- Animation de transition dédiée à la rotation sur place : hors proto v0.1 (la feature 10 ne fournit que "idle" et "walk").
