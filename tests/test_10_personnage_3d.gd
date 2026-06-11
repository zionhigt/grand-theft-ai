extends GutTest

# Tests unitaires — Feature 10 : Personnage 3D Mixamo (remplacement mock capsule)
#
# Chaque test cible un comportement numéroté de la spec docs/specs/10-personnage-3d.md.
#
# Stratégie :
#   B1–B3 chargent scenes/player/player.tscn et vérifient la structure de nœuds.
#   B4–B8 et CL1–CL2 instancient PlayerController manuellement avec un AnimationPlayer
#   mock injecté comme enfant, et appellent _update_animation() directement.
#   B9–B10 testent game_state.gd (enter/exit_vehicle) avec un player mock ayant PlayerBody.
#   B11–B12 testent _ready() de GameState avec et sans PlayerBody.
#   CL3 vérifie que _update_animation() ne rappelle pas play() si l'animation est déjà active.
#   CL4 vérifie que exit_vehicle() remet visible=true quand visible était déjà false.
#   CL5 vérifie que enter_vehicle() ne crashe pas si _player_body == null.
#
# En phase rouge : player.tscn n'a pas encore PlayerBody ni AnimationPlayer,
#   player_controller.gd n'a pas encore _update_animation(),
#   game_state.gd n'a pas encore _player_body.
#   Les tests B1–B3 et B4–B12 échoueront — attendu.

# ---------------------------------------------------------------------------
# Préchargements
# ---------------------------------------------------------------------------
const PlayerControllerScript = preload("res://src/player/player_controller.gd")

var GameStateScript  # chargement dynamique dans before_each

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Crée un AnimationPlayer avec deux animations vides "idle" et "walk".
# Utilisé pour tester _update_animation() sans vrai rig.
# Godot 4.x : les animations sont déclarées dans une AnimationLibrary,
# ajoutée ensuite à l'AnimationPlayer via add_animation_library("", lib).
func _creer_anim_player_mock() -> AnimationPlayer:
	var ap: AnimationPlayer = AnimationPlayer.new()
	var lib: AnimationLibrary = AnimationLibrary.new()
	var anim_idle: Animation = Animation.new()
	var anim_walk: Animation = Animation.new()
	lib.add_animation("idle", anim_idle)
	lib.add_animation("walk", anim_walk)
	ap.add_animation_library("", lib)
	return ap

# Crée un PlayerController avec un AnimationPlayer mock injecté comme enfant
# nommé "AnimationPlayer" — ce qui permettra à @onready _anim_player de le résoudre.
func _creer_player_ctrl_avec_anim() -> PlayerController:
	var ctrl: PlayerController = PlayerControllerScript.new()
	var ap: AnimationPlayer = _creer_anim_player_mock()
	ap.name = "AnimationPlayer"
	ctrl.add_child(ap)
	return ctrl

# Crée un PlayerController avec un enfant PlayerBody : Node3D
func _creer_player_mock_avec_body() -> CharacterBody3D:
	var player: CharacterBody3D = PlayerControllerScript.new()
	var body: Node3D = Node3D.new()
	body.name = "PlayerBody"
	player.add_child(body)
	return player

# Crée un CameraController mock
func _creer_camera_rig_mock() -> Node3D:
	return load("res://src/camera/camera_controller.gd").new()

# Crée un VehicleBody3D mock minimal
func _creer_car_mock() -> VehicleBody3D:
	var car: VehicleBody3D = VehicleBody3D.new()
	var cs: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(4.0, 1.5, 2.0)
	cs.shape = shape
	car.add_child(cs)
	return car

# Crée un GameState avec player_body injecté, sans passer par _ready()
# Utilise set() défensif pour _player_body : avant feature 10, la propriété n'existe
# pas encore dans game_state.gd — set() est silencieux dans ce cas.
# Après feature 10, _player_body est une propriété déclarée → set() l'assigne correctement.
func _creer_game_state_avec_mocks(player: CharacterBody3D, camera_rig: Node3D, car: VehicleBody3D) -> Node:
	var gs: Node = GameStateScript.new()
	gs._player = player
	if player != null:
		var body: Node3D = player.get_node_or_null("PlayerBody") as Node3D
		gs.set("_player_body", body)
	gs._camera_rig = camera_rig
	gs._car = car
	return gs

# ---------------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------------

func before_each() -> void:
	GameStateScript = load("res://src/core/game_state.gd")

func after_each() -> void:
	pass

