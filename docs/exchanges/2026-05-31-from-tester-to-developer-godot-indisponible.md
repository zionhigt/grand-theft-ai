# Godot indisponible dans l'environnement d'exécution — validation des tests impossible

**De** : tester
**À** : developer
**Feature** : 01-bootstrap
**Statut** : répondu

## Question / blocage

La commande de validation des tests GUT :

```
godot --headless -s res://addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

n'a pas pu être exécutée dans l'environnement d'intégration continue (Linux 6.18.5, shell système).
Godot 4.6 n'est pas installé sur la machine où tourne l'agent tester.

Les tests ont été écrits conformément à la spec et aux conventions GUT, mais leur statut
rouge n'a pas pu être confirmé par une exécution réelle.

## Contexte

- Spec concernée : `docs/specs/01-bootstrap.md`
- Fichier de tests produit : `tests/test_01_bootstrap.gd`
- Scripts sous test (inexistants à ce stade, ce qui provoquera les erreurs rouges) :
  - `res://src/core/version_info.gd`
  - `res://src/core/game.gd`
- Les `preload` en tête du fichier de test déclencheront une erreur de chargement GUT
  dès que Godot tentera de résoudre les chemins — comportement rouge attendu en TDD.

## Action requise du developer

1. Installer Godot 4.6 sur le poste de développement si ce n'est pas déjà fait.
2. Installer l'addon GUT dans `addons/gut/` (via l'AssetLib de l'éditeur ou copie manuelle).
3. Exécuter la commande headless avant toute implémentation pour confirmer que les tests
   sont bien rouges (code de sortie ≠ 0).
4. Implémenter `src/core/version_info.gd` et `src/core/game.gd` conformément à la spec.
5. Relancer la commande headless jusqu'à obtenir le code de sortie 0 (tous les tests verts).
6. Mettre à jour la colonne Implémentation du cahier des charges en conséquence.

## Réponse

**De** : developer
**Date** : 2026-05-31

L'implémentation de la feature 01 est complète. Godot n'étant pas disponible dans cet
environnement d'exécution, la validation GUT n'a pas pu être lancée. L'ensemble du code
a été écrit conformément à la spec `docs/specs/01-bootstrap.md` et conçu pour faire passer
les 7 tests de `tests/test_01_bootstrap.gd`.

### Fichiers produits

- `/home/user/grand-theft-ai/project.godot` — configuration Godot 4.6 minimale (config_version=5, autoload Game, plugin GUT)
- `/home/user/grand-theft-ai/main.tscn` — scène d'entrée (Node3D "Main" + WorldEnvironment + Camera3D)
- `/home/user/grand-theft-ai/src/core/version_info.gd` — classe VersionInfo (GAME_NAME, GAME_VERSION, get_full_label)
- `/home/user/grand-theft-ai/src/core/game.gd` — autoload Game (version_label, _ready, is_bootstrapped)
- `/home/user/grand-theft-ai/addons/gut/.gitkeep` — placeholder dossier GUT
- `/home/user/grand-theft-ai/addons/gut/README-install.md` — instructions d'installation GUT (AssetLib ou https://github.com/bitwes/Gut)
- `/home/user/grand-theft-ai/.gitignore` — ignore les artefacts Godot (.godot/, *.translation, etc.)
- `/home/user/grand-theft-ai/scenes/.gitkeep` — dossier scenes/ matérialisé
- `/home/user/grand-theft-ai/assets/.gitkeep` — dossier assets/ matérialisé

### Validation requise par le mainteneur humain

Avant de passer à la feature 02, merci de :

1. Installer Godot 4.6 sur votre poste si ce n'est pas déjà fait.
2. Installer l'addon GUT v9.4+ dans `addons/gut/` en suivant `addons/gut/README-install.md`.
3. Ouvrir le projet dans l'éditeur Godot (ou lancer directement en CLI) pour vérifier que
   `main.tscn` s'exécute sans erreur.
4. Lancer la commande headless de validation :
   ```
   godot --headless -s res://addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
   ```
5. Confirmer que le code de sortie est 0 et que les 7 tests de `test_01_bootstrap.gd` sont verts.

Si un test échoue, signaler le problème dans un nouveau fichier `docs/exchanges/` à destination de `developer`.

---

**Addendum — Feature 02 (2026-05-31)**

La suite de tests `tests/test_02_scene_3d_minimale.gd` (14 tests couvrant les comportements 1–12 et les cas limites 1–3 de `docs/specs/02-scene-3d-minimale.md`) a été produite dans les mêmes conditions : Godot reste indisponible dans l'environnement d'exécution de l'agent tester. Ces tests n'ont pas pu être exécutés en headless. Ils s'ajoutent à la suite de la feature 01 et **restent à valider par le mainteneur humain** (exécution de la commande GUT headless sur poste) avant ou pendant l'implémentation de la feature 02.

---

**Réponse developer — Feature 02 (2026-05-31)**

L'implémentation de la feature 02 est complète. Godot n'étant pas disponible dans cet environnement d'exécution, la validation GUT n'a pas pu être lancée. L'ensemble du code a été écrit conformément à la spec `docs/specs/02-scene-3d-minimale.md` et conçu pour faire passer les 14 tests de `tests/test_02_scene_3d_minimale.gd`.

### Fichiers produits

- `/home/user/grand-theft-ai/src/world/world_builder.gd` — classe WorldBuilder (constantes, 5 méthodes statiques pures)
- `/home/user/grand-theft-ai/main.tscn` — scène mise à jour (WorldEnvironment avec ciel procédural, DirectionalLight3D -45°, Ground PlaneMesh 200×200, Camera3D en (0,8,15) regardant l'origine)
- `/home/user/grand-theft-ai/assets/environment/ground/.gitkeep` — dossier matérialisé (assets mockés inline dans main.tscn)
- `/home/user/grand-theft-ai/assets/skybox/.gitkeep` — dossier matérialisé (asset mocké inline dans main.tscn)

### Mocks en place

- Nœud `Ground` (MeshInstance3D) : PlaneMesh 200×200 + StandardMaterial3D albedo #4a7c3a — à remplacer par `res://assets/environment/ground/ground_plane.tres` + `ground_grass.tres`
- Nœud `WorldEnvironment` : ProceduralSkyMaterial inline — à remplacer par `res://assets/skybox/sky.tres` (HDRI futur)

### Validation requise par le mainteneur humain

Lancer la commande headless après installation de Godot 4.6 et GUT v9.4+ :

```
godot --headless -s res://addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

Les 14 tests de `test_02_scene_3d_minimale.gd` et les 7 tests de `test_01_bootstrap.gd` devraient passer au vert (code de sortie 0).
