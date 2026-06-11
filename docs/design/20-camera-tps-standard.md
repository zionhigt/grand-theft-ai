# Design 20 — Refonte caméra TPS standard

## Pitch (1 phrase)

La caméra suit automatiquement le dos du personnage ou de la voiture ; le clic droit permet une orbite temporaire libre qui revient en douceur derrière la cible dès le relâchement.

## Pourquoi cette feature (valeur joueur)

La caméra orbitale de la feature 09 stocke le yaw comme un angle absolu permanent. Résultat : après un swipe clic droit, la caméra reste collée sur le côté ou en face du personnage jusqu'au prochain reset manuel. Le joueur doit se souvenir d'utiliser le clic molette pour recadrer la vue, ce qui brise le flux de jeu.

Les TPS de référence (GTA III, GTA Vice City, GTA SA) fonctionnent différemment : la caméra a une "home position" derrière la cible, et l'orbite au clic droit est une consultation temporaire. Dès que le joueur relâche, la vue revient doucement dans le dos. Le joueur n'a jamais à gérer l'angle de caméra — il peut se concentrer sur l'action.

Cette feature apporte ce comportement fondamental, élimine le reset molette devenu inutile, et consolide la propagation du yaw effectif (position réelle de la caméra, pas un angle mémorisé) vers le `PlayerController` pour que le déplacement ZQSD reste camera-relatif.

## Description détaillée

### Définition de l'angle "home"

Le yaw home est l'opposé de l'orientation horizontale de la cible :

```
home_yaw = target.global_transform.basis.get_euler().y + PI
```

Quand `home_yaw` est actif, la caméra se place exactement derrière la cible, quel que soit le cap de celle-ci.

Le pitch home est la valeur `DEFAULT_PITCH` héritée (≈ 26.57°, identique à la feature 09). Il n'est pas modifié par cette feature.

### Mode normal (pas de clic droit)

En dehors de tout clic droit, le yaw effectif de la caméra est interpolé chaque frame vers `home_yaw` :

```
_yaw = lerp_angle(_yaw, home_yaw, SPRING_RATE * delta)
```

Constante `SPRING_RATE = 5.0` (rad/s effectifs à distance 1). À cette valeur, l'écart entre le yaw courant et le yaw home est réduit d'environ 99 % en moins d'une seconde, ce qui donne un retour perceptible mais non brutal.

Effets perceptibles :

- Si le joueur avance tout droit sans jamais toucher le clic droit, la caméra reste en permanence dans son dos.
- Si la cible tourne (le joueur change de direction ou tourne le volant), le yaw home suit, et la caméra glisse progressivement pour coller derrière la nouvelle orientation.
- Après un swipe clic droit, la caméra revient toute seule sans aucune action du joueur.

### Mode orbite (clic droit maintenu)

Quand le joueur maintient le clic droit :

- Le curseur est capturé (`MOUSE_MODE_CAPTURED`).
- Le spring-back est **suspendu** : `_yaw` n'est plus interpolé vers `home_yaw`.
- Chaque pixel de déplacement horizontal modifie `_yaw` librement (identique à la feature 09).
- Chaque pixel vertical modifie `_pitch` (borné entre `PITCH_MIN` et `PITCH_MAX`), identique à la feature 09.

Le joueur peut parcourir librement les 360° autour de la cible, regarder l'environnement, inspecter la voiture, etc.

### Retour au home (relâchement clic droit)

Dès que le joueur relâche le bouton droit :

- Le curseur est libéré (`MOUSE_MODE_VISIBLE`).
- Le spring-back reprend immédiatement : `_yaw` recommence à interpoler vers `home_yaw` à chaque frame.

Il n'y a pas de délai ni de condition supplémentaire. Le retour est continu et fluide — le joueur voit la scène glisser doucement pour recadrer le dos de la cible.

### Propagation du yaw effectif vers PlayerController