# ---------------------------------------------------------------------------
# B1 — player.tscn contient AnimationPlayer enfant direct de Player
# Spec §Comportements attendus point B1
# ---------------------------------------------------------------------------
func test_player_tscn_contient_un_noeud_animation_player() -> void:
	var packed: PackedScene = load("res://scenes/player/player.tscn")
	assert_not_null(packed, "scenes/player/player.tscn doit se charger sans erreur")
	if packed == null:
		return
	var player: Node = packed.instantiate()
	add_child_autofree(player)

	var ap: Node = player.get_node_or_null("AnimationPlayer")
	assert_not_null(ap, "player.tscn doit contenir un nœud 'AnimationPlayer' enfant direct de Player")
	if ap == null:
		return
	assert_true(ap is AnimationPlayer,
		"Le nœud 'AnimationPlayer' doit être de type AnimationPlayer")

# ---------------------------------------------------------------------------
# B2 — player.tscn contient PlayerBody enfant direct de Player, de type Node3D
# Spec §Comportements attendus point B2
# ---------------------------------------------------------------------------
func test_player_tscn_contient_un_noeud_player_body_node3d() -> void:
	var packed: PackedScene = load("res://scenes/player/player.tscn")
	assert_not_null(packed, "scenes/player/player.tscn doit se charger sans erreur")
	if packed == null:
		return
	var player: Node = packed.instantiate()
	add_child_autofree(player)

	var body: Node = player.get_node_or_null("PlayerBody")
	assert_not_null(body, "player.tscn doit contenir un nœud 'PlayerBody' enfant direct de Player")
	if body == null:
		return
	assert_true(body is Node3D,
		"Le nœud 'PlayerBody' doit être de type Node3D")

# ---------------------------------------------------------------------------
# B3 — player.tscn ne contient plus de MeshInstance3D (mock capsule supprimé)
# Spec §Comportements attendus point B3
# ---------------------------------------------------------------------------
func test_player_tscn_ne_contient_plus_de_mesh_instance_3d_capsule_mock() -> void:
	var packed: PackedScene = load("res://scenes/player/player.tscn")
	assert_not_null(packed, "scenes/player/player.tscn doit se charger sans erreur")
	if packed == null:
		return
	var player: Node = packed.instantiate()
	add_child_autofree(player)

	var mesh: Node = player.get_node_or_null("MeshInstance3D")
	assert_null(mesh,
		"Le nœud 'MeshInstance3D' (mock CapsuleMesh) ne doit plus exister dans player.tscn")

# ---------------------------------------------------------------------------
# B4 — PlayerController possède la méthode _update_animation
# Spec §Comportements attendus point B4
# ---------------------------------------------------------------------------
func test_player_controller_a_la_methode_update_animation() -> void:
	var ctrl: PlayerController = PlayerControllerScript.new()
	add_child_autofree(ctrl)
	assert_true(ctrl.has_method("_update_animation"),
		"PlayerController doit posséder la méthode _update_animation()")

# ---------------------------------------------------------------------------
# B5 — _update_animation() avec velocity horizontal → animation "walk"
# Spec §Comportements attendus point B5
# Guard : si _update_animation() absent, assert_true(false) fait échouer proprement.
# ---------------------------------------------------------------------------
func test_update_animation_avec_velocity_horizontal_joue_walk() -> void:
	var ctrl: PlayerController = _creer_player_ctrl_avec_anim()
	add_child_autofree(ctrl)
	assert_true(ctrl.has_method("_update_animation"),
		"PlayerController doit avoir la méthode _update_animation() pour ce test")
	if not ctrl.has_method("_update_animation"):
		return
	ctrl.velocity = Vector3(1.0, 0.0, 0.0)
	ctrl._update_animation()
	var ap: AnimationPlayer = ctrl.get_node_or_null("AnimationPlayer") as AnimationPlayer
	assert_not_null(ap, "AnimationPlayer doit être présent dans le player ctrl mock")
	if ap == null:
		return
	var current: String = ap.current_animation
	assert_eq(current, "walk",
		"_update_animation() avec velocity.x != 0 doit jouer l'animation 'walk'")

# ---------------------------------------------------------------------------
# B6 — _update_animation() avec velocity == 0 → animation "idle"
# Spec §Comportements attendus point B6
# ---------------------------------------------------------------------------
func test_update_animation_avec_velocity_zero_joue_idle() -> void:
	var ctrl: PlayerController = _creer_player_ctrl_avec_anim()
	add_child_autofree(ctrl)
	assert_true(ctrl.has_method("_update_animation"),
		"PlayerController doit avoir la méthode _update_animation() pour ce test")
	if not ctrl.has_method("_update_animation"):
		return
	ctrl.velocity = Vector3.ZERO
	ctrl._update_animation()
	var ap: AnimationPlayer = ctrl.get_node_or_null("AnimationPlayer") as AnimationPlayer
	assert_not_null(ap, "AnimationPlayer doit être présent dans le player ctrl mock")
	if ap == null:
		return
	var current: String = ap.current_animation
	assert_eq(current, "idle",
		"_update_animation() avec velocity == 0 doit jouer l'animation 'idle'")

