# Design 12 — Déplacement camera-relatif (ZQSD orienté caméra)

## Pitch (1 phrase)

Les touches ZQSD déplacent le personnage dans le référentiel de la caméra : Z avance toujours vers où la caméra pointe, quelle que soit l'orientation du personnage ou la rotation de la caméra.

## Pourquoi cette feature (valeur joueur)

Depuis la feature 09 (caméra orbitale), le joueur peut faire pivoter librement la caméra autour du personnage. Pourtant, appuyer sur Z continue de propulser le personnage vers le monde -Z absolu, indépendamment de la caméra. Résultat : après un clic droit + rotation, la touche "avancer" envoie le personnage dans une direction qui ne correspond plus à ce que le joueur voit à l'écran. C'est contre-intuitif et nuit à la maniabilité en ville.

La feature 12 corrige ce problème fondamental : les touches directionnelles sont désormais relatives à la caméra. C'est le comportement standard de tous les TPS modernes (GTA V, The Witcher 3, Zelda BOTW) et il est indispensable pour que la navigation piétonne en ville soit lisible et agréable.

## Description détaillée

### Principe : transformation du vecteur d'input par le yaw caméra

L'input brut ZQSD produit un vecteur 2D dans le repère "neutre" (Z = avant monde, X = droite monde). Ce vecteur est ensuite **tourné** par le yaw courant de la caméra (angle de rotation horizontale autour de l'axe Y) pour obtenir un vecteur de déplacement dans le repère monde.

La rotation se fait exclusivement autour de l'axe Y (plan horizontal). Le pitch de la caméra n'influence pas la direction de déplacement au sol — le personnage ne se déplace jamais vers le haut ou vers le bas à cause de l'inclinaison de la caméra.

Formule dans `compute_input_direction()` :

```
raw_x = move_right - move_left
raw_z = move_backward - move_forward

dir = Vector3(raw_x, 0.0, raw_z)
if dir.length() > 0.0:
    dir = dir.normalized()
    dir = dir.rotated(Vector3.UP, camera_yaw)
return dir
```

Le vecteur résultant est dans le repère monde et sert directement à calculer la vélocité de déplacement.

### Propagation permanente du yaw

La feature 11 propageait `_yaw` au `PlayerController` uniquement quand `_right_mouse_held` était `true`. Cette feature étend ce comportement : la propagation devient **permanente**, chaque frame, indépendamment du clic droit.

Justification : même sans clic droit maintenu, le yaw de la caméra a pu changer (il est conservé entre les sessions de clic droit). Si la propagation ne se fait que pendant le clic droit, le `PlayerController` aurait un yaw figé au dernier yaw reçu, et le déplacement ne serait camera-relatif qu'à l'intérieur d'un clic droit, pas après. La propagation permanente garantit que `PlayerController._camera_yaw` est toujours synchronisé avec `CameraController._yaw`.

Concrètement, dans `CameraController._process`, la condition `if _right_mouse_held:` est retirée (ou conservée pour la feature 11 uniquement) et `target.set_camera_yaw(_yaw)` est appelé **inconditionnellement** à chaque frame, si la cible expose la méthode.

### Comportement par cas d'usage

**Cas 1 — Joueur immobile, aucun clic droit, appui Z :**
Le personnage avance dans la direction actuelle du yaw caméra. Si la caméra était à yaw=0 (derrière le joueur), le personnage avance "dans l'écran". Si la caméra était rotée à yaw=90° (sur le côté gauche du joueur), le personnage avance vers la gauche de l'écran (ce qui correspond à "avancer" du point de vue de la caméra).

**Cas 2 — Clic droit + swipe + relâcher + appui Z :**
Pendant le clic droit, `_yaw` change, et `set_camera_yaw` est appelé à chaque frame. Quand le joueur relâche et appuie sur Z, `_camera_yaw` dans `PlayerController` est déjà à jour avec la nouvelle orientation de caméra. Le personnage avance exactement dans la direction où la caméra pointait.

**Cas 3 — Clic droit maintenu + appui Z simultané :**
La direction de déplacement est calculée en temps réel par rapport au yaw courant. Si le joueur fait pivoter la caméra tout en avançant, la direction de marche suit la caméra en continu. Effet : le personnage décrit un arc de cercle autour du point d'intérêt si le joueur orbite la caméra tout en maintenant Z.

**Cas 4 — Joueur dans un véhicule :**
`CameraController.target` est un `VehicleBody3D` qui n'expose pas `set_camera_yaw`. Le `has_method` check retourne `false`, la propagation n'a pas lieu. Le comportement de conduite (feature 08) est strictement inchangé.

### Rotation du personnage

La méthode `rotate_toward_direction` héritée de la feature 03 reste inchangée : le personnage fait toujours face à la direction effective de déplacement dans le monde. Avec le déplacement camera-relatif, cela signifie que le personnage se tourne face à la direction où pointe la caméra quand on avance — ce qui est exactement l'effet attendu.

### Compatibilité avec la feature 11 (alignement idle)

La feature 11 alignait le personnage sur la caméra en état idle, **uniquement pendant le clic droit**. La feature 12 ne modifie pas cette logique de rotation en idle. Ce qui change :

