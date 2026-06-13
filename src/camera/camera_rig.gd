extends Node3D
## Caméra TPS : suit une cible Node3D, orbite au clic droit maintenu, zoom à la molette.
## Elle ignore la nature de la cible — joueur ou voiture, ce n'est qu'un Node3D à suivre.

@export var cible: Node3D
@export var sensibilite := 0.005
@export var vitesse_suivi := 10.0

const PITCH_MIN := -1.1
const PITCH_MAX := 0.4
const ZOOM_MIN := 2.5
const ZOOM_MAX := 11.0
const ZOOM_PAS := 0.8

@onready var _bras: SpringArm3D = $SpringArm3D

var _yaw := 0.0
var _pitch := -0.35
var _orbite_active := false


func _ready() -> void:
	if cible:
		definir_cible(cible)


## Change la cible suivie ; appelée par l'orchestrateur quand l'état du jeu bascule (itération 6).
func definir_cible(nouvelle: Node3D) -> void:
	cible = nouvelle
	# Empêche le bras de caméra de buter contre la cible elle-même.
	_bras.clear_excluded_objects()
	if cible is CollisionObject3D:
		_bras.add_excluded_object((cible as CollisionObject3D).get_rid())


func _unhandled_input(evenement: InputEvent) -> void:
	if evenement is InputEventMouseButton:
		_gerer_bouton(evenement as InputEventMouseButton)
	elif evenement is InputEventMouseMotion and _orbite_active:
		var motion := evenement as InputEventMouseMotion
		_yaw -= motion.relative.x * sensibilite
		_pitch = clampf(_pitch - motion.relative.y * sensibilite, PITCH_MIN, PITCH_MAX)


func _gerer_bouton(bouton: InputEventMouseButton) -> void:
	match bouton.button_index:
		MOUSE_BUTTON_RIGHT:
			_orbite_active = bouton.pressed
		MOUSE_BUTTON_WHEEL_UP:
			_bras.spring_length = clampf(_bras.spring_length - ZOOM_PAS, ZOOM_MIN, ZOOM_MAX)
		MOUSE_BUTTON_WHEEL_DOWN:
			_bras.spring_length = clampf(_bras.spring_length + ZOOM_PAS, ZOOM_MIN, ZOOM_MAX)


func _process(delta: float) -> void:
	if cible:
		global_position = global_position.lerp(cible.global_position, clampf(vitesse_suivi * delta, 0.0, 1.0))
	rotation.y = _yaw
	_bras.rotation.x = _pitch
