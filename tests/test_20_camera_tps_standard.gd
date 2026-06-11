extends GutTest

# Tests unitaires — Feature 20 : Refonte caméra TPS standard (spring-back + suppression reset molette)
#
# Chaque test cible un comportement numéroté de la spec
# docs/specs/20-camera-tps-standard.md (B1–B15 et CL1–CL6).
#
# Stratégie :
#   CameraController est chargé via load() dynamique pour que l'absence de SPRING_RATE
#   produise un fail à l'exécution plutôt qu'une erreur de parse silencieuse.
#   Le pattern de setup est identique à test_09_camera_orbitale.gd :
#     - Instancier CameraController
#     - Ajouter un enfant Camera3D (requis pour $Camera3D.look_at dans _process)
#     - Créer des cibles Node3D ou CharacterBody3D dans l'arbre via add_child_autofree
#     - Appeler _process(delta) directement sans attendre des frames réelles
#
# En phase rouge : SPRING_RATE n'existe pas encore dans camera_controller.gd.
#   Les accès à CameraControllerScript.SPRING_RATE produiront une erreur GUT
#   (propriété inconnue) ce qui rendra les tests rouges — attendu.
#   La logique spring dans _process est également absente : _yaw ne convergera pas.

# ---------------------------------------------------------------------------
# Scripts chargés dynamiquement
# ---------------------------------------------------------------------------

var CameraControllerScript  # résolu dans before_each via load()
var PlayerControllerScript   # résolu dans before_each via load()

# ---------------------------------------------------------------------------
# SUT — instancié par chaque test via les helpers
# ---------------------------------------------------------------------------

var sut  # CameraController avec Camera3D enfant

func before_each() -> void:
	CameraControllerScript = load("res://src/camera/camera_controller.gd")
	assert_not_null(CameraControllerScript,
		"camera_controller.gd doit être chargeable")
	PlayerControllerScript = load("res://src/player/player_controller.gd")
	assert_not_null(PlayerControllerScript,
		"player_controller.gd doit être chargeable")

func after_each() -> void:
	# add_child_autofree gère la libération
	pass

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Instancie un CameraController avec un enfant Camera3D nommé "Camera3D"
func _creer_camera_controller():
	if CameraControllerScript == null:
		return null
	var cam_ctrl = CameraControllerScript.new()
	var cam3d := Camera3D.new()
	cam3d.name = "Camera3D"
	cam_ctrl.add_child(cam3d)
	add_child_autofree(cam_ctrl)
	return cam_ctrl

# Crée un Node3D cible dans l'arbre à la position donnée
func _creer_cible_node3d(pos: Vector3) -> Node3D:
	var cible := Node3D.new()
	add_child_autofree(cible)
	cible.global_position = pos
	return cible

# Crée un VehicleBody3D dans l'arbre
func _creer_vehicule() -> VehicleBody3D:
	var v := VehicleBody3D.new()
	add_child_autofree(v)
	return v

# Crée un InputEventMouseButton configuré
func _creer_event_bouton(index: int, appuye: bool) -> InputEventMouseButton:
	var ev := InputEventMouseButton.new()
	ev.button_index = index
	ev.pressed = appuye
	return ev

# Crée un InputEventMouseMotion avec un déplacement relatif
func _creer_event_mouvement(dx: float, dy: float) -> InputEventMouseMotion:
	var ev := InputEventMouseMotion.new()
	ev.relative = Vector2(dx, dy)
	return ev

# ---------------------------------------------------------------------------
# B1 — Constante SPRING_RATE présente et égale à 5.0
# Spec §Comportements attendus point B1
#
# CameraControllerScript.SPRING_RATE doit exister et valoir approximativement 5.0.
# En phase rouge : SPRING_RATE absent → accès à propriété inconnue → test rouge.
# ---------------------------------------------------------------------------
func test_B1_constante_spring_rate_presente_et_egale_a_5() -> void:
	if CameraControllerScript == null:
		return
	var taux: float = CameraControllerScript.SPRING_RATE
	assert_almost_eq(taux, 5.0, 0.0001,
		"B1 : SPRING_RATE doit exister sur la classe et valoir 5.0")

