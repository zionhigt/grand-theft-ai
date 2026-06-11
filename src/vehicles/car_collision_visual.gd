extends Node3D

func _ready() -> void:
	var cs := get_parent() as CollisionShape3D
	if cs == null or not cs.shape is BoxShape3D:
		return
	var h: Vector3 = (cs.shape as BoxShape3D).size / 2.0
	var corners := [
		Vector3(-h.x, -h.y, -h.z), Vector3( h.x, -h.y, -h.z),
		Vector3( h.x,  h.y, -h.z), Vector3(-h.x,  h.y, -h.z),
		Vector3(-h.x, -h.y,  h.z), Vector3( h.x, -h.y,  h.z),
		Vector3( h.x,  h.y,  h.z), Vector3(-h.x,  h.y,  h.z),
	]
	var edges := [
		[0,1],[1,2],[2,3],[3,0],
		[4,5],[5,6],[6,7],[7,4],
		[0,4],[1,5],[2,6],[3,7],
	]
	var im := ImmediateMesh.new()
	var mi := MeshInstance3D.new()
	mi.mesh = im
	mi.custom_aabb = AABB(Vector3(-h.x - 0.1, -h.y - 0.1, -h.z - 0.1),
		Vector3(h.x * 2 + 0.2, h.y * 2 + 0.2, h.z * 2 + 0.2))
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mi.material_override = mat
	add_child(mi)
	im.surface_begin(Mesh.PRIMITIVE_LINES)
	for e in edges:
		im.surface_set_color(Color(0.1, 1.0, 0.3))
		im.surface_add_vertex(corners[e[0]])
		im.surface_set_color(Color(0.1, 1.0, 0.3))
		im.surface_add_vertex(corners[e[1]])
	im.surface_end()