La feature 12 propage `_yaw` au `PlayerController.set_camera_yaw()` pour que ZQSD soit camera-relatif. Cette logique est conservée et mise à jour :

- En mode normal (spring actif), le yaw propagé est le `_yaw` courant (qui converge vers `home_yaw`). Le déplacement ZQSD reste camera-relatif à la position réelle de la caméra.
- En mode orbite (clic droit), le yaw propagé est le `_yaw` orbital. Si le joueur avance tout en orbitant, le personnage part dans la direction de la caméra actuelle — comportement cohérent.

L'appel à `set_camera_yaw` reste inconditionnel dans `_process` (hérité de la feature 12).

### Suppression du reset clic molette

Le comportement "clic molette = reset yaw + zoom" de la feature 09 est **supprimé**. Le clic molette ne produit aucun effet.

Justification : le spring-back automatique rend le reset manuel obsolète. Le joueur n'a jamais besoin de recadrer manuellement — la caméra le fait seule.

### Zoom molette (conservé à l'identique)

Les trois niveaux de zoom discrets `[3.0, 4.5, 6.708]` mètres sont conservés sans modification. Molette haut = zoom in, molette bas = zoom out. Comportement identique à la feature 09.

### Comportement en véhicule

Quand la cible est un `VehicleBody3D` (joueur au volant, feature 18), le mécanisme est identique :

- `home_yaw` est calculé depuis `target.global_transform.basis.get_euler().y + PI` — c'est l'arrière de la voiture.
- En ligne droite, la caméra reste derrière la voiture.
- Quand la voiture tourne, la caméra suit progressivement (spring `SPRING_RATE = 5.0`).
- Le clic droit permet l'orbite temporaire autour de la voiture, avec retour spring dès le relâchement.
- `set_camera_yaw` n'est pas appelé sur le `VehicleBody3D` (pas de `has_method` correspondant) — la conduite reste pilotée par les touches locales.

### Compatibilité avec feature 11 (alignement idle)

La feature 11 utilise `_yaw` pour aligner le personnage pendant le clic droit. Ce comportement est conservé : quand le clic droit est maintenu, `_yaw` reflète la position orbitale et le personnage pivote pour y faire face.

En mode normal (pas de clic droit), le yaw glisse vers `home_yaw`. La feature 11 ne s'applique qu'au clic droit — donc pas de conflit.

## Contrôles / inputs

| Entrée | Effet |
|--------|-------|
| Aucune (mode normal) | La caméra revient progressivement derrière la cible (spring-back actif) |
| Clic droit maintenu + souris horizontal | Orbite temporaire : `_yaw` change librement, spring suspendu |
| Clic droit maintenu + souris vertical | Pitch change librement (borné PITCH_MIN / PITCH_MAX) |
| Relâcher clic droit | Spring-back reprend, caméra revient derrière la cible |
| Molette haut | Zoom in (niveau inférieur dans [3.0, 4.5, 6.708] m) |
| Molette bas | Zoom out (niveau supérieur dans [3.0, 4.5, 6.708] m) |
| Clic molette | Aucun effet (reset supprimé) |

Aucune touche clavier n'est affectée. ZQSD / WASD restent inchangés.

## Feedback joueur

**Visuel — mode normal :**
- En avançant tout droit, le joueur ne voit jamais la caméra dériver : elle reste dans le dos.
- Quand le personnage tourne, la caméra glisse doucement pour recadrer — effet "épaule qui suit" typique des TPS GTA.
- Après un swipe clic droit, sans rien faire d'autre, la caméra revient seule dans le dos en environ 0.5 à 1 seconde selon l'amplitude du swipe.

**Visuel — mode orbite :**
- Dès l'appui clic droit, le curseur disparaît.
- La scène pivote librement autour de la cible, fluide, identique à la feature 09.
- Dès le relâchement, la scène recommence à glisser vers le dos de la cible — transition douce, sans saut.

