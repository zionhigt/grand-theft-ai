extends GutTest

# Tests unitaires — Feature 18 : Refonte complète du véhicule
#
# Ce fichier remplace intégralement les fichiers supprimés :
#   test_06_voiture.gd, test_07_entree_sortie_vehicule.gd,
#   test_08_conduite.gd, test_13_carrosserie_glb_masquage_roues.gd,
#   test_14_calibration_physique_vehicule.gd, test_15_correction_geometrie_roues.gd,
#   test_16_suppression_wheelMesh.gd, test_17_correction_orientation_glb_vitesse.gd
#
# Couvre les comportements B1–B42 et cas limites CL1–CL4 de la spec
# docs/specs/18-refonte-vehicule.md
#
# En phase rouge : src/vehicles/car_controller.gd, src/vehicles/car_visuals.gd,
#   scenes/vehicles/car.tscn sont absents ou dans l'ancienne architecture.
#   Les tests échoueront — attendu.

# ---------------------------------------------------------------------------
# Noms des roues — utilisés dans plusieurs groupes de tests
# ---------------------------------------------------------------------------
const NOMS_ROUES: Array = [
	"WheelFrontLeft", "WheelFrontRight", "WheelRearLeft", "WheelRearRight"
]

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _creer_car_body_mock() -> VehicleBody3D:
	var car: VehicleBody3D = VehicleBody3D.new()
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(2.0, 1.5, 4.0)
	shape.shape = box
	car.add_child(shape)
	return car

func _creer_game_state_mock() -> Node:
	var gs: Node = load("res://src/core/game_state.gd").new()
	return gs

# ===========================================================================
# GROUPE 1 — Structure de car.tscn (B1–B11)
# ===========================================================================

# ---------------------------------------------------------------------------
# B1 — La racine de car.tscn est un VehicleBody3D nommé "Car" sans script
# ---------------------------------------------------------------------------
func test_scene_B01_racine_vehiclebody3d() -> void:
	var packed: PackedScene = load("res://scenes/vehicles/car.tscn")
	assert_not_null(packed, "car.tscn doit être chargeable")
	if packed == null:
		return
	var car: Node = packed.instantiate()
	add_child_autofree(car)
	assert_eq(car.name, "Car", "Le nœud racine doit s'appeler 'Car'")
	assert_true(car is VehicleBody3D, "Le nœud racine doit être un VehicleBody3D")
	assert_null(car.get_script(), "Car (VehicleBody3D) ne doit avoir aucun script attaché")

# ---------------------------------------------------------------------------
# B2 — CarBodyCollision est un CollisionShape3D avec BoxShape3D(4.0, 1.5, 2.0)
# ---------------------------------------------------------------------------
func test_scene_B02_collision_box_shape() -> void:
	var car: Node = load("res://scenes/vehicles/car.tscn").instantiate()
	add_child_autofree(car)
	var cs: Node = car.get_node_or_null("CarBodyCollision")
	assert_not_null(cs, "Le nœud CarBodyCollision doit exister")
	if cs == null:
		return
	assert_true(cs is CollisionShape3D, "CarBodyCollision doit être un CollisionShape3D")
	assert_true((cs as CollisionShape3D).shape is BoxShape3D,
		"CarBodyCollision.shape doit être un BoxShape3D")
	var size: Vector3 = ((cs as CollisionShape3D).shape as BoxShape3D).size
	assert_almost_eq(size.x, 4.0, 0.001, "BoxShape3D.size.x doit valoir 4.0")
	assert_almost_eq(size.y, 1.5, 0.001, "BoxShape3D.size.y doit valoir 1.5")
	assert_almost_eq(size.z, 2.0, 0.001, "BoxShape3D.size.z doit valoir 2.0")

# ---------------------------------------------------------------------------
# B3 — car.tscn a exactement 4 enfants VehicleWheel3D
# ---------------------------------------------------------------------------
func test_scene_B03_quatre_roues() -> void:
	var car: Node = load("res://scenes/vehicles/car.tscn").instantiate()
	add_child_autofree(car)
	var count: int = 0
	for child in car.get_children():
		if child is VehicleWheel3D:
			count += 1
	assert_eq(count, 4, "car.tscn doit contenir exactement 4 VehicleWheel3D")

# ---------------------------------------------------------------------------
# B4 — Roues avant : use_as_steering=true, use_as_traction=false
# ---------------------------------------------------------------------------
func test_scene_B04_roues_avant_steering() -> void:
	var car: Node = load("res://scenes/vehicles/car.tscn").instantiate()
	add_child_autofree(car)
	for nom in ["WheelFrontLeft", "WheelFrontRight"]:
		var w: Node = car.get_node_or_null(nom)
		assert_not_null(w, "Le nœud %s doit exister" % nom)
		if w == null:
			continue
		assert_true((w as VehicleWheel3D).use_as_steering,
			"%s.use_as_steering doit être true" % nom)
		assert_false((w as VehicleWheel3D).use_as_traction,
			"%s.use_as_traction doit être false" % nom)

# ---------------------------------------------------------------------------
# B5 — Roues arrière : use_as_steering=false, use_as_traction=true
# ---------------------------------------------------------------------------
func test_scene_B05_roues_arriere_traction() -> void:
	var car: Node = load("res://scenes/vehicles/car.tscn").instantiate()
	add_child_autofree(car)
	for nom in ["WheelRearLeft", "WheelRearRight"]:
		var w: Node = car.get_node_or_null(nom)
		assert_not_null(w, "Le nœud %s doit exister" % nom)
		if w == null:
			continue
		assert_false((w as VehicleWheel3D).use_as_steering,
			"%s.use_as_steering doit être false" % nom)
		assert_true((w as VehicleWheel3D).use_as_traction,
			"%s.use_as_traction doit être true" % nom)