# ---------------------------------------------------------------------------
# B2 — Spring-back actif en mode normal : _yaw modifié après _process
# Spec §Comportements attendus point B2 (reformulé)
#
# Cible sans rotation → home_yaw = rotation.y = 0.
# _yaw initial = 1.0 (caméra décalée), _right_mouse_held = false.
# Après _process(0.016) : _yaw != 1.0 (spring a démarré la convergence vers 0).
# ---------------------------------------------------------------------------
func test_B2_spring_back_modifie_yaw_en_mode_normal() -> void:
	var sut_cam = _creer_camera_controller()
	if sut_cam == null:
		return
	var cible: Node3D = _creer_cible_node3d(Vector3.ZERO)
	# cible.rotation.y = 0.0 → home_yaw = 0.0
	sut_cam.target = cible
	sut_cam._yaw = 1.0
	sut_cam._right_mouse_held = false

	sut_cam._process(0.016)

	var yaw_apres: float = sut_cam._yaw
	assert_ne(yaw_apres, 1.0,
		"B2 : _yaw doit avoir été modifié par le spring-back (convergence vers home_yaw = 0 amorcée)")

# ---------------------------------------------------------------------------
# B3 — Spring-back : direction de convergence correcte
# Spec §Comportements attendus point B3
#
# Cible sans rotation → home_yaw = 0.
# _yaw = 1.0 (décalé), delta = 0.016, facteur = 5.0 * 0.016 = 0.08.
# diff = 0 - 1.0 = -1.0 → _yaw += -1.0 * 0.08 = 0.92 (converge vers 0 depuis 1.0).
# Vérification : sut_cam._yaw < 1.0 ET ≈ 0.92 (tolérance 0.01).
# ---------------------------------------------------------------------------
func test_B3_spring_back_direction_convergence_correcte() -> void:
	var sut_cam = _creer_camera_controller()
	if sut_cam == null:
		return
	var cible: Node3D = _creer_cible_node3d(Vector3.ZERO)
	sut_cam.target = cible
	sut_cam._yaw = 1.0
	sut_cam._right_mouse_held = false

	sut_cam._process(0.016)

	var yaw_apres: float = sut_cam._yaw
	assert_lt(yaw_apres, 1.0,
		"B3 : _yaw doit être < 1.0 (convergence vers 0 depuis 1.0 — diminue)")
	# diff = -1.0 * 0.08 → _yaw ≈ 0.92
	assert_almost_eq(yaw_apres, 0.92, 0.01,
		"B3 : _yaw ≈ 1.0 - 1.0*0.08 = 0.92 (tolérance 0.01)")

# ---------------------------------------------------------------------------
# B4 — Spring-back suspendu en mode orbite (_right_mouse_held = true)
# Spec §Comportements attendus point B4
#
# Même cible (home_yaw = PI). _yaw = 0.0. _right_mouse_held = true.
# Après _process(0.016) : _yaw ≈ 0.0 (spring inactif).
# ---------------------------------------------------------------------------
func test_B4_spring_back_suspendu_en_mode_orbite() -> void:
	var sut_cam = _creer_camera_controller()
	if sut_cam == null:
		return
	var cible: Node3D = _creer_cible_node3d(Vector3.ZERO)
	sut_cam.target = cible
	sut_cam._yaw = 0.0
	sut_cam._right_mouse_held = true

	sut_cam._process(0.016)

	var yaw_apres: float = sut_cam._yaw
	assert_almost_eq(yaw_apres, 0.0, 0.001,
		"B4 : _yaw doit rester ≈ 0.0 quand _right_mouse_held = true (spring suspendu en mode orbite)")