# ---------------------------------------------------------------------------
# B7 — _update_animation() avec _anim_player == null → pas de crash
# Spec §Comportements attendus point B7
# Stratégie : instancier PlayerController SANS enfant AnimationPlayer.
# @onready ne trouvera pas $AnimationPlayer → _anim_player == null.
# ---------------------------------------------------------------------------
func test_update_animation_sans_anim_player_ne_crashe_pas() -> void:
	var ctrl: PlayerController = PlayerControllerScript.new()
	add_child_autofree(ctrl)
	assert_true(ctrl.has_method("_update_animation"),
		"PlayerController doit avoir la méthode _update_animation() pour ce test")
	if not ctrl.has_method("_update_animation"):
		return
	# Aucun enfant AnimationPlayer — _anim_player sera null après @onready
	ctrl.velocity = Vector3(1.0, 0.0, 0.0)
	# Ce call ne doit pas produire d'erreur ni de crash
	ctrl._update_animation()
	assert_true(true, "Appel de _update_animation() sans AnimationPlayer ne doit pas crasher")

# ---------------------------------------------------------------------------
# B8 — _update_animation() avec AnimationPlayer vide (aucune animation) → pas de crash
# Spec §Comportements attendus point B8
# ---------------------------------------------------------------------------
func test_update_animation_avec_anim_player_vide_ne_crashe_pas() -> void:
	var ctrl: PlayerController = PlayerControllerScript.new()
	var ap: AnimationPlayer = AnimationPlayer.new()
	# AnimationPlayer vide — aucune animation "idle" ni "walk"
	ap.name = "AnimationPlayer"
	ctrl.add_child(ap)
	add_child_autofree(ctrl)
	assert_true(ctrl.has_method("_update_animation"),
		"PlayerController doit avoir la méthode _update_animation() pour ce test")
	if not ctrl.has_method("_update_animation"):
		return
	ctrl.velocity = Vector3(1.0, 0.0, 0.0)
	# has_animation() guard doit éviter le crash
	ctrl._update_animation()
	assert_true(true, "Appel de _update_animation() avec AnimationPlayer vide ne doit pas crasher")

# ---------------------------------------------------------------------------
# B9 — enter_vehicle → PlayerBody.visible == false
# Spec §Comportements attendus point B9
# ---------------------------------------------------------------------------
func test_enter_vehicle_rend_player_body_invisible() -> void:
	assert_not_null(GameStateScript,
		"src/core/game_state.gd doit exister et être chargeable")
	if GameStateScript == null:
		return
	var player: CharacterBody3D = _creer_player_mock_avec_body()
	add_child_autofree(player)
	var camera_rig: Node3D = _creer_camera_rig_mock()
	add_child_autofree(camera_rig)
	var car: VehicleBody3D = _creer_car_mock()
	add_child_autofree(car)

	var gs: Node = _creer_game_state_avec_mocks(player, camera_rig, car)
	add_child_autofree(gs)

	gs.enter_vehicle(car)

	var body: Node3D = player.get_node_or_null("PlayerBody") as Node3D
	assert_not_null(body, "Le nœud PlayerBody doit exister dans le player mock")
	if body == null:
		return
	assert_false(body.visible,
		"PlayerBody.visible doit être false après enter_vehicle")

# ---------------------------------------------------------------------------
# B10 — exit_vehicle après enter_vehicle → PlayerBody.visible == true
# Spec §Comportements attendus point B10
# ---------------------------------------------------------------------------
func test_exit_vehicle_rend_player_body_visible() -> void:
	assert_not_null(GameStateScript,
		"src/core/game_state.gd doit exister et être chargeable")
	if GameStateScript == null:
		return
	var player: CharacterBody3D = _creer_player_mock_avec_body()
	add_child_autofree(player)
	var camera_rig: Node3D = _creer_camera_rig_mock()
	add_child_autofree(camera_rig)
	var car: VehicleBody3D = _creer_car_mock()
	add_child_autofree(car)

	var gs: Node = _creer_game_state_avec_mocks(player, camera_rig, car)
	add_child_autofree(gs)

	gs.enter_vehicle(car)
	gs.exit_vehicle()

	var body: Node3D = player.get_node_or_null("PlayerBody") as Node3D
	assert_not_null(body, "Le nœud PlayerBody doit exister dans le player mock")
	if body == null:
		return
	assert_true(body.visible,
		"PlayerBody.visible doit être true après exit_vehicle")

