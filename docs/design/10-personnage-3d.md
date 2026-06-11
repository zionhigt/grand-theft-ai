# Design 10 — Personnage 3D Mixamo (remplacement du mock capsule)

## Pitch (1 phrase)

Le mesh capsule rouge placeholder est remplacé par un vrai personnage humanoïde 3D importé depuis Mixamo, animé en idle et en marche selon l'état courant du `PlayerController`.

## Pourquoi cette feature (valeur joueur)

Depuis la feature 03, le joueur est représenté par une capsule rouge sans expression. Cette feature substitue ce placeholder par un personnage humanoïde low-poly avec deux animations squelettales (idle et walk), ce qui ancre immédiatement la présence et la lisibilité du joueur dans le monde : on sait dans quelle direction il regarde, s'il bouge ou s'il attend. C'est le saut qualitatif minimal entre "proto technique" et "proto jouable ressentable".

## Description détaillée

### Remplacement du mesh

Le nœud `MeshInstance3D` avec `CapsuleMesh` dans `scenes/player/player.tscn` est retiré. Il est remplacé par une instance du GLB `res://assets/characters/player/player_body.glb` (mesh Mixamo, T-Pose, with skin). Ce GLB contient le mesh humanoïde et son squelette.

Le `CollisionShape3D` avec `CapsuleShape3D` (h = 1.8 m, r = 0.4 m) reste strictement inchangé : la collision ne suit pas le mesh visuel, elle reste une capsule analytique stable et cohérente avec la physique existante.

### Animations squelettales

Deux animations sont importées séparément depuis Mixamo :

- `player_idle.glb` — animation "idle" : personnage debout, léger mouvement de respiration. Jouée en boucle quand l'état du `PlayerController` est `"idle"`.
- `player_walk.glb` — animation "walk" : marche avant In Place (le personnage ne se déplace pas par l'animation, c'est le script qui déplace). Jouée en boucle quand l'état est `"walk"`.

Les animations GLB sont intégrées dans `scenes/player/player.tscn` via un `AnimationPlayer` (ou `AnimationTree` si nécessaire). Le `player_controller.gd` pilote la transition d'animations via `get_state()`.

### Architecture de la scène player.tscn

Structure cible après remplacement :

```
Player : CharacterBody3D  (script : res://src/player/player_controller.gd)
  position = Vector3(0, 0.9, 0)
  up_direction = Vector3(0, 1, 0)
  floor_max_angle = 0.785398

  CollisionShape3D                         (inchangé depuis feature 03)
    shape = CapsuleShape3D
      height = 1.8
      radius = 0.4

  PlayerMesh : Node3D                      (conteneur du mesh 3D + squelette)
    MeshInstance3D                         (issu de player_body.glb)
      # à remplacer / instancié depuis res://assets/characters/player/player_body.glb

  AnimationPlayer                          (joue idle / walk selon get_state())
    animation "idle" — importée depuis player_idle.glb
    animation "walk" — importée depuis player_walk.glb
```

En l'absence de GLB livré, le mock CapsuleMesh reste en place et l'`AnimationPlayer` est présent mais vide (aucun crash, le jeu reste lançable).

### Pilotage des animations depuis player_controller.gd

`player_controller.gd` reçoit une référence à l'`AnimationPlayer` (via `@onready var _anim_player`). À chaque frame physique, après mise à jour de `_state`, il appelle la logique d'animation :

- Si `get_state() == "idle"` et que l'animation courante n'est pas `"idle"` : `_anim_player.play("idle")`.
- Si `get_state() == "walk"` et que l'animation courante n'est pas `"walk"` : `_anim_player.play("walk")`.

Les animations sont en boucle (`loop_mode = LOOP_LINEAR` côté AnimationPlayer). Le passage idle → walk et walk → idle est instantané (pas de blend — le proto vise la simplicité).

Si l'`AnimationPlayer` est absent ou vide (mock), la logique d'animation est silencieusement ignorée (`if _anim_player == null: return`).

### Invisibilité en voiture (feature 07)

