extends GutTest

# Tests unitaires — Feature 19 : Animations véhicule (entrer / conduire / sortir)
#
# Couvre les comportements B1–B31 et cas limites CL1–CL7 de la spec
# docs/specs/19-animations-vehicule.md
#
# En phase rouge : src/player/player_controller.gd ne contient pas encore
# _vehicle_state, _followed_vehicle, start_car_enter(), start_car_drive(),
# start_car_exit(), finish_car_exit(), _play_anim(), _on_vehicle_anim_finished(),
# _charger_animations_vehicule(), ni le signal vehicle_anim_finished.
# src/core/game_state.gd ne contient pas encore _anim_enter_pending,
# _anim_exit_pending, _complete_enter_vehicle(), _complete_exit_vehicle(),
# _on_player_vehicle_anim_finished().
# src/vehicles/car_controller.gd ne contient pas encore player_path ni la guard étendue.

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _creer_player_controller() -> CharacterBody3D:
	var PlayerControllerScript = load("res://src/player/player_controller.gd")
	assert_not_null(PlayerControllerScript, "player_controller.gd doit être chargeable")
	if PlayerControllerScript == null:
		return null
	var ctrl: CharacterBody3D = PlayerControllerScript.new() as CharacterBody3D
	# Ajouter les nœuds attendus par _ready()
	var col: CollisionShape3D = CollisionShape3D.new()
	var cap: CapsuleShape3D = CapsuleShape3D.new()
	cap.height = 1.8
	cap.radius = 0.4
	col.shape = cap
	ctrl.add_child(col)
	var body: Node3D = Node3D.new()
	body.name = "PlayerBody"
	ctrl.add_child(body)
	var ap: AnimationPlayer = AnimationPlayer.new()
	ap.name = "AnimationPlayer"
	ctrl.add_child(ap)
	# CollisionShape3D pour B24 (disabled)
	col.name = "CollisionShape3D"
	return ctrl

func _creer_vehicle_mock() -> VehicleBody3D:
	var car: VehicleBody3D = VehicleBody3D.new()
	var shape: CollisionShape3D = CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	car.add_child(shape)
	return car

func _creer_game_state() -> GameState:
	var gs: GameState = load("res://src/core/game_state.gd").new() as GameState
	return gs

func _creer_car_controller() -> Node:
	var CarControllerScript = load("res://src/vehicles/car_controller.gd")
	if CarControllerScript == null:
		return null
	return CarControllerScript.new()

# ===========================================================================
# GROUPE 1 — Machine à états PlayerController (B1–B8)
# ===========================================================================

# ---------------------------------------------------------------------------
# B1 — PlayerController instancié : _vehicle_state == "none", _followed_vehicle == null
# ---------------------------------------------------------------------------
func test_B01_etat_initial_vehicle_state_none() -> void:
	# B1
	var ctrl: CharacterBody3D = _creer_player_controller()
	assert_not_null(ctrl, "player_controller.gd doit être instanciable")
	if ctrl == null:
		return
	add_child_autofree(ctrl)
	assert_eq(ctrl.get("_vehicle_state"), "none",
		"_vehicle_state doit valoir 'none' à l'initialisation")
	assert_null(ctrl.get("_followed_vehicle"),
		"_followed_vehicle doit être null à l'initialisation")

# ---------------------------------------------------------------------------
# B2 — start_car_enter(vehicle_mock) : _vehicle_state == "car_enter", _followed_vehicle == vehicle_mock
# ---------------------------------------------------------------------------
func test_B02_start_car_enter_met_a_jour_etat() -> void:
	# B2
	var ctrl: CharacterBody3D = _creer_player_controller()
	assert_not_null(ctrl, "player_controller.gd doit être instanciable")
	if ctrl == null:
		return
	add_child_autofree(ctrl)
	var vehicle_mock: VehicleBody3D = _creer_vehicle_mock()
	add_child_autofree(vehicle_mock)

	assert_true(ctrl.has_method("start_car_enter"),
		"PlayerController doit avoir la méthode start_car_enter()")
	if not ctrl.has_method("start_car_enter"):
		return

	ctrl.start_car_enter(vehicle_mock)

	assert_eq(ctrl.get("_vehicle_state"), "car_enter",
		"_vehicle_state doit valoir 'car_enter' après start_car_enter()")
	assert_true(is_same(ctrl.get("_followed_vehicle"), vehicle_mock),
		"_followed_vehicle doit référencer le vehicle_mock passé à start_car_enter()")

# ---------------------------------------------------------------------------
# B3 — start_car_enter + AnimationPlayer sans "car_enter" → vehicle_anim_finished émis immédiatement
# ---------------------------------------------------------------------------
func test_B03_start_car_enter_sans_animation_emet_signal_immediat() -> void:
	# B3
	var ctrl: CharacterBody3D = _creer_player_controller()
	assert_not_null(ctrl, "player_controller.gd doit être instanciable")
	if ctrl == null:
		return
	add_child_autofree(ctrl)
	var vehicle_mock: VehicleBody3D = _creer_vehicle_mock()
	add_child_autofree(vehicle_mock)

	assert_true(ctrl.has_signal("vehicle_anim_finished"),
		"PlayerController doit déclarer le signal vehicle_anim_finished")
	if not ctrl.has_signal("vehicle_anim_finished"):
		return
	if not ctrl.has_method("start_car_enter"):
		return

	# L'AnimationPlayer créé dans _creer_player_controller() est vide (pas d'animation "car_enter")
	watch_signals(ctrl)
	ctrl.start_car_enter(vehicle_mock)

	assert_signal_emitted(ctrl, "vehicle_anim_finished",
		"vehicle_anim_finished doit être émis immédiatement quand 'car_enter' est absente de l'AnimationPlayer")

# ---------------------------------------------------------------------------
# B4 — start_car_drive() : _vehicle_state == "car_drive"
# ---------------------------------------------------------------------------
func test_B04_start_car_drive_met_a_jour_etat() -> void:
	# B4
	var ctrl: CharacterBody3D = _creer_player_controller()
	assert_not_null(ctrl, "player_controller.gd doit être instanciable")
	if ctrl == null:
		return
	add_child_autofree(ctrl)

	assert_true(ctrl.has_method("start_car_drive"),
		"PlayerController doit avoir la méthode start_car_drive()")
	if not ctrl.has_method("start_car_drive"):
		return

	ctrl.start_car_drive()

	assert_eq(ctrl.get("_vehicle_state"), "car_drive",
		"_vehicle_state doit valoir 'car_drive' après start_car_drive()")

# ---------------------------------------------------------------------------
# B5 — start_car_exit(exit_pos) : _vehicle_state == "car_exit", global_position ≈ exit_pos
# ---------------------------------------------------------------------------
func test_B05_start_car_exit_met_a_jour_etat_et_position() -> void:
	# B5
	var ctrl: CharacterBody3D = _creer_player_controller()
	assert_not_null(ctrl, "player_controller.gd doit être instanciable")
	if ctrl == null:
		return
	add_child_autofree(ctrl)

	assert_true(ctrl.has_method("start_car_exit"),
		"PlayerController doit avoir la méthode start_car_exit()")
	if not ctrl.has_method("start_car_exit"):
		return

	var exit_pos: Vector3 = Vector3(1.0, 0.9, 0.0)
	ctrl.start_car_exit(exit_pos)

	assert_eq(ctrl.get("_vehicle_state"), "car_exit",
		"_vehicle_state doit valoir 'car_exit' après start_car_exit()")
	var gpos: Vector3 = ctrl.global_position
	assert_almost_eq(gpos.x, exit_pos.x, 0.01,
		"global_position.x doit être ≈ exit_pos.x après start_car_exit()")
	assert_almost_eq(gpos.y, exit_pos.y, 0.01,
		"global_position.y doit être ≈ exit_pos.y après start_car_exit()")
	assert_almost_eq(gpos.z, exit_pos.z, 0.01,
		"global_position.z doit être ≈ exit_pos.z après start_car_exit()")