# ---------------------------------------------------------------------------
# B11 — GameState._ready() avec PlayerBody présent → _player_body non null, is Node3D
# Spec §Comportements attendus point B11
# Stratégie : on injecte _player avant add_child, _ready() résout _player_body.
# Accès défensif via get() pour ne pas crasher avant que _player_body soit déclaré.
# ---------------------------------------------------------------------------
func test_game_state_ready_resout_player_body_non_null() -> void:
	assert_not_null(GameStateScript,
		"src/core/game_state.gd doit exister et être chargeable")
	if GameStateScript == null:
		return
	var player: CharacterBody3D = _creer_player_mock_avec_body()
	add_child_autofree(player)

	var gs: Node = GameStateScript.new()
	# Injection du player avant add_child — _ready() le verra et résoudra _player_body
	gs._player = player
	add_child_autofree(gs)
	# _ready() s'est exécuté lors de add_child

	# Accès défensif via get() : avant feature 10, _player_body n'existe pas → null.
	# Après feature 10, _player_body est résolu → Node3D non null.
	var player_body = gs.get("_player_body")
	assert_not_null(player_body,
		"GameState._player_body doit être non null après _ready() quand PlayerBody est présent")
	if player_body == null:
		return
	assert_true(player_body is Node3D,
		"GameState._player_body doit être de type Node3D")

# ---------------------------------------------------------------------------
# B12 — GameState._ready() sans PlayerBody → _player_body == null, pas de crash
# Spec §Comportements attendus point B12
# ---------------------------------------------------------------------------
func test_game_state_ready_sans_player_body_donne_player_body_null() -> void:
	assert_not_null(GameStateScript,
		"src/core/game_state.gd doit exister et être chargeable")
	if GameStateScript == null:
		return
	# PlayerController sans enfant PlayerBody
	var player: CharacterBody3D = PlayerControllerScript.new()
	add_child_autofree(player)

	var gs: Node = GameStateScript.new()
	gs._player = player
	add_child_autofree(gs)
	# _ready() ne doit pas crasher même si PlayerBody est absent

	# Accès défensif via get() : avant feature 10, _player_body n'existe pas → null.
	# Après feature 10, _player_body est déclaré mais non résolu (absent) → null aussi.
	var player_body = gs.get("_player_body")
	assert_null(player_body,
		"GameState._player_body doit être null si PlayerBody est absent du player")

# ---------------------------------------------------------------------------
# CL1 — velocity.y seul non nul → état "idle" (Y ignoré pour walk/idle)
# Spec §Cas limites / erreurs point CL1
# ---------------------------------------------------------------------------
func test_update_animation_avec_velocity_y_seulement_joue_idle() -> void:
	var ctrl: PlayerController = _creer_player_ctrl_avec_anim()
	add_child_autofree(ctrl)
	assert_true(ctrl.has_method("_update_animation"),
		"PlayerController doit avoir la méthode _update_animation() pour ce test")
	if not ctrl.has_method("_update_animation"):
		return
	# Uniquement composante Y — personnage en chute
	ctrl.velocity = Vector3(0.0, 5.0, 0.0)
	ctrl._update_animation()
	var ap: AnimationPlayer = ctrl.get_node_or_null("AnimationPlayer") as AnimationPlayer
	assert_not_null(ap, "AnimationPlayer doit être présent")
	if ap == null:
		return
	var current: String = ap.current_animation
	assert_eq(current, "idle",
		"_update_animation() avec uniquement velocity.y != 0 doit jouer 'idle' (axe Y ignoré)")

# ---------------------------------------------------------------------------
# CL2 — Alternance idle → walk → idle en 3 appels successifs → pas de crash, final = "idle"
# Spec §Cas limites / erreurs point CL2
# ---------------------------------------------------------------------------
func test_update_animation_alternance_idle_walk_idle_pas_de_crash() -> void:
	var ctrl: PlayerController = _creer_player_ctrl_avec_anim()
	add_child_autofree(ctrl)
	assert_true(ctrl.has_method("_update_animation"),
		"PlayerController doit avoir la méthode _update_animation() pour ce test")
	if not ctrl.has_method("_update_animation"):
		return

	# Frame 1 : idle
	ctrl.velocity = Vector3.ZERO
	ctrl._update_animation()
	# Frame 2 : walk
	ctrl.velocity = Vector3(1.0, 0.0, 0.0)
	ctrl._update_animation()
	# Frame 3 : idle
	ctrl.velocity = Vector3.ZERO
	ctrl._update_animation()

	var ap: AnimationPlayer = ctrl.get_node_or_null("AnimationPlayer") as AnimationPlayer
	assert_not_null(ap, "AnimationPlayer doit être présent")
	if ap == null:
		return
	var current: String = ap.current_animation
	assert_eq(current, "idle",
		"Après alternance idle/walk/idle, l'animation finale doit être 'idle'")
	assert_true(true, "Aucun crash lors de l'alternance rapide idle/walk/idle")

