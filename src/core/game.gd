extends Node3D
## Orchestrateur : seul endroit qui bascule l'état à pied <-> en voiture.
## Call down uniquement — active/désactive joueur et voiture, redirige la caméra.

enum Etat { A_PIED, EN_VOITURE }
const DISTANCE_ENTREE := 4.0  # m : portée pour monter dans la voiture
const SORTIE_LATERALE := 2.2  # m : décalage de dépose du joueur à la sortie

@onready var _joueur = $Joueur
@onready var _voiture = $Voiture
@onready var _camera = $CameraRig

var _etat := Etat.A_PIED


func _ready() -> void:
	_passer_a_pied()


func _unhandled_input(evenement: InputEvent) -> void:
	if not evenement.is_action_pressed("interact"):
		return
	if _etat == Etat.A_PIED and _proche_voiture():
		_monter()
	elif _etat == Etat.EN_VOITURE:
		_descendre()


func _proche_voiture() -> bool:
	return _joueur.global_position.distance_to(_voiture.global_position) < DISTANCE_ENTREE


func _monter() -> void:
	_etat = Etat.EN_VOITURE
	_joueur.definir_actif(false)
	_voiture.actif = true
	_camera.definir_cible(_voiture)


func _descendre() -> void:
	_voiture.actif = false
	# Déposer le joueur sur le flanc gauche de la voiture, au sol.
	var pos: Vector3 = _voiture.global_position + _voiture.global_transform.basis.x.normalized() * SORTIE_LATERALE
	pos.y = 0.9
	_joueur.global_position = pos
	_passer_a_pied()


func _passer_a_pied() -> void:
	_etat = Etat.A_PIED
	_voiture.actif = false
	_joueur.definir_actif(true)
	_camera.definir_cible(_joueur)