# ---------------------------------------------------------------------------
# B6 — start_car_exit + AnimationPlayer sans "car_exit" → vehicle_anim_finished émis immédiatement
# ---------------------------------------------------------------------------
func test_B06_start_car_exit_sans_animation_emet_signal_immediat() -> void:
	# B6
	var ctrl: CharacterBody3D = _creer_player_controller()
	assert_not_null(ctrl, "player_controller.gd doit être instanciable")
	if ctrl == null:
		return
	add_child_autofree(ctrl)

	assert_true(ctrl.has_signal("vehicle_anim_finished"),
		"PlayerController doit déclarer le signal vehicle_anim_finished")
	if not ctrl.has_signal("vehicle_anim_finished"):
		return
	if not ctrl.has_method("start_car_exit"):
		return

	watch_signals(ctrl)
	ctrl.start_car_exit(Vector3.ZERO)

	assert_signal_emitted(ctrl, "vehicle_anim_finished",
		"vehicle_anim_finished doit être émis immédiatement quand 'car_exit' est absente de l'AnimationPlayer")

# ---------------------------------------------------------------------------
# B7 — finish_car_exit() : _vehicle_state == "none", _followed_vehicle == null
# ---------------------------------------------------------------------------
func test_B07_finish_car_exit_remet_etat_none() -> void:
	# B7
	var ctrl: CharacterBody3D = _creer_player_controller()
	assert_not_null(ctrl, "player_controller.gd doit être instanciable")
	if ctrl == null:
		return
	add_child_autofree(ctrl)

	assert_true(ctrl.has_method("finish_car_exit"),
		"PlayerController doit avoir la méthode finish_car_exit()")
	if not ctrl.has_method("finish_car_exit"):
		return

	# Forcer un état intermédiaire
	var vehicle_mock: VehicleBody3D = _creer_vehicle_mock()
	add_child_autofree(vehicle_mock)
	if ctrl.has_method("start_car_enter"):
		ctrl.start_car_enter(vehicle_mock)
	ctrl.set("_vehicle_state", "car_exit")

	ctrl.finish_car_exit()

	assert_eq(ctrl.get("_vehicle_state"), "none",
		"_vehicle_state doit valoir 'none' après finish_car_exit()")
	assert_null(ctrl.get("_followed_vehicle"),
		"_followed_vehicle doit être null après finish_car_exit()")

# ---------------------------------------------------------------------------
# B8 — _update_animation() avec _vehicle_state == "car_drive" → ne joue pas "idle" ni "walk"
# ---------------------------------------------------------------------------
func test_B08_update_animation_bloque_pendant_conduite() -> void:
	# B8
	var ctrl: CharacterBody3D = _creer_player_controller()
	assert_not_null(ctrl, "player_controller.gd doit être instanciable")
	if ctrl == null:
		return
	add_child_autofree(ctrl)

	# Injecter une animation "idle" dans l'AnimationPlayer
	var ap: AnimationPlayer = ctrl.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if ap == null:
		return
	if not ap.has_animation_library(""):
		ap.add_animation_library("", AnimationLibrary.new())
	var lib: AnimationLibrary = ap.get_animation_library("")
	if not lib.has_animation("idle"):
		lib.add_animation("idle", Animation.new())
	if not lib.has_animation("walk"):
		lib.add_animation("walk", Animation.new())

	# Forcer l'état car_drive
	ctrl.set("_vehicle_state", "car_drive")
	ctrl.set("_anim_player", ap)

	# Mémoriser l'animation courante avant appel
	var anim_avant: String = ap.current_animation

	if ctrl.has_method("_update_animation"):
		ctrl._update_animation()

	# L'animation courante ne doit pas avoir changé vers "idle" ou "walk"
	assert_ne(ap.current_animation, "idle",
		"_update_animation() ne doit pas jouer 'idle' quand _vehicle_state == 'car_drive'")
	assert_ne(ap.current_animation, "walk",
		"_update_animation() ne doit pas jouer 'walk' quand _vehicle_state == 'car_drive'")
	assert_eq(ap.current_animation, anim_avant,
		"L'animation courante ne doit pas changer pendant l'état car_drive")

# ===========================================================================
# GROUPE 2 — Méthode _play_anim (B9–B12)
# ===========================================================================

# ---------------------------------------------------------------------------
# B9 — _play_anim("car_enter") avec _anim_player == null → aucun crash, vehicle_anim_finished émis
# ---------------------------------------------------------------------------
func test_B09_play_anim_avec_anim_player_null_pas_de_crash() -> void:
	# B9
	var ctrl: CharacterBody3D = _creer_player_controller()
	assert_not_null(ctrl, "player_controller.gd doit être instanciable")
	if ctrl == null:
		return
	add_child_autofree(ctrl)

	# Forcer _anim_player à null
	ctrl.set("_anim_player", null)
	ctrl.set("_vehicle_state", "car_enter")

	assert_true(ctrl.has_signal("vehicle_anim_finished"),
		"vehicle_anim_finished doit être déclaré")
	if not ctrl.has_signal("vehicle_anim_finished"):
		return
	if not ctrl.has_method("_play_anim"):
		fail_test("PlayerController doit avoir la méthode _play_anim()")
		return

	watch_signals(ctrl)
	ctrl._play_anim("car_enter")

	assert_signal_emitted(ctrl, "vehicle_anim_finished",
		"vehicle_anim_finished doit être émis quand _anim_player == null")

# ---------------------------------------------------------------------------
# B10 — _play_anim("car_enter") avec AnimationPlayer sans "car_enter" → aucun crash, signal émis
# ---------------------------------------------------------------------------
func test_B10_play_anim_animation_absente_emet_signal() -> void:
	# B10
	var ctrl: CharacterBody3D = _creer_player_controller()
	assert_not_null(ctrl, "player_controller.gd doit être instanciable")
	if ctrl == null:
		return
	add_child_autofree(ctrl)

	# L'AnimationPlayer ne contient pas "car_enter"
	var ap: AnimationPlayer = ctrl.get_node_or_null("AnimationPlayer") as AnimationPlayer
	assert_not_null(ap, "AnimationPlayer doit exister")
	if ap == null:
		return

	ctrl.set("_anim_player", ap)
	ctrl.set("_vehicle_state", "car_enter")

	assert_true(ctrl.has_signal("vehicle_anim_finished"),
		"vehicle_anim_finished doit être déclaré")
	if not ctrl.has_signal("vehicle_anim_finished"):
		return
	if not ctrl.has_method("_play_anim"):
		fail_test("PlayerController doit avoir la méthode _play_anim()")
		return

	watch_signals(ctrl)
	ctrl._play_anim("car_enter")

	assert_signal_emitted(ctrl, "vehicle_anim_finished",
		"vehicle_anim_finished doit être émis quand 'car_enter' est absente de l'AnimationPlayer")