# ---------------------------------------------------------------------------
# B5 — home_yaw calculé depuis l'orientation de la cible
# Spec §Comportements attendus point B5
#
# Cible avec rotation.y = PI/2 → home_yaw = PI/2 + PI = 3PI/2 ≈ 4.712.
# _yaw = 0.0, _right_mouse_held = false.
# lerp_angle(0.0, 3PI/2, 0.08) : lerp_angle prend le chemin court.
# home_yaw_attendu = PI/2 + PI ≈ 4.712.
# lerp_angle(0, 4.712, 0.08) → chemin court de 0 vers -PI/2 (= 3PI/2 - 2PI) → _yaw diminue.
# Ou : lerp_angle(0, 3*PI/2, 0.08) : différence = 3PI/2, chemin court = -PI/2 → _yaw ≈ -0.126.
# Vérification simplifiée : _yaw != 0.0 (le spring a agi).
# ---------------------------------------------------------------------------
func test_B5_home_yaw_calcule_depuis_orientation_cible() -> void:
	var sut_cam = _creer_camera_controller()
	if sut_cam == null:
		return
	var cible: Node3D = _creer_cible_node3d(Vector3.ZERO)
	cible.rotation.y = PI / 2.0
	sut_cam.target = cible
	sut_cam._yaw = 0.0
	sut_cam._right_mouse_held = false

	sut_cam._process(0.016)

	var yaw_apres: float = sut_cam._yaw
	assert_ne(yaw_apres, 0.0,
		"B5 : _yaw doit avoir changé — home_yaw calculé depuis rotation.y = PI/2 de la cible")

# ---------------------------------------------------------------------------
# B6 — Spring-back avec delta grand : _yaw atteint home_yaw (convergence complète)
# Spec §Comportements attendus point B6
#
# Cible sans rotation → home_yaw = 0.
# _yaw = 1.0, delta = 100.0 → facteur clampé à 1.0 → convergence totale vers 0.
# Vérification : sut_cam._yaw ≈ 0.0 (tolérance 0.01).
# ---------------------------------------------------------------------------
func test_B6_spring_back_delta_grand_converge_completement() -> void:
	var sut_cam = _creer_camera_controller()
	if sut_cam == null:
		return
	var cible: Node3D = _creer_cible_node3d(Vector3.ZERO)
	sut_cam.target = cible
	sut_cam._yaw = 1.0
	sut_cam._right_mouse_held = false

	sut_cam._process(100.0)

	var yaw_apres: float = sut_cam._yaw
	assert_almost_eq(yaw_apres, 0.0, 0.01,
		"B6 : avec delta=100.0, facteur clampé à 1.0 → _yaw ≈ 0.0 (home_yaw de cible sans rotation)")

# ---------------------------------------------------------------------------
# B7 — Suppression du reset clic milieu : clic milieu n'a aucun effet
# Spec §Comportements attendus point B7
#
# _yaw = 1.57, _zoom_level = 2. Envoyer MOUSE_BUTTON_MIDDLE pressed.
# Vérification : _yaw ≈ 1.57 ET _zoom_level == 2 (aucune réinitialisation).
# En phase rouge : camera_controller.gd contient encore le bloc MOUSE_BUTTON_MIDDLE
#   qui réinitialise _yaw à 0.0 et _zoom_level à 0 → assertions échouent.
# ---------------------------------------------------------------------------
func test_B7_clic_milieu_n_a_aucun_effet() -> void:
	var sut_cam = _creer_camera_controller()
	if sut_cam == null:
		return
	sut_cam._yaw = 1.57
	sut_cam._pitch = 0.8
	sut_cam._zoom_level = 2

	var ev: InputEventMouseButton = _creer_event_bouton(MOUSE_BUTTON_MIDDLE, true)
	sut_cam._unhandled_input(ev)

	assert_almost_eq(sut_cam._yaw, 1.57, 0.0001,
		"B7 : clic milieu ne doit pas modifier _yaw (bloc MOUSE_BUTTON_MIDDLE supprimé en feature 20)")
	assert_eq(sut_cam._zoom_level, 2,
		"B7 : clic milieu ne doit pas modifier _zoom_level (feature 20)")
	assert_almost_eq(sut_cam._pitch, 0.8, 0.0001,
		"B7 : clic milieu ne doit pas modifier _pitch (feature 20)")

