extends GutTest

# Tests unitaires — Feature 05 : Ville minimale (sol étendu + bâtiments cubiques)
#
# Chaque test cible un comportement numéroté de la spec docs/specs/05-ville-minimale.md.
#
# Stratégie :
#   Les tests B1 à B12 chargent city.tscn directement.
#   Les tests B13, B14, B15 chargent main.tscn pour vérifier la structure intégrée.
#   Les tests CL1 à CL5 couvrent les cas limites / erreurs.
#
# En phase rouge : city.tscn et la modification de main.tscn n'existent pas encore.
#   Les load() échoueront ou retourneront null — attendu.

# ---------------------------------------------------------------------------
# Constantes de validation (spec §Données et constantes)
# ---------------------------------------------------------------------------
const BUILDING_COUNT        := 8
const MIN_SPAWN_DISTANCE    := 10.0
const MAX_DISTANCE_FROM_ORIGIN := 50.0
const MIN_HEIGHT            := 4.0
const MAX_HEIGHT            := 14.0

# ---------------------------------------------------------------------------
# B1 — city.tscn se charge sans erreur et instantiate() retourne non null
# Spec §Comportements attendus point B1
# ---------------------------------------------------------------------------
func test_city_tscn_se_charge_et_instancie_sans_erreur() -> void:
	var packed = load("res://scenes/city/city.tscn")
	assert_not_null(packed, "load('res://scenes/city/city.tscn') ne doit pas retourner null")
	var city = packed.instantiate()
	assert_not_null(city, "instantiate() de city.tscn ne doit pas retourner null")
	city.free()

# ---------------------------------------------------------------------------
# B2 — Nœud racine de city.tscn : nom "City", type Node3D
# Spec §Comportements attendus point B2
# ---------------------------------------------------------------------------
func test_noeud_racine_de_city_tscn_s_appelle_city_et_est_un_node3d() -> void:
	var city = load("res://scenes/city/city.tscn").instantiate()
	add_child_autofree(city)
	assert_eq(city.name, "City",
		"Le nœud racine de city.tscn doit s'appeler 'City'")
	assert_true(city is Node3D,
		"Le nœud racine de city.tscn doit être de type Node3D")

# ---------------------------------------------------------------------------
# B3 — city.tscn contient exactement 8 enfants directs StaticBody3D
# Spec §Comportements attendus point B3
# ---------------------------------------------------------------------------
func test_city_tscn_contient_exactement_huit_enfants_staticbody3d() -> void:
	var city = load("res://scenes/city/city.tscn").instantiate()
	add_child_autofree(city)
	var bodies = city.get_children().filter(func(n): return n is StaticBody3D)
	assert_eq(bodies.size(), BUILDING_COUNT,
		"city.tscn doit contenir exactement 8 StaticBody3D enfants directs")
	assert_eq(city.get_child_count(), BUILDING_COUNT,
		"city.tscn doit avoir exactement 8 enfants directs (pas d'autres nœuds)")

# ---------------------------------------------------------------------------
# B4 — Chaque StaticBody3D a exactement un CollisionShape3D dont le shape est BoxShape3D
# Spec §Comportements attendus point B4
# ---------------------------------------------------------------------------
func test_chaque_batiment_a_un_collisionshape3d_avec_boxshape3d() -> void:
	var city = load("res://scenes/city/city.tscn").instantiate()
	add_child_autofree(city)
	var bodies = city.get_children().filter(func(n): return n is StaticBody3D)
	for body in bodies:
		var shapes = body.get_children().filter(func(n): return n is CollisionShape3D)
		assert_eq(shapes.size(), 1,
			"Le bâtiment '%s' doit avoir exactement un CollisionShape3D" % body.name)
		assert_true(shapes[0].shape is BoxShape3D,
			"Le CollisionShape3D de '%s' doit avoir un BoxShape3D" % body.name)

# ---------------------------------------------------------------------------
# B5 — Chaque StaticBody3D a exactement un MeshInstance3D dont le mesh est BoxMesh
# Spec §Comportements attendus point B5
# ---------------------------------------------------------------------------
func test_chaque_batiment_a_un_meshinstance3d_avec_boxmesh() -> void:
	var city = load("res://scenes/city/city.tscn").instantiate()
	add_child_autofree(city)
	var bodies = city.get_children().filter(func(n): return n is StaticBody3D)
	for body in bodies:
		var meshes = body.get_children().filter(func(n): return n is MeshInstance3D)
		assert_eq(meshes.size(), 1,
			"Le bâtiment '%s' doit avoir exactement un MeshInstance3D" % body.name)
		assert_true(meshes[0].mesh is BoxMesh,
			"Le MeshInstance3D de '%s' doit avoir un BoxMesh" % body.name)