# ---------------------------------------------------------------------------
# B11 — _play_anim("car_enter") avec AnimationPlayer contenant "car_enter" → animation en cours,
#        vehicle_anim_finished PAS encore émis
# ---------------------------------------------------------------------------
func test_B11_play_anim_avec_animation_presente_joue_et_ne_pas_emettre_signal() -> void:
	# B11
	var ctrl: CharacterBody3D = _creer_player_controller()
	assert_not_null(ctrl, "player_controller.gd doit être instanciable")
	if ctrl == null:
		return
	add_child_autofree(ctrl)

	var ap: AnimationPlayer = ctrl.get_node_or_null("AnimationPlayer") as AnimationPlayer
	assert_not_null(ap, "AnimationPlayer doit exister")
	if ap == null:
		return

	# Injecter une animation "car_enter" dans l'AnimationPlayer
	if not ap.has_animation_library(""):
		ap.add_animation_library("", AnimationLibrary.new())
	var lib: AnimationLibrary = ap.get_animation_library("")
	var anim: Animation = Animation.new()
	# Durée non nulle pour que l'animation ne se termine pas immédiatement
	anim.length = 1.0
	if not lib.has_animation("car_enter"):
		lib.add_animation("car_enter", anim)

	ctrl.set("_anim_player", ap)
	ctrl.set("_vehicle_state", "car_enter")

	assert_true(ctrl.has_signal("vehicle_anim_finished"),
		"vehicle_anim_finished doit être déclaré")
	if not ctrl.has_signal("vehicle_anim_finished"):
		return
	if not ctrl.has_method("_play_anim"):
		fail_test("PlayerController doit avoir la méthode _play_anim()")
		return

	watch_signals(ctrl)
	ctrl._play_anim("car_enter")

	assert_eq(ap.current_animation, "car_enter",
		"L'animation 'car_enter' doit être en cours de lecture après _play_anim('car_enter')")
	assert_signal_not_emitted(ctrl, "vehicle_anim_finished",
		"vehicle_anim_finished ne doit pas encore être émis pendant la lecture de 'car_enter'")

# ---------------------------------------------------------------------------
# B12 — _play_anim("car_drive") avec AnimationPlayer contenant "car_drive" (boucle) → en cours de lecture
# ---------------------------------------------------------------------------
func test_B12_play_anim_car_drive_boucle() -> void:
	# B12
	var ctrl: CharacterBody3D = _creer_player_controller()
	assert_not_null(ctrl, "player_controller.gd doit être instanciable")
	if ctrl == null:
		return
	add_child_autofree(ctrl)

	var ap: AnimationPlayer = ctrl.get_node_or_null("AnimationPlayer") as AnimationPlayer
	assert_not_null(ap, "AnimationPlayer doit exister")
	if ap == null:
		return

	# Injecter une animation "car_drive" en boucle
	if not ap.has_animation_library(""):
		ap.add_animation_library("", AnimationLibrary.new())
	var lib: AnimationLibrary = ap.get_animation_library("")
	var anim: Animation = Animation.new()
	anim.length = 2.0
	anim.loop_mode = Animation.LOOP_LINEAR
	if not lib.has_animation("car_drive"):
		lib.add_animation("car_drive", anim)

	ctrl.set("_anim_player", ap)
	ctrl.set("_vehicle_state", "car_drive")

	if not ctrl.has_method("_play_anim"):
		fail_test("PlayerController doit avoir la méthode _play_anim()")
		return

	ctrl._play_anim("car_drive")

	assert_eq(ap.current_animation, "car_drive",
		"L'animation 'car_drive' doit être en cours de lecture après _play_anim('car_drive')")
	var played_anim: Animation = ap.get_animation("car_drive")
	assert_eq(played_anim.loop_mode, Animation.LOOP_LINEAR,
		"L'animation 'car_drive' doit avoir loop_mode == LOOP_LINEAR")

# ===========================================================================
# GROUPE 3 — Signal vehicle_anim_finished (B13–B15)
# ===========================================================================

# ---------------------------------------------------------------------------
# B13 — _on_vehicle_anim_finished("idle") → vehicle_anim_finished PAS émis
# ---------------------------------------------------------------------------
func test_B13_on_vehicle_anim_finished_idle_pas_de_signal() -> void:
	# B13
	var ctrl: CharacterBody3D = _creer_player_controller()
	assert_not_null(ctrl, "player_controller.gd doit être instanciable")
	if ctrl == null:
		return
	add_child_autofree(ctrl)

	assert_true(ctrl.has_signal("vehicle_anim_finished"),
		"vehicle_anim_finished doit être déclaré")
	if not ctrl.has_signal("vehicle_anim_finished"):
		return
	if not ctrl.has_method("_on_vehicle_anim_finished"):
		fail_test("PlayerController doit avoir la méthode _on_vehicle_anim_finished()")
		return

	watch_signals(ctrl)
	ctrl._on_vehicle_anim_finished("idle")

	assert_signal_not_emitted(ctrl, "vehicle_anim_finished",
		"vehicle_anim_finished ne doit pas être émis pour l'animation 'idle'")

# ---------------------------------------------------------------------------
# B14 — _on_vehicle_anim_finished("walk") → vehicle_anim_finished PAS émis
# ---------------------------------------------------------------------------
func test_B14_on_vehicle_anim_finished_walk_pas_de_signal() -> void:
	# B14
	var ctrl: CharacterBody3D = _creer_player_controller()
	assert_not_null(ctrl, "player_controller.gd doit être instanciable")
	if ctrl == null:
		return
	add_child_autofree(ctrl)

	assert_true(ctrl.has_signal("vehicle_anim_finished"),
		"vehicle_anim_finished doit être déclaré")
	if not ctrl.has_signal("vehicle_anim_finished"):
		return
	if not ctrl.has_method("_on_vehicle_anim_finished"):
		fail_test("PlayerController doit avoir la méthode _on_vehicle_anim_finished()")
		return

	watch_signals(ctrl)
	ctrl._on_vehicle_anim_finished("walk")

	assert_signal_not_emitted(ctrl, "vehicle_anim_finished",
		"vehicle_anim_finished ne doit pas être émis pour l'animation 'walk'")

# ---------------------------------------------------------------------------
# B15 — _on_vehicle_anim_finished("car_enter") avec _vehicle_state == "car_enter"
#        → vehicle_anim_finished émis exactement une fois
# ---------------------------------------------------------------------------
func test_B15_on_vehicle_anim_finished_car_enter_emet_signal_exactement_une_fois() -> void:
	# B15
	var ctrl: CharacterBody3D = _creer_player_controller()
	assert_not_null(ctrl, "player_controller.gd doit être instanciable")
	if ctrl == null:
		return
	add_child_autofree(ctrl)

	assert_true(ctrl.has_signal("vehicle_anim_finished"),
		"vehicle_anim_finished doit être déclaré")
	if not ctrl.has_signal("vehicle_anim_finished"):
		return
	if not ctrl.has_method("_on_vehicle_anim_finished"):
		fail_test("PlayerController doit avoir la méthode _on_vehicle_anim_finished()")
		return

	ctrl.set("_vehicle_state", "car_enter")

	watch_signals(ctrl)
	ctrl._on_vehicle_anim_finished("car_enter")

	assert_signal_emit_count(ctrl, "vehicle_anim_finished", 1,
		"vehicle_anim_finished doit être émis exactement une fois pour 'car_enter'")

# ===========================================================================
# GROUPE 4 — Suivi du siège conducteur (B16–B17)
# ===========================================================================

