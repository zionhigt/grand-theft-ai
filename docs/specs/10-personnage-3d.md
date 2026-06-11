# Spec 10 — Personnage 3D Mixamo (remplacement mock capsule)

## Contexte

- Design : `docs/design/10-personnage-3d.md`
- Bon de commande graphique : `docs/assets/10-personnage-3d.md`
- Dépendances de specs précédentes :
  - **Spec 03 — Personnage joueur** (`docs/specs/03-personnage-joueur.md`) : fournit `scenes/player/player.tscn` (nœud `Player : CharacterBody3D`, enfants `CollisionShape3D` + `MeshInstance3D` CapsuleMesh mock), `src/player/player_controller.gd` (`class_name PlayerController`, méthodes `get_state() -> String`, `apply_movement`, `apply_gravity`, `rotate_toward_direction`).
  - **Spec 07 — Entrée / sortie véhicule** (`docs/specs/07-entree-sortie-vehicule.md`) : `GameState._player_mesh` est résolu via `_player.get_node_or_null("MeshInstance3D")`. Cette feature renomme ce nœud et change l'arborescence — impact décrit en section "Impact sur les specs existantes".

## Objectif fonctionnel

Remplacer le mesh capsule rouge placeholder (`MeshInstance3D` CapsuleMesh) dans `scenes/player/player.tscn` par un conteneur `PlayerBody : Node3D` destiné à accueillir le GLB humanoïde Mixamo. Ajouter un unique `AnimationPlayer` piloté par `player_controller.gd` qui joue les animations "idle" et "walk" selon `get_state()`. Tant que les GLB ne sont pas livrés, le `PlayerBody` reste vide (aucun mesh visible) et l'`AnimationPlayer` existe mais est vide — le jeu reste lançable et jouable. Quand les trois GLB sont livrés, le developer les intègre dans `player.tscn` selon les instructions de cette spec.

## Arborescence cible

```
.
├── scenes/
│   └── player/
│       └── player.tscn                  # modifié — MeshInstance3D remplacé par PlayerBody + AnimationPlayer
├── src/
│   └── player/
│       └── player_controller.gd         # modifié — ajout de @onready _anim_player + _update_animation()
├── src/
│   └── core/
│       └── game_state.gd                # modifié — _player_mesh remplacé par _player_body (Node3D)
├── tests/
│   └── test_10_personnage_3d.gd         # à écrire par le tester
└── assets/
    └── characters/
        └── player/
            ├── player_body.glb          # fourni (présent sur disque) — intégrer dans PlayerBody
            ├── player_idle.glb          # fourni (présent sur disque) — charger dans AnimationPlayer
            └── player_walk.glb          # fourni (présent sur disque) — charger dans AnimationPlayer
```

Notes :
- `player.glb` déclaré en feature 03 est désormais obsolète. Le nœud `MeshInstance3D` qui le référençait (sous forme de mock) est retiré et remplacé par `PlayerBody : Node3D`.
- `game_state.gd` est modifié : `_player_mesh: MeshInstance3D` devient `_player_body: Node3D` afin de pointer sur le nouveau nœud conteneur `PlayerBody`.
- Les GLB étant présents sur disque, le developer les intègre directement — il n'y a pas de phase "mock vide" à maintenir.

## Interface publique (GDScript)

### `src/player/player_controller.gd` (modifié)

Toutes les signatures de la spec 03 restent inchangées. Les ajouts sont :

```gdscript
class_name PlayerController
extends CharacterBody3D

# (tout le contenu existant de la spec 03 est conservé intact)

# --- Référence animation (ajoutée par feature 10) ---

@onready var _anim_player: AnimationPlayer = $AnimationPlayer
# Référence au nœud AnimationPlayer enfant direct.
# Null si le nœud n'existe pas (mode dégradé sans crash).

# --- Méthodes ajoutées ---

func _update_animation() -> void
# Pilote l'AnimationPlayer selon get_state().
# Pré-condition : appelée après move_and_slide() et la mise à jour de _state dans _physics_process.
# Comportement :
#   - Si _anim_player == null : return immédiat (défensif, pas de crash).
#   - Si get_state() == "walk" et animation courante != "walk" : _anim_player.play("walk").
#   - Si get_state() == "idle" et animation courante != "idle" : _anim_player.play("idle").
#   - Si l'animation demandée n'existe pas dans l'AnimationPlayer : return silencieux
#     (guard : if not _anim_player.has_animation(anim_name): return).
# Aucun blend, transition instantanée.
```

