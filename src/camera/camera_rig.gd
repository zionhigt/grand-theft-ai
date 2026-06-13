extends Node3D
## Caméra TPS classique : la souris (curseur capturé) oriente librement la vue en continu.
## Le rig suit la cible avec amortissement (lerp), Échap libère/recapture le curseur, molette = zoom.
## Elle ignore la nature de la cible — joueur ou voiture, ce n'est qu'un Node3D à suivre.

## Cible initiale, câblée dans la scène (NodePath fiable, contrairement à un export Node3D direct).
@export var cible_path: NodePath
@export var sensibilite := 0.0035
@export var vitesse_suivi := 9.0

const PITCH_MIN := -1.1
const PITCH_MAX := 0.5
const ZOOM_MIN := 2.5
const ZOOM_MAX := 11.0
const ZOOM_PAS := 0.8

@onready var _bras: SpringArm3D = $SpringArm3D

var cible: Node3D
var _yaw := PI  # démarre dans le dos du perso (qui regarde +Z au spawn)
var _pitch := -0.25
var _souris_capturee := true


func _ready() -> void:
	_bras.spring_length = ZOOM_MIN  # caméra au plus près du perso au démarrage
	if not cible_path.is_empty():
		definir_cible(get_node(cible_path))
	_appliquer_capture(true)


## Change la cible suivie ; appelée par l'orchestrateur quand l'état du jeu bascule (itération 6).
func definir_cible(nouvelle: Node3D) -> void:
	cible = nouvelle
	# Empêche le bras de caméra de buter contre la cible elle-même.
	_bras.clear_excluded_objects()
	if cible is CollisionObject3D:
		_bras.add_excluded_object((cible as CollisionObject3D).get_rid())


func _unhandled_input(evenement: InputEvent) -> void:
	if evenement.is_action_pressed("ui_cancel"):
		_appliquer_capture(not _souris_capturee)
	elif evenement is InputEventMouseMotion and _souris_capturee:
		var motion := evenement as InputEventMouseMotion
		_yaw -= motion.relative.x * sensibilite
		_pitch = clampf(_pitch - motion.relative.y * sensibilite, PITCH_MIN, PITCH_MAX)
	elif evenement is InputEventMouseButton:
		_gerer_zoom(evenement as InputEventMouseButton)


func _gerer_zoom(bouton: InputEventMouseButton) -> void:
	if bouton.button_index == MOUSE_BUTTON_WHEEL_UP:
		_bras.spring_length = clampf(_bras.spring_length - ZOOM_PAS, ZOOM_MIN, ZOOM_MAX)
	elif bouton.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		_bras.spring_length = clampf(_bras.spring_length + ZOOM_PAS, ZOOM_MIN, ZOOM_MAX)


func _appliquer_capture(capturee: bool) -> void:
	_souris_capturee = capturee
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if capturee else Input.MOUSE_MODE_VISIBLE)


func _process(delta: float) -> void:
	if cible:
		global_position = global_position.lerp(cible.global_position, clampf(vitesse_suivi * delta, 0.0, 1.0))
	rotation.y = _yaw
	_bras.rotation.x = _pitch