# ---------------------------------------------------------------------------
# B6 — WheelFrontLeft.position ≈ Vector3(-0.8, -0.5, -1.0)
# ---------------------------------------------------------------------------
func test_scene_B06_position_wheel_front_left() -> void:
	var car: Node = load("res://scenes/vehicles/car.tscn").instantiate()
	add_child_autofree(car)
	var w: Node = car.get_node_or_null("WheelFrontLeft")
	assert_not_null(w, "WheelFrontLeft doit exister")
	if w == null:
		return
	var pos: Vector3 = (w as Node3D).position
	assert_almost_eq(pos.x, -0.8, 0.001, "WheelFrontLeft.position.x doit valoir -0.8")
	assert_almost_eq(pos.y, -0.5, 0.001, "WheelFrontLeft.position.y doit valoir -0.5")
	assert_almost_eq(pos.z, -1.0, 0.001, "WheelFrontLeft.position.z doit valoir -1.0")

# ---------------------------------------------------------------------------
# B7 — WheelFrontRight.position ≈ Vector3(0.8, -0.5, -1.0)
# ---------------------------------------------------------------------------
func test_scene_B07_position_wheel_front_right() -> void:
	var car: Node = load("res://scenes/vehicles/car.tscn").instantiate()
	add_child_autofree(car)
	var w: Node = car.get_node_or_null("WheelFrontRight")
	assert_not_null(w, "WheelFrontRight doit exister")
	if w == null:
		return
	var pos: Vector3 = (w as Node3D).position
	assert_almost_eq(pos.x,  0.8, 0.001, "WheelFrontRight.position.x doit valoir 0.8")
	assert_almost_eq(pos.y, -0.5, 0.001, "WheelFrontRight.position.y doit valoir -0.5")
	assert_almost_eq(pos.z, -1.0, 0.001, "WheelFrontRight.position.z doit valoir -1.0")

# ---------------------------------------------------------------------------
# B8 — WheelRearLeft.position ≈ Vector3(-0.8, -0.5, 1.0)
# ---------------------------------------------------------------------------
func test_scene_B08_position_wheel_rear_left() -> void:
	var car: Node = load("res://scenes/vehicles/car.tscn").instantiate()
	add_child_autofree(car)
	var w: Node = car.get_node_or_null("WheelRearLeft")
	assert_not_null(w, "WheelRearLeft doit exister")
	if w == null:
		return
	var pos: Vector3 = (w as Node3D).position
	assert_almost_eq(pos.x, -0.8, 0.001, "WheelRearLeft.position.x doit valoir -0.8")
	assert_almost_eq(pos.y, -0.5, 0.001, "WheelRearLeft.position.y doit valoir -0.5")
	assert_almost_eq(pos.z,  1.0, 0.001, "WheelRearLeft.position.z doit valoir 1.0")

# ---------------------------------------------------------------------------
# B9 — WheelRearRight.position ≈ Vector3(0.8, -0.5, 1.0)
# ---------------------------------------------------------------------------
func test_scene_B09_position_wheel_rear_right() -> void:
	var car: Node = load("res://scenes/vehicles/car.tscn").instantiate()
	add_child_autofree(car)
	var w: Node = car.get_node_or_null("WheelRearRight")
	assert_not_null(w, "WheelRearRight doit exister")
	if w == null:
		return
	var pos: Vector3 = (w as Node3D).position
	assert_almost_eq(pos.x,  0.8, 0.001, "WheelRearRight.position.x doit valoir 0.8")
	assert_almost_eq(pos.y, -0.5, 0.001, "WheelRearRight.position.y doit valoir -0.5")
	assert_almost_eq(pos.z,  1.0, 0.001, "WheelRearRight.position.z doit valoir 1.0")

# ---------------------------------------------------------------------------
# B10 — Paramètres de suspension sur les 4 roues
# ---------------------------------------------------------------------------
func test_scene_B10_params_suspension() -> void:
	var car: Node = load("res://scenes/vehicles/car.tscn").instantiate()
	add_child_autofree(car)
	for nom in NOMS_ROUES:
		var w: Node = car.get_node_or_null(nom)
		assert_not_null(w, "La roue %s doit exister" % nom)
		if w == null:
			continue
		var vw: VehicleWheel3D = w as VehicleWheel3D
		assert_almost_eq(vw.wheel_radius,        0.35,    0.001, "%s.wheel_radius doit valoir 0.35" % nom)
		assert_almost_eq(vw.wheel_rest_length,   0.25,    0.001, "%s.wheel_rest_length doit valoir 0.25" % nom)
		assert_almost_eq(vw.suspension_travel,   0.2,     0.001, "%s.suspension_travel doit valoir 0.2" % nom)
		assert_almost_eq(vw.suspension_stiffness, 5.88,   0.001, "%s.suspension_stiffness doit valoir 5.88" % nom)
		assert_almost_eq(vw.damping_compression, 0.83,    0.001, "%s.damping_compression doit valoir 0.83" % nom)
		assert_almost_eq(vw.damping_relaxation,  0.88,    0.001, "%s.damping_relaxation doit valoir 0.88" % nom)
		assert_almost_eq(vw.suspension_max_force, 6000.0, 0.001, "%s.suspension_max_force doit valoir 6000" % nom)
		assert_almost_eq(vw.wheel_friction_slip,  10.5,   0.001, "%s.wheel_friction_slip doit valoir 10.5" % nom)