# ---------------------------------------------------------------------------
# CL3 — _update_animation() ne rappelle pas play() si animation déjà active
# Spec §Cas limites / erreurs point CL3
# Stratégie : jouer "walk", rappeler _update_animation() avec même état
# → current_animation reste "walk" sans redémarrage.
# ---------------------------------------------------------------------------
func test_update_animation_ne_redemarre_pas_animation_deja_active() -> void:
	var ctrl: PlayerController = _creer_player_ctrl_avec_anim()
	add_child_autofree(ctrl)
	assert_true(ctrl.has_method("_update_animation"),
		"PlayerController doit avoir la méthode _update_animation() pour ce test")
	if not ctrl.has_method("_update_animation"):
		return

	# Mettre en état walk
	ctrl.velocity = Vector3(1.0, 0.0, 0.0)
	ctrl._update_animation()

	var ap: AnimationPlayer = ctrl.get_node_or_null("AnimationPlayer") as AnimationPlayer
	assert_not_null(ap, "AnimationPlayer doit être présent")
	if ap == null:
		return

	# Vérifier que l'animation est bien "walk"
	assert_eq(ap.current_animation, "walk",
		"L'animation doit être 'walk' avant le deuxième appel")

	# Deuxième appel avec même état — guard if current_animation != anim_name doit s'activer
	ctrl._update_animation()

	# L'animation reste "walk"
	var current: String = ap.current_animation
	assert_eq(current, "walk",
		"_update_animation() avec même état ne doit pas redémarrer l'animation")

# ---------------------------------------------------------------------------
# CL4 — exit_vehicle() quand PlayerBody.visible déjà false → remet visible = true
# Spec §Cas limites / erreurs point CL4
# ---------------------------------------------------------------------------
func test_exit_vehicle_remet_visible_true_meme_si_deja_false() -> void:
	assert_not_null(GameStateScript,
		"src/core/game_state.gd doit exister et être chargeable")
	if GameStateScript == null:
		return
	var player: CharacterBody3D = _creer_player_mock_avec_body()
	add_child_autofree(player)
	var camera_rig: Node3D = _creer_camera_rig_mock()
	add_child_autofree(camera_rig)
	var car: VehicleBody3D = _creer_car_mock()
	add_child_autofree(car)

	var gs: Node = _creer_game_state_avec_mocks(player, camera_rig, car)
	add_child_autofree(gs)

	# Forcer PlayerBody.visible à false avant enter_vehicle
	var body: Node3D = player.get_node_or_null("PlayerBody") as Node3D
	if body != null:
		body.visible = false

	gs.enter_vehicle(car)
	gs.exit_vehicle()

	assert_not_null(body, "Le nœud PlayerBody doit exister dans le player mock")
	if body == null:
		return
	assert_true(body.visible,
		"PlayerBody.visible doit être true après exit_vehicle même si visible était déjà false avant enter_vehicle")

# ---------------------------------------------------------------------------
# CL5 — enter_vehicle avec _player_body == null → pas de crash, transition effectuée
# Spec §Cas limites / erreurs point CL5
# ---------------------------------------------------------------------------
func test_enter_vehicle_avec_player_body_null_ne_crashe_pas() -> void:
	assert_not_null(GameStateScript,
		"src/core/game_state.gd doit exister et être chargeable")
	if GameStateScript == null:
		return
	# PlayerController sans PlayerBody — _player_body sera null
	var player: CharacterBody3D = PlayerControllerScript.new()
	add_child_autofree(player)
	var camera_rig: Node3D = _creer_camera_rig_mock()
	add_child_autofree(camera_rig)
	var car: VehicleBody3D = _creer_car_mock()
	add_child_autofree(car)

	var gs: Node = _creer_game_state_avec_mocks(player, camera_rig, car)
	add_child_autofree(gs)

	# Ne doit pas crasher
	gs.enter_vehicle(car)

	assert_eq(gs.player_mode, GameStateScript.PlayerMode.IN_VEHICLE,
		"player_mode doit passer IN_VEHICLE même si _player_body == null")