# ---------------------------------------------------------------------------
# B16 — _physics_process() en état "car_drive" → global_position ≈ DRIVER_SEAT_OFFSET
# ---------------------------------------------------------------------------
func test_B16_physics_process_suit_siege_conducteur() -> void:
	# B16
	var ctrl: CharacterBody3D = _creer_player_controller()
	assert_not_null(ctrl, "player_controller.gd doit être instanciable")
	if ctrl == null:
		return
	add_child_autofree(ctrl)

	var vehicle_mock: VehicleBody3D = _creer_vehicle_mock()
	vehicle_mock.global_position = Vector3.ZERO
	add_child_autofree(vehicle_mock)

	# Forcer l'état car_drive avec le véhicule référencé
	ctrl.set("_vehicle_state", "car_drive")
	ctrl.set("_followed_vehicle", vehicle_mock)

	ctrl._physics_process(0.016)

	# Vérifier que la position est approximativement DRIVER_SEAT_OFFSET = Vector3(-0.4, 0.6, 0.3)
	# quand le véhicule est à l'origine avec transform identité
	var gpos: Vector3 = ctrl.global_position
	assert_almost_eq(gpos.x, -0.4, 0.05,
		"global_position.x doit être ≈ DRIVER_SEAT_OFFSET.x (-0.4) en état car_drive")
	assert_almost_eq(gpos.y, 0.6, 0.05,
		"global_position.y doit être ≈ DRIVER_SEAT_OFFSET.y (0.6) en état car_drive")
	assert_almost_eq(gpos.z, 0.3, 0.05,
		"global_position.z doit être ≈ DRIVER_SEAT_OFFSET.z (0.3) en état car_drive")

# ---------------------------------------------------------------------------
# B17 — _physics_process() en état "none" → position non modifiée par la logique siège
# ---------------------------------------------------------------------------
func test_B17_physics_process_sans_conduite_ne_modifie_pas_position_siege() -> void:
	# B17
	var ctrl: CharacterBody3D = _creer_player_controller()
	assert_not_null(ctrl, "player_controller.gd doit être instanciable")
	if ctrl == null:
		return
	add_child_autofree(ctrl)

	# État piéton normal
	ctrl.set("_vehicle_state", "none")
	ctrl.global_position = Vector3(5.0, 0.0, 5.0)

	ctrl._physics_process(0.016)

	# La logique de siège conducteur ne doit pas modifier la position
	# (la position peut changer à cause du mouvement normal mais pas à cause du siège)
	# On vérifie que _followed_vehicle == null ne provoque pas un repositionnement forcé
	var gpos: Vector3 = ctrl.global_position
	assert_false(
		abs(gpos.x - (-0.4)) < 0.1 and abs(gpos.y - 0.6) < 0.1 and abs(gpos.z - 0.3) < 0.1,
		"_physics_process() en état 'none' ne doit pas positionner le joueur au DRIVER_SEAT_OFFSET"
	)

# ===========================================================================
# GROUPE 5 — Guard CarController (B18–B20)
# ===========================================================================

func _setup_car_controller_avec_player(vehicle_state: String) -> Array:
	var CarControllerScript = load("res://src/vehicles/car_controller.gd")
	if CarControllerScript == null:
		return []
	var PlayerControllerScript = load("res://src/player/player_controller.gd")
	if PlayerControllerScript == null:
		return []

	var car_body: VehicleBody3D = _creer_vehicle_mock()
	add_child_autofree(car_body)

	var mock_gs: GameState = _creer_game_state()
	add_child_autofree(mock_gs)
	mock_gs.player_mode = GameState.PlayerMode.IN_VEHICLE

	var player_mock: CharacterBody3D = PlayerControllerScript.new() as CharacterBody3D
	player_mock.set("_vehicle_state", vehicle_state)
	add_child_autofree(player_mock)

	var ctrl: Node = CarControllerScript.new()
	ctrl.set("_game_state", mock_gs)
	ctrl.set("_car_body", car_body)
	ctrl.set("_player", player_mock)
	add_child_autofree(ctrl)

	return [ctrl, car_body, mock_gs, player_mock]

# ---------------------------------------------------------------------------
# B18 — CarController._physics_process() en IN_VEHICLE + _vehicle_state == "car_enter"
#        → engine_force == 0, brake == 0
# ---------------------------------------------------------------------------
func test_B18_guard_car_controller_bloque_pendant_car_enter() -> void:
	# B18
	var setup: Array = _setup_car_controller_avec_player("car_enter")
	if setup.is_empty():
		fail_test("car_controller.gd ou player_controller.gd non chargeable")
		return

	var ctrl: Node = setup[0]
	var car_body: VehicleBody3D = setup[1]

	if not ctrl.has_method("_physics_process"):
		fail_test("CarController doit avoir _physics_process()")
		return

	Input.action_press("drive_forward")
	ctrl._physics_process(0.016)
	Input.action_release("drive_forward")
	Input.flush_buffered_events()

	assert_eq(car_body.engine_force, 0.0,
		"engine_force doit être 0 quand _vehicle_state == 'car_enter' (guard B18)")
	assert_eq(car_body.brake, 0.0,
		"brake doit être 0 quand _vehicle_state == 'car_enter' (guard B18)")

# ---------------------------------------------------------------------------
# B19 — CarController._physics_process() en IN_VEHICLE + _vehicle_state == "car_exit"
#        → engine_force == 0, brake == 0
# ---------------------------------------------------------------------------
func test_B19_guard_car_controller_bloque_pendant_car_exit() -> void:
	# B19
	var setup: Array = _setup_car_controller_avec_player("car_exit")
	if setup.is_empty():
		fail_test("car_controller.gd ou player_controller.gd non chargeable")
		return

	var ctrl: Node = setup[0]
	var car_body: VehicleBody3D = setup[1]

	if not ctrl.has_method("_physics_process"):
		fail_test("CarController doit avoir _physics_process()")
		return

	Input.action_press("drive_forward")
	ctrl._physics_process(0.016)
	Input.action_release("drive_forward")
	Input.flush_buffered_events()

	assert_eq(car_body.engine_force, 0.0,
		"engine_force doit être 0 quand _vehicle_state == 'car_exit' (guard B19)")
	assert_eq(car_body.brake, 0.0,
		"brake doit être 0 quand _vehicle_state == 'car_exit' (guard B19)")

# ---------------------------------------------------------------------------
# B20 — CarController._physics_process() en IN_VEHICLE + _vehicle_state == "car_drive"
#        + drive_forward pressé → engine_force != 0
# ---------------------------------------------------------------------------
func test_B20_guard_car_controller_autorise_conduite_pendant_car_drive() -> void:
	# B20
	var setup: Array = _setup_car_controller_avec_player("car_drive")
	if setup.is_empty():
		fail_test("car_controller.gd ou player_controller.gd non chargeable")
		return

	var ctrl: Node = setup[0]
	var car_body: VehicleBody3D = setup[1]

	if not ctrl.has_method("_physics_process"):
		fail_test("CarController doit avoir _physics_process()")
		return

	Input.action_press("drive_forward")
	ctrl._physics_process(0.016)
	Input.action_release("drive_forward")
	Input.flush_buffered_events()

	assert_ne(car_body.engine_force, 0.0,
		"engine_force doit être != 0 quand _vehicle_state == 'car_drive' et drive_forward pressé (B20)")