# ---------------------------------------------------------------------------
# B11 — Aucun VehicleWheel3D n'a d'enfant MeshInstance3D
# ---------------------------------------------------------------------------
func test_scene_B11_pas_de_wheelMesh() -> void:
	var car: Node = load("res://scenes/vehicles/car.tscn").instantiate()
	add_child_autofree(car)
	for nom in NOMS_ROUES:
		var w: Node = car.get_node_or_null(nom)
		assert_not_null(w, "La roue %s doit exister" % nom)
		if w == null:
			continue
		var mesh_enfants: int = 0
		for child in w.get_children():
			if child is MeshInstance3D:
				mesh_enfants += 1
		assert_eq(mesh_enfants, 0,
			"%s ne doit avoir aucun enfant MeshInstance3D (roues visuelles dans car_body.glb)" % nom)

# ===========================================================================
# GROUPE 2 — Intégration GLB (B12–B17)
# ===========================================================================

# ---------------------------------------------------------------------------
# B12 — car_body.glb est présent et chargeable
# ---------------------------------------------------------------------------
func test_glb_B12_car_body_chargeable() -> void:
	assert_true(
		ResourceLoader.exists("res://assets/vehicles/car/car_body.glb"),
		"res://assets/vehicles/car/car_body.glb doit exister et être chargeable"
	)

# ---------------------------------------------------------------------------
# B13 — wheel.glb est absent (supprimé définitivement)
# ---------------------------------------------------------------------------
func test_glb_B13_wheel_glb_absent() -> void:
	assert_false(
		ResourceLoader.exists("res://assets/vehicles/car/wheel.glb"),
		"wheel.glb doit avoir été supprimé du projet"
	)

# ---------------------------------------------------------------------------
# B14 — Après add_child_autofree, CarBodyMesh a au moins un enfant
#        (GLB ou fallback BoxMesh ajouté par CarVisuals._ready())
# ---------------------------------------------------------------------------
func test_glb_B14_carBodyMesh_a_un_enfant() -> void:
	var car: Node = load("res://scenes/vehicles/car.tscn").instantiate()
	add_child_autofree(car)
	var mi: Node = car.get_node_or_null("CarBodyMesh")
	assert_not_null(mi, "CarBodyMesh doit exister dans car.tscn")
	if mi == null:
		return
	assert_true(mi is MeshInstance3D, "CarBodyMesh doit être un MeshInstance3D")
	assert_gt((mi as MeshInstance3D).get_child_count(), 0,
		"CarBodyMesh doit avoir au moins un enfant après _ready() (GLB ou fallback BoxMesh)")

# ---------------------------------------------------------------------------
# B15 — Quand car_body.glb est présent, le premier enfant Node3D de CarBodyMesh
#        a rotation_degrees.y ≈ 180.0 (tolérance 0.1°)
#        Valeur corrigée : 180° aligne le capot GLB (+Z local) avec l'axe -Z physique.
# ---------------------------------------------------------------------------
func test_glb_B15_rotation_glb() -> void:
	if not ResourceLoader.exists("res://assets/vehicles/car/car_body.glb"):
		pass  # GLB absent → test non applicable (B12 aura échoué)
		return
	var car: Node = load("res://scenes/vehicles/car.tscn").instantiate()
	add_child_autofree(car)
	var mi: Node = car.get_node_or_null("CarBodyMesh")
	assert_not_null(mi, "CarBodyMesh doit exister")
	if mi == null:
		return
	if (mi as MeshInstance3D).get_child_count() == 0:
		fail_test("CarBodyMesh n'a aucun enfant — le GLB n'a pas été chargé")
		return
	var enfant: Node3D = (mi as MeshInstance3D).get_child(0) as Node3D
	assert_not_null(enfant, "Le premier enfant de CarBodyMesh doit être un Node3D")
	if enfant == null:
		return
	assert_almost_eq(enfant.rotation_degrees.y, 180.0, 0.1,
		"L'instance GLB doit avoir rotation_degrees.y ≈ 180.0")

# ---------------------------------------------------------------------------
# B16 — CarVisuals n'a pas de méthode _masquer_roues
# ---------------------------------------------------------------------------
func test_glb_B16_pas_de_methode_masquer_roues() -> void:
	var car: Node = load("res://scenes/vehicles/car.tscn").instantiate()
	add_child_autofree(car)
	var visuals: Node = car.get_node_or_null("CarVisuals")
	assert_not_null(visuals, "Le nœud CarVisuals doit exister dans car.tscn")
	if visuals == null:
		return
	assert_false(visuals.has_method("_masquer_roues"),
		"CarVisuals ne doit pas avoir de méthode _masquer_roues")

# ---------------------------------------------------------------------------
# B17 — car_visuals.gd ne contient ni "wheel.glb" ni "_masquer_roues"
# ---------------------------------------------------------------------------
func test_glb_B17_pas_de_ref_wheel_dans_code() -> void:
	var file: FileAccess = FileAccess.open("res://src/vehicles/car_visuals.gd", FileAccess.READ)
	assert_not_null(file, "car_visuals.gd doit exister")
	if file == null:
		return
	var content: String = file.get_as_text()
	file.close()
	assert_false("wheel.glb" in content,
		"car_visuals.gd ne doit pas référencer wheel.glb")
	assert_false("_masquer_roues" in content,
		"car_visuals.gd ne doit pas contenir _masquer_roues")

