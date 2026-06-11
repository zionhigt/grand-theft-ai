class_name CameraController
extends Node3D

# --- Constantes héritées (feature 04 — inchangées) ---

const OFFSET: Vector3 = Vector3(0, 3, 6)
# Décalage monde appliqué à target.global_position :
#   X = 0   → centré latéralement
#   Y = +3  → 3 m au-dessus de la cible
#   Z = +6  → 6 m derrière la cible (axe +Z monde = derrière un personnage spawn face à -Z)
# Conservé pour rétrocompatibilité tests 04 — non utilisé dans _process feature 09.

const EYE_HEIGHT: float = 1.6
# Hauteur du point visé au-dessus de target.global_position (hauteur des yeux, personnage 1.8 m)

# --- Nouvelles constantes (feature 09) ---

const ZOOM_DISTANCES: Array[float] = [3.0, 4.5, 6.708]
# Trois distances orbitales discrètes (mètres).
# Index 0 : 3.0 — vue la plus proche (défaut).
# Index 1 : 4.5 — vue intermédiaire.
# Index 2 : 6.708 ≈ sqrt(3²+6²) — vue la plus éloignée.

const DEFAULT_PITCH: float = 0.4636
# Angle de pitch initial en radians ≈ atan2(3.0, 6.0) — reproduit exactement OFFSET(0,3,6)
# quand yaw=0 et zoom_level=0 : distance*sin(pitch)≈3, distance*cos(pitch)*cos(0)≈6.

const DEFAULT_YAW: float = 0.0
# Yaw initial : 0 rad, caméra derrière la cible.

const DEFAULT_ZOOM_LEVEL: int = 0
# Niveau de zoom initial : 0 (distance la plus proche).

const MOUSE_SENSITIVITY: float = 0.003
# Sensibilité souris en radians par pixel. ≈ 0.17°/px.

const PITCH_MIN: float = -0.1745
# Pitch minimum : -10° en radians (-0.1745 rad).

const PITCH_MAX: float = 1.2217
# Pitch maximum : +70° en radians (1.2217 rad).

const SPRING_RATE: float = 5.0
# Coefficient du lerp_angle vers home_yaw chaque frame (rad/s).
# Actif uniquement quand _right_mouse_held == false.

# --- Propriétés exportées héritées (feature 04 — inchangées) ---

@export var target: Node3D
# Nœud suivi chaque frame. Si null, la caméra ne bouge pas (fail-safe).

# --- Variables d'état (feature 09) ---

var _yaw: float = DEFAULT_YAW
# Angle de rotation horizontal autour de l'axe Y du monde. Libre à 360°, non borné.

var _pitch: float = DEFAULT_PITCH
# Angle d'élévation vertical. Borné entre PITCH_MIN et PITCH_MAX.

var _zoom_level: int = DEFAULT_ZOOM_LEVEL
# Niveau de zoom courant. Entier dans [0, 2].

var _right_mouse_held: bool = false
# Vrai si le bouton droit de la souris est actuellement maintenu enfoncé.

# --- Méthodes ---

func _ready() -> void:
	if target == null:
		target = get_node_or_null("../Player")

func _process(delta: float) -> void:
	if target == null:
		return
	# Spring-back : quand pas en orbite, _yaw converge vers le dos de la cible
	if not _right_mouse_held and target.is_inside_tree():
		var home_yaw: float = target.global_transform.basis.get_euler().y
		# Calcule la différence angulaire dans (-PI, PI] pour choisir le chemin court.
		# fmod garantit que diff dans [0, TAU[, puis on ramène dans (-PI, PI].
		# Quand diff == PI exactement, on conserve le signe positif (chemin direct).
		var diff: float = fmod(home_yaw - _yaw, TAU)
		if diff > PI:
			diff -= TAU
		elif diff < -PI:
			diff += TAU
		_yaw += diff * clamp(SPRING_RATE * delta, 0.0, 1.0)
	# Positionnement orbital (inchangé depuis feature 09 / 12)
	var target_pos: Vector3 = target.global_position if target.is_inside_tree() else target.position
	var dist: float = ZOOM_DISTANCES[_zoom_level]
	var orbit: Vector3 = Vector3(0.0, 0.0, dist).rotated(Vector3.RIGHT, -_pitch).rotated(Vector3.UP, _yaw)
	global_position = target_pos + orbit
	$Camera3D.look_at(target_pos + Vector3(0.0, EYE_HEIGHT, 0.0), Vector3.UP)
	# Propagation permanente du yaw vers PlayerController (feature 12 — inchangée)
	if target.has_method("set_camera_yaw"):
		target.set_camera_yaw(_yaw)

# --- Nouvelle méthode publique (feature 11) ---

func get_yaw() -> float:
	# Retourne la valeur courante de _yaw.
	return _yaw

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_RIGHT:
			_right_mouse_held = mb.pressed
			if mb.pressed:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			else:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_zoom_level = min(_zoom_level + 1, 2)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_zoom_level = max(_zoom_level - 1, 0)
	elif event is InputEventMouseMotion and _right_mouse_held:
		var mm := event as InputEventMouseMotion
		_yaw -= mm.relative.x * MOUSE_SENSITIVITY
		_pitch = clamp(_pitch - mm.relative.y * MOUSE_SENSITIVITY, PITCH_MIN, PITCH_MAX)