# ===========================================================================
# GROUPE 6 — Intégration GameState (B21–B27)
# ===========================================================================

# ---------------------------------------------------------------------------
# B21 — GameState.enter_vehicle(car_mock) avec _player mock → start_car_enter est appelé,
#        _anim_enter_pending == true
# ---------------------------------------------------------------------------
func test_B21_enter_vehicle_appelle_start_car_enter_et_met_pending_a_true() -> void:
	# B21
	var gs: GameState = _creer_game_state()
	assert_not_null(gs, "game_state.gd doit être instanciable")
	if gs == null:
		return
	add_child_autofree(gs)

	var PlayerControllerScript = load("res://src/player/player_controller.gd")
	if PlayerControllerScript == null:
		fail_test("player_controller.gd doit être chargeable")
		return
	var player_mock: CharacterBody3D = PlayerControllerScript.new() as CharacterBody3D
	add_child_autofree(player_mock)

	var car_mock: VehicleBody3D = _creer_vehicle_mock()
	add_child_autofree(car_mock)

	gs.set("_player", player_mock as PlayerController)

	gs.enter_vehicle(car_mock)

	assert_true(gs.get("_anim_enter_pending"),
		"_anim_enter_pending doit être true pendant l'animation d'entrée (B21)")
	# Vérifier que _vehicle_state du player est passé à "car_enter"
	assert_eq(player_mock.get("_vehicle_state"), "car_enter",
		"player._vehicle_state doit valoir 'car_enter' après enter_vehicle() (B21)")

# ---------------------------------------------------------------------------
# B22 — Double appel enter_vehicle : deuxième appel ignoré, start_car_enter appelé une seule fois
# ---------------------------------------------------------------------------
func test_B22_double_enter_vehicle_ignore_deuxieme_appel() -> void:
	# B22
	var gs: GameState = _creer_game_state()
	assert_not_null(gs, "game_state.gd doit être instanciable")
	if gs == null:
		return
	add_child_autofree(gs)

	var PlayerControllerScript = load("res://src/player/player_controller.gd")
	if PlayerControllerScript == null:
		fail_test("player_controller.gd doit être chargeable")
		return
	var player_mock: CharacterBody3D = PlayerControllerScript.new() as CharacterBody3D
	add_child_autofree(player_mock)

	var car_mock: VehicleBody3D = _creer_vehicle_mock()
	add_child_autofree(car_mock)

	gs.set("_player", player_mock as PlayerController)

	# Premier appel
	gs.enter_vehicle(car_mock)
	assert_true(gs.get("_anim_enter_pending"),
		"_anim_enter_pending doit être true après premier enter_vehicle() (B22)")

	# Simuler le deuxième appel — _anim_enter_pending doit bloquer
	# On capture l'état de _vehicle_state avant le deuxième appel
	var state_avant_deuxieme: String = player_mock.get("_vehicle_state") as String

	gs.enter_vehicle(car_mock)

	# Le deuxième appel ne doit pas avoir changé _vehicle_state à nouveau
	# (il devrait être ignoré)
	assert_eq(player_mock.get("_vehicle_state"), state_avant_deuxieme,
		"Le deuxième appel à enter_vehicle() doit être ignoré (_anim_enter_pending) (B22)")

# ---------------------------------------------------------------------------
# B23 — Après enter_vehicle + émission de vehicle_anim_finished → player_mode == IN_VEHICLE,
#        _anim_enter_pending == false
# ---------------------------------------------------------------------------
func test_B23_apres_vehicle_anim_finished_enter_player_mode_in_vehicle() -> void:
	# B23
	var gs: GameState = _creer_game_state()
	assert_not_null(gs, "game_state.gd doit être instanciable")
	if gs == null:
		return
	add_child_autofree(gs)

	var PlayerControllerScript = load("res://src/player/player_controller.gd")
	if PlayerControllerScript == null:
		fail_test("player_controller.gd doit être chargeable")
		return
	var player_mock: CharacterBody3D = PlayerControllerScript.new() as CharacterBody3D
	add_child_autofree(player_mock)

	var car_mock: VehicleBody3D = _creer_vehicle_mock()
	add_child_autofree(car_mock)

	gs.set("_player", player_mock as PlayerController)

	# enter_vehicle() déclenche start_car_enter() → fallback (pas d'animation) →
	# vehicle_anim_finished émis immédiatement → _on_player_vehicle_anim_finished() →
	# _complete_enter_vehicle()
	gs.enter_vehicle(car_mock)

	# Après le cycle complet (synchrone en fallback), player_mode doit être IN_VEHICLE
	assert_eq(gs.player_mode, GameState.PlayerMode.IN_VEHICLE,
		"player_mode doit valoir IN_VEHICLE après le cycle complet enter_vehicle (B23)")
	assert_false(gs.get("_anim_enter_pending"),
		"_anim_enter_pending doit être false après _complete_enter_vehicle (B23)")

# ---------------------------------------------------------------------------
# B24 — Après _complete_enter_vehicle() → CollisionShape3D du joueur désactivée
# ---------------------------------------------------------------------------
func test_B24_complete_enter_vehicle_desactive_collision() -> void:
	# B24
	var gs: GameState = _creer_game_state()
	assert_not_null(gs, "game_state.gd doit être instanciable")
	if gs == null:
		return
	add_child_autofree(gs)

	var PlayerControllerScript = load("res://src/player/player_controller.gd")
	if PlayerControllerScript == null:
		fail_test("player_controller.gd doit être chargeable")
		return
	var player_mock: CharacterBody3D = PlayerControllerScript.new() as CharacterBody3D

	# Ajouter une CollisionShape3D nommée "CollisionShape3D"
	var col: CollisionShape3D = CollisionShape3D.new()
	col.name = "CollisionShape3D"
	col.shape = CapsuleShape3D.new()
	player_mock.add_child(col)

	var body: Node3D = Node3D.new()
	body.name = "PlayerBody"
	player_mock.add_child(body)
	add_child_autofree(player_mock)

	var car_mock: VehicleBody3D = _creer_vehicle_mock()
	add_child_autofree(car_mock)

	gs.set("_player", player_mock as PlayerController)
	gs.set("_player_body", body)

	# Cycle complet en fallback (pas d'animation)
	gs.enter_vehicle(car_mock)

	var col_node: CollisionShape3D = player_mock.get_node_or_null("CollisionShape3D") as CollisionShape3D
	assert_not_null(col_node, "CollisionShape3D doit exister dans le joueur mock")
	if col_node == null:
		return
	assert_true(col_node.disabled,
		"CollisionShape3D.disabled doit être true après _complete_enter_vehicle() (B24)")

# ---------------------------------------------------------------------------
# B25 — exit_vehicle() avec _vehicle_state == "car_drive" → start_car_exit appelé,
#        _anim_exit_pending == true
# ---------------------------------------------------------------------------
func test_B25_exit_vehicle_appelle_start_car_exit_et_met_pending_a_true() -> void:
	# B25
	var gs: GameState = _creer_game_state()
	assert_not_null(gs, "game_state.gd doit être instanciable")
	if gs == null:
		return
	add_child_autofree(gs)

	var PlayerControllerScript = load("res://src/player/player_controller.gd")
	if PlayerControllerScript == null:
		fail_test("player_controller.gd doit être chargeable")
		return
	var player_mock: CharacterBody3D = PlayerControllerScript.new() as CharacterBody3D
	add_child_autofree(player_mock)

	var car_mock: VehicleBody3D = _creer_vehicle_mock()
	car_mock.global_position = Vector3.ZERO
	add_child_autofree(car_mock)

	gs.set("_player", player_mock as PlayerController)
	gs.set("current_vehicle", car_mock)
	gs.player_mode = GameState.PlayerMode.IN_VEHICLE
	player_mock.set("_vehicle_state", "car_drive")

	gs.exit_vehicle()

	assert_true(gs.get("_anim_exit_pending"),
		"_anim_exit_pending doit être true pendant l'animation de sortie (B25)")
	assert_eq(player_mock.get("_vehicle_state"), "car_exit",
		"player._vehicle_state doit valoir 'car_exit' après exit_vehicle() (B25)")

