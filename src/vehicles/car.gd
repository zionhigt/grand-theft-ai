extends VehicleBody3D
## Voiture conduisible : VehicleBody3D piloté aux actions drive_* quand actif.
## Carrosserie = car_body.glb (livré, échelle 0.01). La physique est gérée par les VehicleWheel3D natifs.

@export var actif := true

const MOTEUR := 2600.0        # force moteur (N) à pleine accélération
const BRAQUAGE_MAX := 0.5     # angle de braquage max (rad, ~28°)
const VITESSE_BRAQUAGE := 4.0 # vitesse de retour/atteinte du braquage
const FREIN_RALENTI := 1.2    # frein-moteur léger au relâché (coast)
const SEUIL_RENVERSE := 1.5   # s sur le toit/flanc avant auto-redressement

var _temps_renverse := 0.0


func _physics_process(delta: float) -> void:
	if not actif:
		engine_force = 0.0
		steering = move_toward(steering, 0.0, VITESSE_BRAQUAGE * delta)
		brake = FREIN_RALENTI
		return

	_gerer_redressement(delta)

	var acceleration := Input.get_axis("drive_backward", "drive_forward")
	engine_force = acceleration * MOTEUR
	brake = FREIN_RALENTI if is_zero_approx(acceleration) else 0.0

	var braquage := Input.get_axis("drive_right", "drive_left")
	steering = move_toward(steering, braquage * BRAQUAGE_MAX, VITESSE_BRAQUAGE * delta)


## Auto-redressement : si la voiture reste sur le flanc/toit et quasi immobile, on la remet à plat.
func _gerer_redressement(delta: float) -> void:
	var renversee := global_transform.basis.y.y < 0.2
	if renversee and linear_velocity.length() < 2.0:
		_temps_renverse += delta
		if _temps_renverse >= SEUIL_RENVERSE:
			_redresser()
			_temps_renverse = 0.0
	else:
		_temps_renverse = 0.0


func _redresser() -> void:
	global_rotation = Vector3(0.0, rotation.y, 0.0)  # conserve le cap, remet à plat
	global_position += Vector3.UP
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