# ---------------------------------------------------------------------------
# B8 — Zoom molette conservé : molette bas depuis niveau 0 passe à niveau 1
# Spec §Comportements attendus point B8
#
# Non-régression : le bloc molette est conservé intact depuis feature 09.
# ---------------------------------------------------------------------------
func test_B8_molette_bas_depuis_niveau_0_passe_a_niveau_1() -> void:
	var sut_cam = _creer_camera_controller()
	if sut_cam == null:
		return
	sut_cam._zoom_level = 0

	var ev: InputEventMouseButton = _creer_event_bouton(MOUSE_BUTTON_WHEEL_DOWN, true)
	sut_cam._unhandled_input(ev)

	assert_eq(sut_cam._zoom_level, 1,
		"B8 : _zoom_level doit passer à 1 après molette bas depuis niveau 0 (non-régression feature 09)")

# ---------------------------------------------------------------------------
# B9 — Zoom molette conservé : molette haut depuis niveau 2 passe à niveau 1
# Spec §Comportements attendus point B9
# ---------------------------------------------------------------------------
func test_B9_molette_haut_depuis_niveau_2_passe_a_niveau_1() -> void:
	var sut_cam = _creer_camera_controller()
	if sut_cam == null:
		return
	sut_cam._zoom_level = 2

	var ev: InputEventMouseButton = _creer_event_bouton(MOUSE_BUTTON_WHEEL_UP, true)
	sut_cam._unhandled_input(ev)

	assert_eq(sut_cam._zoom_level, 1,
		"B9 : _zoom_level doit passer à 1 après molette haut depuis niveau 2 (non-régression feature 09)")

# ---------------------------------------------------------------------------
# B10 — Clic droit presse : _right_mouse_held true, spring suspendu
# Spec §Comportements attendus point B10
# ---------------------------------------------------------------------------
func test_B10_clic_droit_press_active_right_mouse_held_et_suspend_spring() -> void:
	var sut_cam = _creer_camera_controller()
	if sut_cam == null:
		return
	var cible: Node3D = _creer_cible_node3d(Vector3.ZERO)
	# home_yaw = 0, _yaw = 1.0 → différence non nulle, mais spring suspendu
	sut_cam.target = cible
	sut_cam._yaw = 1.0

	var ev: InputEventMouseButton = _creer_event_bouton(MOUSE_BUTTON_RIGHT, true)
	sut_cam._unhandled_input(ev)

	assert_true(sut_cam._right_mouse_held,
		"B10 : _right_mouse_held doit être true après clic droit press")

	var yaw_avant: float = sut_cam._yaw  # 1.0
	sut_cam._process(0.016)
	var yaw_apres: float = sut_cam._yaw

	assert_almost_eq(yaw_apres, yaw_avant, 0.001,
		"B10 : _yaw doit être inchangé après _process avec _right_mouse_held = true (spring suspendu)")

# ---------------------------------------------------------------------------
# B11 — Clic droit relâché : _right_mouse_held false, spring reprend
# Spec §Comportements attendus point B11
# ---------------------------------------------------------------------------
func test_B11_clic_droit_release_desactive_right_mouse_held_et_reprend_spring() -> void:
	var sut_cam = _creer_camera_controller()
	if sut_cam == null:
		return
	var cible: Node3D = _creer_cible_node3d(Vector3.ZERO)
	# home_yaw = 0, _yaw = 1.0 → spring actif dès que _right_mouse_held = false
	sut_cam.target = cible
	sut_cam._yaw = 1.0
	sut_cam._right_mouse_held = true

	var ev: InputEventMouseButton = _creer_event_bouton(MOUSE_BUTTON_RIGHT, false)
	sut_cam._unhandled_input(ev)

	assert_false(sut_cam._right_mouse_held,
		"B11 : _right_mouse_held doit être false après clic droit release")

	var yaw_avant: float = sut_cam._yaw  # 1.0
	sut_cam._process(0.016)
	var yaw_apres: float = sut_cam._yaw

	assert_ne(yaw_apres, yaw_avant,
		"B11 : _yaw doit avoir changé après _process avec _right_mouse_held = false (spring tire vers 0)")