# ---------------------------------------------------------------------------
# B26 — Double appel exit_vehicle() → deuxième appel ignoré (_anim_exit_pending)
# ---------------------------------------------------------------------------
func test_B26_double_exit_vehicle_ignore_deuxieme_appel() -> void:
	# B26
	var gs: GameState = _creer_game_state()
	assert_not_null(gs, "game_state.gd doit être instanciable")
	if gs == null:
		return
	add_child_autofree(gs)

	var PlayerControllerScript = load("res://src/player/player_controller.gd")
	if PlayerControllerScript == null:
		fail_test("player_controller.gd doit être chargeable")
		return
	var player_mock: CharacterBody3D = PlayerControllerScript.new() as CharacterBody3D
	add_child_autofree(player_mock)

	var car_mock: VehicleBody3D = _creer_vehicle_mock()
	car_mock.global_position = Vector3.ZERO
	add_child_autofree(car_mock)

	gs.set("_player", player_mock as PlayerController)
	gs.set("current_vehicle", car_mock)
	gs.player_mode = GameState.PlayerMode.IN_VEHICLE
	player_mock.set("_vehicle_state", "car_drive")

	# Premier appel
	gs.exit_vehicle()
	assert_true(gs.get("_anim_exit_pending"),
		"_anim_exit_pending doit être true après premier exit_vehicle() (B26)")

	# Deuxième appel — doit être ignoré
	var state_avant: String = player_mock.get("_vehicle_state") as String
	gs.exit_vehicle()
	assert_eq(player_mock.get("_vehicle_state"), state_avant,
		"Le deuxième appel à exit_vehicle() doit être ignoré (_anim_exit_pending) (B26)")

# ---------------------------------------------------------------------------
# B27 — Après exit_vehicle + vehicle_anim_finished → player_mode == ON_FOOT,
#        CollisionShape3D.disabled == false
# ---------------------------------------------------------------------------
func test_B27_apres_vehicle_anim_finished_exit_player_mode_on_foot_et_collision_reactive() -> void:
	# B27
	var gs: GameState = _creer_game_state()
	assert_not_null(gs, "game_state.gd doit être instanciable")
	if gs == null:
		return
	add_child_autofree(gs)

	var PlayerControllerScript = load("res://src/player/player_controller.gd")
	if PlayerControllerScript == null:
		fail_test("player_controller.gd doit être chargeable")
		return
	var player_mock: CharacterBody3D = PlayerControllerScript.new() as CharacterBody3D

	# CollisionShape3D pour vérification B27
	var col: CollisionShape3D = CollisionShape3D.new()
	col.name = "CollisionShape3D"
	col.shape = CapsuleShape3D.new()
	col.disabled = true  # désactivée pendant la conduite
	player_mock.add_child(col)

	var body: Node3D = Node3D.new()
	body.name = "PlayerBody"
	player_mock.add_child(body)
	add_child_autofree(player_mock)

	var car_mock: VehicleBody3D = _creer_vehicle_mock()
	car_mock.global_position = Vector3.ZERO
	add_child_autofree(car_mock)

	gs.set("_player", player_mock as PlayerController)
	gs.set("_player_body", body)
	gs.set("current_vehicle", car_mock)
	gs.player_mode = GameState.PlayerMode.IN_VEHICLE
	player_mock.set("_vehicle_state", "car_drive")

	# exit_vehicle() → start_car_exit() → fallback (pas d'animation) →
	# vehicle_anim_finished → _complete_exit_vehicle()
	gs.exit_vehicle()

	assert_eq(gs.player_mode, GameState.PlayerMode.ON_FOOT,
		"player_mode doit valoir ON_FOOT après le cycle complet exit_vehicle (B27)")

	var col_node: CollisionShape3D = player_mock.get_node_or_null("CollisionShape3D") as CollisionShape3D
	assert_not_null(col_node, "CollisionShape3D doit exister dans le joueur mock")
	if col_node == null:
		return
	assert_false(col_node.disabled,
		"CollisionShape3D.disabled doit être false après _complete_exit_vehicle() (B27)")

# ===========================================================================
# GROUPE 7 — Chargement des animations véhicule (B28–B31)
# ===========================================================================

# ---------------------------------------------------------------------------
# B28 — PlayerController a la méthode _charger_animations_vehicule()
# ---------------------------------------------------------------------------
func test_B28_player_controller_a_methode_charger_animations_vehicule() -> void:
	# B28
	var ctrl: CharacterBody3D = _creer_player_controller()
	assert_not_null(ctrl, "player_controller.gd doit être instanciable")
	if ctrl == null:
		return
	add_child_autofree(ctrl)

	assert_true(ctrl.has_method("_charger_animations_vehicule"),
		"PlayerController doit avoir la méthode _charger_animations_vehicule() (B28)")

# ---------------------------------------------------------------------------
# B29 — Si player_car_drive.glb est présent → après _charger_animations_vehicule(),
#        AnimationPlayer a "car_drive" avec loop_mode == LOOP_LINEAR
# ---------------------------------------------------------------------------
func test_B29_car_drive_glb_present_injecte_animation_bouclée() -> void:
	# B29
	if not ResourceLoader.exists("res://assets/characters/player/player_car_drive.glb"):
		pass  # GLB absent → test non applicable, B30 couvre l'absence
		return

	var ctrl: CharacterBody3D = _creer_player_controller()
	assert_not_null(ctrl, "player_controller.gd doit être instanciable")
	if ctrl == null:
		return
	add_child_autofree(ctrl)

	if not ctrl.has_method("_charger_animations_vehicule"):
		fail_test("PlayerController doit avoir _charger_animations_vehicule()")
		return

	ctrl._charger_animations_vehicule()

	var ap: AnimationPlayer = ctrl.get_node_or_null("AnimationPlayer") as AnimationPlayer
	assert_not_null(ap, "AnimationPlayer doit exister après _charger_animations_vehicule()")
	if ap == null:
		return

	assert_true(ap.has_animation("car_drive"),
		"AnimationPlayer doit avoir l'animation 'car_drive' après _charger_animations_vehicule() (B29)")

	if ap.has_animation("car_drive"):
		var anim: Animation = ap.get_animation("car_drive")
		assert_eq(anim.loop_mode, Animation.LOOP_LINEAR,
			"L'animation 'car_drive' doit avoir loop_mode == LOOP_LINEAR (B29)")