`_physics_process` est étendu (après la mise à jour de `_state`) :

```gdscript
func _physics_process(delta: float) -> void:
    var direction := compute_input_direction()
    if not is_on_floor():
        apply_gravity(delta)
    apply_movement(direction)
    rotate_toward_direction(direction, delta)
    move_and_slide()
    _state = "walk" if direction != Vector3.ZERO else "idle"
    _update_animation()   # <-- ajout feature 10
```

### `src/core/game_state.gd` (modifié — impact feature 10)

Un seul changement : la résolution du nœud visuel du joueur passe de `MeshInstance3D` à `PlayerBody` :

```gdscript
# Avant (feature 07) :
var _player_mesh: MeshInstance3D = null
# ...
_player_mesh = _player.get_node_or_null("MeshInstance3D") as MeshInstance3D

# Après (feature 10) :
var _player_body: Node3D = null
# ...
_player_body = _player.get_node_or_null("PlayerBody") as Node3D
```

Toutes les occurrences de `_player_mesh.visible` deviennent `_player_body.visible`. Toutes les gardes `if _player_mesh != null` deviennent `if _player_body != null`.

L'interface publique de `GameState` (signaux, méthodes publiques, enum) reste strictement inchangée.

## Structure des scènes (.tscn)

### `scenes/player/player.tscn` (modifiée)

Structure cible après implémentation de la feature 10 :

```
Player : CharacterBody3D
  (script = res://src/player/player_controller.gd)
  position = Vector3(0, 0.9, 0)
  up_direction = Vector3(0, 1, 0)
  floor_max_angle = 0.785398
  │
  ├── CollisionShape3D : CollisionShape3D
  │     shape = CapsuleShape3D
  │       height = 1.8
  │       radius = 0.4
  │     position = Vector3(0, 0, 0)
  │     # Inchangé depuis feature 03
  │
  ├── PlayerBody : Node3D
  │     position = Vector3(0, 0, 0)
  │     # Conteneur du mesh humanoïde et de son squelette
  │     # Les GLB étant livrés, leur contenu est intégré ici par le developer :
  │     # - Instancier res://assets/characters/player/player_body.glb comme scène enfant
  │     #   (ou importer le GLB et en déposer la scène instanciée comme enfant de PlayerBody)
  │     # - Le contenu importé du GLB fournit : Skeleton3D + MeshInstance3D(s)
  │     # - rotation_degrees.y peut être ajusté sur ce nœud si l'orientation Mixamo
  │     #   ne correspond pas à -Z (voir section "Données et constantes")
  │     #
  │     # Si les GLB ne sont pas intégrés à l'exécution (mode dégradé) :
  │     # PlayerBody reste un Node3D vide — le personnage est invisible mais le jeu tourne.
  │
  └── AnimationPlayer : AnimationPlayer
        # Nœud requis, enfant direct de Player, nommé exactement "AnimationPlayer"
        # Référencé depuis player_controller.gd via @onready var _anim_player = $AnimationPlayer
        #
        # Quand les GLB sont livrés :
        # - Importer les animations depuis player_idle.glb et player_walk.glb
        # - Créer une piste (ou importer) nommée "idle" (boucle, LOOP_LINEAR)
        # - Créer une piste (ou importer) nommée "walk" (boucle, LOOP_LINEAR)
        # - L'AnimationPlayer pilote les os du Skeleton3D présent dans PlayerBody
        #
        # Si les GLB ne sont pas intégrés : AnimationPlayer est présent mais vide.
        # _update_animation() gère ce cas via has_animation() — pas de crash.
        autoplay = ""   # pas d'animation automatique au démarrage
```

Nœuds supprimés par rapport à la version feature 03 :
- `MeshInstance3D` (avec CapsuleMesh + StandardMaterial3D rouge) — retiré définitivement.

### `main.tscn` (inchangée par cette feature)

L'arbre de `main.tscn` est inchangé. Le nœud `Player` est une instance de `scenes/player/player.tscn` — la modification de `player.tscn` se propage automatiquement. Seul `game_state.gd` est modifié (résolution de `_player_body` à la place de `_player_mesh`).