**Visuel — véhicule :**
- En ligne droite, la caméra reste derrière la voiture (aucune action requise).
- Dans un virage, la caméra suit avec un léger retard (spring) — effet de "traînée" réaliste qui donne de la lisibilité à la trajectoire.

**Sonore :** Aucun son ajouté par cette feature.

**Mouvement de caméra :** Le spring est calculé chaque frame dans `_process` via `lerp_angle`. La transition est continue, jamais abrupte.

## Règles et limites

| Paramètre | Valeur | Unité | Justification |
|-----------|--------|-------|---------------|
| `SPRING_RATE` | 5.0 | (sans unité, facteur lerp) | Retour à ~99 % en ~1 s. Assez rapide pour ne pas gêner, assez lent pour ne pas être sec. |
| `ZOOM_DISTANCES` | [3.0, 4.5, 6.708] | mètres | Inchangé depuis feature 09. |
| `DEFAULT_PITCH` | 0.4636 rad (≈ 26.57°) | radians | Inchangé depuis feature 09. |
| `PITCH_MIN` | -0.1745 rad (−10°) | radians | Inchangé depuis feature 09. |
| `PITCH_MAX` | 1.2217 rad (70°) | radians | Inchangé depuis feature 09. |
| `MOUSE_SENSITIVITY` | 0.003 | rad/px | Inchangé depuis feature 09. |
| `EYE_HEIGHT` | 1.6 | mètres | Inchangé depuis feature 04. |
| `home_yaw` | `target.global_transform.basis.get_euler().y + PI` | radians | Angle derrière la cible selon son orientation. |
| Spring actif | quand clic droit non maintenu | — | Suspendu uniquement pendant le clic droit. |
| Reset clic molette | supprimé | — | Obsolète avec le spring-back. |
| Propagation yaw | chaque frame, inconditionnelle | — | Hérité feature 12, inchangé. |
| Yaw home pitch | non modifié | — | Seul le yaw est géré par le spring ; le pitch reste tel que positionné par le dernier clic droit. |

## Dépendances de design

- **Feature 09 — Caméra orbitale** : fournit `CameraController` avec `_yaw`, `_pitch`, `_zoom_level`, `_right_mouse_held`, `ZOOM_DISTANCES`, `PITCH_MIN`, `PITCH_MAX`, `MOUSE_SENSITIVITY`, `EYE_HEIGHT`. La feature 20 modifie le comportement de `_process` sans casser ces constantes.
- **Feature 11 — Alignement personnage-caméra** : fournit la logique de propagation `_yaw → PlayerController.set_camera_yaw()` pendant le clic droit. Conservée telle quelle.
- **Feature 12 — Déplacement camera-relatif** : fournit la propagation permanente du yaw. Conservée, la valeur propagée devient le yaw effectif (post-spring).
- **Feature 18 — Refonte complète du véhicule** : fournit le `VehicleBody3D` cible lors de la conduite. La caméra doit se positionner derrière la voiture selon son orientation.

## Hors-périmètre

- Collision de caméra (empêcher la caméra de traverser les murs) : hors proto v0.1.
- Interpolation du pitch vers un pitch home (seul le yaw bénéficie du spring-back) : hors périmètre.
- Sensibilité souris réglable dans un menu : hors proto v0.1.
- Rotation automatique de la caméra derrière le joueur après inactivité prolongée (différent du spring-back : après X secondes sans input) : hors périmètre.
- Effets visuels liés à la caméra (motion blur, FOV dynamique, depth of field) : hors périmètre proto.
- Gestion pad / joystick : hors périmètre, clavier + souris uniquement.
- Zoom interpolé (lerp vers la nouvelle distance au lieu d'un saut discret) : hors périmètre.
- Caméra cinématique (cutscenes, entrée/sortie de véhicule animée) : hors périmètre.
- Inversion axe Y souris (option accessibilité) : hors périmètre.
