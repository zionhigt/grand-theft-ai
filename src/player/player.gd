extends CharacterBody3D
## Joueur à pied : déplacement camera-relatif sur un CharacterBody3D.
## Lit les inputs lui-même ; ignore tout le reste (call down, signal up).
## La capsule gère la collision ; le visuel animé est délégué au nœud Modele (call down).

const VITESSE := 6.0
const ACCELERATION := 14.0
const FREINAGE := 16.0
const GRAVITE := 22.0
const VITESSE_ROTATION := 8.0

@onready var _modele: Node = $Modele


func _physics_process(delta: float) -> void:
	# Gravité — garde la capsule posée au sol.
	if not is_on_floor():
		velocity.y -= GRAVITE * delta

	var direction := _direction_voulue()
	_orienter_vers(direction, delta)

	# Pivot naturel : on n'avance à pleine vitesse qu'une fois bien réorienté.
	var cible := direction * VITESSE * _facteur_avance(direction)
	var taux := ACCELERATION if direction != Vector3.ZERO else FREINAGE
	velocity.x = move_toward(velocity.x, cible.x, taux * delta)
	velocity.z = move_toward(velocity.z, cible.z, taux * delta)

	move_and_slide()
	_modele.definir_vitesse(Vector2(velocity.x, velocity.z).length())


## Réduit la vitesse tant que le perso n'est pas orienté vers la direction voulue
## (1.0 quand il est aligné, jusqu'à 0.2 sur un demi-tour) → changement d'appui crédible.
func _facteur_avance(direction: Vector3) -> float:
	if direction == Vector3.ZERO:
		return 0.0
	var avant := Vector3(sin(rotation.y), 0.0, cos(rotation.y))
	return clampf(1.0 + avant.dot(direction), 0.2, 1.0)


## Direction de déplacement souhaitée, projetée dans le repère horizontal de la caméra active.
func _direction_voulue() -> Vector3:
	var entree := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	if entree == Vector2.ZERO:
		return Vector3.ZERO

	var camera := get_viewport().get_camera_3d()
	if camera == null:
		# Repli sans caméra (ex. tests headless) : repère monde.
		return Vector3(entree.x, 0.0, entree.y).normalized()

	var arriere := camera.global_transform.basis.z
	arriere.y = 0.0
	var droite := camera.global_transform.basis.x
	droite.y = 0.0
	# entree.y > 0 = reculer (vers l'arrière caméra) ; entree.x > 0 = droite.
	var dir := droite.normalized() * entree.x + arriere.normalized() * entree.y
	return dir.normalized()


## Oriente le mesh vers la direction de marche, en douceur (lissage framerate-indépendant).
func _orienter_vers(direction: Vector3, delta: float) -> void:
	if direction.length_squared() < 0.01:
		return
	var angle_cible := atan2(direction.x, direction.z)
	rotation.y = lerp_angle(rotation.y, angle_cible, 1.0 - exp(-VITESSE_ROTATION * delta))