# ---------------------------------------------------------------------------
# B12 — Propagation du yaw vers PlayerController : valeur = _yaw post-spring
# Spec §Comportements attendus point B12
#
# Cible PlayerController avec rotation.y = 0 → home_yaw = 0.
# _yaw = 1.0, _right_mouse_held = false → spring actif.
# Après _process(0.016) : _yaw ≈ 0.92 (spring vers 0 depuis 1.0).
# La valeur propagée (_camera_yaw sur le player) doit valoir ≈ sut_cam._yaw post-spring.
# ---------------------------------------------------------------------------
func test_B12_propagation_yaw_vers_player_est_valeur_post_spring() -> void:
	var sut_cam = _creer_camera_controller()
	if sut_cam == null:
		return
	if PlayerControllerScript == null:
		return
	var sut_player = PlayerControllerScript.new()
	add_child_autofree(sut_player)

	# rotation.y = 0.0 par défaut → home_yaw = 0.0
	sut_cam.target = sut_player
	sut_cam._yaw = 1.0
	sut_cam._right_mouse_held = false

	sut_cam._process(0.016)

	var yaw_post_spring: float = sut_cam._yaw
	var yaw_propage: float = sut_player._camera_yaw

	# La valeur propagée est le _yaw après spring (≈ 0.92), pas la valeur initiale (1.0)
	assert_almost_eq(yaw_propage, yaw_post_spring, 0.001,
		"B12 : _camera_yaw du player doit valoir exactement _yaw post-spring (≈ 0.92), pas la valeur initiale")

# ---------------------------------------------------------------------------
# B13 — En véhicule : pas de propagation vers VehicleBody3D
# Spec §Comportements attendus point B13
#
# VehicleBody3D ne possède pas set_camera_yaw → has_method retourne false.
# Pas de crash. Spring actif mais silencieux (pas de propagation).
# ---------------------------------------------------------------------------
func test_B13_en_vehicule_pas_de_propagation_pas_de_crash() -> void:
	var sut_cam = _creer_camera_controller()
	if sut_cam == null:
		return
	var vehicule: VehicleBody3D = _creer_vehicule()
	sut_cam.target = vehicule
	sut_cam._right_mouse_held = false

	# Ne doit pas crasher
	sut_cam._process(0.016)

	assert_false(vehicule.has_method("set_camera_yaw"),
		"B13 : VehicleBody3D ne doit pas avoir set_camera_yaw (has_method = false)")
	assert_true(true,
		"B13 : _process avec VehicleBody3D ne doit pas crasher")

# ---------------------------------------------------------------------------
# B14 — Spring-back en véhicule : _yaw converge vers home_yaw du véhicule
# Spec §Comportements attendus point B14
#
# VehicleBody3D avec rotation.y = PI/4 → home_yaw = PI/4 ≈ 0.785.
# _yaw = 0.0, _right_mouse_held = false.
# Après _process(0.016) : _yaw > 0.0 (convergence amorcée vers PI/4).
# ---------------------------------------------------------------------------
func test_B14_spring_back_en_vehicule_converge_vers_home_yaw_vehicule() -> void:
	var sut_cam = _creer_camera_controller()
	if sut_cam == null:
		return
	var vehicule: VehicleBody3D = _creer_vehicule()
	vehicule.rotation.y = PI / 4.0
	sut_cam.target = vehicule
	sut_cam._yaw = 0.0
	sut_cam._right_mouse_held = false

	sut_cam._process(0.016)

	var yaw_apres: float = sut_cam._yaw
	# home_yaw = PI/4 ≈ 0.785. diff = 0.785 - 0 = 0.785 → _yaw += 0.785 * 0.08 ≈ 0.063 > 0
	assert_gt(yaw_apres, 0.0,
		"B14 : _yaw doit être > 0 — spring converge de 0 vers home_yaw = PI/4 (dos du véhicule)")

