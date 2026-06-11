# De : tester → developer
# Date : 2026-05-31
# Sujet : Tests feature 04 (Caméra troisième personne) — rouges prêts, Godot indisponible

## Statut

Les tests GUT de la feature 04 ont été écrits dans `tests/test_04_camera_tp.gd`.

La commande de validation :
```
godot --headless -s res://addons/Gut-9.6.0/addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```
n'a pas pu être exécutée car Godot n'est pas disponible dans l'environnement d'exécution de l'agent tester (Windows 11, CLI uniquement, pas de binaire `godot` dans le PATH).

## Raison pour laquelle les tests seront rouges

Le fichier `res://src/camera/camera_controller.gd` n'existe pas encore. Le `preload` en tête de `test_04_camera_tp.gd` provoquera immédiatement une erreur de chargement GUT, garantissant que tous les tests échouent (rouge) dès le premier lancement.

## Couverture des tests

| Test | Comportement couvert |
|------|---------------------|
| `test_la_constante_offset_est_vector3_0_3_6` | B1 |
| `test_la_constante_eye_height_est_1_6` | B2 |
| `test_process_avec_target_null_ne_modifie_pas_global_position` | B3 |
| `test_process_avec_target_a_l_origine_positionne_la_camera_a_offset` | B4 |
| `test_process_avec_target_deplace_positionne_la_camera_a_target_plus_offset` | B5 |
| `test_process_oriente_camera3d_vers_la_tete_de_la_cible` | B6 |
| `test_process_suit_instantanement_un_deplacement_de_la_cible` | B7 |
| `test_main_tscn_contient_un_noeud_camera_rig_de_classe_camera_controller` | B8 |
| `test_main_tscn_camera_rig_possede_un_enfant_camera3d_actif` | B9 |
| `test_main_tscn_ne_contient_pas_de_camera3d_enfant_direct_de_main` | B10 |
| `test_process_avec_target_null_retour_immediat_sans_exception` | CL1 |
| `test_process_cible_meme_position_que_rig_ne_crashe_pas` | CL2 |
| `test_process_avec_delta_nul_ne_produit_pas_d_erreur` | CL3 |
| `test_main_tscn_ne_contient_qu_une_seule_camera3d_avec_current_true` | CL4 |
| `test_process_avec_target_hors_scene_tree_positionne_a_offset_sans_crash` | CL5 |

## Tâche du developer

Implémenter `src/camera/camera_controller.gd` (class_name CameraController, extends Node3D)
et modifier `main.tscn` selon la spec `docs/specs/04-camera-tp.md` jusqu'à ce que tous
les 15 tests passent au vert.

Points d'attention pour l'implémentation :
- Le nœud enfant doit être nommé exactement `Camera3D` (le script accède via `$Camera3D`).
- `CameraRig` est enfant direct de `Main`, pas de `Player`.
- La `Camera3D` fixe héritée de la feature 02 doit être supprimée de `main.tscn`.
- La propriété `target` doit être assignée au nœud `Player` dans l'éditeur (NodePath `../Player`).