## Données et constantes

| Constante / Valeur | Type | Valeur | Rôle |
|--------------------|------|--------|------|
| Nom nœud conteneur mesh | `String` | `"PlayerBody"` | Chemin `$PlayerBody` depuis le CharacterBody3D — utilisé par GameState |
| Nom nœud AnimationPlayer | `String` | `"AnimationPlayer"` | Chemin `$AnimationPlayer` depuis le CharacterBody3D — référencé via @onready |
| Nom animation idle | `String` | `"idle"` | Nom exact de l'animation dans l'AnimationPlayer — `_anim_player.play("idle")` |
| Nom animation walk | `String` | `"walk"` | Nom exact de l'animation dans l'AnimationPlayer — `_anim_player.play("walk")` |
| Offset rotation mesh (si nécessaire) | `float` | `0.0` ou `180.0` deg | Sur `PlayerBody.rotation_degrees.y` — corrige l'orientation d'export Mixamo. Valeur à déterminer à l'implémentation. Si appliqué, commentaire obligatoire : `# Offset orientation export Mixamo — axe avant Mixamo = +Z, Godot forward = -Z` |
| CollisionShape3D | `CapsuleShape3D` | height=1.8, radius=0.4 | Inchangé depuis feature 03 |
| Budget polycount player_body.glb | `int` | < 10 000 tris | Contrainte Mixamo — proto |
| FPS animations | `int` | 30 | Réglage d'export Mixamo |

## Comportements attendus

Chaque point est testable unitairement avec GUT dans `tests/test_10_personnage_3d.gd`.

**B1.** La scène `res://scenes/player/player.tscn` instanciée contient un nœud `AnimationPlayer` enfant direct de `Player` :
`player.get_node_or_null("AnimationPlayer") != null` et `player.get_node("AnimationPlayer") is AnimationPlayer == true`.

**B2.** La scène `res://scenes/player/player.tscn` instanciée contient un nœud `PlayerBody` enfant direct de `Player` :
`player.get_node_or_null("PlayerBody") != null` et `player.get_node("PlayerBody") is Node3D == true`.

**B3.** La scène `res://scenes/player/player.tscn` instanciée ne contient plus de `MeshInstance3D` avec une `CapsuleMesh` enfant direct de `Player` : le nœud nommé `"MeshInstance3D"` est absent (`player.get_node_or_null("MeshInstance3D") == null`).

**B4.** `PlayerController` instancié et ajouté à l'arbre (`add_child_autofree`) possède la méthode `_update_animation` : `player_ctrl.has_method("_update_animation") == true`.

**B5.** Avec un `AnimationPlayer` mocké ayant une animation "walk" et une animation "idle" :
après `player_ctrl.velocity = Vector3(1.0, 0.0, 0.0)` (état walk) puis appel de `player_ctrl._update_animation()`, l'animation courante de l'`AnimationPlayer` est `"walk"`.

**B6.** Avec le même `AnimationPlayer` mocké, après `player_ctrl.velocity = Vector3(0.0, 0.0, 0.0)` (état idle) puis appel de `player_ctrl._update_animation()`, l'animation courante est `"idle"`.

**B7.** Appel de `player_ctrl._update_animation()` quand `_anim_player == null` (nœud absent) : aucune erreur GDScript levée, la méthode retourne sans crasher.

**B8.** Appel de `player_ctrl._update_animation()` avec un `AnimationPlayer` présent mais vide (aucune animation) : aucune erreur levée, la méthode retourne sans crasher (`has_animation()` guard actif).

**B9.** `GameState` instancié avec un `PlayerController` mock ayant un enfant `PlayerBody : Node3D` :
après `enter_vehicle(car_mock)`, `player_ctrl.get_node("PlayerBody").visible == false`.

**B10.** `GameState` instancié avec le même mock :
après `enter_vehicle(car_mock)` puis `exit_vehicle()`, `player_ctrl.get_node("PlayerBody").visible == true`.

**B11.** `GameState._ready()` avec un `PlayerController` ayant un enfant `PlayerBody` : `game_state._player_body != null` et `game_state._player_body is Node3D == true`.

