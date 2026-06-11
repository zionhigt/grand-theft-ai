# De : tester → developer
# Date : 2026-05-31
# Sujet : Tests rouges feature 03 — Personnage joueur déplaçable — prêts pour implémentation

## Statut

Le fichier `tests/test_03_personnage_joueur.gd` est écrit et prêt.

La commande GUT headless n'a pas pu être exécutée dans cet environnement (Godot 4.6 non disponible en CLI sur la machine d'intégration). Les tests sont structurellement corrects et seront rouges dès le premier lancement sur poste, car `res://src/player/player_controller.gd` n'existe pas encore — le `preload` en tête de fichier déclenchera une erreur de chargement GUT immédiate.

## Ce que couvrent les tests

21 tests au total :

### Comportements attendus (B1–B15)

| Test | Comportement |
|---|---|
| `test_la_constante_speed_est_5` | B1 — SPEED == 5.0 |
| `test_la_constante_gravity_est_9_8` | B2 — GRAVITY == 9.8 |
| `test_la_constante_rotation_speed_est_8` | B3 — ROTATION_SPEED == 8.0 |
| `test_les_proprietes_exportees_correspondent_aux_constantes` | B4 — propriétés @export |
| `test_apply_movement_vers_la_droite_donne_velocity_x_egal_speed` | B5 — direction +X |
| `test_apply_movement_vers_l_avant_donne_velocity_z_negatif_egal_speed` | B6 — direction -Z |
| `test_apply_movement_zero_arrete_net_le_personnage` | B7 — arrêt net |
| `test_apply_gravity_diminue_velocity_y_de_gravity_fois_delta` | B8 — gravité |
| `test_apply_movement_diagonal_norme_ne_cree_pas_de_sur_vitesse` | B9 — pas de sur-vitesse diagonale |
| `test_get_state_retourne_walk_apres_mouvement_et_idle_a_l_arret` | B10 — état walk/idle |
| `test_rotate_toward_direction_converge_vers_la_cible_avec_grand_delta` | B11 — rotation convergente |
| `test_rotate_toward_direction_zero_ne_modifie_pas_la_rotation` | B12 — rotation sans effet sur ZERO |
| `test_main_tscn_contient_un_noeud_player_characterbody3d` | B13 — Player dans main.tscn |
| `test_main_tscn_contient_un_noeud_ground_collider_staticbody3d` | B14 — GroundCollider dans main.tscn |
| `test_le_noeud_player_porte_le_script_player_controller` | B15 — script PlayerController attaché |

### Cas limites (CL1–CL6)

| Test | Cas limite |
|---|---|
| `test_compute_input_direction_sans_input_retourne_zero` | CL1 — no-input → ZERO |
| `test_apply_gravity_avec_delta_zero_ne_change_pas_velocity_y` | CL2 — delta=0 sans effet |
| `test_apply_movement_avec_direction_unitaire_donne_velocity_egal_speed` | CL3 — direction unitaire |
| `test_rotate_toward_direction_avec_composante_y_ne_modifie_pas_rotation_x_z` | CL4 — robustesse composante Y |
| `test_deux_instances_player_controller_ont_des_velocity_independants` | CL5 — isolation des instances |
| `test_methodes_ne_crashent_pas_sans_parent_dans_le_scene_tree` | CL6 — pas de crash hors SceneTree |

## Prochaine étape

Le `developer` doit créer :
- `src/player/player_controller.gd` (`class_name PlayerController extends CharacterBody3D`)
- `scenes/player/player.tscn`
- Modifier `main.tscn` pour ajouter `GroundCollider : StaticBody3D` et `Player` (instance de `player.tscn`)
- Compléter la section `[input]` de `project.godot` avec les quatre actions `move_*`

Référence spec : `docs/specs/03-personnage-joueur.md`
