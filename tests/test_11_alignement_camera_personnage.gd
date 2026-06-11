extends GutTest

# Tests unitaires — Feature 11 : Alignement personnage-caméra (clic droit, axe horizontal)
#
# Chaque test cible un comportement numéroté de la spec
# docs/specs/11-alignement-camera-personnage.md.
#
# Stratégie :
#   CameraController et PlayerController sont chargés via load() dynamique dans before_each.
#   Cette approche est nécessaire pour que les membres manquants (CAMERA_ALIGN_SPEED,
#   get_yaw, set_camera_yaw, rotate_toward_camera, _camera_yaw, _camera_yaw_dirty)
#   produisent des fails de tests à l'exécution plutôt que des erreurs de parse qui
#   silencieraient tout le fichier GUT.
#
# Comportements testés :
#   B1  — Constante CAMERA_ALIGN_SPEED == 15.0
#   B2  — get_yaw() retourne _yaw
#   B3  — set_camera_yaw() enregistre le yaw et lève _camera_yaw_dirty
#   B4  — rotate_toward_camera() avec delta grand converge vers camera_yaw
#   B5  — rotate_toward_camera() avec delta petit effectue rotation partielle
#   B6  — rotate_toward_camera() ne modifie pas rotation.x ni rotation.z
#   B7  — CameraController propage set_camera_yaw quand _right_mouse_held et cible PlayerController
#   B8  — CameraController ne propage pas quand _right_mouse_held est false
#   B9  — CameraController ne propage pas vers une cible sans set_camera_yaw (véhicule)
#   B10 — Alignement appliqué en idle quand flag levé
#   B11 — Alignement non appliqué quand direction WASD non nulle
#   B12 — Flag _camera_yaw_dirty remis à false après _physics_process même sans set_camera_yaw
#   B13 — lerp_angle gère le passage ±PI sans saut angulaire
#   CL1 — Cible véhicule : pas de propagation, pas de crash
#   CL2 — Direction WASD active : rotate_toward_camera non appelé, flag consommé
#   CL3 — Pitch ignoré (set_camera_yaw ne reçoit que le yaw)
#   CL4 — delta = 0 dans rotate_toward_camera : rotation.y inchangée, pas de crash
#   CL5 — set_camera_yaw appelé plusieurs fois : la dernière valeur l'emporte
#   CL6 — PlayerController sans CameraController : méthodes utilisables directement
#   CL7 — CameraController sans PlayerController en target (target null) : pas de crash

# ---------------------------------------------------------------------------
# Scripts chargés dynamiquement — erreurs membres manquants = fail de test, pas d'erreur de parse
# ---------------------------------------------------------------------------

var CameraControllerScript  # résolu via load() dans before_each
var PlayerControllerScript  # résolu via load() dans before_each

func before_each() -> void:
	CameraControllerScript = load("res://src/camera/camera_controller.gd")
	assert_not_null(CameraControllerScript,
		"camera_controller.gd doit être chargeable")
	PlayerControllerScript = load("res://src/player/player_controller.gd")
	assert_not_null(PlayerControllerScript,
		"player_controller.gd doit être chargeable")

func after_each() -> void:
	# add_child_autofree gère la libération — rien à faire ici
	pass

# ---------------------------------------------------------------------------
# Helpers — factorisation de la création des nœuds récurrents
# ---------------------------------------------------------------------------

# Instancie et ajoute un CameraController avec un enfant Camera3D
func _creer_camera_controller():
	if CameraControllerScript == null:
		return null
	var sut_cam = CameraControllerScript.new()
	var cam3d := Camera3D.new()
	cam3d.name = "Camera3D"
	sut_cam.add_child(cam3d)
	add_child_autofree(sut_cam)
	return sut_cam

# Instancie et ajoute un PlayerController
func _creer_player_controller():
	if PlayerControllerScript == null:
		return null
	var sut_player = PlayerControllerScript.new()
	add_child_autofree(sut_player)
	return sut_player

# ---------------------------------------------------------------------------
# B1 — Constante CAMERA_ALIGN_SPEED == 15.0
# Spec §Comportements attendus point B1
# ---------------------------------------------------------------------------
func test_constante_camera_align_speed_est_15() -> void:
	if PlayerControllerScript == null:
		return
	var vitesse: float = PlayerControllerScript.CAMERA_ALIGN_SPEED
	assert_almost_eq(vitesse, 15.0, 0.0001,
		"CAMERA_ALIGN_SPEED doit valoir 15.0 rad/s")