**B12.** `GameState._ready()` avec un `PlayerController` sans enfant `PlayerBody` (nœud absent) : `game_state._player_body == null`, pas de crash dans `_ready()`.

## Cas limites / erreurs

**CL1.** `_update_animation()` appelé avec `velocity = Vector3(0.0, 5.0, 0.0)` (uniquement Y non nul — personnage en chute) → `get_state()` retourne `"idle"` (Y ignoré), animation "idle" jouée. Pas d'état "walk" sur axe vertical.

**CL2.** Changement d'état "idle" → "walk" → "idle" en 3 frames consécutives (appels successifs de `_update_animation()`) : pas de crash, animation finale est "idle". Les transitions sont instantanées — chaque appel remplace l'animation précédente.

**CL3.** `_update_animation()` appelé alors que l'animation courante est déjà l'animation cible (ex. "walk" → "walk") : `_anim_player.play()` n'est pas rappelé inutilement (guard `if _anim_player.current_animation != anim_name`). Pas de redémarrage de l'animation.

**CL4.** `PlayerBody` présent mais `PlayerBody.visible` déjà à `false` quand `exit_vehicle()` est appelé : `_player_body.visible = true` remet correctement à `true`. Pas de double-toggle problématique.

**CL5.** `game_state._player_body == null` lors de `enter_vehicle` : le guard `if _player_body != null` empêche le crash. La transition `player_mode = IN_VEHICLE` s'effectue quand même. `player_body.visible` n'est pas modifié (déjà visible mais joueur non affecté côté logique).

## Inputs Godot (Input Map)

Aucun changement requis dans `project.godot`. Les actions `move_forward`, `move_backward`, `move_left`, `move_right` et `interact` déclarées dans les specs 03 et 07 restent inchangées.

## Impact sur les specs existantes

### Spec 07 — `game_state.gd` : changement de `_player_mesh` vers `_player_body`

La spec 07 spécifie que `GameState._player_mesh` est résolu via :
```gdscript
_player_mesh = _player.get_node_or_null("MeshInstance3D") as MeshInstance3D
```
et que `_player_mesh.visible` est mis à `false` / `true` lors de `enter_vehicle` / `exit_vehicle`.

La feature 10 supprime le nœud `MeshInstance3D` enfant direct de `Player` et le remplace par `PlayerBody : Node3D`. La variable `_player_mesh: MeshInstance3D` est renommée `_player_body: Node3D` dans `game_state.gd`.

Conséquence sur les tests existants de `test_07_entree_sortie_vehicule.gd` :
- **B4** : vérifie que l'enfant `MeshInstance3D` a `visible == false` après `enter_vehicle`. Ce test doit être mis à jour par le tester pour vérifier `get_node("PlayerBody").visible == false`.
- **B7** : vérifie que l'enfant `MeshInstance3D` a `visible == true` après `exit_vehicle`. Idem — `PlayerBody.visible`.

Le tester **doit** adapter les tests B4 et B7 de `test_07` lors de l'écriture de `test_10`, ou dans un fichier de régression distinct si les tests 07 sont considérés figés.

### Spec 03 — `player.tscn` : retrait du nœud `MeshInstance3D`

La spec 03 liste dans ses critères d'acceptation :
> L'arbre de `player.tscn` dans l'éditeur affiche : `Player : CharacterBody3D` > `CollisionShape3D` + `MeshInstance3D`.

Après feature 10, l'arbre devient : `Player : CharacterBody3D` > `CollisionShape3D` + `PlayerBody` + `AnimationPlayer`. Ce critère d'acceptation de la spec 03 est obsolète dès que la feature 10 est implémentée.

Le test **B3 de la présente spec** (spec 10) valide explicitement l'absence du nœud `MeshInstance3D` — il joue le rôle de test de régression inverse.

## Assets consommés

| Chemin `res://` | Mock attendu | Usage dans la scène |
|-----------------|-------------|---------------------|
| `res://assets/characters/player/player_body.glb` | non (GLB livré) | Instancié comme scène enfant de `PlayerBody : Node3D` dans `player.tscn` — fournit le mesh humanoïde + Skeleton3D |
| `res://assets/characters/player/player_idle.glb` | non (GLB livré) | Animation "idle" importée dans l'`AnimationPlayer` de `player.tscn` |
| `res://assets/characters/player/player_walk.glb` | non (GLB livré) | Animation "walk" importée dans l'`AnimationPlayer` de `player.tscn` |