# ---------------------------------------------------------------------------
# Règle 6 — Intégration GLB par code (CLAUDE.md §Règles non négociables point 6)
#
# Ces tests garantissent que les assets GLB livrés (player_body.glb, player_idle.glb,
# player_walk.glb) sont intégrés intégralement par du code GDScript dans _ready(),
# sans aucune intervention manuelle dans l'éditeur Godot.
#
# Architecture attendue après intégration par code :
#   Player (CharacterBody3D, script = player_controller.gd)
#   ├── CollisionShape3D
#   ├── PlayerBody (Node3D)
#   │   └── <instance du player_body.glb, chargée via load() dans _ready()>
#   │       └── ... (Skeleton3D, MeshInstance3D(s) du GLB)
#   └── AnimationPlayer (AnimationPlayer)
#       └── animations "idle" et "walk" injectées par code depuis player_idle.glb
#           et player_walk.glb dans _ready() de player_controller.gd
#
# En phase rouge : player_controller.gd ne charge pas encore les GLB dans _ready().
#   PlayerBody reste vide, AnimationPlayer reste vide.
#   Ces tests échoueront — attendu.
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# B_GLB1 — PlayerBody contient au moins un enfant après _ready()
# (le GLB player_body.glb a été instancié par code)
# Règle 6 — intégration asset par code dans _ready()
# ---------------------------------------------------------------------------
func test_player_body_contient_un_enfant_glb_apres_ready() -> void:
	var packed: PackedScene = load("res://scenes/player/player.tscn")
	assert_not_null(packed, "scenes/player/player.tscn doit se charger sans erreur")
	if packed == null:
		return
	var player: Node = packed.instantiate()
	add_child_autofree(player)
	# _ready() s'exécute lors de add_child_autofree

	var body: Node = player.get_node_or_null("PlayerBody")
	assert_not_null(body,
		"PlayerBody doit exister dans player.tscn")
	if body == null:
		return
	assert_gt(body.get_child_count(), 0,
		"PlayerBody doit contenir au moins un enfant après _ready() — le GLB player_body.glb doit être instancié par code")

# ---------------------------------------------------------------------------
# B_GLB2 — L'AnimationPlayer de player.tscn contient l'animation "idle" après _ready()
# (player_idle.glb a été injecté dans l'AnimationPlayer par code dans _ready())
# Règle 6 — intégration asset par code dans _ready()
# ---------------------------------------------------------------------------
func test_animation_player_contient_animation_idle_apres_ready() -> void:
	var packed: PackedScene = load("res://scenes/player/player.tscn")
	assert_not_null(packed, "scenes/player/player.tscn doit se charger sans erreur")
	if packed == null:
		return
	var player: Node = packed.instantiate()
	add_child_autofree(player)

	var ap: Node = player.get_node_or_null("AnimationPlayer")
	assert_not_null(ap,
		"AnimationPlayer doit exister dans player.tscn")
	if ap == null:
		return
	assert_true((ap as AnimationPlayer).has_animation("idle"),
		"AnimationPlayer doit contenir l'animation 'idle' après _ready() — injectée par code depuis player_idle.glb")

# ---------------------------------------------------------------------------
# B_GLB3 — L'AnimationPlayer de player.tscn contient l'animation "walk" après _ready()
# (player_walk.glb a été injecté dans l'AnimationPlayer par code dans _ready())
# Règle 6 — intégration asset par code dans _ready()
# ---------------------------------------------------------------------------
func test_animation_player_contient_animation_walk_apres_ready() -> void:
	var packed: PackedScene = load("res://scenes/player/player.tscn")
	assert_not_null(packed, "scenes/player/player.tscn doit se charger sans erreur")
	if packed == null:
		return
	var player: Node = packed.instantiate()
	add_child_autofree(player)

	var ap: Node = player.get_node_or_null("AnimationPlayer")
	assert_not_null(ap,
		"AnimationPlayer doit exister dans player.tscn")
	if ap == null:
		return
	assert_true((ap as AnimationPlayer).has_animation("walk"),
		"AnimationPlayer doit contenir l'animation 'walk' après _ready() — injectée par code depuis player_walk.glb")

# ---------------------------------------------------------------------------
# B_GLB4 — Un Skeleton3D est présent dans les descendants de PlayerBody après _ready()
# (player_body.glb fournit le Skeleton3D — sa présence confirme l'intégration par code)
# Règle 6 — intégration asset par code dans _ready()
# ---------------------------------------------------------------------------
func test_player_body_contient_un_skeleton3d_dans_ses_descendants() -> void:
	var packed: PackedScene = load("res://scenes/player/player.tscn")
	assert_not_null(packed, "scenes/player/player.tscn doit se charger sans erreur")
	if packed == null:
		return
	var player: Node = packed.instantiate()
	add_child_autofree(player)

	var body: Node = player.get_node_or_null("PlayerBody")
	assert_not_null(body,
		"PlayerBody doit exister dans player.tscn")
	if body == null:
		return

	var skeleton: Node = body.find_child("*", true, false)
	# find_child avec pattern "*" retourne le premier descendant — on cherche un Skeleton3D
	var skeleton3d: Node = null
	for desc in _trouver_tous_les_descendants(body):
		if desc is Skeleton3D:
			skeleton3d = desc
			break

	assert_not_null(skeleton3d,
		"PlayerBody doit contenir un Skeleton3D dans ses descendants après _ready() — fourni par player_body.glb instancié par code")

