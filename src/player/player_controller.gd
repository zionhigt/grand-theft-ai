class_name PlayerController
extends CharacterBody3D

# --- Constantes ---

const SPEED: float = 5.0
const GRAVITY: float = 9.8
const ROTATION_SPEED: float = 8.0

# --- Nouvelles constantes (feature 11) ---

const CAMERA_ALIGN_SPEED: float = 15.0
# Vitesse d'alignement du personnage sur le yaw de la caméra, en rad/s.

# --- Propriétés exportées ---

@export var speed: float = SPEED
@export var gravity: float = GRAVITY
@export var rotation_speed: float = ROTATION_SPEED

# --- Référence animation (feature 10) ---

var _anim_player: AnimationPlayer = null
# Référence au nœud AnimationPlayer enfant direct.
# Null si le nœud n'existe pas (mode dégradé sans crash).
# Résolu dans _ready() après chargement des assets par code.

# --- État interne ---

var _state: String = "idle"

# --- Nouvelles variables d'état (feature 11) ---

var _camera_yaw: float = 0.0
# Dernière valeur de yaw transmise par le CameraController via set_camera_yaw().

var _camera_yaw_dirty: bool = false
# true dès que set_camera_yaw() est appelé dans la frame courante.

# --- Cycle de vie ---

func _ready() -> void:
	_charger_mesh_joueur()
	_charger_animations()
	_anim_player = get_node_or_null("AnimationPlayer") as AnimationPlayer

func _charger_mesh_joueur() -> void:
	var player_body := get_node_or_null("PlayerBody") as Node3D
	if player_body == null:
		return
	# Supprimer tout enfant existant (évite doublon si déjà instancié dans .tscn)
	for child in player_body.get_children():
		child.queue_free()
	# MOCK — à remplacer par res://assets/characters/player/player_body.glb
	var packed := load("res://assets/characters/player/player_body.glb") as PackedScene
	if packed == null:
		return
	var instance := packed.instantiate()
	player_body.add_child(instance)
	instance.rotation.y = PI
	instance.position.y = -0.9
	var ap := get_node_or_null("AnimationPlayer") as AnimationPlayer
	if ap != null:
		ap.root_node = ap.get_path_to(instance)

func _charger_animations() -> void:
	var ap := get_node_or_null("AnimationPlayer") as AnimationPlayer
	if ap == null:
		return
	_injecter_animation(ap, "res://assets/characters/player/player_idle.glb", "idle")
	_injecter_animation(ap, "res://assets/characters/player/player_walk.glb", "walk")

func _injecter_animation(dest_ap: AnimationPlayer, chemin: String, nom: String) -> void:
	var packed := load(chemin) as PackedScene
	if packed == null:
		return
	var instance := packed.instantiate()
	var src_ap := instance.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if src_ap == null:
		instance.free()
		return
	# Chercher le clip principal : "mixamo_com" en priorité, sinon premier clip disponible
	var clip: Animation = null
	for lib_name in src_ap.get_animation_library_list():
		var lib := src_ap.get_animation_library(lib_name)
		if lib.has_animation("mixamo_com"):
			clip = lib.get_animation("mixamo_com")
			break
		var anim_list := lib.get_animation_list()
		if anim_list.size() > 0:
			clip = lib.get_animation(anim_list[0])
			break
	if clip == null:
		instance.free()
		return
	# Zérouter X et Z de tous les tracks TYPE_POSITION_3D (bone ou non)
	# Le root motion Mixamo est sur l'os hips (path contient ':') → l'ancienne logique ne l'attrapait pas
	for i in range(clip.get_track_count()):
		if clip.track_get_type(i) != Animation.TYPE_POSITION_3D:
			continue
		for k in range(clip.track_get_key_count(i)):
			var val: Vector3 = clip.track_get_key_value(i, k)
			val.x = 0.0
			val.z = 0.0
			clip.track_set_key_value(i, k, val)
	# Injecter dans la librairie par défaut ("") de dest_ap pour que
	# has_animation("idle") / has_animation("walk") fonctionnent directement.
	if not dest_ap.has_animation_library(""):
		dest_ap.add_animation_library("", AnimationLibrary.new())
	var lib_defaut := dest_ap.get_animation_library("")
	if not lib_defaut.has_animation(nom):
		lib_defaut.add_animation(nom, clip)
	instance.free()

# --- Méthodes publiques ---

func get_state() -> String:
	if velocity.x != 0.0 or velocity.z != 0.0:
		return "walk"
	return "idle"

func compute_input_direction() -> Vector3:
	var raw := Vector3.ZERO
	raw.x += Input.get_action_strength("move_right")
	raw.x -= Input.get_action_strength("move_left")
	raw.z -= Input.get_action_strength("move_forward")
	raw.z += Input.get_action_strength("move_backward")
	if raw.length() > 0.0:
		raw = raw.normalized()
	return raw.rotated(Vector3.UP, _camera_yaw)

func apply_gravity(delta: float) -> void:
	velocity.y -= gravity * delta

func apply_movement(direction: Vector3) -> void:
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed

# --- Nouvelles méthodes publiques (feature 11) ---

func set_camera_yaw(yaw: float) -> void:
	# Enregistre le yaw horizontal de la caméra et lève le flag _camera_yaw_dirty.
	_camera_yaw = yaw
	_camera_yaw_dirty = true

func rotate_toward_camera(camera_yaw: float, delta: float) -> void:
	# Fait pivoter le nœud (rotation.y) vers camera_yaw à la vitesse CAMERA_ALIGN_SPEED.
	# Normalise camera_yaw dans [rotation.y - PI, rotation.y + PI] pour prendre l'arc le
	# plus court tout en évitant le saut angulaire lors du passage ±PI.
	var from: float = rotation.y
	var to: float = camera_yaw
	while to > from + PI:
		to -= TAU
	while to < from - PI:
		to += TAU
	rotation.y = lerp(from, to, clamp(CAMERA_ALIGN_SPEED * delta, 0.0, 1.0))

func rotate_toward_direction(direction: Vector3, delta: float) -> void:
	if direction == Vector3.ZERO:
		return
	var target_angle := atan2(-direction.x, -direction.z)
	rotation.y = lerp_angle(rotation.y, target_angle, clamp(rotation_speed * delta, 0.0, 1.0))

func _update_animation() -> void:
	# Pilote l'AnimationPlayer selon get_state().
	# Défensif : aucun crash si _anim_player == null ou si l'animation n'existe pas.
	if _anim_player == null:
		return
	var anim_name: String = "walk" if get_state() == "walk" else "idle"
	if not _anim_player.has_animation(anim_name):
		return
	if _anim_player.current_animation != anim_name:
		_anim_player.play(anim_name)

func _physics_process(delta: float) -> void:
	var direction := compute_input_direction()
	if not is_on_floor():
		apply_gravity(delta)
	apply_movement(direction)
	rotate_toward_direction(direction, delta)
	# --- Feature 11 : alignement sur le yaw caméra si idle et flag levé ---
	if direction == Vector3.ZERO and _camera_yaw_dirty:
		rotate_toward_camera(_camera_yaw, delta)
	_camera_yaw_dirty = false
	move_and_slide()
	_state = "walk" if direction != Vector3.ZERO else "idle"
	_update_animation()