Note : les GLB étant présents sur disque, il n'y a pas de mock primitif à maintenir pour cette feature. Si pour une raison quelconque un GLB était absent à l'exécution, le comportement dégradé est :
- `PlayerBody` vide → personnage invisible mais jeu lançable.
- `AnimationPlayer` vide → `has_animation()` retourne `false` → `_update_animation()` retourne silencieusement.

Le nœud `PlayerBody` doit toujours porter le commentaire suivant tant que l'intégration GLB n'est pas faite :
```gdscript
# MOCK — à remplacer par instance de res://assets/characters/player/player_body.glb
```
L'`AnimationPlayer` doit porter :
```gdscript
# MOCK — animations idle/walk absentes, à remplir depuis :
#   res://assets/characters/player/player_idle.glb
#   res://assets/characters/player/player_walk.glb
```

## Dépendances

- **Spec 03 — Personnage joueur** : `PlayerController`, `player.tscn`, `CollisionShape3D` inchangée, méthode `get_state()`.
- **Spec 07 — Entrée / sortie véhicule** : `GameState._player_body` remplace `_player_mesh` — impact documenté ci-dessus.
- **`addons/gut/`** : addon GUT v9.6, installé dans `addons/gut/`. Aucun autre addon autorisé.
- Aucun addon supplémentaire requis. L'`AnimationPlayer` est natif Godot 4.6.

## Critères d'acceptation

- [ ] Le fichier `scenes/player/player.tscn` s'ouvre dans l'éditeur Godot 4.6 sans warning rouge.
- [ ] L'arbre de `player.tscn` affiche : `Player : CharacterBody3D` > `CollisionShape3D` + `PlayerBody : Node3D` + `AnimationPlayer : AnimationPlayer`. Le nœud `MeshInstance3D` avec `CapsuleMesh` est absent.
- [ ] `src/player/player_controller.gd` compile sans erreur GDScript : la méthode `_update_animation()` est définie et `@onready var _anim_player` est déclaré.
- [ ] `src/core/game_state.gd` compile sans erreur GDScript : `_player_body: Node3D` est déclaré, `_player_mesh` est absent.
- [ ] `godot --path . res://main.tscn` se lance sans `ERROR:` ni `SCRIPT ERROR:` dans la console.
- [ ] En jeu : le personnage humanoïde est visible debout sur le sol (mesh GLB rendu).
- [ ] En jeu : déplacer le personnage (ZQSD/WASD) déclenche l'animation "walk" visible. Relâcher les touches déclenche l'animation "idle".
- [ ] En jeu : entrer dans la voiture (touche E) fait disparaître le personnage humanoïde (PlayerBody.visible = false).
- [ ] En jeu : sortir de la voiture (touche E) fait réapparaître le personnage humanoïde.
- [ ] La commande `godot --headless -s res://addons/gut/gut_cmdln.gd -gdir=res://tests -gexit` retourne 0 (tous les tests, y compris `test_10_personnage_3d.gd`, passent au vert).
- [ ] Les 12 comportements attendus (B1 à B12) passent au vert dans GUT.
- [ ] Les 5 cas limites (CL1 à CL5) passent au vert dans GUT.
- [ ] Les tests B4 et B7 de `test_07_entree_sortie_vehicule.gd` ont été adaptés pour pointer sur `PlayerBody` au lieu de `MeshInstance3D`, et passent au vert.

## Hors-périmètre

- Animations supplémentaires (run, sprint, saut, atterrissage) : hors proto v0.1.
- Blend d'animations (AnimationTree, BlendTree) : hors proto — transitions instantanées.
- Rig facial / animations faciales : hors proto.
- Sons de pas synchronisés aux animations : hors proto v0.1.
- AnimationTree : non requis pour les 2 animations. L'`AnimationPlayer` simple suffit.
- PNJ réutilisant le même rig : feature ultérieure.
- Ragdoll / physique de corps : hors proto.
- Matériaux et textures custom au-delà de ce que Mixamo fournit avec le mesh : hors périmètre.
- `res://assets/characters/player/player.glb` (déclaré obsolète en bon de commande 10) : ne pas réintégrer.
