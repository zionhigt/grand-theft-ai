# Spec 01 — Bootstrap projet (Godot 4.6 + GUT)

## Contexte

- Design : `docs/design/01-bootstrap.md`
- Bon de commande : `docs/assets/01-bootstrap.md` (aucun asset graphique — statut `n/a`)
- Dépendances de specs précédentes : aucune (feature racine)

## Objectif fonctionnel

Mettre en place le squelette technique du projet Godot 4.6 : fichier `project.godot` valide, scène d'entrée `main.tscn` affichant un fond uni gris foncé, addon GUT installé et activé, dossiers de travail créés, et un module GDScript de santé (`VersionInfo`) testable sans dépendance au rendu, accompagné d'un autoload `Game` servant de point d'entrée applicatif.

À l'issue de cette feature, la commande `godot --path . res://main.tscn` se lance sans erreur et la commande headless GUT retourne le code 0.

## Arborescence cible

```
.
├── project.godot                        # créé — config Godot 4.6 minimale
├── main.tscn                            # créé — scène d'entrée (Node3D + Camera3D + WorldEnvironment)
├── src/
│   └── core/
│       ├── version_info.gd              # créé — constantes de version + get_full_label()
│       └── game.gd                      # créé — autoload Game (extends Node)
├── scenes/                              # créé — vide (.gitkeep)
├── assets/                              # créé — vide (.gitkeep)
├── tests/
│   └── test_01_bootstrap.gd             # à écrire par le tester
└── addons/
    └── gut/                             # dépendance externe — copié par le developer
```

## Interface publique (GDScript)

### `src/core/version_info.gd`

```gdscript
class_name VersionInfo

const GAME_NAME: String = "Grand Theft AI"
const GAME_VERSION: String = "0.1.0-bootstrap"

static func get_full_label() -> String
```

- `get_full_label()` retourne `"%s %s" % [GAME_NAME, GAME_VERSION]`, soit `"Grand Theft AI 0.1.0-bootstrap"`.
- La classe n'étend rien (`extends RefCounted` implicite en GDScript 4). Aucun signal. Aucune propriété exportée. Aucune dépendance moteur.

---

### `src/core/game.gd`

```gdscript
class_name Game
extends Node

var version_label: String

func _ready() -> void

func is_bootstrapped() -> bool
```

- `version_label` est initialisé à `VersionInfo.get_full_label()` lors de l'appel à `_ready()`.
- `is_bootstrapped()` retourne `true` si et seulement si `_ready()` a déjà été exécuté ; retourne `false` sinon.
- La sentinelle interne est une variable privée `_ready_called: bool` initialisée à `false`, passée à `true` en début de `_ready()`.
- Appels successifs à `_ready()` sont idempotents : `_ready_called` reste `true`, `version_label` reste inchangé.

Déclaration complète attendue :

```gdscript
class_name Game
extends Node

var version_label: String = ""
var _ready_called: bool = false

func _ready() -> void:
    if _ready_called:
        return
    _ready_called = true
    version_label = VersionInfo.get_full_label()

func is_bootstrapped() -> bool:
    return _ready_called
```

## Structure des scènes (.tscn)

### `main.tscn`

```
Main  [Node3D]  (scène racine)
├── Camera3D   [Camera3D]  (current = true, position = Vector3(0, 1, 5), rotation = Vector3(0, 0, 0))
└── WorldEnvironment  [WorldEnvironment]
        └── (propriété `environment`)  [Environment]
                background_mode = Sky.BG_COLOR
                background_color = Color(0.133, 0.133, 0.200, 1.0)   # #222233
```

Notes de structure :
- Le nœud racine est nommé `Main` et est de type `Node3D`. Il ne porte aucun script.
- `Camera3D` a sa propriété `current` à `true` (seule caméra active). Pas de script.
- `WorldEnvironment` embarque directement une ressource `Environment` inline (pas de fichier `.tres` séparé pour cette feature). La couleur de fond `#222233` correspond à `Color(0.133, 0.133, 0.200, 1.0)`.
- Aucun éclairage, aucun mesh, aucun nœud de gameplay. Aucun mock car aucun asset n'est requis.

## Données et constantes