La feature 07 implémente déjà `visible = false` sur le nœud `Player` lors de l'entrée en voiture. Ce comportement reste inchangé : le personnage 3D (et son mesh GLB) disparaît intégralement pendant la conduite, sans modification nécessaire côté feature 10.

### Orientation du personnage

L'axe avant du mesh Mixamo exporté en T-Pose est orienté -Z (convention Mixamo / Godot). La logique de rotation existante dans `rotate_toward_direction` (feature 03) reste donc compatible sans ajustement.

Si l'export Mixamo donne un mesh tourné d'un autre angle, un offset de rotation local est appliqué sur le nœud conteneur `PlayerMesh` (par exemple `rotation_degrees.y = 180`). Cet offset est décidé à l'implémentation et documenté dans la scène avec un commentaire.

## Contrôles / inputs

Aucun contrôle nouveau. Les touches ZQSD / WASD (feature 03) et la touche E (feature 07) restent inchangées.

| Action | Effet sur les animations |
|--------|--------------------------|
| Aucune touche directionnelle | état "idle" → animation "idle" en boucle |
| Z / W / Q / A / S / D | état "walk" → animation "walk" en boucle |
| Touche E (entrer en voiture) | `visible = false` sur le nœud Player — animation suspendue |
| Touche E (sortir de voiture) | `visible = true` → reprise de l'animation selon état |

## Feedback joueur

### Visuel

- Le personnage humanoïde est visible dès le lancement, debout sur le sol, animé en "idle" (léger mouvement de respiration).
- Dès qu'une touche directionnelle est pressée, l'animation passe en "walk" et les jambes bougent.
- La rotation vers la direction de marche (feature 03) reste visible : le personnage se tourne et marche vers la direction voulue.
- En voiture, le personnage disparaît (feature 07, comportement inchangé).

### Sonore

Aucun son ajouté par cette feature.

### Mouvement de caméra

Aucun changement. La caméra orbitale (feature 09) suit le personnage comme avant.

## Règles et limites

| Paramètre | Valeur | Raison |
|-----------|--------|--------|
| Budget polycount mesh personnage | < 10 000 tris | Low-poly Mixamo — acceptable pour un proto, permet d'avoir des PNJ futurs |
| Résolution texture albedo (si fournie par Mixamo) | max 1 024 × 1 024 px | Limite mémoire proto |
| Animations | idle + walk uniquement | Minimaliste — les autres animations (run, jump, etc.) sont hors proto v0.1 |
| Transition d'animations | instantanée (pas de blend) | Simplicité du proto |
| CollisionShape3D | CapsuleShape3D inchangée (h = 1.8 m, r = 0.4 m) | La physique ne dépend pas du mesh visuel |
| Offset mesh si nécessaire | rotation_degrees.y sur le nœud conteneur | Corrige l'orientation d'export Mixamo sans toucher à la logique de rotation du CharacterBody3D |
| AnimationPlayer absent (mock) | ignoré silencieusement | Le jeu ne crashe pas si le GLB n'est pas encore livré |

## Dépendances de design

- **Feature 03 — Personnage joueur** : fournit `scenes/player/player.tscn`, `src/player/player_controller.gd`, `get_state()`, la CapsuleShape3D et la logique de déplacement.
- **Feature 07 — Entrer / sortir d'un véhicule** : fournit le mécanisme `visible = false` en voiture, qui doit continuer à fonctionner avec le mesh 3D remplacé.

## Hors-périmètre

- Animations supplémentaires (run, sprint, saut, atterrissage, idle assis, etc.) : hors proto v0.1.
- Blend d'animations (AnimationTree avec BlendTree) : hors proto — transitions instantanées.
- Rig facial / animations faciales : hors proto.
- Textures / matériaux custom sur le personnage (en dehors de ce que Mixamo fournit avec le mesh) : hors périmètre de cette feature.
- PNJ (personnages non-joueurs) utilisant le même rig : feature ultérieure.
- Ragdoll / physique de corps : hors proto.
- Sons de pas synchronisés aux animations : hors proto v0.1.
- Ombre projetée par le personnage (déjà gérée par le moteur Godot nativement, aucun réglage nécessaire).
