extends GutTest

# Tests unitaires — Feature 04 : Caméra troisième personne suivant le joueur
#
# Chaque test cible un comportement numéroté de la spec docs/specs/04-camera-tp.md.
#
# Stratégie :
#   Les tests B1 à B7 et CL1 à CL5 exercent directement CameraController
#   sans charger main.tscn (sauf CL2 qui nécessite un enfant Camera3D).
#   Les tests B8, B9, B10 chargent main.tscn pour vérifier la structure de scène.
#
# Note (changement UX zoom — feature 09) :
#   ZOOM_DISTANCES passe à [3.0, 4.5, 6.708]. La position par défaut change :
#   dist=3.0, pitch=0.4636, yaw=0 → orbit ≈ Vector3(0, 1.342, 2.683).
#   Les tests B4/B5/B6/B7/CL2/CL3/CL5 ont été mis à jour en conséquence.
#
# En phase rouge : camera_controller.gd n'existe pas encore.
#   Le preload en tête de fichier provoquera une erreur de chargement GUT — attendu.

# ---------------------------------------------------------------------------
# Préchargement du module sous test
# ---------------------------------------------------------------------------
const CameraControllerScript = preload("res://src/camera/camera_controller.gd")

# ---------------------------------------------------------------------------
# SUT CameraController — instancié pour chaque test unitaire
# ---------------------------------------------------------------------------

var sut  # CameraController

func before_each() -> void:
	sut = CameraControllerScript.new()
	add_child_autofree(sut)

func after_each() -> void:
	# add_child_autofree s'occupe du free — pas de free() manuel nécessaire
	pass

# ---------------------------------------------------------------------------
# B1 — CameraController.OFFSET == Vector3(0, 3, 6)
# Spec §Comportements attendus point B1
# ---------------------------------------------------------------------------
func test_la_constante_offset_est_vector3_0_3_6() -> void:
	assert_eq(CameraControllerScript.OFFSET, Vector3(0.0, 3.0, 6.0))

# ---------------------------------------------------------------------------
# B2 — CameraController.EYE_HEIGHT == 1.6
# Spec §Comportements attendus point B2
# ---------------------------------------------------------------------------
func test_la_constante_eye_height_est_1_6() -> void:
	assert_almost_eq(CameraControllerScript.EYE_HEIGHT, 1.6, 0.0001)

# ---------------------------------------------------------------------------
# B3 — target null : _process ne modifie pas global_position
# Spec §Comportements attendus point B3
# ---------------------------------------------------------------------------
func test_process_avec_target_null_ne_modifie_pas_global_position() -> void:
	sut.target = null
	var position_initiale: Vector3 = sut.global_position
	sut._process(0.016)
	assert_eq(sut.global_position, position_initiale,
		"global_position ne doit pas changer si target est null")

# ---------------------------------------------------------------------------
# B4 — target à l'origine : après _process, global_position ≈ orbit par défaut
# Spec §Comportements attendus point B4
# Mis à jour (changement UX zoom) :
#   dist=ZOOM_DISTANCES[0]=3.0, pitch=DEFAULT_PITCH≈0.4636, yaw=0
#   → orbit ≈ Vector3(0, 1.342, 2.683)  (tolérance 0.05)
# ---------------------------------------------------------------------------
func test_process_avec_target_a_l_origine_positionne_la_camera_a_orbit_defaut() -> void:
	var cible := Node3D.new()
	add_child_autofree(cible)
	cible.global_position = Vector3(0.0, 0.0, 0.0)

	# Ajouter un enfant Camera3D pour éviter l'erreur $Camera3D manquant
	var cam := Camera3D.new()
	cam.name = "Camera3D"
	sut.add_child(cam)

	sut.target = cible
	sut._right_mouse_held = true
	sut._process(0.016)

	assert_almost_eq(sut.global_position.x, 0.0, 0.05)
	assert_almost_eq(sut.global_position.y, 1.342, 0.05)
	assert_almost_eq(sut.global_position.z, 2.683, 0.05)