# ---------------------------------------------------------------------------
# B30 — Si player_car_enter.glb est absent → _charger_animations_vehicule() sans crash,
#        AnimationPlayer n'a pas "car_enter"
# ---------------------------------------------------------------------------
func test_B30_car_enter_glb_absent_pas_de_crash_pas_animation() -> void:
	# B30
	if ResourceLoader.exists("res://assets/characters/player/player_car_enter.glb"):
		pass  # GLB présent → ce test n'est pas applicable
		return

	var ctrl: CharacterBody3D = _creer_player_controller()
	assert_not_null(ctrl, "player_controller.gd doit être instanciable")
	if ctrl == null:
		return
	add_child_autofree(ctrl)

	if not ctrl.has_method("_charger_animations_vehicule"):
		fail_test("PlayerController doit avoir _charger_animations_vehicule()")
		return

	# Ne doit pas crasher
	ctrl._charger_animations_vehicule()

	var ap: AnimationPlayer = ctrl.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if ap == null:
		return

	assert_false(ap.has_animation("car_enter"),
		"AnimationPlayer ne doit pas avoir 'car_enter' si player_car_enter.glb est absent (B30)")
	pass_test("_charger_animations_vehicule() sans crash quand player_car_enter.glb est absent (B30)")

# ---------------------------------------------------------------------------
# B31 — Après _ready(), AnimationPlayer.animation_finished est connecté à _on_vehicle_anim_finished
# ---------------------------------------------------------------------------
func test_B31_animation_finished_connecte_a_on_vehicle_anim_finished() -> void:
	# B31
	var ctrl: CharacterBody3D = _creer_player_controller()
	assert_not_null(ctrl, "player_controller.gd doit être instanciable")
	if ctrl == null:
		return
	add_child_autofree(ctrl)

	var ap: AnimationPlayer = ctrl.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if ap == null:
		pass  # _anim_player == null → connexion conditionnée → CL7 couvre ce cas
		return

	assert_true(ctrl.has_method("_on_vehicle_anim_finished"),
		"PlayerController doit avoir _on_vehicle_anim_finished() (B31)")
	if not ctrl.has_method("_on_vehicle_anim_finished"):
		return

	assert_true(ap.animation_finished.is_connected(ctrl._on_vehicle_anim_finished),
		"AnimationPlayer.animation_finished doit être connecté à _on_vehicle_anim_finished après _ready() (B31)")

# ===========================================================================
# GROUPE 8 — Cas limites (CL1–CL7)
# ===========================================================================

# ---------------------------------------------------------------------------
# CL1 — _play_anim("") : aucun crash, _on_vehicle_anim_finished() appelé immédiatement
# ---------------------------------------------------------------------------
func test_CL1_play_anim_chaine_vide_pas_de_crash() -> void:
	# CL1
	var ctrl: CharacterBody3D = _creer_player_controller()
	assert_not_null(ctrl, "player_controller.gd doit être instanciable")
	if ctrl == null:
		return
	add_child_autofree(ctrl)

	var ap: AnimationPlayer = ctrl.get_node_or_null("AnimationPlayer") as AnimationPlayer
	ctrl.set("_anim_player", ap)
	ctrl.set("_vehicle_state", "car_enter")

	if not ctrl.has_method("_play_anim"):
		fail_test("PlayerController doit avoir _play_anim()")
		return

	watch_signals(ctrl)
	ctrl._play_anim("")

	assert_signal_emitted(ctrl, "vehicle_anim_finished",
		"vehicle_anim_finished doit être émis immédiatement pour _play_anim('') (CL1)")
	pass_test("_play_anim('') ne doit pas provoquer de crash (CL1)")

# ---------------------------------------------------------------------------
# CL2 — start_car_enter(null) : aucun crash, _vehicle_state == "car_enter",
#        _followed_vehicle == null, vehicle_anim_finished émis en fallback
# ---------------------------------------------------------------------------
func test_CL2_start_car_enter_null_pas_de_crash() -> void:
	# CL2
	var ctrl: CharacterBody3D = _creer_player_controller()
	assert_not_null(ctrl, "player_controller.gd doit être instanciable")
	if ctrl == null:
		return
	add_child_autofree(ctrl)

	if not ctrl.has_method("start_car_enter"):
		fail_test("PlayerController doit avoir start_car_enter()")
		return

	watch_signals(ctrl)
	ctrl.start_car_enter(null)

	assert_eq(ctrl.get("_vehicle_state"), "car_enter",
		"_vehicle_state doit valoir 'car_enter' même avec vehicle == null (CL2)")
	assert_null(ctrl.get("_followed_vehicle"),
		"_followed_vehicle doit être null quand start_car_enter(null) est appelé (CL2)")
	assert_signal_emitted(ctrl, "vehicle_anim_finished",
		"vehicle_anim_finished doit être émis immédiatement en fallback pour start_car_enter(null) (CL2)")
	pass_test("start_car_enter(null) ne doit pas provoquer de crash (CL2)")

# ---------------------------------------------------------------------------
# CL3 — finish_car_exit() appelé deux fois de suite : idempotent, pas de crash
# ---------------------------------------------------------------------------
func test_CL3_finish_car_exit_idempotent() -> void:
	# CL3
	var ctrl: CharacterBody3D = _creer_player_controller()
	assert_not_null(ctrl, "player_controller.gd doit être instanciable")
	if ctrl == null:
		return
	add_child_autofree(ctrl)

	if not ctrl.has_method("finish_car_exit"):
		fail_test("PlayerController doit avoir finish_car_exit()")
		return

	# Premier appel
	ctrl.finish_car_exit()
	assert_eq(ctrl.get("_vehicle_state"), "none",
		"_vehicle_state doit valoir 'none' après premier finish_car_exit() (CL3)")

	# Deuxième appel — pas de crash, état nominal conservé
	ctrl.finish_car_exit()
	assert_eq(ctrl.get("_vehicle_state"), "none",
		"_vehicle_state doit rester 'none' après deuxième finish_car_exit() (CL3)")
	assert_null(ctrl.get("_followed_vehicle"),
		"_followed_vehicle doit rester null après deuxième finish_car_exit() (CL3)")
	pass_test("finish_car_exit() appelé deux fois de suite ne provoque pas de crash (CL3)")

# ---------------------------------------------------------------------------
# CL4 — _on_vehicle_anim_finished() avec _vehicle_state == "none" : aucun signal émis, pas de crash
# ---------------------------------------------------------------------------
func test_CL4_on_vehicle_anim_finished_hors_contexte_vehicule_pas_de_signal() -> void:
	# CL4
	var ctrl: CharacterBody3D = _creer_player_controller()
	assert_not_null(ctrl, "player_controller.gd doit être instanciable")
	if ctrl == null:
		return
	add_child_autofree(ctrl)

	# État piéton
	ctrl.set("_vehicle_state", "none")

	if not ctrl.has_method("_on_vehicle_anim_finished"):
		fail_test("PlayerController doit avoir _on_vehicle_anim_finished()")
		return

	watch_signals(ctrl)
	ctrl._on_vehicle_anim_finished("car_enter")

	assert_signal_not_emitted(ctrl, "vehicle_anim_finished",
		"vehicle_anim_finished ne doit pas être émis quand _vehicle_state == 'none' (CL4)")
	pass_test("_on_vehicle_anim_finished() hors contexte véhicule ne provoque pas de crash (CL4)")

