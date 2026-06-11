extends GutTest

# Tests unitaires — Feature 03 : Personnage joueur déplaçable (ZQSD/WASD)
#
# Chaque test cible un comportement numéroté de la spec docs/specs/03-personnage-joueur.md.
#
# Stratégie :
#   Les tests B1 à B12 et CL1 à CL6 exercent directement PlayerController
#   sans charger main.tscn. Le PlayerController est instancié manuellement.
#   Les tests B13 à B15 chargent main.tscn pour vérifier la structure de scène.
#
# En phase rouge : player_controller.gd n'existe pas encore.
#   Le preload en tête de fichier provoquera une erreur de chargement GUT — attendu.

# ---------------------------------------------------------------------------
# Préchargement du module sous test
# ---------------------------------------------------------------------------
const PlayerControllerScript = preload("res://src/player/player_controller.gd")

# ---------------------------------------------------------------------------
# SUT PlayerController — instancié pour chaque test
# ---------------------------------------------------------------------------

var sut  # PlayerController

func before_each() -> void:
	sut = PlayerControllerScript.new()
	add_child_autofree(sut)

func after_each() -> void:
	# add_child_autofree s'occupe du free — pas de free() manuel nécessaire
	pass

# ---------------------------------------------------------------------------
# B1 — PlayerController.SPEED == 5.0
# Spec §Comportements attendus point B1
# ---------------------------------------------------------------------------
func test_la_constante_speed_est_5() -> void:
	assert_eq(PlayerControllerScript.SPEED, 5.0)

# ---------------------------------------------------------------------------
# B2 — PlayerController.GRAVITY == 9.8
# Spec §Comportements attendus point B2
# ---------------------------------------------------------------------------
func test_la_constante_gravity_est_9_8() -> void:
	assert_eq(PlayerControllerScript.GRAVITY, 9.8)

# ---------------------------------------------------------------------------
# B3 — PlayerController.ROTATION_SPEED == 8.0
# Spec §Comportements attendus point B3
# ---------------------------------------------------------------------------
func test_la_constante_rotation_speed_est_8() -> void:
	assert_eq(PlayerControllerScript.ROTATION_SPEED, 8.0)

# ---------------------------------------------------------------------------
# B4 — Les propriétés exportées reprennent les valeurs des constantes
# Spec §Comportements attendus point B4
# ---------------------------------------------------------------------------
func test_les_proprietes_exportees_correspondent_aux_constantes() -> void:
	assert_eq(sut.speed, PlayerControllerScript.SPEED)
	assert_eq(sut.gravity, PlayerControllerScript.GRAVITY)
	assert_eq(sut.rotation_speed, PlayerControllerScript.ROTATION_SPEED)

# ---------------------------------------------------------------------------
# B5 — apply_movement(Vector3(1, 0, 0)) → velocity.x == speed, velocity.z == 0
# Spec §Comportements attendus point B5
# ---------------------------------------------------------------------------
func test_apply_movement_vers_la_droite_donne_velocity_x_egal_speed() -> void:
	sut.apply_movement(Vector3(1.0, 0.0, 0.0))
	assert_eq(sut.velocity.x, sut.speed)
	assert_eq(sut.velocity.z, 0.0)

# ---------------------------------------------------------------------------
# B6 — apply_movement(Vector3(0, 0, -1)) → velocity.z == -speed, velocity.x == 0
# Spec §Comportements attendus point B6
# ---------------------------------------------------------------------------
func test_apply_movement_vers_l_avant_donne_velocity_z_negatif_egal_speed() -> void:
	sut.apply_movement(Vector3(0.0, 0.0, -1.0))
	assert_eq(sut.velocity.z, -sut.speed)
	assert_eq(sut.velocity.x, 0.0)

# ---------------------------------------------------------------------------
# B7 — apply_movement(Vector3.ZERO) → velocity.x == 0.0 et velocity.z == 0.0
# Spec §Comportements attendus point B7
# ---------------------------------------------------------------------------
func test_apply_movement_zero_arrete_net_le_personnage() -> void:
	# D'abord on met de la vitesse
	sut.apply_movement(Vector3(1.0, 0.0, 0.0))
	# Puis on stoppe
	sut.apply_movement(Vector3.ZERO)
	assert_eq(sut.velocity.x, 0.0)
	assert_eq(sut.velocity.z, 0.0)