# ---------------------------------------------------------------------------
# B5 — target à (10, 0, -5) : après _process, global_position ≈ (10, 1.342, -2.317)
# Spec §Comportements attendus point B5
# Mis à jour (changement UX zoom) :
#   target=(10,0,-5), orbit≈(0, 1.342, 2.683) → position=(10, 1.342, -5+2.683)=(10, 1.342, -2.317)
# ---------------------------------------------------------------------------
func test_process_avec_target_deplace_positionne_la_camera_a_target_plus_orbit() -> void:
	var cible := Node3D.new()
	add_child_autofree(cible)
	cible.global_position = Vector3(10.0, 0.0, -5.0)

	var cam := Camera3D.new()
	cam.name = "Camera3D"
	sut.add_child(cam)

	sut.target = cible
	sut._right_mouse_held = true
	sut._process(0.016)

	assert_almost_eq(sut.global_position.x, 10.0, 0.05)
	assert_almost_eq(sut.global_position.y, 1.342, 0.05)
	assert_almost_eq(sut.global_position.z, -2.317, 0.05)

# ---------------------------------------------------------------------------
# B6 — Orientation de Camera3D vers la tête de la cible
# Spec §Comportements attendus point B6
# L'axe -Z local de Camera3D doit pointer vers Vector3(0, EYE_HEIGHT, 0)
# depuis la position orbit par défaut ≈ Vector3(0, 1.342, 2.683) après look_at.
# Concrètement : basis.z.normalized() ≈ opposé de (look_target - cam_pos).normalized()
# Mis à jour (changement UX zoom) : position_cam ≈ Vector3(0, 1.342, 2.683).
# ---------------------------------------------------------------------------
func test_process_oriente_camera3d_vers_la_tete_de_la_cible() -> void:
	var cible := Node3D.new()
	add_child_autofree(cible)
	cible.global_position = Vector3(0.0, 0.0, 0.0)

	var cam := Camera3D.new()
	cam.name = "Camera3D"
	sut.add_child(cam)

	sut.target = cible
	sut._right_mouse_held = true
	sut._process(0.016)

	# Position finale de la caméra rig (orbit par défaut) ≈ Vector3(0, 1.342, 2.683)
	# Point visé : Vector3(0, EYE_HEIGHT, 0) = Vector3(0, 1.6, 0)
	# Direction attendue de -Z : (point_vise - position_cam).normalized()
	var position_cam := Vector3(0.0, 1.342, 2.683)
	var point_vise := Vector3(0.0, CameraControllerScript.EYE_HEIGHT, 0.0)
	var direction_attendue := (point_vise - position_cam).normalized()

	# basis.z doit être l'opposé de cette direction (convention Godot : -Z = devant)
	var basis_z := cam.global_transform.basis.z.normalized()

	assert_almost_eq(basis_z.x, -direction_attendue.x, 0.02)
	assert_almost_eq(basis_z.y, -direction_attendue.y, 0.02)
	assert_almost_eq(basis_z.z, -direction_attendue.z, 0.02)

# ---------------------------------------------------------------------------
# B7 — Suivi instantané : déplacer la cible puis _process → global_position mis à jour
# Spec §Comportements attendus point B7
# Mis à jour (changement UX zoom) :
#   orbit par défaut ≈ (0, 1.342, 2.683) → après target=(5,0,0) : position ≈ (5, 1.342, 2.683)
# ---------------------------------------------------------------------------
func test_process_suit_instantanement_un_deplacement_de_la_cible() -> void:
	var cible := Node3D.new()
	add_child_autofree(cible)
	cible.global_position = Vector3(0.0, 0.0, 0.0)

	var cam := Camera3D.new()
	cam.name = "Camera3D"
	sut.add_child(cam)

	sut.target = cible
	sut._right_mouse_held = true

	# Premier appel avec cible à l'origine
	sut._process(0.016)
	assert_almost_eq(sut.global_position.x, 0.0, 0.05)

	# Déplacer la cible vers (5, 0, 0)
	cible.global_position = Vector3(5.0, 0.0, 0.0)
	sut._process(0.016)

	# Pas de lerp — suivi rigide immédiat
	assert_almost_eq(sut.global_position.x, 5.0, 0.05)
	assert_almost_eq(sut.global_position.y, 1.342, 0.05)
	assert_almost_eq(sut.global_position.z, 2.683, 0.05)