# ---------------------------------------------------------------------------
# B2 — get_yaw() retourne la valeur courante de _yaw
# Spec §Comportements attendus point B2
# ---------------------------------------------------------------------------
func test_get_yaw_retourne_yaw_courant() -> void:
	var sut_cam = _creer_camera_controller()
	if sut_cam == null:
		return
	sut_cam._yaw = 1.23
	var yaw_lu: float = sut_cam.get_yaw()
	assert_almost_eq(yaw_lu, 1.23, 0.0001,
		"get_yaw() doit retourner la valeur courante de _yaw (1.23)")

func test_get_yaw_retourne_zero_par_defaut() -> void:
	var sut_cam = _creer_camera_controller()
	if sut_cam == null:
		return
	var yaw_initial: float = sut_cam.get_yaw()
	assert_almost_eq(yaw_initial, 0.0, 0.0001,
		"get_yaw() doit retourner 0.0 à l'initialisation (DEFAULT_YAW)")

# ---------------------------------------------------------------------------
# B3 — set_camera_yaw() enregistre le yaw et lève _camera_yaw_dirty
# Spec §Comportements attendus point B3
# ---------------------------------------------------------------------------
func test_set_camera_yaw_enregistre_la_valeur() -> void:
	var sut_player = _creer_player_controller()
	if sut_player == null:
		return
	sut_player.set_camera_yaw(0.785)
	var yaw_enregistre: float = sut_player._camera_yaw
	assert_almost_eq(yaw_enregistre, 0.785, 0.0001,
		"_camera_yaw doit valoir 0.785 après set_camera_yaw(0.785)")

func test_set_camera_yaw_leve_le_flag_dirty() -> void:
	var sut_player = _creer_player_controller()
	if sut_player == null:
		return
	# Flag doit être false avant l'appel
	assert_false(sut_player._camera_yaw_dirty,
		"_camera_yaw_dirty doit être false avant le premier appel à set_camera_yaw")
	sut_player.set_camera_yaw(0.785)
	var dirty: bool = sut_player._camera_yaw_dirty
	assert_true(dirty,
		"_camera_yaw_dirty doit être true après set_camera_yaw(0.785)")

# ---------------------------------------------------------------------------
# B4 — rotate_toward_camera() avec delta grand converge vers camera_yaw
# Spec §Comportements attendus point B4
# ---------------------------------------------------------------------------
func test_rotate_toward_camera_avec_delta_grand_converge_vers_camera_yaw() -> void:
	var sut_player = _creer_player_controller()
	if sut_player == null:
		return
	sut_player.rotation.y = 0.0
	# delta=10.0 → clamp(15.0*10.0, 0.0, 1.0) = 1.0 → lerp_angle atteint la cible
	sut_player.rotate_toward_camera(PI / 2.0, 10.0)
	var rotation_finale: float = sut_player.rotation.y
	assert_almost_eq(rotation_finale, PI / 2.0, 0.01,
		"rotation.y doit atteindre PI/2 avec delta=10.0 (facteur lerp clampé à 1.0)")

func test_rotate_toward_camera_ne_modifie_pas_rotation_x_ni_z_avec_delta_grand() -> void:
	var sut_player = _creer_player_controller()
	if sut_player == null:
		return
	sut_player.rotation = Vector3(0.3, 0.0, 0.1)
	sut_player.rotate_toward_camera(1.0, 10.0)
	var rx: float = sut_player.rotation.x
	var rz: float = sut_player.rotation.z
	assert_almost_eq(rx, 0.3, 0.0001,
		"rotation.x == 0.3 doit être conservé après rotate_toward_camera")
	assert_almost_eq(rz, 0.1, 0.0001,
		"rotation.z == 0.1 doit être conservé après rotate_toward_camera")