# ---------------------------------------------------------------------------
# B6 — La size du BoxShape3D est égale à la size du BoxMesh (à 0.001 près)
# Spec §Comportements attendus point B6
# ---------------------------------------------------------------------------
func test_la_size_du_boxshape3d_est_egale_a_la_size_du_boxmesh() -> void:
	var city = load("res://scenes/city/city.tscn").instantiate()
	add_child_autofree(city)
	var bodies = city.get_children().filter(func(n): return n is StaticBody3D)
	for body in bodies:
		var shape_size: Vector3 = (body.get_node("CollisionShape3D").shape as BoxShape3D).size
		var mesh_size: Vector3  = (body.get_node("MeshInstance3D").mesh as BoxMesh).size
		assert_almost_eq(shape_size.x, mesh_size.x, 0.001,
			"Composante X size incohérente pour '%s'" % body.name)
		assert_almost_eq(shape_size.y, mesh_size.y, 0.001,
			"Composante Y size incohérente pour '%s'" % body.name)
		assert_almost_eq(shape_size.z, mesh_size.z, 0.001,
			"Composante Z size incohérente pour '%s'" % body.name)

# ---------------------------------------------------------------------------
# B7 — position.y locale du CollisionShape3D == shape.size.y / 2.0 (à 0.001 près)
# Spec §Comportements attendus point B7
# ---------------------------------------------------------------------------
func test_collisionshape3d_decale_de_moitie_hauteur_sur_y() -> void:
	var city = load("res://scenes/city/city.tscn").instantiate()
	add_child_autofree(city)
	var bodies = city.get_children().filter(func(n): return n is StaticBody3D)
	for body in bodies:
		var cs = body.get_node("CollisionShape3D")
		var demi_hauteur := (cs.shape as BoxShape3D).size.y / 2.0
		assert_almost_eq(cs.position.y, demi_hauteur, 0.001,
			"position.y de CollisionShape3D doit être hauteur/2 pour '%s'" % body.name)

# ---------------------------------------------------------------------------
# B8 — position.y locale du MeshInstance3D == mesh.size.y / 2.0 (à 0.001 près)
# Spec §Comportements attendus point B8
# ---------------------------------------------------------------------------
func test_meshinstance3d_decale_de_moitie_hauteur_sur_y() -> void:
	var city = load("res://scenes/city/city.tscn").instantiate()
	add_child_autofree(city)
	var bodies = city.get_children().filter(func(n): return n is StaticBody3D)
	for body in bodies:
		var mi = body.get_node("MeshInstance3D")
		var demi_hauteur := (mi.mesh as BoxMesh).size.y / 2.0
		assert_almost_eq(mi.position.y, demi_hauteur, 0.001,
			"position.y de MeshInstance3D doit être hauteur/2 pour '%s'" % body.name)

# ---------------------------------------------------------------------------
# B9 — position.y de chaque StaticBody3D est exactement 0.0 (posé sur le sol)
# Spec §Comportements attendus point B9
# ---------------------------------------------------------------------------
func test_chaque_batiment_est_pose_sur_le_sol_y_egal_zero() -> void:
	var city = load("res://scenes/city/city.tscn").instantiate()
	add_child_autofree(city)
	var bodies = city.get_children().filter(func(n): return n is StaticBody3D)
	for body in bodies:
		assert_almost_eq(body.position.y, 0.0, 0.001,
			"position.y du StaticBody3D '%s' doit être 0.0 (niveau du sol)" % body.name)

