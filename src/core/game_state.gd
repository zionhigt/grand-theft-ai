class_name GameState
extends Node

# --- Enum ---

enum PlayerMode { ON_FOOT, IN_VEHICLE }

# --- Propriétés publiques ---

var player_mode: PlayerMode = PlayerMode.ON_FOOT
# État courant du joueur. Lecture libre, modification via enter_vehicle / exit_vehicle.

var current_vehicle: VehicleBody3D = null
# Référence à la voiture occupée. null quand player_mode == ON_FOOT.

var player_near_car: bool = false
# true quand le CharacterBody3D du joueur est dans la zone InteractionZone de la voiture.
# Mis à jour par les signaux body_entered / body_exited de l'Area3D.

# --- NodePaths exportés ---

@export var player_path: NodePath = NodePath("../Player")
@export var camera_rig_path: NodePath = NodePath("../CameraRig")
@export var car_path: NodePath = NodePath("../Car")

# --- Références internes (résolues dans _ready) ---

var _player: PlayerController = null
var _player_body: Node3D = null
var _camera_rig: CameraController = null
var _car: VehicleBody3D = null
var original_parent: Node

# Marqueurs de position dans la voiture — créés programmatiquement dans _creer_marqueurs_voiture()
var _driver_seat: Node3D = null
var _exit_point: Node3D = null

# --- Cycle de vie ---

func _ready() -> void:
	# Résolution des NodePaths uniquement si les références ne sont pas déjà injectées
	# (les tests injectent directement _player/_camera_rig/_car avant add_child).
	if _player == null:
		_player = get_node_or_null(player_path) as PlayerController
	if _camera_rig == null:
		_camera_rig = get_node_or_null(camera_rig_path) as CameraController
	if _car == null:
		_car = get_node_or_null(car_path) as VehicleBody3D
	if _player != null and _player_body == null:
		_player_body = _player.get_node_or_null("PlayerBody") as Node3D
	if _car != null:
		_creer_marqueurs_voiture()
		var zone: Area3D = _car.get_node_or_null("InteractionZone") as Area3D
		if zone != null:
			zone.body_entered.connect(_on_interaction_zone_body_entered)
			zone.body_exited.connect(_on_interaction_zone_body_exited)

# --- Marqueurs voiture ---

func _creer_marqueurs_voiture() -> void:
	# Positions déduites de la géométrie gelée de car.tscn + main.tscn.
	# Voir le bloc GÉOMÉTRIE DE RÉFÉRENCE dans car_visuals.gd pour les valeurs sources.
	#
	# Axe -X = côté conducteur (gauche en conduite à droite)
	# Axe -Z = avant du véhicule
	# Y local -1.1 correspond au sol monde quand Car.position.y == 1.1 (main.tscn)

	_driver_seat = Node3D.new()
	_driver_seat.name = "DriverSeat"
	# Côté gauche (-X), mi-hauteur caisse (+Y), avant du véhicule (-Z)
	_driver_seat.position = Vector3(-0.35, 0.5, -0.5)
	_car.add_child(_driver_seat)

	_exit_point = Node3D.new()
	_exit_point.name = "ExitPoint"
	# À la portière conducteur (-X), niveau sol physique (-1.1), avant (-Z)
	_exit_point.position = Vector3(-1.8, -1.1, -0.5)
	_car.add_child(_exit_point)

# --- Méthodes publiques ---

func enter_vehicle(car: VehicleBody3D) -> void:
	# Idempotent : si déjà IN_VEHICLE, retour immédiat.
	if player_mode == PlayerMode.IN_VEHICLE:
		return
	player_mode = PlayerMode.IN_VEHICLE
	current_vehicle = car
	if _player != null:
		_player.set_process_input(false)
		_player.set_physics_process(false)
		_player.velocity = Vector3.ZERO
		if _player_body != null:
			original_parent = _player_body.get_parent()
			_player_body.reparent(current_vehicle)
			# Positionner le mesh au siège conducteur
			if _driver_seat != null:
				_player_body.global_position = _driver_seat.global_position
			# Forcer l'animation idle pendant la conduite
			var ap := _player.get_node_or_null("AnimationPlayer") as AnimationPlayer
			if ap != null and ap.has_animation("idle"):
				ap.play("idle")
	if _camera_rig != null:
		_camera_rig.target = car

func exit_vehicle() -> void:
	# Idempotent : si déjà ON_FOOT, retour immédiat.
	if player_mode == PlayerMode.ON_FOOT:
		return
	if current_vehicle != null and _player != null:
		var spawn_pos: Vector3
		if _exit_point != null:
			# Le CharacterBody3D a son origine 0.9 m au-dessus du sol (capsule height=1.8)
			spawn_pos = _exit_point.global_position + Vector3(0, 0.9, 0)
		else:
			spawn_pos = current_vehicle.global_position \
				+ current_vehicle.global_transform.basis.x * -2.5 \
				+ Vector3(0, 1.0, 0)
		_player.global_position = spawn_pos
		# Réinitialiser la vélocité pour éviter que le personnage s'enfonce dans le sol
		# à cause d'une vélocité résiduelle (gravité ou momentum) accumulée avant l'entrée.
		_player.velocity = Vector3.ZERO
	if _player != null:
		_player.set_process_input(true)
		_player.set_physics_process(true)
		if _player_body != null:
			_player_body.reparent(original_parent)
			# Remettre le mesh en position locale nulle par rapport au PlayerController
			_player_body.position = Vector3.ZERO
			_player_body.rotation = Vector3.ZERO
			_player_body.visible = true
	if _camera_rig != null:
		_camera_rig.target = _player
	player_mode = PlayerMode.ON_FOOT
	current_vehicle = null

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		if player_mode == PlayerMode.ON_FOOT and player_near_car:
			enter_vehicle(_car)
		elif player_mode == PlayerMode.IN_VEHICLE:
			exit_vehicle()

# --- Signaux internes ---

func _on_interaction_zone_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		player_near_car = true

func _on_interaction_zone_body_exited(body: Node3D) -> void:
	if body is CharacterBody3D:
		player_near_car = false