- En idle sans clic droit : le personnage garde son orientation (la feature 11 ne s'applique pas, c'est le comportement voulu).
- En idle avec clic droit : la feature 11 continue d'aligner le personnage (via `CAMERA_ALIGN_SPEED`).
- En marche avec ou sans clic droit : `rotate_toward_direction` dirige le personnage vers la direction de déplacement camera-relatif.

Il n'y a pas de conflit : l'alignement idle (feature 11) agit sur la rotation, le déplacement camera-relatif (feature 12) agit sur la direction de vélocité. Les deux coexistent.

### Changement minimal dans les deux scripts

**`src/camera/camera_controller.gd`** — une seule modification :
- Retirer la condition `if _right_mouse_held:` qui enveloppait l'appel `target.set_camera_yaw(_yaw)` dans `_process`.
- L'appel devient inconditionnel (toujours exécuté si `target.has_method("set_camera_yaw")`).

**`src/player/player_controller.gd`** — une seule modification :
- Dans `compute_input_direction()`, appliquer `dir.rotated(Vector3.UP, _camera_yaw)` au vecteur normalisé avant de le retourner.
- Aucune nouvelle propriété ni méthode ne sont nécessaires — `_camera_yaw` existe déjà depuis la feature 11.

## Contrôles / inputs

| Entrée | Effet attendu |
|--------|--------------|
| Z (move_forward) | Personnage avance dans la direction horizontale où pointe la caméra |
| S (move_backward) | Personnage recule à l'opposé de la direction de la caméra |
| Q (move_left) | Personnage strafe à gauche de la direction de la caméra |
| D (move_right) | Personnage strafe à droite de la direction de la caméra |
| Combinaisons diagonales (Z+Q, Z+D, S+Q, S+D) | Direction diagonale dans le référentiel caméra, normalisée |
| Clic droit + souris (feature 09) | Modifie le yaw caméra, ce qui modifie immédiatement le référentiel de déplacement |

Aucune nouvelle touche clavier n'est introduite. Aucune touche existante ne change d'action.

## Feedback joueur

**Visuel :**
- La correspondance entre la touche "avancer" et la direction d'avance à l'écran est permanente, quelle que soit la rotation de la caméra. Le joueur perçoit immédiatement que ZQSD "suivent" la caméra.
- Après un swipe clic droit, les touches fonctionnent directement dans le bon sens — pas besoin de re-tourner la caméra ni d'attendre que le personnage se réoriente avant de partir.
- En état walk avec clic droit tenu + mouvement souris : le personnage décrit un arc autour de la caméra si l'orbite est en cours — effet fluide et prévisible.

**Sonore :** Aucun son ajouté par cette feature.

**Mouvement de caméra :** La caméra n'est pas modifiée par cette feature. Elle se comporte exactement comme définie par les features 09 et 11.

## Règles et limites

| Paramètre | Valeur | Unité | Justification |
|-----------|--------|-------|---------------|
| Axe de rotation | Y uniquement | — | Le déplacement est horizontal. Le pitch de la caméra ne contribue pas à la direction de marche. |
| Normalisation | Avant rotation | — | Le vecteur est normalisé en espace "neutre" puis tourné, pour éviter les variations de vitesse en diagonale. |
| Propagation yaw | Chaque frame | — | `set_camera_yaw` est appelé inconditionnellement dans `CameraController._process` si la cible a la méthode. |
| Cible sans `set_camera_yaw` | ignorée silencieusement | — | `has_method` check avant l'appel — aucune erreur pour les véhicules. |
| Comportement en véhicule | inchangé | — | La conduite (feature 08) n'est pas affectée. |
| Rotation personnage | inchangée | — | `rotate_toward_direction` continue de tourner le personnage vers la direction effective de déplacement monde. |

## Dépendances de design

- **Feature 09 — Caméra orbitale** : fournit `CameraController._yaw` (angle horizontal de la caméra) qui est la source du référentiel de déplacement.
- **Feature 11 — Alignement personnage-caméra** : fournit `PlayerController._camera_yaw`, `set_camera_yaw()`, et la logique de propagation conditionnelle que cette feature rend permanente.
- **Feature 03 — Personnage joueur** : fournit `compute_input_direction()` et `rotate_toward_direction()` qui sont modifiés ou appelés par cette feature.
- **Feature 07 — Entrer / sortir d'un véhicule** : le `has_method` check garantit que les véhicules ne sont pas affectés.

## Hors-périmètre

- Déplacement camera-relatif en véhicule : la conduite reste pilotée par les axes locaux du véhicule (feature 08), pas par la caméra.
- Déplacement influencé par le pitch de la caméra (ex. personnage qui "monte" en pente si la caméra regarde vers le bas) : hors périmètre.
- Sensibilité ou accélération de déplacement différente selon l'angle caméra : hors périmètre.
- Lock-on / système de visée : hors proto v0.1.
- Gestion du pad / joystick : hors périmètre, clavier + souris uniquement.
- Strafe animé (animation dédiée au déplacement latéral) : hors proto v0.1, les animations actuelles (idle/walk) s'appliquent dans toutes les directions.
