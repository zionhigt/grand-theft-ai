extends GutTest

# Tests unitaires — Feature 02 : Scène 3D minimale (sol + ciel + lumière + caméra fixe)
#
# Chaque test cible un comportement numéroté de la spec docs/specs/02-scene-3d-minimale.md.
#
# Stratégie :
#   Les tests 1 à 9 (comportements 1–8 + cas limites) exercent les méthodes statiques
#   pures de WorldBuilder sans instancier main.tscn.
#   Les tests 10 à 12 chargent main.tscn en headless pour vérifier la structure de scène
#   et les valeurs configurées dans les nœuds.
#
# En phase rouge : WorldBuilder n'existe pas encore.
#   Le preload en tête de fichier provoquera une erreur de chargement GUT — attendu.

# ---------------------------------------------------------------------------
# Préchargement du module sous test
# ---------------------------------------------------------------------------
const WorldBuilder = preload("res://src/world/world_builder.gd")

# ---------------------------------------------------------------------------
# Comportement 1 — WorldBuilder.GROUND_SIZE == 200.0
# Spec §Comportements attendus point 1
# ---------------------------------------------------------------------------
func test_la_taille_du_sol_est_de_200_metres() -> void:
	assert_eq(WorldBuilder.GROUND_SIZE, 200.0)

# ---------------------------------------------------------------------------
# Comportement 2 — build_ground_mesh() retourne un PlaneMesh 200×200
# Spec §Comportements attendus point 2
# ---------------------------------------------------------------------------
func test_build_ground_mesh_retourne_un_plane_mesh_200x200() -> void:
	var mesh = WorldBuilder.build_ground_mesh()
	assert_true(mesh is PlaneMesh, "Le mesh doit être un PlaneMesh")
	assert_eq(mesh.size, Vector2(200.0, 200.0))

# ---------------------------------------------------------------------------
# Comportement 3 — build_ground_material() a la bonne couleur albedo
# Spec §Comportements attendus point 3
# ---------------------------------------------------------------------------
func test_la_couleur_du_sol_est_vert_sombre() -> void:
	var mat = WorldBuilder.build_ground_material()
	assert_true(mat is StandardMaterial3D, "Le matériau doit être un StandardMaterial3D")
	var c: Color = mat.albedo_color
	var expected: Color = WorldBuilder.GROUND_ALBEDO
	assert_almost_eq(c.r, expected.r, 0.001)
	assert_almost_eq(c.g, expected.g, 0.001)
	assert_almost_eq(c.b, expected.b, 0.001)

# ---------------------------------------------------------------------------
# Comportement 4 — build_sky_material() a la bonne couleur de zénith
# Spec §Comportements attendus point 4
# ---------------------------------------------------------------------------
func test_la_couleur_du_haut_du_ciel_est_bleue() -> void:
	var sky_mat = WorldBuilder.build_sky_material()
	assert_true(sky_mat is ProceduralSkyMaterial, "Le matériau de ciel doit être un ProceduralSkyMaterial")
	var c: Color = sky_mat.sky_top_color
	var expected: Color = WorldBuilder.SKY_TOP_COLOR
	assert_almost_eq(c.r, expected.r, 0.001)
	assert_almost_eq(c.g, expected.g, 0.001)
	assert_almost_eq(c.b, expected.b, 0.001)

# ---------------------------------------------------------------------------
# Comportements 5 et 6 — build_sky_material() couleurs horizon et sol du ciel
# Spec §Comportements attendus points 5 et 6
# ---------------------------------------------------------------------------
func test_les_couleurs_horizon_et_sol_du_ciel_sont_correctes() -> void:
	var sky_mat = WorldBuilder.build_sky_material()

	# Horizon
	var horizon: Color = sky_mat.sky_horizon_color
	var expected_horizon: Color = WorldBuilder.SKY_HORIZON_COLOR
	assert_almost_eq(horizon.r, expected_horizon.r, 0.001)
	assert_almost_eq(horizon.g, expected_horizon.g, 0.001)
	assert_almost_eq(horizon.b, expected_horizon.b, 0.001)

	# Sol du ciel (ground_bottom_color)
	var ground_bottom: Color = sky_mat.ground_bottom_color
	var expected_ground: Color = WorldBuilder.SKY_GROUND_COLOR
	assert_almost_eq(ground_bottom.r, expected_ground.r, 0.001)
	assert_almost_eq(ground_bottom.g, expected_ground.g, 0.001)
	assert_almost_eq(ground_bottom.b, expected_ground.b, 0.001)

# ---------------------------------------------------------------------------
# Comportement 7 — build_camera_transform() origine == CAMERA_POSITION
# Spec §Comportements attendus point 7
# ---------------------------------------------------------------------------
func test_la_camera_est_positionnee_a_0_8_15() -> void:
	var t: Transform3D = WorldBuilder.build_camera_transform()
	assert_eq(t.origin, WorldBuilder.CAMERA_POSITION)

