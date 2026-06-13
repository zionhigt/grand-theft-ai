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


func test_la_ville_pose_des_batiments_avec_collision() -> void:
	var monde: Node = load("res://scenes/world.tscn").instantiate()
	add_child_autofree(monde)
	var ville: Node = monde.get_node("Ville")
	var batiments: Array = []
	for enfant in ville.get_children():
		if enfant is StaticBody3D:
			batiments.append(enfant)
	assert_eq(batiments.size(), 8, "la ville doit poser 8 bâtiments")
	for b in batiments:
		var collision: Node = null
		for e in b.get_children():
			if e is CollisionShape3D:
				collision = e
		assert_not_null(collision, "chaque bâtiment doit avoir une CollisionShape3D")


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
	assert_true(principale.get_node("Voiture") is VehicleBody3D, "main.tscn doit instancier la Voiture")
	var rig: Node = principale.get_node("CameraRig")
	assert_true(rig is Node3D, "main.tscn doit instancier le CameraRig")
	assert_eq(rig.cible, principale.get_node("Joueur"), "au démarrage la caméra cible le Joueur (à pied)")


func test_monter_et_descendre_de_la_voiture() -> void:
	var principale: Node = load("res://main.tscn").instantiate()
	add_child_autofree(principale)
	var joueur: Node = principale.get_node("Joueur")
	var voiture: Node = principale.get_node("Voiture")
	var rig: Node = principale.get_node("CameraRig")
	# Départ à pied.
	assert_true(joueur.actif, "départ : joueur actif")
	assert_false(voiture.actif, "départ : voiture inactive")
	# Monter.
	principale._monter()
	assert_false(joueur.actif, "en voiture : joueur inactif")
	assert_true(voiture.actif, "en voiture : voiture active")
	assert_eq(rig.cible, voiture, "en voiture : caméra sur la voiture")
	# Descendre.
	principale._descendre()
	assert_true(joueur.actif, "à pied : joueur actif")
	assert_false(voiture.actif, "à pied : voiture inactive")
	assert_eq(rig.cible, joueur, "à pied : caméra sur le joueur")


func test_le_joueur_est_un_corps_avec_collision() -> void:
	var joueur: Node = load("res://scenes/player.tscn").instantiate()
	add_child_autofree(joueur)
	assert_true(joueur is CharacterBody3D, "le joueur doit être un CharacterBody3D")
	var collision: Node = joueur.get_node("Collision")
	assert_not_null((collision as CollisionShape3D).shape, "le joueur doit avoir une forme de collision")


func test_le_modele_charge_idle_et_marche() -> void:
	var joueur: Node = load("res://scenes/player.tscn").instantiate()
	add_child_autofree(joueur)
	var modele: Node = joueur.get_node("Modele")
	var player: AnimationPlayer = modele.find_child("AnimationPlayer", true, false)
	assert_not_null(player, "le modèle doit exposer un AnimationPlayer")
	assert_true(player.has_animation("mixamo_com"), "l'idle natif doit être présent")
	assert_true(player.has_animation("marche"), "la marche doit avoir été injectée")


func test_la_marche_est_sur_place() -> void:
	var joueur: Node = load("res://scenes/player.tscn").instantiate()
	add_child_autofree(joueur)
	var player: AnimationPlayer = joueur.get_node("Modele").find_child("AnimationPlayer", true, false)
	var marche: Animation = player.get_animation("marche")
	var idx := -1
	for i in marche.get_track_count():
		if marche.track_get_type(i) == Animation.TYPE_POSITION_3D and str(marche.track_get_path(i)).contains("Hips"):
			idx = i
			break
	assert_gt(idx, -1, "la piste de position du bassin doit exister")
	var base: Vector3 = marche.track_get_key_value(idx, 0)
	var plat := true
	for k in marche.track_get_key_count(idx):
		var v: Vector3 = marche.track_get_key_value(idx, k)
		if absf(v.x - base.x) > 0.001 or absf(v.z - base.z) > 0.001:
			plat = false
	assert_true(plat, "le déplacement horizontal du bassin doit être neutralisé (marche sur place)")