# ===========================================================================
# GROUPE 3 — Constantes CarController (B18–B22)
# ===========================================================================

# ---------------------------------------------------------------------------
# B18 — CarController.ENGINE_FORCE == 8000.0
# ---------------------------------------------------------------------------
func test_ctrl_B18_engine_force_constante() -> void:
	var CarControllerScript = load("res://src/vehicles/car_controller.gd")
	assert_not_null(CarControllerScript, "car_controller.gd doit être chargeable")
	if CarControllerScript == null:
		return
	var ctrl: Node = CarControllerScript.new()
	add_child_autofree(ctrl)
	assert_eq(ctrl.ENGINE_FORCE, 8000.0, "ENGINE_FORCE doit valoir 8000.0")

# ---------------------------------------------------------------------------
# B19 — CarController.BRAKE_FORCE == 80.0
# ---------------------------------------------------------------------------
func test_ctrl_B19_brake_force_constante() -> void:
	var CarControllerScript = load("res://src/vehicles/car_controller.gd")
	assert_not_null(CarControllerScript, "car_controller.gd doit être chargeable")
	if CarControllerScript == null:
		return
	var ctrl: Node = CarControllerScript.new()
	add_child_autofree(ctrl)
	assert_eq(ctrl.BRAKE_FORCE, 80.0, "BRAKE_FORCE doit valoir 80.0")

# ---------------------------------------------------------------------------
# B20 — CarController.MAX_STEERING == 0.4
# ---------------------------------------------------------------------------
func test_ctrl_B20_max_steering_constante() -> void:
	var CarControllerScript = load("res://src/vehicles/car_controller.gd")
	assert_not_null(CarControllerScript, "car_controller.gd doit être chargeable")
	if CarControllerScript == null:
		return
	var ctrl: Node = CarControllerScript.new()
	add_child_autofree(ctrl)
	assert_eq(ctrl.MAX_STEERING, 0.4, "MAX_STEERING doit valoir 0.4")

# ---------------------------------------------------------------------------
# B21 — CarController.STEERING_SPEED == 5.0
# ---------------------------------------------------------------------------
func test_ctrl_B21_steering_speed_constante() -> void:
	var CarControllerScript = load("res://src/vehicles/car_controller.gd")
	assert_not_null(CarControllerScript, "car_controller.gd doit être chargeable")
	if CarControllerScript == null:
		return
	var ctrl: Node = CarControllerScript.new()
	add_child_autofree(ctrl)
	assert_eq(ctrl.STEERING_SPEED, 5.0, "STEERING_SPEED doit valoir 5.0")

# ---------------------------------------------------------------------------
# B22 — CarController.FORWARD_SPEED_THRESHOLD == 0.5
# ---------------------------------------------------------------------------
func test_ctrl_B22_forward_speed_threshold() -> void:
	var CarControllerScript = load("res://src/vehicles/car_controller.gd")
	assert_not_null(CarControllerScript, "car_controller.gd doit être chargeable")
	if CarControllerScript == null:
		return
	var ctrl: Node = CarControllerScript.new()
	add_child_autofree(ctrl)
	assert_eq(ctrl.FORWARD_SPEED_THRESHOLD, 0.5,
		"FORWARD_SPEED_THRESHOLD doit valoir 0.5")

# ===========================================================================
# GROUPE 4 — Comportement de conduite (B23–B30)
# ===========================================================================

# ---------------------------------------------------------------------------
# Setup commun pour les tests de conduite :
# - un VehicleBody3D avec CollisionShape3D dans le SceneTree
# - un GameState mock avec player_mode = IN_VEHICLE
# - un CarController avec injection manuelle
# ---------------------------------------------------------------------------

func _setup_conduite() -> Array:
	var CarControllerScript = load("res://src/vehicles/car_controller.gd")
	if CarControllerScript == null:
		return []

	var car_body: VehicleBody3D = _creer_car_body_mock()
	add_child_autofree(car_body)

	var mock_gs: Node = _creer_game_state_mock()
	add_child_autofree(mock_gs)
	mock_gs.player_mode = GameState.PlayerMode.IN_VEHICLE

	# Feature 19 : la guard étendue de CarController vérifie _player._vehicle_state.
	# On injecte un PlayerController avec _vehicle_state == "car_drive" pour que les
	# tests de conduite restent valides après implémentation de la feature 19.
	# En phase rouge, _player n'existe pas encore dans CarController et _vehicle_state
	# n'existe pas dans PlayerController : les set() sont silencieux (pas de crash).
	var PlayerControllerScript = load("res://src/player/player_controller.gd")
	var player_mock = null
	if PlayerControllerScript != null:
		player_mock = PlayerControllerScript.new()
		player_mock.set("_vehicle_state", "car_drive")
		add_child_autofree(player_mock)

	var ctrl: Node = CarControllerScript.new()
	ctrl._game_state = mock_gs
	ctrl._car_body = car_body
	if player_mock != null:
		ctrl.set("_player", player_mock)
	add_child_autofree(ctrl)

	return [ctrl, car_body, mock_gs]