# ---------------------------------------------------------------------------
# B8 — main.tscn contient un nœud CameraRig de classe CameraController
# Spec §Comportements attendus point B8
# ---------------------------------------------------------------------------
func test_main_tscn_contient_un_noeud_camera_rig_de_classe_camera_controller() -> void:
	var scene = load("res://main.tscn").instantiate()
	add_child_autofree(scene)
	var camera_rig = scene.get_node_or_null("CameraRig")
	assert_not_null(camera_rig, "Le nœud CameraRig doit exister dans main.tscn")
	assert_true(camera_rig is CameraController,
		"Le nœud CameraRig doit être de type CameraController")

# ---------------------------------------------------------------------------
# B9 — main.tscn CameraRig a un enfant Camera3D avec current = true
# Spec §Comportements attendus point B9
# ---------------------------------------------------------------------------
func test_main_tscn_camera_rig_possede_un_enfant_camera3d_actif() -> void:
	var scene = load("res://main.tscn").instantiate()
	add_child_autofree(scene)
	var cam = scene.get_node_or_null("CameraRig/Camera3D")
	assert_not_null(cam, "Le nœud CameraRig/Camera3D doit exister dans main.tscn")
	assert_true(cam is Camera3D,
		"CameraRig/Camera3D doit être une Camera3D")
	assert_true(cam.current,
		"La Camera3D de CameraRig doit avoir current = true")

# ---------------------------------------------------------------------------
# B10 — main.tscn ne contient pas de Camera3D enfant direct de Main
# Spec §Comportements attendus point B10
# La caméra fixe feature 02 doit avoir été supprimée.
# ---------------------------------------------------------------------------
func test_main_tscn_ne_contient_pas_de_camera3d_enfant_direct_de_main() -> void:
	var scene = load("res://main.tscn").instantiate()
	add_child_autofree(scene)
	var camera_fixe = scene.get_node_or_null("Camera3D")
	assert_null(camera_fixe,
		"Aucun nœud Camera3D enfant direct de Main ne doit subsister (caméra fixe supprimée)")

# ---------------------------------------------------------------------------
# CL1 — target null : _process retourne immédiatement sans toucher global_position
# Spec §Cas limites / erreurs point CL1
# ---------------------------------------------------------------------------
func test_process_avec_target_null_retour_immediat_sans_exception() -> void:
	# Positionner le rig à une position non nulle pour détecter toute modification
	sut.global_position = Vector3(1.0, 2.0, 3.0)
	sut.target = null

	# Ne doit pas crasher
	sut._process(0.016)

	# global_position doit être inchangé
	assert_almost_eq(sut.global_position.x, 1.0, 0.0001)
	assert_almost_eq(sut.global_position.y, 2.0, 0.0001)
	assert_almost_eq(sut.global_position.z, 3.0, 0.0001)

# ---------------------------------------------------------------------------
# CL2 — Cible à la même position que CameraRig : look_at ne crashe pas
# Spec §Cas limites / erreurs point CL2
# Avec orbit non nul, le point visé (0, EYE_HEIGHT, 0) est toujours distinct
# de la position de la caméra ≈ (0, 1.342, 2.683) — pas de vecteur nul dans look_at.
# Mis à jour (changement UX zoom) : position orbit ≈ (0, 1.342, 2.683).
# ---------------------------------------------------------------------------
func test_process_cible_meme_position_que_rig_ne_crashe_pas() -> void:
	var cible := Node3D.new()
	add_child_autofree(cible)
	# La cible sera à (0,0,0), le rig se positionnera à orbit ≈ (0, 1.342, 2.683)
	# Le point visé sera (0, 1.6, 0) ≠ (0, 1.342, 2.683) — look_at valide
	cible.global_position = Vector3(0.0, 0.0, 0.0)

	var cam := Camera3D.new()
	cam.name = "Camera3D"
	sut.add_child(cam)

	sut.target = cible
	sut._right_mouse_held = true

	# Ne doit pas crasher
	sut._process(0.016)

	# La caméra rig est bien positionnée à orbit par défaut
	assert_almost_eq(sut.global_position.y, 1.342, 0.05)
	assert_almost_eq(sut.global_position.z, 2.683, 0.05)