# ---------------------------------------------------------------------------
# B10 — Distance de chaque bâtiment à l'origine (XZ) : entre 10.0 m et 50.0 m
# Spec §Comportements attendus point B10
# ---------------------------------------------------------------------------
func test_chaque_batiment_est_a_distance_valide_de_l_origine() -> void:
	var city = load("res://scenes/city/city.tscn").instantiate()
	add_child_autofree(city)
	var bodies = city.get_children().filter(func(n): return n is StaticBody3D)
	for body in bodies:
		var dist_xz := Vector2(body.position.x, body.position.z).length()
		assert_true(dist_xz >= MIN_SPAWN_DISTANCE,
			"Bâtiment '%s' trop proche du spawn (dist=%.2f, min=%.2f)" % [body.name, dist_xz, MIN_SPAWN_DISTANCE])
		assert_true(dist_xz <= MAX_DISTANCE_FROM_ORIGIN,
			"Bâtiment '%s' trop loin de l'origine (dist=%.2f, max=%.2f)" % [body.name, dist_xz, MAX_DISTANCE_FROM_ORIGIN])

# ---------------------------------------------------------------------------
# B11 — Hauteur (BoxMesh.size.y) de chaque bâtiment entre 4.0 m et 14.0 m
# Spec §Comportements attendus point B11
# ---------------------------------------------------------------------------
func test_chaque_batiment_a_une_hauteur_dans_les_bornes() -> void:
	var city = load("res://scenes/city/city.tscn").instantiate()
	add_child_autofree(city)
	var bodies = city.get_children().filter(func(n): return n is StaticBody3D)
	for body in bodies:
		var h := (body.get_node("MeshInstance3D").mesh as BoxMesh).size.y
		assert_true(h >= MIN_HEIGHT,
			"Bâtiment '%s' trop bas : hauteur=%.2f, min=%.2f" % [body.name, h, MIN_HEIGHT])
		assert_true(h <= MAX_HEIGHT,
			"Bâtiment '%s' trop haut : hauteur=%.2f, max=%.2f" % [body.name, h, MAX_HEIGHT])

# ---------------------------------------------------------------------------
# B12 — Chaque MeshInstance3D a un material_override non null de type StandardMaterial3D
# Spec §Comportements attendus point B12
# ---------------------------------------------------------------------------
func test_chaque_batiment_a_un_material_override_standard_material3d() -> void:
	var city = load("res://scenes/city/city.tscn").instantiate()
	add_child_autofree(city)
	var bodies = city.get_children().filter(func(n): return n is StaticBody3D)
	for body in bodies:
		var mat = body.get_node("MeshInstance3D").material_override
		assert_not_null(mat,
			"Le MeshInstance3D de '%s' doit avoir un material_override non null" % body.name)
		assert_true(mat is StandardMaterial3D,
			"Le material_override de '%s' doit être un StandardMaterial3D" % body.name)

# ---------------------------------------------------------------------------
# B13 — main.tscn contient un enfant direct nommé "City" de type Node3D
# Spec §Comportements attendus point B13
# ---------------------------------------------------------------------------
func test_main_tscn_contient_un_enfant_city_de_type_node3d() -> void:
	var main = load("res://main.tscn").instantiate()
	add_child_autofree(main)
	var city_node = main.get_node_or_null("City")
	assert_not_null(city_node,
		"main.tscn doit contenir un enfant direct nommé 'City'")
	assert_true(city_node is Node3D,
		"Le nœud 'City' dans main.tscn doit être de type Node3D")

# ---------------------------------------------------------------------------
# B14 — Le nœud City dans main.tscn contient exactement 8 enfants StaticBody3D
# Spec §Comportements attendus point B14
# ---------------------------------------------------------------------------
func test_city_dans_main_tscn_contient_exactement_huit_batiments() -> void:
	var main = load("res://main.tscn").instantiate()
	add_child_autofree(main)
	var city_in_main = main.get_node("City")
	var bodies_in_main = city_in_main.get_children().filter(func(n): return n is StaticBody3D)
	assert_eq(bodies_in_main.size(), BUILDING_COUNT,
		"Le nœud 'City' dans main.tscn doit contenir exactement 8 StaticBody3D")

# ---------------------------------------------------------------------------
# B15 — Les nœuds des features précédentes sont toujours présents dans main.tscn
# Spec §Comportements attendus point B15
# ---------------------------------------------------------------------------
func test_noeuds_features_precedentes_toujours_presents_dans_main_tscn() -> void:
	var main = load("res://main.tscn").instantiate()
	add_child_autofree(main)
	var noeuds_requis := [
		"WorldEnvironment",
		"DirectionalLight3D",
		"Ground",
		"GroundCollider",
		"Player",
		"CameraRig"
	]
	for node_name in noeuds_requis:
		assert_not_null(main.get_node_or_null(node_name),
			"Nœud manquant dans main.tscn après ajout de City : '%s'" % node_name)