| Identifiant | Valeur | Emplacement | Rôle |
|---|---|---|---|
| `VersionInfo.GAME_NAME` | `"Grand Theft AI"` | `src/core/version_info.gd` | Nom officiel du jeu |
| `VersionInfo.GAME_VERSION` | `"0.1.0-bootstrap"` | `src/core/version_info.gd` | Version courante |
| Couleur de fond | `Color(0.133, 0.133, 0.200, 1.0)` (#222233) | `main.tscn` — ressource `Environment` | Fond uni gris foncé de la scène principale |
| Position `Camera3D` | `Vector3(0, 1, 5)` | `main.tscn` | Caméra par défaut, regardant vers l'origine |

## Comportements attendus

Chaque point est testable unitairement avec GUT dans `tests/test_01_bootstrap.gd`.

1. `VersionInfo.GAME_NAME` vaut exactement `"Grand Theft AI"`.
2. `VersionInfo.GAME_VERSION` vaut exactement `"0.1.0-bootstrap"`.
3. `VersionInfo.get_full_label()` retourne exactement `"Grand Theft AI 0.1.0-bootstrap"`.
4. Un nouvel objet `Game` instancié sans appel à `_ready()` retourne `false` à `is_bootstrapped()`.
5. Après un appel explicite à `_ready()` sur l'objet `Game`, `is_bootstrapped()` retourne `true`.
6. Après `_ready()`, `Game.version_label` vaut `"Grand Theft AI 0.1.0-bootstrap"`.

## Cas limites / erreurs

1. `Game._ready()` appelé deux fois consécutivement : `is_bootstrapped()` reste `true` et `version_label` reste `"Grand Theft AI 0.1.0-bootstrap"` (idempotence garantie par la sentinelle `_ready_called`).
2. `VersionInfo.get_full_label()` ne dépend d'aucune instance ni d'aucun singleton moteur — elle peut être appelée depuis un test headless sans scène active.
3. `Game.version_label` avant `_ready()` vaut `""` (valeur d'initialisation par défaut) — ce comportement est documenté mais ne constitue pas une erreur.

## Inputs Godot (Input Map)

Aucun input à configurer pour cette feature. La section `[input]` de `project.godot` reste vide.

## Assets consommés

| Chemin `res://` | Mock attendu | Usage |
|---|---|---|
| (aucun) | — | Cette feature ne consomme aucun asset graphique, sonore ou de mesh. |

## Dépendances

- **`addons/gut/`** : addon GUT v9.4 ou supérieur, compatible Godot 4.6 (la branche 9.4+ supporte Godot 4.4+). Installation externe — le developer copie le dossier dans le projet ou l'installe via l'éditeur Godot (AssetLib). Aucun autre addon autorisé pour cette feature.
- Aucune autre spec en dépendance.

### Configuration `project.godot`

Le fichier `project.godot` doit contenir au minimum :

```ini
; Engine configuration file — généré pour Godot 4.6
; Format : sections INI

config_version=5

[application]

config/name="Grand Theft AI"
run/main_scene="res://main.tscn"
config/features=PackedStringArray("4.6")

[autoload]

Game="*res://src/core/game.gd"

[editor_plugins]

enabled=PackedStringArray("res://addons/gut/plugin.cfg")
```

Notes :
- `config/features` doit contenir la version Godot ciblée (ici `"4.6"`).
- L'autoload `Game` est déclaré avec le préfixe `*` pour indiquer qu'il doit être instancié automatiquement.
- La section `[editor_plugins]` active GUT.
- Les sections `[input]` et `[physics]` sont absentes (valeurs par défaut moteur).

## Critères d'acceptation

- [ ] Le fichier `project.godot` est présent à la racine du projet, `config_version=5`, contient `config/name="Grand Theft AI"`, `run/main_scene="res://main.tscn"`, l'autoload `Game` et l'entrée `editor_plugins` pour GUT.
- [ ] `godot --path . res://main.tscn` se lance sans erreur dans la console (code de sortie 0, aucun `ERROR:` ni `SCRIPT ERROR:` affiché).
- [ ] La fenêtre affichée montre un fond uni de couleur `#222233` (gris foncé tirant vers le bleu), sans aucun autre élément visuel.
- [ ] `main.tscn` s'ouvre dans l'éditeur Godot 4.6 sans erreur et affiche l'arbre `Main > Camera3D + WorldEnvironment`.
- [ ] Le fichier `src/core/version_info.gd` est présent et la classe `VersionInfo` est reconnue par GDScript sans erreur.
- [ ] Le fichier `src/core/game.gd` est présent et la classe `Game` est reconnue par GDScript sans erreur.
- [ ] L'addon GUT est présent dans `addons/gut/` et activé (`plugin.cfg` lisible).
- [ ] La commande `godot --headless -s res://addons/gut/gut_cmdln.gd -gdir=res://tests -gexit` retourne le code de sortie 0 (suite vide ou suite verte).
- [ ] Les 6 comportements attendus de la section "Comportements attendus" passent tous au vert dans GUT.
- [ ] Les dossiers `src/`, `scenes/`, `assets/`, `tests/` existent dans l'arborescence du projet.

## Hors-périmètre

- Tout éclairage, sol, ciel ou environnement 3D détaillé : feature 02.
- Tout personnage, véhicule, bâtiment : features 03 à 08.
- Configuration des inputs clavier : feature 03 et suivantes.
- Tout écran de menu, HUD, ou UI quelconque.
- La génération automatique de `project.godot` par l'éditeur Godot (le developer crée le fichier manuellement ou via l'éditeur — les deux approches sont valides).
- Les assets graphiques finaux (`.glb`, `.png`, `.ogg`) : aucun n'est requis par cette feature.