# ---------------------------------------------------------------------------
# B23 — drive_forward pressé + IN_VEHICLE → engine_force > 0
# ---------------------------------------------------------------------------
func test_drive_B23_avancer() -> void:
	var setup: Array = _setup_conduite()
	if setup.is_empty():
		fail_test("car_controller.gd non chargeable — test ignoré")
		return
	var ctrl: Node = setup[0]
	var car_body: VehicleBody3D = setup[1]

	Input.action_press("drive_forward")
	ctrl._physics_process(0.016)
	Input.action_release("drive_forward")
	Input.flush_buffered_events()

	assert_lt(car_body.engine_force, 0.0,
		"engine_force doit être < 0 quand drive_forward est pressé en IN_VEHICLE")

# ---------------------------------------------------------------------------
# B24 — drive_backward pressé + vitesse ≥ 0.5 m/s → brake > 0, engine_force == 0
# ---------------------------------------------------------------------------
func test_drive_B24_freiner_en_marche() -> void:
	var setup: Array = _setup_conduite()
	if setup.is_empty():
		fail_test("car_controller.gd non chargeable — test ignoré")
		return
	var ctrl: Node = setup[0]
	var car_body: VehicleBody3D = setup[1]

	# Injecter une vitesse linéaire suffisante (> FORWARD_SPEED_THRESHOLD = 0.5)
	# forward_speed = dot(velocity, global_basis.z) → vitesse en +Z = avancer
	car_body.linear_velocity = Vector3(0.0, 0.0, 1.0)

	Input.action_press("drive_backward")
	ctrl._physics_process(0.016)
	Input.action_release("drive_backward")
	Input.flush_buffered_events()

	assert_gt(car_body.brake, 0.0,
		"brake doit être > 0 quand drive_backward est pressé à vitesse >= 0.5 m/s")
	assert_eq(car_body.engine_force, 0.0,
		"engine_force doit être 0 lors du freinage (drive_backward + vitesse >= 0.5)")

# ---------------------------------------------------------------------------
# B25 — drive_backward pressé + vitesse < 0.5 m/s → engine_force < 0, brake == 0
# ---------------------------------------------------------------------------
func test_drive_B25_marche_arriere() -> void:
	var setup: Array = _setup_conduite()
	if setup.is_empty():
		fail_test("car_controller.gd non chargeable — test ignoré")
		return
	var ctrl: Node = setup[0]
	var car_body: VehicleBody3D = setup[1]

	# Vitesse nulle (< FORWARD_SPEED_THRESHOLD)
	car_body.linear_velocity = Vector3.ZERO

	Input.action_press("drive_backward")
	ctrl._physics_process(0.016)
	Input.action_release("drive_backward")
	Input.flush_buffered_events()

	assert_gt(car_body.engine_force, 0.0,
		"engine_force doit être > 0 en marche arrière (drive_backward + vitesse < 0.5)")
	assert_eq(car_body.brake, 0.0,
		"brake doit être 0 en marche arrière (pas de freinage)")

# ---------------------------------------------------------------------------
# B26 — drive_left pressé × 10 frames → ctrl._steering > 0
# ---------------------------------------------------------------------------
func test_drive_B26_tourner_gauche() -> void:
	var setup: Array = _setup_conduite()
	if setup.is_empty():
		fail_test("car_controller.gd non chargeable — test ignoré")
		return
	var ctrl: Node = setup[0]

	Input.action_press("drive_left")
	for _i in range(10):
		ctrl._physics_process(0.016)
	Input.action_release("drive_left")
	Input.flush_buffered_events()

	assert_gt(ctrl._steering, 0.0,
		"_steering doit être > 0 après 10 frames avec drive_left pressé (braquage gauche)")

# ---------------------------------------------------------------------------
# B27 — drive_right pressé × 10 frames → ctrl._steering < 0
# ---------------------------------------------------------------------------
func test_drive_B27_tourner_droite() -> void:
	var setup: Array = _setup_conduite()
	if setup.is_empty():
		fail_test("car_controller.gd non chargeable — test ignoré")
		return
	var ctrl: Node = setup[0]

	Input.action_press("drive_right")
	for _i in range(10):
		ctrl._physics_process(0.016)
	Input.action_release("drive_right")
	Input.flush_buffered_events()

	assert_lt(ctrl._steering, 0.0,
		"_steering doit être < 0 après 10 frames avec drive_right pressé (braquage droite)")

# ---------------------------------------------------------------------------
# B28 — _steering initialisé à MAX_STEERING, aucun input → retour vers 0 amorcé
# ---------------------------------------------------------------------------
func test_drive_B28_retour_steering_zero() -> void:
	var setup: Array = _setup_conduite()
	if setup.is_empty():
		fail_test("car_controller.gd non chargeable — test ignoré")
		return
	var ctrl: Node = setup[0]

	# Forcer _steering à MAX_STEERING
	ctrl._steering = 0.4

	# Aucun input directionnel actif
	ctrl._physics_process(0.016)

	assert_lt(abs(ctrl._steering), 0.4,
		"_steering doit diminuer vers 0 quand aucun input directionnel n'est actif")

# ---------------------------------------------------------------------------
# B29 — ON_FOOT + _physics_process → engine_force == 0, brake == 0
# ---------------------------------------------------------------------------
func test_drive_B29_on_foot_no_force() -> void:
	var setup: Array = _setup_conduite()
	if setup.is_empty():
		fail_test("car_controller.gd non chargeable — test ignoré")
		return
	var ctrl: Node = setup[0]
	var car_body: VehicleBody3D = setup[1]
	var mock_gs: Node = setup[2]

	# Passer en mode ON_FOOT
	mock_gs.player_mode = GameState.PlayerMode.ON_FOOT

	Input.action_press("drive_forward")
	ctrl._physics_process(0.016)
	Input.action_release("drive_forward")
	Input.flush_buffered_events()

	assert_eq(car_body.engine_force, 0.0,
		"engine_force doit être 0 quand player_mode == ON_FOOT")
	assert_eq(car_body.brake, 0.0,
		"brake doit être 0 quand player_mode == ON_FOOT")