# ---------------------------------------------------------------------------
# CL5 — CarController._physics_process() avec _player == null et IN_VEHICLE
#        → engine_force == 0, brake == 0 (guard protège contre null)
# ---------------------------------------------------------------------------
func test_CL5_car_controller_player_null_guard_protege() -> void:
	# CL5
	var CarControllerScript = load("res://src/vehicles/car_controller.gd")
	assert_not_null(CarControllerScript, "car_controller.gd doit être chargeable")
	if CarControllerScript == null:
		return

	var car_body: VehicleBody3D = _creer_vehicle_mock()
	add_child_autofree(car_body)

	var mock_gs: GameState = _creer_game_state()
	add_child_autofree(mock_gs)
	mock_gs.player_mode = GameState.PlayerMode.IN_VEHICLE

	var ctrl: Node = CarControllerScript.new()
	ctrl.set("_game_state", mock_gs)
	ctrl.set("_car_body", car_body)
	ctrl.set("_player", null)  # pas de joueur
	add_child_autofree(ctrl)

	Input.action_press("drive_forward")
	ctrl._physics_process(0.016)
	Input.action_release("drive_forward")
	Input.flush_buffered_events()

	assert_eq(car_body.engine_force, 0.0,
		"engine_force doit être 0 quand _player == null (guard CL5)")
	assert_eq(car_body.brake, 0.0,
		"brake doit être 0 quand _player == null (guard CL5)")
	pass_test("CarController._physics_process() avec _player == null ne provoque pas de crash (CL5)")

# ---------------------------------------------------------------------------
# CL6 — start_car_drive() avec _vehicle_state == "none" (appel hors séquence) : pas de crash
# ---------------------------------------------------------------------------
func test_CL6_start_car_drive_hors_sequence_pas_de_crash() -> void:
	# CL6
	var ctrl: CharacterBody3D = _creer_player_controller()
	assert_not_null(ctrl, "player_controller.gd doit être instanciable")
	if ctrl == null:
		return
	add_child_autofree(ctrl)

	# _followed_vehicle est null (hors séquence normale)
	assert_null(ctrl.get("_followed_vehicle"),
		"_followed_vehicle doit être null en état initial (CL6)")

	if not ctrl.has_method("start_car_drive"):
		fail_test("PlayerController doit avoir start_car_drive()")
		return

	ctrl.start_car_drive()

	assert_eq(ctrl.get("_vehicle_state"), "car_drive",
		"_vehicle_state doit passer à 'car_drive' même en appel hors séquence (CL6)")
	pass_test("start_car_drive() avec _followed_vehicle == null ne provoque pas de crash (CL6)")

# ---------------------------------------------------------------------------
# CL7 — _ready() avec _anim_player == null : connexion signal conditionnée, pas de crash
# ---------------------------------------------------------------------------
func test_CL7_ready_anim_player_null_pas_de_connexion_crash() -> void:
	# CL7
	# Créer un PlayerController sans nœud AnimationPlayer enfant
	var PlayerControllerScript = load("res://src/player/player_controller.gd")
	assert_not_null(PlayerControllerScript, "player_controller.gd doit être chargeable")
	if PlayerControllerScript == null:
		return

	var ctrl: CharacterBody3D = PlayerControllerScript.new() as CharacterBody3D
	# Pas d'AnimationPlayer ajouté → _anim_player restera null après _ready()
	var col: CollisionShape3D = CollisionShape3D.new()
	col.name = "CollisionShape3D"
	col.shape = CapsuleShape3D.new()
	ctrl.add_child(col)
	var body: Node3D = Node3D.new()
	body.name = "PlayerBody"
	ctrl.add_child(body)
	# Intentionnellement pas d'AnimationPlayer

	add_child_autofree(ctrl)

	# _ready() a été appelé (add_child_autofree déclenche _ready via le SceneTree)
	assert_null(ctrl.get("_anim_player"),
		"_anim_player doit être null quand AnimationPlayer est absent du SceneTree (CL7)")
	pass_test("_ready() sans AnimationPlayer ne provoque pas de crash (CL7)")

# ===========================================================================
# GROUPE 9 — Constante DRIVER_SEAT_OFFSET
# ===========================================================================

func test_constante_driver_seat_offset_presente_et_correcte() -> void:
	# Vérifie que PlayerController expose DRIVER_SEAT_OFFSET = Vector3(-0.4, 0.6, 0.3)
	var ctrl: CharacterBody3D = _creer_player_controller()
	assert_not_null(ctrl, "player_controller.gd doit être instanciable")
	if ctrl == null:
		return
	add_child_autofree(ctrl)

	assert_true(ctrl.get("DRIVER_SEAT_OFFSET") != null,
		"PlayerController doit exposer la constante DRIVER_SEAT_OFFSET")

	var offset: Vector3 = ctrl.get("DRIVER_SEAT_OFFSET") as Vector3
	assert_almost_eq(offset.x, -0.4, 0.001,
		"DRIVER_SEAT_OFFSET.x doit valoir -0.4")
	assert_almost_eq(offset.y, 0.6, 0.001,
		"DRIVER_SEAT_OFFSET.y doit valoir 0.6")
	assert_almost_eq(offset.z, 0.3, 0.001,
		"DRIVER_SEAT_OFFSET.z doit valoir 0.3")

# ===========================================================================
# GROUPE 10 — Variables GameState ajoutées (Feature 19)
# ===========================================================================

func test_game_state_a_variable_anim_enter_pending() -> void:
	var gs: GameState = _creer_game_state()
	assert_not_null(gs, "game_state.gd doit être instanciable")
	if gs == null:
		return
	add_child_autofree(gs)

	assert_false(gs.get("_anim_enter_pending"),
		"_anim_enter_pending doit valoir false à l'initialisation")

func test_game_state_a_variable_anim_exit_pending() -> void:
	var gs: GameState = _creer_game_state()
	assert_not_null(gs, "game_state.gd doit être instanciable")
	if gs == null:
		return
	add_child_autofree(gs)

	assert_false(gs.get("_anim_exit_pending"),
		"_anim_exit_pending doit valoir false à l'initialisation")

func test_game_state_a_methode_complete_enter_vehicle() -> void:
	var gs: GameState = _creer_game_state()
	assert_not_null(gs, "game_state.gd doit être instanciable")
	if gs == null:
		return
	add_child_autofree(gs)

	assert_true(gs.has_method("_complete_enter_vehicle"),
		"GameState doit avoir la méthode _complete_enter_vehicle()")

func test_game_state_a_methode_complete_exit_vehicle() -> void:
	var gs: GameState = _creer_game_state()
	assert_not_null(gs, "game_state.gd doit être instanciable")
	if gs == null:
		return
	add_child_autofree(gs)

	assert_true(gs.has_method("_complete_exit_vehicle"),
		"GameState doit avoir la méthode _complete_exit_vehicle()")

func test_game_state_a_methode_on_player_vehicle_anim_finished() -> void:
	var gs: GameState = _creer_game_state()
	assert_not_null(gs, "game_state.gd doit être instanciable")
	if gs == null:
		return
	add_child_autofree(gs)

	assert_true(gs.has_method("_on_player_vehicle_anim_finished"),
		"GameState doit avoir la méthode _on_player_vehicle_anim_finished()")

# ===========================================================================
# GROUPE 11 — CarController : player_path exposé
# ===========================================================================

func test_car_controller_expose_player_path() -> void:
	var CarControllerScript = load("res://src/vehicles/car_controller.gd")
	assert_not_null(CarControllerScript, "car_controller.gd doit être chargeable")
	if CarControllerScript == null:
		return

	var ctrl: Node = CarControllerScript.new()
	add_child_autofree(ctrl)

	# player_path doit exister comme propriété exportée ou variable accessible
	assert_true(ctrl.get("player_path") != null or ctrl.get("player_path") == NodePath(""),
		"CarController doit exposer player_path (NodePath)")
