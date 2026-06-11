class_name CarController
extends Node

const ENGINE_FORCE: float = 8000.0
const BRAKE_FORCE: float = 80.0
const MAX_STEERING: float = 0.4
const STEERING_SPEED: float = 5.0
const FORWARD_SPEED_THRESHOLD: float = 0.5

@export var game_state_path: NodePath
@export var car_body_path: NodePath

var _game_state
var _car_body: VehicleBody3D
var _steering: float = 0.0

func _ready() -> void:
	if _game_state == null and not game_state_path.is_empty():
		_game_state = get_node(game_state_path)
	if _car_body == null and not car_body_path.is_empty():
		_car_body = get_node(car_body_path)

func _physics_process(delta: float) -> void:
	Input.flush_buffered_events()
	if _car_body == null or _game_state == null:
		return
	if _game_state.player_mode != GameState.PlayerMode.IN_VEHICLE:
		_car_body.engine_force = 0
		_car_body.brake = 0
		return
	var forward_speed: float = _car_body.linear_velocity.dot(_car_body.global_basis.z)
	if Input.is_action_pressed("drive_forward"):
		_car_body.engine_force = -ENGINE_FORCE
		_car_body.brake = 0
	elif Input.is_action_pressed("drive_backward"):
		if forward_speed >= FORWARD_SPEED_THRESHOLD:
			_car_body.engine_force = 0
			_car_body.brake = BRAKE_FORCE
		else:
			_car_body.engine_force = ENGINE_FORCE
			_car_body.brake = 0
	else:
		_car_body.engine_force = 0
		_car_body.brake = 0
	var target_steering: float = 0.0
	if Input.is_action_pressed("drive_left"):
		target_steering = MAX_STEERING
	elif Input.is_action_pressed("drive_right"):
		target_steering = -MAX_STEERING
	_steering = lerp(_steering, target_steering, STEERING_SPEED * delta)
	_steering = clamp(_steering, -MAX_STEERING, MAX_STEERING)
	_car_body.steering = _steering
