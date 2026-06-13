extends CharacterBody3D
## Joueur à pied : déplacement camera-relatif sur un CharacterBody3D.
## Lit les inputs lui-même ; ignore tout le reste (call down, signal up).
## MOCK visuel — capsule. À remplacer par res://assets/characters/player/player_body.glb (itération 3).

const VITESSE := 6.0
const ACCELERATION := 14.0
const FREINAGE := 16.0
const GRAVITE := 22.0
const VITESSE_ROTATION := 12.0


func _physics_process(delta: float) -> void:
	# Gravité — garde la capsule posée au sol.
	if not is_on_floor():
		velocity.y -= GRAVITE * delta

	var direction := _direction_voulue()
	var cible := direction * VITESSE
	var taux := ACCELERATION if direction != Vector3.ZERO else FREINAGE
	velocity.x = move_toward(velocity.x, cible.x, taux * delta)
	velocity.z = move_toward(velocity.z, cible.z, taux * delta)

	move_and_slide()
	_orienter_vers(direction, delta)


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


## Oriente progressivement le mesh vers la direction de marche.
func _orienter_vers(direction: Vector3, delta: float) -> void:
	if direction.length_squared() < 0.01:
		return
	var angle_cible := atan2(direction.x, direction.z)
	rotation.y = lerp_angle(rotation.y, angle_cible, VITESSE_ROTATION * delta)