# ---------------------------------------------------------------------------
# CL1 — city.tscn instanciée sans add_child : nœuds accessibles sans arbre actif
# Spec §Cas limites / erreurs point CL1
# ---------------------------------------------------------------------------
func test_city_tscn_instanciee_sans_arbre_enfants_accessibles() -> void:
	var city = load("res://scenes/city/city.tscn").instantiate()
	# Pas de add_child — scène hors arbre
	var bodies = city.get_children().filter(func(n): return n is StaticBody3D)
	assert_eq(bodies.size(), BUILDING_COUNT,
		"Les enfants de city.tscn doivent être accessibles même hors arbre")
	# Vérification que CollisionShape3D et BoxShape3D sont accessibles sans arbre actif
	for body in bodies:
		var cs = body.get_node("CollisionShape3D")
		assert_not_null(cs,
			"CollisionShape3D accessible hors arbre pour '%s'" % body.name)
		assert_not_null(cs.shape,
			"BoxShape3D accessible hors arbre pour '%s'" % body.name)
	city.free()

# ---------------------------------------------------------------------------
# CL2 — Aucun composant de size (X, Y, Z) n'est nul ou négatif pour aucun bâtiment
# Spec §Cas limites / erreurs point CL2
# ---------------------------------------------------------------------------
func test_aucun_composant_size_nul_ou_negatif() -> void:
	var city = load("res://scenes/city/city.tscn").instantiate()
	add_child_autofree(city)
	var bodies = city.get_children().filter(func(n): return n is StaticBody3D)
	for body in bodies:
		var s: Vector3 = (body.get_node("CollisionShape3D").shape as BoxShape3D).size
		assert_gt(s.x, 0.0,
			"Composante X de size doit être > 0 pour '%s'" % body.name)
		assert_gt(s.y, 0.0,
			"Composante Y de size doit être > 0 pour '%s'" % body.name)
		assert_gt(s.z, 0.0,
			"Composante Z de size doit être > 0 pour '%s'" % body.name)

# ---------------------------------------------------------------------------
# CL3 — Le nœud City dans main.tscn est positionné à Vector3(0, 0, 0)
# Spec §Cas limites / erreurs point CL3
# ---------------------------------------------------------------------------
func test_noeud_city_dans_main_tscn_est_a_l_origine() -> void:
	var main = load("res://main.tscn").instantiate()
	add_child_autofree(main)
	var city_node = main.get_node("City")
	assert_almost_eq(city_node.position.x, 0.0, 0.001,
		"La position X du nœud City dans main.tscn doit être 0.0")
	assert_almost_eq(city_node.position.y, 0.0, 0.001,
		"La position Y du nœud City dans main.tscn doit être 0.0")
	assert_almost_eq(city_node.position.z, 0.0, 0.001,
		"La position Z du nœud City dans main.tscn doit être 0.0")

# ---------------------------------------------------------------------------
# CL4 — Aucun StaticBody3D de city.tscn n'a de script attaché
# Spec §Cas limites / erreurs point CL4
# ---------------------------------------------------------------------------
func test_aucun_batiment_n_a_de_script_attache() -> void:
	var city = load("res://scenes/city/city.tscn").instantiate()
	add_child_autofree(city)
	var bodies = city.get_children().filter(func(n): return n is StaticBody3D)
	for body in bodies:
		assert_null(body.get_script(),
			"Le StaticBody3D '%s' ne doit pas avoir de script attaché" % body.name)

# ---------------------------------------------------------------------------
# CL5 — Aucun bâtiment ne chevauche le point de spawn (origine XZ, distance > 10 m)
# Spec §Cas limites / erreurs point CL5
# Redondant avec B10 mais confirme explicitement la sécurité du spawn
# ---------------------------------------------------------------------------
func test_aucun_batiment_ne_chevauche_le_point_de_spawn() -> void:
	var city = load("res://scenes/city/city.tscn").instantiate()
	add_child_autofree(city)
	var bodies = city.get_children().filter(func(n): return n is StaticBody3D)
	for body in bodies:
		var dist_xz := Vector2(body.position.x, body.position.z).length()
		assert_true(dist_xz > MIN_SPAWN_DISTANCE,
			"Bâtiment '%s' chevauche la zone de spawn du joueur (dist XZ=%.2f)" % [body.name, dist_xz])
