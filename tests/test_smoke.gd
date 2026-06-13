extends GutTest

# Tests smoke : le projet boote et les scènes s'instancient sans erreur.
# Une scène cassée (référence morte, nœud manquant) échoue ici avant tout playtest.


func test_la_scene_principale_s_instancie() -> void:
	var principale: Node = load("res://main.tscn").instantiate()
	add_child_autofree(principale)
	assert_not_null(principale, "main.tscn doit s'instancier")


func test_le_monde_contient_un_sol_avec_collision() -> void:
	var monde: Node = load("res://scenes/world.tscn").instantiate()
	add_child_autofree(monde)
	var sol: Node = monde.get_node("Sol")
	assert_true(sol is StaticBody3D, "le sol doit être un StaticBody3D")
	var collision: Node = sol.get_node("SolCollision")
	assert_true(collision is CollisionShape3D, "le sol doit avoir une CollisionShape3D")
	assert_not_null((collision as CollisionShape3D).shape, "la collision du sol doit avoir une forme")


func test_le_monde_a_une_lumiere_avec_ombres() -> void:
	var monde: Node = load("res://scenes/world.tscn").instantiate()
	add_child_autofree(monde)
	var soleil: Node = monde.get_node("Soleil")
	assert_true(soleil is DirectionalLight3D, "le monde doit avoir une lumière directionnelle")
	assert_true((soleil as DirectionalLight3D).shadow_enabled, "le soleil doit projeter des ombres")


func test_le_monde_a_un_environnement_ciel() -> void:
	var monde: Node = load("res://scenes/world.tscn").instantiate()
	add_child_autofree(monde)
	var ciel: Node = monde.get_node("Ciel")
	assert_true(ciel is WorldEnvironment, "le monde doit avoir un WorldEnvironment")
	assert_not_null((ciel as WorldEnvironment).environment, "l'environnement doit être défini")


func test_main_contient_joueur_et_camera() -> void:
	var principale: Node = load("res://main.tscn").instantiate()
	add_child_autofree(principale)
	assert_true(principale.get_node("Joueur") is CharacterBody3D, "main.tscn doit instancier le Joueur")
	assert_true(principale.get_node("CameraRig") is Node3D, "main.tscn doit instancier le CameraRig")


func test_le_joueur_est_un_corps_avec_collision() -> void:
	var joueur: Node = load("res://scenes/player.tscn").instantiate()
	add_child_autofree(joueur)
	assert_true(joueur is CharacterBody3D, "le joueur doit être un CharacterBody3D")
	var collision: Node = joueur.get_node("Collision")
	assert_not_null((collision as CollisionShape3D).shape, "le joueur doit avoir une forme de collision")


func test_sans_input_la_direction_du_joueur_est_nulle() -> void:
	var joueur: CharacterBody3D = load("res://scenes/player.tscn").instantiate()
	add_child_autofree(joueur)
	assert_eq(joueur._direction_voulue(), Vector3.ZERO, "sans touche pressée, aucune direction")


func test_le_rig_a_un_bras_et_une_camera_active() -> void:
	var rig: Node = load("res://scenes/camera_rig.tscn").instantiate()
	add_child_autofree(rig)
	var bras: Node = rig.get_node("SpringArm3D")
	assert_true(bras is SpringArm3D, "le rig doit avoir un SpringArm3D")
	var camera: Node = bras.get_node("Camera3D")
	assert_true((camera as Camera3D).current, "la caméra du rig doit être active")


func test_definir_cible_assigne_la_cible() -> void:
	var rig: Node = load("res://scenes/camera_rig.tscn").instantiate()
	add_child_autofree(rig)
	var faux_cible := Node3D.new()
	add_child_autofree(faux_cible)
	rig.definir_cible(faux_cible)
	assert_eq(rig.cible, faux_cible, "definir_cible doit mémoriser la cible")