# ---------------------------------------------------------------------------
# B8 — apply_gravity(0.1) → velocity.y == -GRAVITY * 0.1 == -0.98
# Spec §Comportements attendus point B8
# ---------------------------------------------------------------------------
func test_apply_gravity_diminue_velocity_y_de_gravity_fois_delta() -> void:
	sut.velocity.y = 0.0
	sut.apply_gravity(0.1)
	assert_almost_eq(sut.velocity.y, -PlayerControllerScript.GRAVITY * 0.1, 0.001)

# ---------------------------------------------------------------------------
# B9 — Direction diagonale normalisée → velocity.length() ≈ speed (pas de sur-vitesse)
# Spec §Comportements attendus point B9
# ---------------------------------------------------------------------------
func test_apply_movement_diagonal_norme_ne_cree_pas_de_sur_vitesse() -> void:
	var direction_diagonale := Vector3(1.0, 0.0, -1.0).normalized()
	sut.apply_movement(direction_diagonale)
	assert_almost_eq(sut.velocity.length(), sut.speed, 0.001)

# ---------------------------------------------------------------------------
# B10 — get_state() retourne "walk" après mouvement, "idle" à l'arrêt
# Spec §Comportements attendus point B10
# ---------------------------------------------------------------------------
func test_get_state_retourne_walk_apres_mouvement_et_idle_a_l_arret() -> void:
	sut.apply_movement(Vector3(0.0, 0.0, -1.0))
	assert_eq(sut.get_state(), "walk")
	sut.apply_movement(Vector3.ZERO)
	assert_eq(sut.get_state(), "idle")

# ---------------------------------------------------------------------------
# B11 — rotate_toward_direction avec grand delta converge vers atan2(-1, 0) == -PI/2
# Spec §Comportements attendus point B11
# ---------------------------------------------------------------------------
func test_rotate_toward_direction_converge_vers_la_cible_avec_grand_delta() -> void:
	sut.rotation.y = 0.0
	sut.rotate_toward_direction(Vector3(1.0, 0.0, 0.0), 10.0)
	var angle_cible := atan2(-1.0, 0.0)  # -PI/2
	assert_almost_eq(sut.rotation.y, angle_cible, 0.01)

# ---------------------------------------------------------------------------
# B12 — rotate_toward_direction(Vector3.ZERO, ...) ne modifie pas rotation.y
# Spec §Comportements attendus point B12
# ---------------------------------------------------------------------------
func test_rotate_toward_direction_zero_ne_modifie_pas_la_rotation() -> void:
	sut.rotation.y = 1.23
	sut.rotate_toward_direction(Vector3.ZERO, 1.0)
	assert_almost_eq(sut.rotation.y, 1.23, 0.0001)

# ---------------------------------------------------------------------------
# B13 — main.tscn contient un nœud Player de classe CharacterBody3D
# Spec §Comportements attendus point B13
# ---------------------------------------------------------------------------
func test_main_tscn_contient_un_noeud_player_characterbody3d() -> void:
	var scene = load("res://main.tscn").instantiate()
	add_child_autofree(scene)
	var player_node = scene.get_node_or_null("Player")
	assert_not_null(player_node, "Le nœud Player doit exister dans main.tscn")
	assert_true(player_node is CharacterBody3D,
		"Le nœud Player doit être un CharacterBody3D")

# ---------------------------------------------------------------------------
# B14 — main.tscn contient un nœud GroundCollider de classe StaticBody3D
# Spec §Comportements attendus point B14
# ---------------------------------------------------------------------------
func test_main_tscn_contient_un_noeud_ground_collider_staticbody3d() -> void:
	var scene = load("res://main.tscn").instantiate()
	add_child_autofree(scene)
	var ground_collider = scene.get_node_or_null("GroundCollider")
	assert_not_null(ground_collider, "Le nœud GroundCollider doit exister dans main.tscn")
	assert_true(ground_collider is StaticBody3D,
		"Le nœud GroundCollider doit être un StaticBody3D")

# ---------------------------------------------------------------------------
# B15 — Le nœud Player porte le script PlayerController
# Spec §Comportements attendus point B15
# ---------------------------------------------------------------------------
func test_le_noeud_player_porte_le_script_player_controller() -> void:
	var scene = load("res://main.tscn").instantiate()
	add_child_autofree(scene)
	var player_node = scene.get_node("Player")
	assert_not_null(player_node, "Le nœud Player doit exister")
	assert_true(player_node is PlayerController,
		"Le nœud Player doit être de type PlayerController")