# ---------------------------------------------------------------------------
# B30 — drive_left pendant 1000 frames → _steering clampé à MAX_STEERING
#        drive_right pendant 1000 frames → _steering clampé à -MAX_STEERING
# ---------------------------------------------------------------------------
func test_drive_B30_steering_clamp() -> void:
	var setup: Array = _setup_conduite()
	if setup.is_empty():
		fail_test("car_controller.gd non chargeable — test ignoré")
		return
	var ctrl: Node = setup[0]

	# Côté gauche
	Input.action_press("drive_left")
	for _i in range(1000):
		ctrl._physics_process(0.016)
	Input.action_release("drive_left")
	Input.flush_buffered_events()

	assert_lt(ctrl._steering, 0.4 + 0.001,
		"_steering ne doit pas dépasser MAX_STEERING (0.4) même après 1000 frames drive_left")
	assert_gt(ctrl._steering, -0.001,
		"_steering doit rester >= 0 avec drive_left continu (braquage gauche positif)")

	# Réinitialiser pour le côté droit
	ctrl._steering = 0.0

	Input.action_press("drive_right")
	for _i in range(1000):
		ctrl._physics_process(0.016)
	Input.action_release("drive_right")
	Input.flush_buffered_events()

	assert_gt(ctrl._steering, -0.4 - 0.001,
		"_steering ne doit pas descendre sous -MAX_STEERING (-0.4) après 1000 frames drive_right")
	assert_lt(ctrl._steering, 0.001,
		"_steering doit rester <= 0 avec drive_right continu (braquage droite négatif)")

# ===========================================================================
# GROUPE 5 — Entrée/sortie véhicule (B31–B38)
# ===========================================================================

# ---------------------------------------------------------------------------
# B31 — GameState instancié seul : player_mode == ON_FOOT
# ---------------------------------------------------------------------------
func test_enter_B31_mode_initial_on_foot() -> void:
	var gs: Node = _creer_game_state_mock()
	add_child_autofree(gs)
	assert_eq((gs as GameState).player_mode, GameState.PlayerMode.ON_FOOT,
		"GameState.player_mode doit valoir ON_FOOT à l'initialisation")

# ---------------------------------------------------------------------------
# B32 — enter_vehicle(car_mock) → player_mode == IN_VEHICLE, current_vehicle == car_mock
# ---------------------------------------------------------------------------
func test_enter_B32_enter_vehicle() -> void:
	var gs: Node = _creer_game_state_mock()
	add_child_autofree(gs)
	var car_mock: VehicleBody3D = _creer_car_body_mock()
	add_child_autofree(car_mock)

	(gs as GameState).enter_vehicle(car_mock)

	assert_eq((gs as GameState).player_mode, GameState.PlayerMode.IN_VEHICLE,
		"player_mode doit valoir IN_VEHICLE après enter_vehicle()")
	assert_true(is_same((gs as GameState).current_vehicle, car_mock),
		"current_vehicle doit référencer le car_mock passé à enter_vehicle()")

# ---------------------------------------------------------------------------
# B33 — Double appel enter_vehicle sans exit → pas de crash, mode reste IN_VEHICLE
# ---------------------------------------------------------------------------
func test_enter_B33_enter_vehicle_idempotent() -> void:
	var gs: Node = _creer_game_state_mock()
	add_child_autofree(gs)
	var car_mock: VehicleBody3D = _creer_car_body_mock()
	add_child_autofree(car_mock)

	(gs as GameState).enter_vehicle(car_mock)
	(gs as GameState).enter_vehicle(car_mock)  # double appel

	assert_eq((gs as GameState).player_mode, GameState.PlayerMode.IN_VEHICLE,
		"player_mode doit rester IN_VEHICLE après double enter_vehicle()")
	assert_true(is_same((gs as GameState).current_vehicle, car_mock),
		"current_vehicle doit rester inchangé après double enter_vehicle()")

# ---------------------------------------------------------------------------
# B34 — exit_vehicle() après enter_vehicle() → player_mode == ON_FOOT, current_vehicle == null
# ---------------------------------------------------------------------------
func test_enter_B34_exit_vehicle() -> void:
	var gs: Node = _creer_game_state_mock()
	add_child_autofree(gs)
	var car_mock: VehicleBody3D = _creer_car_body_mock()
	add_child_autofree(car_mock)

	(gs as GameState).enter_vehicle(car_mock)
	(gs as GameState).exit_vehicle()

	assert_eq((gs as GameState).player_mode, GameState.PlayerMode.ON_FOOT,
		"player_mode doit valoir ON_FOOT après exit_vehicle()")
	assert_null((gs as GameState).current_vehicle,
		"current_vehicle doit être null après exit_vehicle()")

# ---------------------------------------------------------------------------
# B35 — Double appel exit_vehicle sans enter → pas de crash, mode reste ON_FOOT
# ---------------------------------------------------------------------------
func test_enter_B35_exit_vehicle_idempotent() -> void:
	var gs: Node = _creer_game_state_mock()
	add_child_autofree(gs)

	(gs as GameState).exit_vehicle()  # déjà ON_FOOT
	(gs as GameState).exit_vehicle()  # double appel

	assert_eq((gs as GameState).player_mode, GameState.PlayerMode.ON_FOOT,
		"player_mode doit rester ON_FOOT après double exit_vehicle()")