# Aide récursive : retourne tous les descendants d'un nœud
func _trouver_tous_les_descendants(noeud: Node) -> Array:
	var resultat: Array = []
	for enfant in noeud.get_children():
		resultat.append(enfant)
		resultat.append_array(_trouver_tous_les_descendants(enfant))
	return resultat

# ---------------------------------------------------------------------------
# BUG1 — AnimationPlayer.root_node pointe vers l'instance GLB (pas "..")
#
# Contexte : Le root_node par défaut d'un AnimationPlayer est NodePath("..")
# (le parent direct, ici le nœud Player). Les pistes d'animation Mixamo
# cherchent les os via un chemin relatif depuis ce root, ex. :
#   "Armature/Skeleton3D:BoneName"
# Or le Skeleton3D est dans PlayerBody/<instance_glb>/Armature/Skeleton3D,
# pas dans Player. Si root_node reste "..", les os ne sont jamais trouvés
# et le personnage reste en T-pose.
#
# Fix attendu : après add_child(instance) dans _charger_mesh_joueur(),
#   _anim_player.root_node = _anim_player.get_path_to(instance_glb)
# pour que les pistes trouvent le squelette correct.
# ---------------------------------------------------------------------------
func test_animation_player_root_node_pointe_vers_instance_glb() -> void:
	var packed: PackedScene = load("res://scenes/player/player.tscn")
	assert_not_null(packed, "scenes/player/player.tscn doit se charger sans erreur")
	if packed == null:
		return
	var player: Node = packed.instantiate()
	add_child_autofree(player)
	# _ready() s'est exécuté lors de add_child_autofree

	var ap: Node = player.get_node_or_null("AnimationPlayer")
	assert_not_null(ap, "AnimationPlayer doit exister dans player.tscn")
	if ap == null:
		return

	var anim_player: AnimationPlayer = ap as AnimationPlayer
	var root_node: NodePath = anim_player.root_node
	assert_ne(root_node, NodePath(".."),
		"AnimationPlayer.root_node ne doit pas rester au défaut '..' — " +
		"les pistes Mixamo ne trouveraient pas le Skeleton3D dans PlayerBody/<glb>")

# ---------------------------------------------------------------------------
# BUG2 — L'instance GLB dans PlayerBody a un offset vertical négatif
#
# Contexte : Player (CharacterBody3D) est centré à y=0.9 dans main.tscn.
# PlayerBody est à position (0,0,0) relatif à Player, donc à y=0.9 monde.
# Le GLB Mixamo a son origine aux pieds (y=0 local). Sans offset, les pieds
# se retrouvent à y=0.9 monde → le personnage flotte à 0.9 m au-dessus du sol.
#
# Fix attendu : après player_body.add_child(instance) dans _charger_mesh_joueur(),
#   instance.position.y = -0.9
# pour que les pieds (y=0 local GLB) arrivent à y=0 monde.
# ---------------------------------------------------------------------------
func test_instance_glb_a_un_offset_vertical_negatif() -> void:
	var packed: PackedScene = load("res://scenes/player/player.tscn")
	assert_not_null(packed, "scenes/player/player.tscn doit se charger sans erreur")
	if packed == null:
		return
	var player: Node = packed.instantiate()
	add_child_autofree(player)
	# _ready() s'est exécuté lors de add_child_autofree

	var body: Node = player.get_node_or_null("PlayerBody")
	assert_not_null(body, "PlayerBody doit exister dans player.tscn")
	if body == null:
		return

	assert_gt(body.get_child_count(), 0,
		"PlayerBody doit contenir au moins un enfant (instance GLB) après _ready()")
	if body.get_child_count() == 0:
		return

	var glb_instance: Node3D = body.get_child(0) as Node3D
	assert_not_null(glb_instance, "Le premier enfant de PlayerBody doit être un Node3D (instance GLB)")
	if glb_instance == null:
		return

	var pos_y: float = glb_instance.position.y
	assert_lt(pos_y, 0.0,
		"L'instance GLB dans PlayerBody doit avoir position.y < 0 pour que les pieds " +
		"touchent le sol (Player centré à y=0.9, GLB origine aux pieds)")