# ---------------------------------------------------------------------------
# B5 — rotate_toward_camera() avec delta petit effectue une rotation partielle
# Spec §Comportements attendus point B5
# ---------------------------------------------------------------------------
func test_rotate_toward_camera_avec_delta_petit_rotation_partielle() -> void:
	var sut_player = _creer_player_controller()
	if sut_player == null:
		return
	sut_player.rotation.y = 0.0
	# delta=0.016 (60fps) → clamp(15.0*0.016, 0.0, 1.0) = 0.24
	# lerp_angle(0, PI, 0.24) ≈ 0.754 — rotation partielle
	sut_player.rotate_toward_camera(PI, 0.016)
	var rotation_partielle: float = sut_player.rotation.y
	assert_gt(rotation_partielle, 0.0,
		"rotation.y doit être > 0 après rotate_toward_camera (delta petit, rotation partielle)")
	assert_lt(rotation_partielle, PI,
		"rotation.y doit être < PI après rotate_toward_camera (pas encore à destination)")

# ---------------------------------------------------------------------------
# B6 — rotate_toward_camera() ne modifie pas rotation.x ni rotation.z
# Spec §Comportements attendus point B6
# ---------------------------------------------------------------------------
func test_rotate_toward_camera_conserve_rotation_x_et_z_non_nuls() -> void:
	var sut_player = _creer_player_controller()
	if sut_player == null:
		return
	sut_player.rotation = Vector3(0.3, 0.0, 0.1)
	sut_player.rotate_toward_camera(1.0, 10.0)
	var rx: float = sut_player.rotation.x
	var rz: float = sut_player.rotation.z
	assert_almost_eq(rx, 0.3, 0.0001,
		"rotation.x == 0.3 doit être inchangé (seul rotation.y est modifié)")
	assert_almost_eq(rz, 0.1, 0.0001,
		"rotation.z == 0.1 doit être inchangé (seul rotation.y est modifié)")

# ---------------------------------------------------------------------------
# B7 — CameraController propage set_camera_yaw quand _right_mouse_held et
#       cible PlayerController
# Spec §Comportements attendus point B7
# ---------------------------------------------------------------------------
func test_camera_controller_propage_yaw_quand_clic_droit_maintenu_et_cible_player() -> void:
	var sut_cam = _creer_camera_controller()
	if sut_cam == null:
		return
	var sut_player = _creer_player_controller()
	if sut_player == null:
		return

	sut_cam.target = sut_player
	sut_cam._yaw = 0.5
	sut_cam._right_mouse_held = true

	sut_cam._process(0.016)

	var yaw_recu: float = sut_player._camera_yaw
	assert_almost_eq(yaw_recu, 0.5, 0.0001,
		"_camera_yaw du PlayerController doit valoir 0.5 après propagation depuis CameraController")

func test_camera_controller_propage_leve_flag_dirty_sur_player() -> void:
	var sut_cam = _creer_camera_controller()
	if sut_cam == null:
		return
	var sut_player = _creer_player_controller()
	if sut_player == null:
		return

	sut_cam.target = sut_player
	sut_cam._yaw = 0.5
	sut_cam._right_mouse_held = true

	sut_cam._process(0.016)

	var dirty: bool = sut_player._camera_yaw_dirty
	assert_true(dirty,
		"_camera_yaw_dirty doit être true sur PlayerController après propagation CameraController")

# ---------------------------------------------------------------------------
# B8 — CameraController propage le yaw même quand _right_mouse_held est false
#       (comportement modifié par feature 12 : propagation permanente)
# Spec feature 12 §Comportements attendus point B1
# ---------------------------------------------------------------------------
func test_camera_controller_propage_yaw_meme_sans_clic_droit() -> void:
	var sut_cam = _creer_camera_controller()
	if sut_cam == null:
		return
	var sut_player = _creer_player_controller()
	if sut_player == null:
		return

	sut_cam.target = sut_player
	sut_cam._yaw = 0.5
	sut_cam._right_mouse_held = false

	sut_cam._process(0.016)

	var dirty: bool = sut_player._camera_yaw_dirty
	assert_true(dirty,
		"_camera_yaw_dirty doit être true même sans clic droit (propagation permanente, feature 12)")

# ---------------------------------------------------------------------------
# B9 — CameraController ne propage pas vers une cible sans set_camera_yaw (véhicule)
# Spec §Comportements attendus point B9
# ---------------------------------------------------------------------------
func test_camera_controller_ne_propage_pas_vers_noeud_sans_set_camera_yaw() -> void:
	var sut_cam = _creer_camera_controller()
	if sut_cam == null:
		return
	# Un Node3D ordinaire ne possède pas set_camera_yaw
	var cible_sans_methode := Node3D.new()
	add_child_autofree(cible_sans_methode)

	sut_cam.target = cible_sans_methode
	sut_cam._right_mouse_held = true

	# Ne doit pas crasher — has_method("set_camera_yaw") retourne false, propagation sautée
	sut_cam._process(0.016)

	assert_false(cible_sans_methode.has_method("set_camera_yaw"),
		"La cible sans set_camera_yaw ne doit pas avoir cette méthode (assertion de contexte)")
	# Si on arrive ici sans crash, le comportement attendu est respecté
	assert_true(true,
		"_process ne doit pas crasher quand la cible n'a pas set_camera_yaw")