# ---------------------------------------------------------------------------
# B15 — Constante SPRING_RATE accessible depuis la classe (pas seulement depuis une instance)
# Spec §Comportements attendus point B15
#
# Constante de classe → accessible via CameraControllerScript.SPRING_RATE.
# Même assertion que B1 mais formulée comme vérification d'accessibilité de classe.
# ---------------------------------------------------------------------------
func test_B15_spring_rate_accessible_depuis_la_classe() -> void:
	if CameraControllerScript == null:
		return
	# Accès sans instanciation — constante de classe
	var taux: float = CameraControllerScript.SPRING_RATE
	assert_almost_eq(taux, 5.0, 0.0001,
		"B15 : SPRING_RATE doit être accessible depuis la classe (constante de classe, valeur 5.0)")

# ---------------------------------------------------------------------------
# CL1 — _yaw déjà égal à home_yaw : pas de dérive
# Spec §Cas limites / erreurs point CL1
#
# Cible avec rotation.y = 1.5 → home_yaw = 1.5. _yaw = 1.5. _right_mouse_held = false.
# diff = 0 → _yaw += 0 → pas de dérive.
# Après _process(0.016) : _yaw ≈ 1.5.
# ---------------------------------------------------------------------------
func test_CL1_yaw_deja_egal_a_home_yaw_pas_de_derive() -> void:
	var sut_cam = _creer_camera_controller()
	if sut_cam == null:
		return
	var cible: Node3D = _creer_cible_node3d(Vector3.ZERO)
	cible.rotation.y = 1.5
	# home_yaw = 1.5
	sut_cam.target = cible
	sut_cam._yaw = 1.5
	sut_cam._right_mouse_held = false

	sut_cam._process(0.016)

	var yaw_apres: float = sut_cam._yaw
	assert_almost_eq(yaw_apres, 1.5, 0.0001,
		"CL1 : _yaw doit rester ≈ 1.5 quand il est déjà égal à home_yaw (diff = 0 → pas de dérive)")

# ---------------------------------------------------------------------------
# CL2 — delta = 0 en mode normal : lerp_angle avec facteur 0 ne modifie pas _yaw
# Spec §Cas limites / erreurs point CL2
#
# SPRING_RATE * 0.0 = 0.0 → lerp_angle(_yaw, home_yaw, 0.0) = _yaw.
# _yaw initial = 0.0. Après _process(0.0) : _yaw ≈ 0.0.
# ---------------------------------------------------------------------------
func test_CL2_delta_zero_ne_modifie_pas_yaw() -> void:
	var sut_cam = _creer_camera_controller()
	if sut_cam == null:
		return
	var cible: Node3D = _creer_cible_node3d(Vector3.ZERO)
	sut_cam.target = cible
	sut_cam._yaw = 0.0
	sut_cam._right_mouse_held = false

	sut_cam._process(0.0)

	var yaw_apres: float = sut_cam._yaw
	assert_almost_eq(yaw_apres, 0.0, 0.0001,
		"CL2 : _yaw doit rester ≈ 0.0 avec delta=0 (lerp_angle * 0 = pas de changement)")

# ---------------------------------------------------------------------------
# CL3 — target null : guard protège avant le calcul de home_yaw
# Spec §Cas limites / erreurs point CL3
#
# sut.target = null. global_position posée à (1, 2, 3).
# Après _process(0.016) : aucun crash, global_position inchangée.
# ---------------------------------------------------------------------------
func test_CL3_target_null_guard_protege_avant_home_yaw() -> void:
	var sut_cam = _creer_camera_controller()
	if sut_cam == null:
		return
	sut_cam.target = null
	sut_cam.global_position = Vector3(1.0, 2.0, 3.0)

	# Ne doit pas crasher
	sut_cam._process(0.016)

	assert_almost_eq(sut_cam.global_position.x, 1.0, 0.0001,
		"CL3 : global_position.x doit rester 1.0 (guard court-circuite avant calcul home_yaw)")
	assert_almost_eq(sut_cam.global_position.y, 2.0, 0.0001,
		"CL3 : global_position.y doit rester 2.0")
	assert_almost_eq(sut_cam.global_position.z, 3.0, 0.0001,
		"CL3 : global_position.z doit rester 3.0")

