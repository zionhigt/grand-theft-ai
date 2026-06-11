class_name CarVisuals
extends Node3D

# =============================================================================
# GÉOMÉTRIE DE RÉFÉRENCE — VALEURS GELÉES, NE PAS MODIFIER
# =============================================================================
# Calibrées pour Godot 4.6 ; toute modification brise l'alignement physique/visuel.
#
# scenes/vehicles/car.tscn :
#   CarBodyCollision BoxShape3D    size = Vector3(2, 1.5, 4)  [x=largeur, y=hauteur, z=longueur]
#   Roues (WheelFront/Rear L/R)   position.y = -0.5  (local voiture)
#   wheel_radius                   = 0.35
#   wheel_rest_length              = 0.25
#   Contact sol physique (Y local) = wheel_pos.y - rest_length - wheel_radius = -1.10
#
# main.tscn :
#   Car.position.y = 1.1   → roues posées au niveau du sol monde (y=0)
#
# car_visuals.gd :
#   PHYSICS_GROUND_Y = -0.77  → offset Y local pour aligner le bas du GLB sur le sol physique
#
# game_state.gd (_creer_marqueurs_voiture) :
#   DriverSeat.position = Vector3(-0.35,  0.5,  -0.5)  [siège conducteur]
#   ExitPoint.position  = Vector3(-1.8,  -1.1,  -0.5)  [pied portière conducteur, niveau sol]
# =============================================================================

const CAR_BODY_GLB: String = "res://assets/vehicles/car/car_body.glb"
const CAR_LENGTH_TARGET: float = 4.0
# Contact sol physique en Y local voiture :
# wheel_pos.y - rest_length - wheel_radius = -0.5 - 0.25 - 0.35 = -1.10
const PHYSICS_GROUND_Y: float = -0.77


func _ready() -> void:
	_charger_carrosserie()


func _charger_carrosserie() -> void:
	var body_mesh: MeshInstance3D = $"../CarBodyMesh"
	body_mesh.mesh = null

	if not ResourceLoader.exists(CAR_BODY_GLB):
		push_warning("car_body.glb introuvable — mock BoxMesh actif")
		# MOCK — à remplacer par res://assets/vehicles/car/car_body.glb
		var mock := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(4.0, 1.5, 2.0)
		mock.mesh = box
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.8, 0.133, 0.133)
		mock.material_override = mat
		body_mesh.add_child(mock)
		return

	var body_instance: Node3D = load(CAR_BODY_GLB).instantiate()
	body_instance.rotation_degrees.y = 180.0
	body_instance.visible = false
	body_mesh.add_child(body_instance)

	await get_tree().process_frame

	# Étape 1 — Scale : ramener la longueur max à CAR_LENGTH_TARGET
	var aabb := _compute_aabb(body_instance)
	if aabb.size.length() > 0.001:
		var max_dim := maxf(aabb.size.x, maxf(aabb.size.y, aabb.size.z))
		if max_dim > 0.001:
			body_instance.scale = Vector3.ONE * (CAR_LENGTH_TARGET / max_dim)

	await get_tree().process_frame

	# Étape 2 — Centrer X-Z sur l'origine physique + aligner Y sur le contact sol
	var car_node := body_mesh.get_parent() as Node3D
	var world_aabb := _find_world_aabb(body_instance)

	if not world_aabb.size.is_zero_approx() and car_node != null:
		var car_pos := car_node.global_position
		var aabb_center := world_aabb.position + world_aabb.size * 0.5
		# Centre X et Z du GLB sur l'origine physique de la voiture
		body_instance.global_position.x += car_pos.x - aabb_center.x
		body_instance.global_position.z += car_pos.z - aabb_center.z
		# Aligne le bas visuel du GLB avec le contact sol physique (monde Y ≈ 0)
		var target_bottom := car_pos.y + PHYSICS_GROUND_Y
		body_instance.global_position.y += target_bottom - world_aabb.position.y

	body_instance.visible = true


# AABB monde en transformant les 8 coins de chaque mesh par son global_transform.
# Correct pour tout type de rotation/scale — ne nécessite pas get_transformed_aabb().
func _find_world_aabb(node: Node) -> AABB:
	var result := AABB()
	var first := true
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		if mi.mesh != null:
			var local_aabb := mi.get_aabb()
			if not local_aabb.size.is_zero_approx():
				var world_aabb := _transform_aabb(local_aabb, mi.global_transform)
				result = world_aabb if first else result.merge(world_aabb)
				first = false
	for child in node.get_children():
		var sub := _find_world_aabb(child)
		if not sub.size.is_zero_approx():
			result = sub if first else result.merge(sub)
			first = false
	return result


func _transform_aabb(local_aabb: AABB, xform: Transform3D) -> AABB:
	var p := local_aabb.position
	var s := local_aabb.size
	var corners := [
		xform * Vector3(p.x,       p.y,       p.z),
		xform * Vector3(p.x + s.x, p.y,       p.z),
		xform * Vector3(p.x,       p.y + s.y, p.z),
		xform * Vector3(p.x + s.x, p.y + s.y, p.z),
		xform * Vector3(p.x,       p.y,       p.z + s.z),
		xform * Vector3(p.x + s.x, p.y,       p.z + s.z),
		xform * Vector3(p.x,       p.y + s.y, p.z + s.z),
		xform * Vector3(p.x + s.x, p.y + s.y, p.z + s.z),
	]
	var mn: Vector3 = corners[0]
	var mx: Vector3 = corners[0]
	for i in range(1, 8):
		mn = mn.min(corners[i])
		mx = mx.max(corners[i])
	return AABB(mn, mx - mn)


# AABB en espace local du nœud (pour le calcul de scale initial).
func _compute_aabb(node: Node3D) -> AABB:
	var result := AABB()
	for child in node.get_children():
		var child_aabb := AABB()
		if child is MeshInstance3D:
			child_aabb = (child as MeshInstance3D).get_aabb()
		if child is Node3D and child.get_child_count() > 0:
			var sub := _compute_aabb(child as Node3D)
			if not sub.size.is_zero_approx():
				child_aabb = child_aabb.merge(sub) if not child_aabb.size.is_zero_approx() else sub
		if not child_aabb.size.is_zero_approx():
			result = result.merge(child_aabb) if not result.size.is_zero_approx() else child_aabb
	return result