# ---------------------------------------------------------------------------
# Comportement 8 — build_camera_transform() direction forward pointe vers l'origine
# Spec §Comportements attendus point 8
# ---------------------------------------------------------------------------
func test_la_camera_regarde_vers_l_origine() -> void:
	var transform: Transform3D = WorldBuilder.build_camera_transform()
	var forward: Vector3 = -transform.basis.z
	var expected: Vector3 = (Vector3.ZERO - WorldBuilder.CAMERA_POSITION).normalized()
	assert_gt(forward.dot(expected), 0.99)

# ---------------------------------------------------------------------------
# Comportement 9 — build_directional_light_basis() pitch == -PI/4
# Spec §Comportements attendus point 9
# ---------------------------------------------------------------------------
func test_la_lumiere_directionnelle_a_un_pitch_de_moins_45_degres() -> void:
	var basis: Basis = WorldBuilder.build_directional_light_basis()
	assert_almost_eq(basis.get_euler().x, -PI / 4.0, 0.001)

# ---------------------------------------------------------------------------
# Comportement 10 — main.tscn contient les nœuds attendus
# Spec §Comportements attendus point 10
# ---------------------------------------------------------------------------
func test_main_tscn_contient_les_noeuds_attendus() -> void:
	var scene = load("res://main.tscn").instantiate()
	add_child_autofree(scene)

	assert_not_null(scene.get_node_or_null("WorldEnvironment"),
		"Le nœud WorldEnvironment doit exister")
	assert_not_null(scene.get_node_or_null("DirectionalLight3D"),
		"Le nœud DirectionalLight3D doit exister")
	assert_not_null(scene.get_node_or_null("Ground"),
		"Le nœud Ground doit exister")
	# La feature 04 a supprimé la Camera3D fixe enfant direct de Main
	# et l'a remplacée par CameraRig/Camera3D — on vérifie la nouvelle structure.
	assert_not_null(scene.get_node_or_null("CameraRig/Camera3D"),
		"Le nœud CameraRig/Camera3D doit exister")
	assert_true(scene.get_node("CameraRig/Camera3D").current,
		"La Camera3D de CameraRig doit être active (current == true)")

# ---------------------------------------------------------------------------
# Comportement 11 — nœud Ground est un PlaneMesh 200×200
# Spec §Comportements attendus point 11
# ---------------------------------------------------------------------------
func test_le_sol_de_main_tscn_est_un_plane_mesh_200x200() -> void:
	var scene = load("res://main.tscn").instantiate()
	add_child_autofree(scene)

	var ground = scene.get_node("Ground")
	assert_not_null(ground, "Le nœud Ground doit exister")
	assert_true(ground.mesh is PlaneMesh, "Le mesh du sol doit être un PlaneMesh")
	assert_eq(ground.mesh.size, Vector2(200.0, 200.0))

# ---------------------------------------------------------------------------
# Comportement 12a — WorldEnvironment utilise un ciel procédural
# Spec §Comportements attendus point 12 (première partie)
# ---------------------------------------------------------------------------
func test_l_environnement_utilise_un_sky_procedural() -> void:
	var scene = load("res://main.tscn").instantiate()
	add_child_autofree(scene)

	var world_env = scene.get_node("WorldEnvironment")
	var env: Environment = world_env.environment
	assert_not_null(env, "L'environment ne doit pas être null")
	assert_eq(env.background_mode, Environment.BG_SKY,
		"Le mode background doit être BG_SKY")
	assert_not_null(env.sky, "Le Sky ne doit pas être null")
	assert_true(env.sky.sky_material is ProceduralSkyMaterial,
		"Le sky_material doit être un ProceduralSkyMaterial")

# ---------------------------------------------------------------------------
# Comportement 12b — DirectionalLight3D a une énergie de 1.0
# Spec §Comportements attendus point 12 (seconde partie)
# ---------------------------------------------------------------------------
func test_la_lumiere_directionnelle_a_une_energie_de_1() -> void:
	var scene = load("res://main.tscn").instantiate()
	add_child_autofree(scene)

	var light = scene.get_node("DirectionalLight3D")
	assert_not_null(light, "Le nœud DirectionalLight3D doit exister")
	assert_almost_eq(light.light_energy, 1.0, 0.001)

# ---------------------------------------------------------------------------
# Cas limite 1 — deux appels à build_ground_mesh() → instances distinctes
# Spec §Cas limites / erreurs point 1
# ---------------------------------------------------------------------------
func test_deux_appels_a_build_ground_mesh_retournent_des_instances_distinctes() -> void:
	var mesh_a = WorldBuilder.build_ground_mesh()
	var mesh_b = WorldBuilder.build_ground_mesh()
	assert_false(is_same(mesh_a, mesh_b),
		"build_ground_mesh() ne doit pas retourner un singleton partagé")

# ---------------------------------------------------------------------------
# Cas limite 2 (stabilité) — build_camera_transform() retourne le même résultat
# Spec §Cas limites / erreurs point 3
# ---------------------------------------------------------------------------
func test_build_camera_transform_est_stable_entre_deux_appels() -> void:
	var t1: Transform3D = WorldBuilder.build_camera_transform()
	var t2: Transform3D = WorldBuilder.build_camera_transform()
	assert_true(t1.is_equal_approx(t2),
		"build_camera_transform() doit être déterministe et stable")