# ---------------------------------------------------------------------------
# BUG3 — L'instance GLB dans PlayerBody a rotation.y ≈ PI (mesh Mixamo inversé)
#
# Contexte : Le mesh Mixamo fait face à +Z par défaut. Quand le joueur avance
# (direction -Z), le CharacterBody3D tourne vers -Z mais le mesh regarde vers +Z
# → personnage toujours dans le mauvais sens.
#
# Fix attendu : après player_body.add_child(instance) dans _charger_mesh_joueur(),
#   instance.rotation.y = PI
# pour que le mesh soit orienté dans la bonne direction par rapport au CharacterBody3D.
# ---------------------------------------------------------------------------
func test_instance_glb_a_rotation_y_egal_a_pi() -> void:
	var packed: PackedScene = load("res://scenes/player/player.tscn")
	assert_not_null(packed, "scenes/player/player.tscn doit se charger sans erreur")
	if packed == null:
		return
	var player: Node = packed.instantiate()
	add_child_autofree(player)
	# _ready() s'est exécuté lors de add_child_autofree

	var body: Node = player.get_node_or_null("PlayerBody")
	assert_not_null(body, "PlayerBody doit exister dans player.tscn")
	if body == null:
		return

	assert_gt(body.get_child_count(), 0,
		"PlayerBody doit contenir au moins un enfant (instance GLB) après _ready()")
	if body.get_child_count() == 0:
		return

	var glb_instance: Node3D = body.get_child(0) as Node3D
	assert_not_null(glb_instance, "Le premier enfant de PlayerBody doit être un Node3D (instance GLB)")
	if glb_instance == null:
		return

	var rot_y: float = glb_instance.rotation.y
	assert_almost_eq(rot_y, PI, 0.01,
		"L'instance GLB dans PlayerBody doit avoir rotation.y ≈ PI pour que le mesh Mixamo (face +Z) soit orienté vers -Z, cohérent avec la direction du CharacterBody3D")

# ---------------------------------------------------------------------------
# BUG4 — Toutes les keyframes TYPE_POSITION_3D des animations "idle" et "walk"
#         ont leurs composantes X et Z zéroïsées (root motion hip bone supprimé)
#
# Contexte : Le root motion Mixamo est porté par l'os racine dont le chemin
# contient ":" (ex. "Skeleton3D:mixamorig:Hips"). L'ancienne version ne
# strippait que les tracks sans ":" ; les tracks bone (avec ":") restaient
# intacts, causant un glissement/téléportation du hip bone en X/Z.
#
# Fix attendu dans _injecter_animation() : après récupération de clip,
# pour TOUS les tracks TYPE_POSITION_3D (bone ou non), zérouter X et Z de
# chaque keyframe :
#   val.x = 0.0
#   val.z = 0.0
#
# Ce test remplace l'ancien BUG4 qui ne couvrait que les tracks non-bone.
# ---------------------------------------------------------------------------
func test_animations_idle_et_walk_n_ont_pas_de_root_motion_x_z() -> void:
	var packed: PackedScene = load("res://scenes/player/player.tscn")
	assert_not_null(packed, "scenes/player/player.tscn doit se charger sans erreur")
	if packed == null:
		return
	var player: Node = packed.instantiate()
	add_child_autofree(player)
	# _ready() s'est exécuté lors de add_child_autofree

	var ap_node: Node = player.get_node_or_null("AnimationPlayer")
	assert_not_null(ap_node, "AnimationPlayer doit exister dans player.tscn")
	if ap_node == null:
		return

	var ap: AnimationPlayer = ap_node as AnimationPlayer

	for anim_name in ["idle", "walk"]:
		if not ap.has_animation(anim_name):
			# Si l'animation est absente, le test GLB2/GLB3 la couvre déjà.
			# Ici on signale que le test ne peut pas s'exécuter sans bloquer.
			continue
		var clip: Animation = ap.get_animation(anim_name)
		for i in range(clip.get_track_count()):
			if clip.track_get_type(i) == Animation.TYPE_POSITION_3D:
				var path_str: String = str(clip.track_get_path(i))
				for k in range(clip.track_get_key_count(i)):
					var val: Vector3 = clip.track_get_key_value(i, k)
					var msg_x: String = "Keyframe %d du track '%s' dans '%s' : val.x doit être 0.0 (root motion X zéroïsé)" % [k, path_str, anim_name]
					var msg_z: String = "Keyframe %d du track '%s' dans '%s' : val.z doit être 0.0 (root motion Z zéroïsé)" % [k, path_str, anim_name]
					assert_almost_eq(val.x, 0.0, 0.0001, msg_x)
					assert_almost_eq(val.z, 0.0, 0.0001, msg_z)