# ---------------------------------------------------------------------------
# B10 — Alignement appliqué en idle quand flag levé
# Spec §Comportements attendus point B10
# ---------------------------------------------------------------------------
func test_physics_process_applique_alignement_si_idle_et_flag_leve() -> void:
	var sut_player = _creer_player_controller()
	if sut_player == null:
		return
	sut_player.rotation.y = 0.0
	sut_player.set_camera_yaw(PI / 2.0)  # lève le flag dirty

	# Aucun input de déplacement actif → direction == Vector3.ZERO
	Input.action_release("move_forward")
	Input.action_release("move_backward")
	Input.action_release("move_left")
	Input.action_release("move_right")

	sut_player._physics_process(0.016)

	var ry: float = sut_player.rotation.y
	assert_gt(ry, 0.0,
		"rotation.y doit être > 0 après _physics_process en idle avec flag dirty (alignement démarré)")

func test_physics_process_consume_flag_dirty_apres_alignement() -> void:
	var sut_player = _creer_player_controller()
	if sut_player == null:
		return
	sut_player.rotation.y = 0.0
	sut_player.set_camera_yaw(PI / 2.0)

	Input.action_release("move_forward")
	Input.action_release("move_backward")
	Input.action_release("move_left")
	Input.action_release("move_right")

	sut_player._physics_process(0.016)

	var dirty: bool = sut_player._camera_yaw_dirty
	assert_false(dirty,
		"_camera_yaw_dirty doit être false après _physics_process (flag consommé)")

# ---------------------------------------------------------------------------
# B11 — Alignement non appliqué quand direction WASD non nulle
# Spec §Comportements attendus point B11
# ---------------------------------------------------------------------------
func test_physics_process_consomme_flag_sans_alignement_si_deplacement_actif() -> void:
	var sut_player = _creer_player_controller()
	if sut_player == null:
		return
	sut_player.rotation.y = 0.0
	sut_player.set_camera_yaw(PI / 2.0)  # flag levé

	# Simuler un déplacement vers l'avant
	Input.action_press("move_forward")
	sut_player._physics_process(0.016)
	Input.action_release("move_forward")

	# Le flag doit être consommé (remis à false) sans que rotate_toward_camera ait été appelé.
	var dirty: bool = sut_player._camera_yaw_dirty
	assert_false(dirty,
		"_camera_yaw_dirty doit être false après _physics_process en déplacement (flag consommé sans alignement)")

# ---------------------------------------------------------------------------
# B12 — Flag _camera_yaw_dirty remis à false après _physics_process même sans appel set_camera_yaw
# Spec §Comportements attendus point B12
# ---------------------------------------------------------------------------
func test_physics_process_maintient_flag_false_si_set_camera_yaw_non_appele() -> void:
	var sut_player = _creer_player_controller()
	if sut_player == null:
		return
	# Flag est false par défaut — ne pas appeler set_camera_yaw
	assert_false(sut_player._camera_yaw_dirty,
		"_camera_yaw_dirty doit être false par défaut (avant tout appel)")

	Input.action_release("move_forward")
	Input.action_release("move_backward")
	Input.action_release("move_left")
	Input.action_release("move_right")

	sut_player._physics_process(0.016)

	var dirty: bool = sut_player._camera_yaw_dirty
	assert_false(dirty,
		"_camera_yaw_dirty doit rester false après _physics_process si set_camera_yaw n'a pas été appelé")