func test_definir_vitesse_bascule_idle_marche() -> void:
	var joueur: Node = load("res://scenes/player.tscn").instantiate()
	add_child_autofree(joueur)
	var modele: Node = joueur.get_node("Modele")
	modele.definir_vitesse(4.0)
	assert_eq(modele._anim_courante, "marche", "vitesse élevée -> marche")
	modele.definir_vitesse(0.0)
	assert_eq(modele._anim_courante, "mixamo_com", "vitesse nulle -> idle")


func test_sans_input_la_direction_du_joueur_est_nulle() -> void:
	var joueur: CharacterBody3D = load("res://scenes/player.tscn").instantiate()
	add_child_autofree(joueur)
	assert_eq(joueur._direction_voulue(), Vector3.ZERO, "sans touche pressée, aucune direction")


func test_la_voiture_a_quatre_roues() -> void:
	var voiture: Node = load("res://scenes/car.tscn").instantiate()
	add_child_autofree(voiture)
	assert_true(voiture is VehicleBody3D, "la voiture doit être un VehicleBody3D")
	var roues: Array = voiture.find_children("*", "VehicleWheel3D", true, false)
	assert_eq(roues.size(), 4, "la voiture doit avoir 4 VehicleWheel3D")


func test_voiture_inactive_coupe_le_moteur() -> void:
	var voiture: VehicleBody3D = load("res://scenes/car.tscn").instantiate()
	voiture.actif = false
	add_child_autofree(voiture)
	voiture._physics_process(0.1)
	assert_eq(voiture.engine_force, 0.0, "voiture inactive : moteur coupé")
	assert_gt(voiture.brake, 0.0, "voiture inactive : frein serré")


func test_le_rig_a_un_bras_et_une_camera_active() -> void:
	var rig: Node = load("res://scenes/camera_rig.tscn").instantiate()
	add_child_autofree(rig)
	var bras: Node = rig.get_node("SpringArm3D")
	assert_true(bras is SpringArm3D, "le rig doit avoir un SpringArm3D")
	var camera: Node = bras.get_node("Camera3D")
	assert_true((camera as Camera3D).current, "la caméra du rig doit être active")


func test_le_rig_se_rapproche_de_la_cible_deplacee() -> void:
	var principale: Node = load("res://main.tscn").instantiate()
	add_child_autofree(principale)
	var rig: Node3D = principale.get_node("CameraRig")
	var joueur: Node3D = principale.get_node("Joueur")
	joueur.global_position = Vector3(25, 1, 25)
	var distance_avant := rig.global_position.distance_to(joueur.global_position)
	for _i in 20:
		rig._process(0.1)
	var distance_apres := rig.global_position.distance_to(joueur.global_position)
	assert_lt(distance_apres, distance_avant, "le rig doit se rapprocher de la cible quand elle se déplace")


func test_la_souris_oriente_la_camera() -> void:
	var rig: Node = load("res://scenes/camera_rig.tscn").instantiate()
	add_child_autofree(rig)
	var yaw_avant: float = rig._yaw
	var motion := InputEventMouseMotion.new()
	motion.relative = Vector2(120, 0)
	rig._unhandled_input(motion)
	assert_ne(rig._yaw, yaw_avant, "un mouvement souris (curseur capturé) doit réorienter la caméra")


func test_definir_cible_assigne_la_cible() -> void:
	var rig: Node = load("res://scenes/camera_rig.tscn").instantiate()
	add_child_autofree(rig)
	var faux_cible := Node3D.new()
	add_child_autofree(faux_cible)
	rig.definir_cible(faux_cible)
	assert_eq(rig.cible, faux_cible, "definir_cible doit mémoriser la cible")
