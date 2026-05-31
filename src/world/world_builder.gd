class_name WorldBuilder
extends RefCounted

# --- Constantes exposées ---

const GROUND_SIZE: float = 200.0

const SKY_TOP_COLOR: Color = Color(0.306, 0.627, 1.0, 1.0)        # #4ea0ff
const SKY_HORIZON_COLOR: Color = Color(0.753, 0.847, 1.0, 1.0)    # #c0d8ff
const SKY_GROUND_COLOR: Color = Color(0.290, 0.486, 0.227, 1.0)   # #4a7c3a

const GROUND_ALBEDO: Color = Color(0.290, 0.486, 0.227, 1.0)      # #4a7c3a

const LIGHT_PITCH_RADIANS: float = -PI / 4.0   # -45 degrés autour de l'axe X

const CAMERA_POSITION: Vector3 = Vector3(0.0, 8.0, 15.0)
const CAMERA_LOOK_AT: Vector3 = Vector3(0.0, 0.0, 0.0)

# --- Méthodes statiques pures ---

static func build_sky_material() -> ProceduralSkyMaterial:
	var mat := ProceduralSkyMaterial.new()
	mat.sky_top_color = SKY_TOP_COLOR
	mat.sky_horizon_color = SKY_HORIZON_COLOR
	mat.ground_horizon_color = SKY_GROUND_COLOR
	mat.ground_bottom_color = SKY_GROUND_COLOR
	mat.sky_energy_multiplier = 1.0
	mat.sun_angle_max = 30.0
	mat.sun_curve = 0.15
	return mat

static func build_ground_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = GROUND_ALBEDO
	mat.roughness = 1.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	return mat

static func build_ground_mesh() -> PlaneMesh:
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(GROUND_SIZE, GROUND_SIZE)
	mesh.subdivide_width = 0
	mesh.subdivide_depth = 0
	return mesh

static func build_directional_light_basis() -> Basis:
	return Basis.from_euler(Vector3(LIGHT_PITCH_RADIANS, 0.0, 0.0))

static func build_camera_transform() -> Transform3D:
	var t := Transform3D()
	t.origin = CAMERA_POSITION
	t = t.looking_at(CAMERA_LOOK_AT, Vector3.UP)
	return t