# ---------------------------------------------------------------------------
# CL3 — _process(0.0) : delta nul ne produit pas d'erreur
# Spec §Cas limites / erreurs point CL3
# Le suivi rigide ne dépend pas de delta.
# Mis à jour (changement UX zoom) :
#   target=(2,0,-3), orbit≈(0, 1.342, 2.683) → position=(2, 1.342, -3+2.683)=(2, 1.342, -0.317)
# ---------------------------------------------------------------------------
func test_process_avec_delta_nul_ne_produit_pas_d_erreur() -> void:
	var cible := Node3D.new()
	add_child_autofree(cible)
	cible.global_position = Vector3(2.0, 0.0, -3.0)

	var cam := Camera3D.new()
	cam.name = "Camera3D"
	sut.add_child(cam)

	sut.target = cible

	# Ne doit pas crasher avec delta == 0.0
	sut._process(0.0)

	# Le résultat est identique à delta normal : position = target + orbit
	assert_almost_eq(sut.global_position.x, 2.0, 0.05)
	assert_almost_eq(sut.global_position.y, 1.342, 0.05)
	assert_almost_eq(sut.global_position.z, -0.317, 0.05)

# ---------------------------------------------------------------------------
# CL4 — Une seule Camera3D avec current = true dans main.tscn
# Spec §Cas limites / erreurs point CL4
# ---------------------------------------------------------------------------
func test_main_tscn_ne_contient_qu_une_seule_camera3d_avec_current_true() -> void:
	var scene = load("res://main.tscn").instantiate()
	add_child_autofree(scene)

	var cameras_actives := _compter_cameras_actives(scene, 0)

	assert_eq(cameras_actives, 1,
		"Il doit y avoir exactement une Camera3D avec current = true dans la scène")

# Fonction récursive auxiliaire — parcourt l'arbre et compte les Camera3D actives
func _compter_cameras_actives(noeud: Node, compteur: int) -> int:
	if noeud is Camera3D and noeud.current:
		compteur += 1
	for enfant in noeud.get_children():
		compteur = _compter_cameras_actives(enfant, compteur)
	return compteur

# ---------------------------------------------------------------------------
# CL5 — target assigné à un nœud hors de l'arbre : positionne à orbit par défaut sans crash
# Spec §Cas limites / erreurs point CL5
# Un Node3D orphelin (non ajouté via add_child) a position == Vector3(0,0,0)
# Mis à jour (changement UX zoom) : position orbit ≈ (0, 1.342, 2.683).
# ---------------------------------------------------------------------------
func test_process_avec_target_hors_scene_tree_positionne_a_orbit_sans_crash() -> void:
	# Créer un nœud sans add_child — il est "orphelin"
	var cible_orpheline := Node3D.new()
	# NE PAS appeler add_child — nœud hors arbre

	var cam := Camera3D.new()
	cam.name = "Camera3D"
	sut.add_child(cam)

	sut.target = cible_orpheline
	sut._right_mouse_held = true

	# Ne doit pas crasher
	sut._process(0.016)

	# position de l'orphelin est (0,0,0) — la caméra se place à orbit par défaut
	assert_almost_eq(sut.global_position.x, 0.0, 0.05)
	assert_almost_eq(sut.global_position.y, 1.342, 0.05)
	assert_almost_eq(sut.global_position.z, 2.683, 0.05)

	# Libération manuelle car pas de add_child_autofree
	cible_orpheline.free()

# ---------------------------------------------------------------------------
# B_TARGET — main.tscn : CameraRig.target est non null et référence le nœud Player
# Couvre le risque de résolution de NodePath échouée au runtime (target resterait null).
# ---------------------------------------------------------------------------
func test_main_tscn_camera_rig_target_est_le_noeud_player() -> void:
	var scene = load("res://main.tscn").instantiate()
	add_child_autofree(scene)

	var camera_rig = scene.get_node_or_null("CameraRig")
	assert_not_null(camera_rig,
		"Le nœud CameraRig doit exister dans main.tscn")

	var target = camera_rig.target
	assert_not_null(target,
		"CameraRig.target ne doit pas être null — la résolution du NodePath a échoué")

	var player = scene.get_node_or_null("Player")
	assert_not_null(player,
		"Le nœud Player doit exister dans main.tscn")

	assert_true(target == player,
		"CameraRig.target doit référencer le nœud Player (même instance)")