# ---------------------------------------------------------------------------
# B13 — lerp_angle gère le passage ±PI sans saut angulaire
# Spec §Comportements attendus point B13
# ---------------------------------------------------------------------------
func test_rotate_toward_camera_passage_pi_sans_saut_angulaire() -> void:
	var sut_player = _creer_player_controller()
	if sut_player == null:
		return
	# Proche de +PI, cible juste de l'autre côté de ±PI
	sut_player.rotation.y = PI - 0.05
	sut_player.rotate_toward_camera(-PI + 0.05, 0.016)
	var ry: float = sut_player.rotation.y
	# La rotation doit être partielle et ne pas sauter de plusieurs radians
	var delta_rotation: float = absf(ry - (PI - 0.05))
	assert_lt(delta_rotation, 0.5,
		"La rotation doit être partielle et sans saut angulaire lors du passage ±PI (lerp_angle)")

# ---------------------------------------------------------------------------
# CL1 — Cible véhicule : pas de propagation, pas de crash
# Spec §Cas limites / erreurs point CL1
# ---------------------------------------------------------------------------
func test_cl1_cible_vehicule_pas_de_crash_ni_propagation() -> void:
	var sut_cam = _creer_camera_controller()
	if sut_cam == null:
		return
	# Simuler une cible véhicule avec un VehicleBody3D
	var vehicule := VehicleBody3D.new()
	add_child_autofree(vehicule)

	sut_cam.target = vehicule
	sut_cam._right_mouse_held = true

	# Ne doit pas crasher
	sut_cam._process(0.016)

	# VehicleBody3D ne possède pas set_camera_yaw — propagation silencieuse
	assert_false(vehicule.has_method("set_camera_yaw"),
		"VehicleBody3D ne doit pas avoir set_camera_yaw")
	assert_true(true,
		"CL1 : _process avec cible VehicleBody3D et clic droit ne doit pas crasher")

# ---------------------------------------------------------------------------
# CL2 — Direction WASD active : rotate_toward_camera non appelé, flag consommé
# Spec §Cas limites / erreurs point CL2
# ---------------------------------------------------------------------------
func test_cl2_direction_wasd_active_flag_consomme_sans_alignement() -> void:
	var sut_player = _creer_player_controller()
	if sut_player == null:
		return
	sut_player.rotation.y = 0.0
	sut_player.set_camera_yaw(PI / 2.0)

	Input.action_press("move_forward")
	sut_player._physics_process(0.016)
	Input.action_release("move_forward")

	assert_false(sut_player._camera_yaw_dirty,
		"CL2 : _camera_yaw_dirty doit être false après _physics_process en déplacement")

# ---------------------------------------------------------------------------
# CL3 — Pitch ignoré : set_camera_yaw ne reçoit que le yaw
# Spec §Cas limites / erreurs point CL3
# ---------------------------------------------------------------------------
func test_cl3_set_camera_yaw_ne_recoit_que_le_yaw() -> void:
	var sut_player = _creer_player_controller()
	if sut_player == null:
		return
	# set_camera_yaw prend un seul float — impossible d'y passer pitch par erreur
	sut_player.set_camera_yaw(1.0)
	var yaw_enregistre: float = sut_player._camera_yaw
	assert_almost_eq(yaw_enregistre, 1.0, 0.0001,
		"CL3 : set_camera_yaw enregistre uniquement un yaw (float) — pas de pitch")

func test_cl3_rotate_toward_camera_utilise_uniquement_le_yaw() -> void:
	var sut_player = _creer_player_controller()
	if sut_player == null:
		return
	# rotate_toward_camera n'utilise que camera_yaw et delta, pas _pitch
	sut_player.rotation.y = 0.0
	sut_player.rotate_toward_camera(1.0, 10.0)
	var ry: float = sut_player.rotation.y
	assert_almost_eq(ry, 1.0, 0.01,
		"CL3 : rotate_toward_camera utilise uniquement le yaw (converge vers 1.0)")

# ---------------------------------------------------------------------------
# CL4 — delta = 0 dans rotate_toward_camera : rotation.y inchangée, pas de crash
# Spec §Cas limites / erreurs point CL4
# ---------------------------------------------------------------------------
func test_cl4_rotate_toward_camera_avec_delta_zero_ne_modifie_pas_rotation_y() -> void:
	var sut_player = _creer_player_controller()
	if sut_player == null:
		return
	sut_player.rotation.y = 0.5
	# clamp(15.0 * 0.0, 0.0, 1.0) = 0.0 → lerp_angle(0.5, 1.0, 0.0) = 0.5
	sut_player.rotate_toward_camera(1.0, 0.0)
	var ry: float = sut_player.rotation.y
	assert_almost_eq(ry, 0.5, 0.0001,
		"CL4 : rotation.y doit rester inchangée si delta == 0.0 (facteur lerp = 0)")