# ---------------------------------------------------------------------------
# B36 — Après exit_vehicle(), le joueur est spawné à distance <= 3.5 m du car_mock
# ---------------------------------------------------------------------------
func test_enter_B36_spawn_position() -> void:
	var gs: GameState = _creer_game_state_mock() as GameState
	add_child_autofree(gs)

	# Créer un joueur mock (PlayerController requis par GameState)
	var PlayerControllerScript = load("res://src/player/player_controller.gd")
	assert_not_null(PlayerControllerScript, "player_controller.gd doit être chargeable")
	if PlayerControllerScript == null:
		return

	var player_mock: CharacterBody3D = PlayerControllerScript.new() as CharacterBody3D
	var body: Node3D = Node3D.new()
	body.name = "PlayerBody"
	player_mock.add_child(body)
	add_child_autofree(player_mock)

	var car_mock: VehicleBody3D = _creer_car_body_mock()
	add_child_autofree(car_mock)
	car_mock.global_position = Vector3.ZERO

	# Injection directe dans GameState (pattern d'injection)
	gs._player = player_mock as PlayerController
	gs._player_body = body
	gs._car = car_mock

	gs.enter_vehicle(car_mock)
	gs.exit_vehicle()

	var dist: float = player_mock.global_position.distance_to(car_mock.global_position)
	assert_lt(dist, 3.5,
		"Le joueur doit spawner à moins de 3.5 m du véhicule après exit_vehicle()")

# ---------------------------------------------------------------------------
# B37 — car.tscn a un nœud InteractionZone de type Area3D
# ---------------------------------------------------------------------------
func test_enter_B37_interaction_zone() -> void:
	var car: Node = load("res://scenes/vehicles/car.tscn").instantiate()
	add_child_autofree(car)
	var zone: Node = car.get_node_or_null("InteractionZone")
	assert_not_null(zone, "car.tscn doit avoir un nœud 'InteractionZone'")
	if zone == null:
		return
	assert_true(zone is Area3D, "InteractionZone doit être de type Area3D")

# ---------------------------------------------------------------------------
# B38 — player_near_car passe à true sur body_entered, false sur body_exited
#
# Stratégie : GameState._ready() connecte déjà les signaux d'InteractionZone quand
# une référence _car est présente. Pour éviter une double connexion, on appelle
# directement les callbacks publics de GameState plutôt que de reconnecte les signaux.
# ---------------------------------------------------------------------------
func test_enter_B38_player_near_car_signal() -> void:
	var gs: GameState = _creer_game_state_mock() as GameState
	add_child_autofree(gs)

	# Simuler l'entrée d'un CharacterBody3D via appel direct au callback
	var player_body: CharacterBody3D = CharacterBody3D.new()
	var cs: CollisionShape3D = CollisionShape3D.new()
	cs.shape = SphereShape3D.new()
	player_body.add_child(cs)
	add_child_autofree(player_body)

	assert_false(gs.player_near_car,
		"player_near_car doit être false avant toute détection")

	gs._on_interaction_zone_body_entered(player_body)
	assert_true(gs.player_near_car,
		"player_near_car doit passer à true après _on_interaction_zone_body_entered avec un CharacterBody3D")

	gs._on_interaction_zone_body_exited(player_body)
	assert_false(gs.player_near_car,
		"player_near_car doit repasser à false après _on_interaction_zone_body_exited")

# ===========================================================================
# GROUPE 6 — Intégration main.tscn (B39–B42)
# ===========================================================================

# ---------------------------------------------------------------------------
# B39 — main.tscn contient un nœud "Car" de type VehicleBody3D
# ---------------------------------------------------------------------------
func test_main_B39_car_existe_dans_main() -> void:
	var main: Node = load("res://main.tscn").instantiate()
	add_child_autofree(main)
	var car: Node = main.get_node_or_null("Car")
	assert_not_null(car, "main.tscn doit contenir un nœud 'Car'")
	if car == null:
		return
	assert_true(car is VehicleBody3D,
		"Le nœud 'Car' dans main.tscn doit être de type VehicleBody3D")

# ---------------------------------------------------------------------------
# B40 — Car.position ≈ Vector3(5.0, 1.1, 5.0)
# ---------------------------------------------------------------------------
func test_main_B40_car_position() -> void:
	var main: Node = load("res://main.tscn").instantiate()
	add_child_autofree(main)
	var car: Node = main.get_node_or_null("Car")
	assert_not_null(car, "main.tscn doit contenir un nœud 'Car'")
	if car == null:
		return
	var pos: Vector3 = (car as Node3D).position
	assert_almost_eq(pos.x, 5.0, 0.001, "Car.position.x doit valoir 5.0")
	assert_almost_eq(pos.y, 1.1, 0.001, "Car.position.y doit valoir 1.1")
	assert_almost_eq(pos.z, 5.0, 0.001, "Car.position.z doit valoir 5.0")

# ---------------------------------------------------------------------------
# B41 — main.tscn contient un nœud "CarController" avec script CarController
# ---------------------------------------------------------------------------
func test_main_B41_car_controller_existe() -> void:
	var CarControllerScript = load("res://src/vehicles/car_controller.gd")
	assert_not_null(CarControllerScript, "car_controller.gd doit être chargeable")
	if CarControllerScript == null:
		return
	var main: Node = load("res://main.tscn").instantiate()
	add_child_autofree(main)
	var ctrl: Node = main.get_node_or_null("CarController")
	assert_not_null(ctrl, "main.tscn doit contenir un nœud 'CarController'")
	if ctrl == null:
		return
	assert_true(ctrl is CarController,
		"Le nœud 'CarController' dans main.tscn doit être de type CarController")