# ---------------------------------------------------------------------------
# CL4 — home_yaw = cible.rotation.y pour cible fraîche sans rotation
# Spec §Cas limites / erreurs point CL4
#
# Vérifie la formule directement sans passer par _process.
# Node3D fraîchement instancié → rotation.y = 0 → home_yaw = 0.
# La caméra est initialement derrière le joueur (yaw=0 = +Z) quand le joueur regarde -Z.
# ---------------------------------------------------------------------------
func test_CL4_formule_home_yaw_cible_sans_rotation() -> void:
	var cible: Node3D = _creer_cible_node3d(Vector3.ZERO)
	# rotation.y = 0.0 par défaut
	var home_yaw_calcule: float = cible.global_transform.basis.get_euler().y
	assert_almost_eq(home_yaw_calcule, 0.0, 0.001,
		"CL4 : home_yaw d'une cible sans rotation doit valoir ≈ 0.0 (caméra derrière = yaw identique au joueur)")

# ---------------------------------------------------------------------------
# CL5 — lerp_angle passage ±PI : pas de saut angulaire
# Spec §Cas limites / erreurs point CL5
#
# Cible avec rotation.y = PI - 0.05 → home_yaw ≈ 2*PI - 0.05.
# _yaw = -(PI - 0.05) (côté opposé, proche de -PI).
# Appel _process(0.016). lerp_angle prend le chemin court.
# Vérification : abs(sut_cam._yaw - (-(PI - 0.05))) < 0.5 rad (pas de saut).
# ---------------------------------------------------------------------------
func test_CL5_lerp_angle_passage_pi_sans_saut_angulaire() -> void:
	var sut_cam = _creer_camera_controller()
	if sut_cam == null:
		return
	var cible: Node3D = _creer_cible_node3d(Vector3.ZERO)
	cible.rotation.y = PI - 0.05
	# home_yaw = (PI - 0.05) + PI = 2*PI - 0.05 ≈ 6.233
	sut_cam.target = cible
	sut_cam._yaw = -(PI - 0.05)  # proche de -PI, côté opposé
	sut_cam._right_mouse_held = false

	var yaw_avant: float = sut_cam._yaw
	sut_cam._process(0.016)
	var yaw_apres: float = sut_cam._yaw

	var variation: float = absf(yaw_apres - yaw_avant)
	assert_lt(variation, 0.5,
		"CL5 : la variation de _yaw doit être < 0.5 rad (lerp_angle prend le chemin court, pas de saut ±PI)")

# ---------------------------------------------------------------------------
# CL6 — Mouvement souris avec clic droit : _yaw modifié par la souris, pas par le spring
# Spec §Cas limites / erreurs point CL6
#
# _right_mouse_held = true. _yaw = 0.0.
# InputEventMouseMotion relative = Vector2(100.0, 0.0).
# _yaw attendu = 0.0 - 100.0 * MOUSE_SENSITIVITY = 0.0 - 100 * 0.003 = -0.3.
# Le spring est suspendu → _yaw modifié uniquement par la souris.
# ---------------------------------------------------------------------------
func test_CL6_mouvement_souris_clic_droit_modifie_yaw_par_souris_pas_spring() -> void:
	var sut_cam = _creer_camera_controller()
	if sut_cam == null:
		return
	sut_cam._right_mouse_held = true
	sut_cam._yaw = 0.0

	var ev: InputEventMouseMotion = _creer_event_mouvement(100.0, 0.0)
	sut_cam._unhandled_input(ev)

	var sensibilite: float = CameraControllerScript.MOUSE_SENSITIVITY
	var yaw_attendu: float = 0.0 - 100.0 * sensibilite  # = -0.3
	assert_almost_eq(sut_cam._yaw, yaw_attendu, 0.0001,
		"CL6 : _yaw doit valoir -0.3 (= -100 * MOUSE_SENSITIVITY) après mouvement souris avec clic droit — valeur orbitale, pas spring")