# ---------------------------------------------------------------------------
# CL1 — compute_input_direction() sans input actif retourne Vector3.ZERO
# Spec §Cas limites / erreurs point CL1
# ---------------------------------------------------------------------------
func test_compute_input_direction_sans_input_retourne_zero() -> void:
	# Aucune touche pressée en contexte headless → toutes les actions à 0
	# On s'assure qu'aucune action n'est active avant d'appeler la méthode
	Input.action_release("move_forward")
	Input.action_release("move_backward")
	Input.action_release("move_left")
	Input.action_release("move_right")
	var direction: Vector3 = sut.compute_input_direction()
	assert_eq(direction, Vector3.ZERO)

# ---------------------------------------------------------------------------
# CL2 — apply_gravity(0.0) ne modifie pas velocity.y (pas d'erreur, pas d'effet)
# Spec §Cas limites / erreurs point CL2
# ---------------------------------------------------------------------------
func test_apply_gravity_avec_delta_zero_ne_change_pas_velocity_y() -> void:
	sut.velocity.y = -3.5
	sut.apply_gravity(0.0)
	assert_almost_eq(sut.velocity.y, -3.5, 0.0001)

# ---------------------------------------------------------------------------
# CL3 — apply_movement avec vecteur unitaire donne velocity.x == speed
# Spec §Cas limites / erreurs point CL3
# La méthode applique direction * speed sans normaliser — l'appelant normalise.
# ---------------------------------------------------------------------------
func test_apply_movement_avec_direction_unitaire_donne_velocity_egal_speed() -> void:
	sut.apply_movement(Vector3(1.0, 0.0, 0.0))
	assert_almost_eq(sut.velocity.x, sut.speed, 0.0001)

# ---------------------------------------------------------------------------
# CL4 — rotate_toward_direction avec direction.y != 0 ne change pas rotation.x/.z
# Spec §Cas limites / erreurs point CL4
# ---------------------------------------------------------------------------
func test_rotate_toward_direction_avec_composante_y_ne_modifie_pas_rotation_x_z() -> void:
	sut.rotation = Vector3(0.0, 0.0, 0.0)
	# Direction avec composante Y non nulle — seul rotation.y doit changer
	sut.rotate_toward_direction(Vector3(0.0, 1.0, 0.0), 10.0)
	assert_almost_eq(sut.rotation.x, 0.0, 0.0001)
	assert_almost_eq(sut.rotation.z, 0.0, 0.0001)

# ---------------------------------------------------------------------------
# CL5 — Deux instances distinctes ont des velocity indépendants
# Spec §Cas limites / erreurs point CL5
# ---------------------------------------------------------------------------
func test_deux_instances_player_controller_ont_des_velocity_independants() -> void:
	var sut2 = PlayerControllerScript.new()
	add_child_autofree(sut2)

	sut.apply_movement(Vector3(1.0, 0.0, 0.0))
	sut2.apply_movement(Vector3.ZERO)

	assert_eq(sut.velocity.x, sut.speed)
	assert_eq(sut2.velocity.x, 0.0)

# ---------------------------------------------------------------------------
# CL6 — apply_movement, apply_gravity et rotate_toward_direction ne crashent pas
#        sans parent dans l'arbre de scène (test unitaire pur sans add_child)
# Spec §Cas limites / erreurs point CL6
# ---------------------------------------------------------------------------
func test_methodes_ne_crashent_pas_sans_parent_dans_le_scene_tree() -> void:
	# Instance séparée, jamais ajoutée au SceneTree
	var sut_sans_parent = PlayerControllerScript.new()

	# Ces trois appels ne doivent pas produire d'erreur ni de crash
	sut_sans_parent.apply_movement(Vector3(0.0, 0.0, -1.0))
	sut_sans_parent.apply_gravity(0.016)
	sut_sans_parent.rotate_toward_direction(Vector3(1.0, 0.0, 0.0), 0.016)

	# Si on arrive ici sans crash, le test passe
	assert_true(true, "Aucun crash ne doit survenir hors SceneTree")

	sut_sans_parent.free()