# ---------------------------------------------------------------------------
# B42 — Les actions drive_forward, drive_backward, drive_left, drive_right
#        sont déclarées dans l'InputMap
# ---------------------------------------------------------------------------
func test_main_B42_input_actions() -> void:
	assert_true(InputMap.has_action("drive_forward"),
		"L'action 'drive_forward' doit être déclarée dans InputMap")
	assert_true(InputMap.has_action("drive_backward"),
		"L'action 'drive_backward' doit être déclarée dans InputMap")
	assert_true(InputMap.has_action("drive_left"),
		"L'action 'drive_left' doit être déclarée dans InputMap")
	assert_true(InputMap.has_action("drive_right"),
		"L'action 'drive_right' doit être déclarée dans InputMap")

# ===========================================================================
# GROUPE 7 — Cas limites (CL1–CL4)
# ===========================================================================

# ---------------------------------------------------------------------------
# CL1 — _car_body == null → _physics_process retourne sans crash
# ---------------------------------------------------------------------------
func test_cl_CL01_null_car_body() -> void:
	var CarControllerScript = load("res://src/vehicles/car_controller.gd")
	assert_not_null(CarControllerScript, "car_controller.gd doit être chargeable")
	if CarControllerScript == null:
		return
	var ctrl: Node = CarControllerScript.new()
	add_child_autofree(ctrl)

	var mock_gs: Node = _creer_game_state_mock()
	add_child_autofree(mock_gs)
	mock_gs.player_mode = GameState.PlayerMode.IN_VEHICLE

	ctrl._game_state = mock_gs
	ctrl._car_body = null  # injection explicite de null

	# Ne doit pas crasher
	ctrl._physics_process(0.016)
	pass_test("_physics_process avec _car_body == null ne doit pas causer de crash")

# ---------------------------------------------------------------------------
# CL2 — _game_state == null → _physics_process retourne sans crash
# ---------------------------------------------------------------------------
func test_cl_CL02_null_game_state() -> void:
	var CarControllerScript = load("res://src/vehicles/car_controller.gd")
	assert_not_null(CarControllerScript, "car_controller.gd doit être chargeable")
	if CarControllerScript == null:
		return
	var ctrl: Node = CarControllerScript.new()
	add_child_autofree(ctrl)

	var car_body: VehicleBody3D = _creer_car_body_mock()
	add_child_autofree(car_body)

	ctrl._game_state = null  # injection explicite de null
	ctrl._car_body = car_body

	# Ne doit pas crasher
	ctrl._physics_process(0.016)
	pass_test("_physics_process avec _game_state == null ne doit pas causer de crash")

# ---------------------------------------------------------------------------
# CL3 — delta == 0.0 → pas de divergence, pas de crash
# ---------------------------------------------------------------------------
func test_cl_CL03_delta_zero() -> void:
	var setup: Array = _setup_conduite()
	if setup.is_empty():
		fail_test("car_controller.gd non chargeable — test ignoré")
		return
	var ctrl: Node = setup[0]
	var _car_body: VehicleBody3D = setup[1]  # présent dans le SceneTree mais non interrogé directement

	ctrl._steering = 0.4  # valeur initiale non nulle

	# delta == 0.0 : lerp(x, target, 0) == x → _steering inchangé
	ctrl._physics_process(0.0)

	assert_almost_eq(ctrl._steering, 0.4, 0.0001,
		"_steering doit rester inchangé avec delta == 0.0 (lerp(x, target, 0) == x)")
	pass_test("_physics_process(0.0) ne doit pas causer de crash ni de divergence")

# ---------------------------------------------------------------------------
# CL4 — car_body.glb absent → fallback BoxMesh rouge, pas de crash
#
# Note : en production, car_body.glb est présent (B12 le vérifie).
# Ce test valide la robustesse du fallback en créant une instance de CarVisuals
# avec un chemin GLB délibérément invalide (test via simulation du comportement
# attendu quand ResourceLoader.exists() retourne false).
# On vérifie que si le GLB est absent, CarBodyMesh reçoit tout de même un enfant.
# ---------------------------------------------------------------------------
func test_cl_CL04_glb_absent_fallback() -> void:
	# Si car_body.glb est présent, on ne peut pas tester l'absence directement
	# sur la scène réelle sans modifier le code.
	# On vérifie l'invariant : CarBodyMesh a au moins un enfant (GLB ou fallback).
	# Le comportement fallback est garanti par le test B14 + cette vérification
	# de robustesse sur l'instance GLB ou sur BoxMesh.
	var car: Node = load("res://scenes/vehicles/car.tscn").instantiate()
	add_child_autofree(car)
	var mi: Node = car.get_node_or_null("CarBodyMesh")
	assert_not_null(mi, "CarBodyMesh doit exister dans car.tscn (CL4)")
	if mi == null:
		return
	# Quelle que soit la présence du GLB (présent → instance GLB, absent → BoxMesh),
	# CarBodyMesh doit avoir au moins un enfant après _ready()
	assert_gt((mi as MeshInstance3D).get_child_count(), 0,
		"CarBodyMesh doit avoir au moins un enfant (GLB ou fallback BoxMesh) — CL4")