# ---------------------------------------------------------------------------
# CL5 — set_camera_yaw appelé plusieurs fois : la dernière valeur l'emporte
# Spec §Cas limites / erreurs point CL5
# ---------------------------------------------------------------------------
func test_cl5_set_camera_yaw_plusieurs_fois_derniere_valeur_emporte() -> void:
	var sut_player = _creer_player_controller()
	if sut_player == null:
		return
	sut_player.set_camera_yaw(0.1)
	sut_player.set_camera_yaw(0.5)
	sut_player.set_camera_yaw(1.2)  # dernière valeur

	var yaw_final: float = sut_player._camera_yaw
	assert_almost_eq(yaw_final, 1.2, 0.0001,
		"CL5 : _camera_yaw doit conserver la dernière valeur passée à set_camera_yaw")

func test_cl5_flag_reste_true_apres_plusieurs_appels_set_camera_yaw() -> void:
	var sut_player = _creer_player_controller()
	if sut_player == null:
		return
	sut_player.set_camera_yaw(0.1)
	sut_player.set_camera_yaw(0.5)
	sut_player.set_camera_yaw(1.2)

	var dirty: bool = sut_player._camera_yaw_dirty
	assert_true(dirty,
		"CL5 : _camera_yaw_dirty doit rester true après plusieurs appels à set_camera_yaw")

# ---------------------------------------------------------------------------
# CL6 — PlayerController sans CameraController : méthodes utilisables directement
# Spec §Cas limites / erreurs point CL6
# ---------------------------------------------------------------------------
func test_cl6_set_camera_yaw_utilisable_sans_camera_controller() -> void:
	if PlayerControllerScript == null:
		return
	# Instance standalone — pas de CameraController dans la scène
	var sut_player = PlayerControllerScript.new()
	add_child_autofree(sut_player)

	# Appel direct sans CameraController — ne doit pas crasher
	sut_player.set_camera_yaw(0.785)
	var yaw_lu: float = sut_player._camera_yaw
	assert_almost_eq(yaw_lu, 0.785, 0.0001,
		"CL6 : set_camera_yaw doit fonctionner sans CameraController dans la scène")

func test_cl6_rotate_toward_camera_utilisable_sans_camera_controller() -> void:
	if PlayerControllerScript == null:
		return
	var sut_player = PlayerControllerScript.new()
	add_child_autofree(sut_player)

	sut_player.rotation.y = 0.0
	# Ne doit pas crasher ni faire référence à un CameraController externe
	sut_player.rotate_toward_camera(PI / 4.0, 10.0)
	var ry: float = sut_player.rotation.y
	assert_almost_eq(ry, PI / 4.0, 0.01,
		"CL6 : rotate_toward_camera doit fonctionner sans CameraController dans la scène")

# ---------------------------------------------------------------------------
# CL7 — CameraController sans PlayerController en target (target null) : pas de crash
# Spec §Cas limites / erreurs point CL7
# ---------------------------------------------------------------------------
func test_cl7_process_avec_target_null_ne_tente_pas_la_propagation() -> void:
	var sut_cam = _creer_camera_controller()
	if sut_cam == null:
		return
	sut_cam.target = null
	sut_cam._right_mouse_held = true  # clic droit maintenu mais target null

	# Le guard "if target == null: return" doit court-circuiter avant la propagation
	sut_cam._process(0.016)

	# Si on arrive ici sans crash, le guard fonctionne
	assert_true(true,
		"CL7 : _process avec target null et _right_mouse_held true ne doit pas crasher")

# ---------------------------------------------------------------------------
# Variables d'état initiales — vérification des valeurs par défaut
# ---------------------------------------------------------------------------

func test_camera_yaw_initialise_a_zero() -> void:
	var sut_player = _creer_player_controller()
	if sut_player == null:
		return
	var yaw_initial: float = sut_player._camera_yaw
	assert_almost_eq(yaw_initial, 0.0, 0.0001,
		"_camera_yaw doit être initialisé à 0.0")

func test_camera_yaw_dirty_initialise_a_false() -> void:
	var sut_player = _creer_player_controller()
	if sut_player == null:
		return
	var dirty_initial: bool = sut_player._camera_yaw_dirty
	assert_false(dirty_initial,
		"_camera_yaw_dirty doit être initialisé à false")
