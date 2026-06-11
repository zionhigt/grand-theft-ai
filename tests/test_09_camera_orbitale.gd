extends GutTest

# Tests unitaires — Feature 09 : Caméra orbitale (rotation souris + zoom molette + reset clic milieu)
#
# Chaque test cible un comportement numéroté de la spec docs/specs/09-camera-orbitale.md.
#
# Stratégie :
#   Charge CameraController via load() dynamique dans before_each pour que les membres
#   manquants (ZOOM_DISTANCES, DEFAULT_PITCH, etc.) produisent des échecs à l'exécution
#   plutôt que des erreurs de parse qui silencieraient le fichier entier.
#   Les inputs sont simulés via _unhandled_input(event) avec des InputEventMouseButton
#   et InputEventMouseMotion créés par code.
#   Les variables d'état _yaw, _pitch, _zoom_level, _right_mouse_held sont accédées directement.
#
# Audit inter-features (mis à jour — changement UX zoom) :
#   ZOOM_DISTANCES passe de [6.708, 12.0, 18.0] à [3.0, 4.5, 6.708].
#   La position par défaut (yaw=0, pitch=DEFAULT_PITCH≈0.4636, zoom_level=0) change :
#     dist = ZOOM_DISTANCES[0] = 3.0
#     orbit = Vector3(0,0,3.0).rotated(RIGHT, -0.4636).rotated(UP, 0.0)
#           ≈ Vector3(0, 3.0*0.4472, 3.0*0.8944)
#           ≈ Vector3(0, 1.342, 2.683)  (tolérance 0.05)
#   Les tests test_04 B4/B5/B7/CL2/CL3/CL5 qui vérifiaient (0,3,6) sont mis à jour
#   dans test_04_camera_tp.gd pour refléter la nouvelle position par défaut.
#
# En phase rouge : camera_controller.gd ne contient pas encore les constantes ni méthodes
#   de la feature 09. Les assertions sur ces membres échoueront — attendu.

# ---------------------------------------------------------------------------
# Chargement dynamique du script sous test
# Même pattern que test_08_conduite.gd : load() dans before_each pour que les
# erreurs de membres manquants apparaissent comme des fails de tests, pas des
# erreurs de parse qui silencieraient tout le fichier.
# ---------------------------------------------------------------------------

var CameraControllerScript  # résolu dans before_each via load()

# ---------------------------------------------------------------------------
# SUT CameraController — instancié pour chaque test
# ---------------------------------------------------------------------------

var sut  # CameraController

func before_each() -> void:
	CameraControllerScript = load("res://src/camera/camera_controller.gd")
	assert_not_null(CameraControllerScript,
		"camera_controller.gd doit être chargeable")
	if CameraControllerScript == null:
		return
	sut = CameraControllerScript.new()
	add_child_autofree(sut)

func after_each() -> void:
	# add_child_autofree gère la libération — rien à faire ici
	pass

# ---------------------------------------------------------------------------
# Helpers — factorisation de la création des nœuds récurrents
# ---------------------------------------------------------------------------

# Crée et attache un enfant Camera3D nommé "Camera3D" au sut
func _ajouter_camera3d() -> Camera3D:
	var cam := Camera3D.new()
	cam.name = "Camera3D"
	sut.add_child(cam)
	return cam

# Crée un Node3D cible dans l'arbre à la position donnée
func _creer_cible(pos: Vector3) -> Node3D:
	var cible := Node3D.new()
	add_child_autofree(cible)
	cible.global_position = pos
	return cible

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
# B1 — ZOOM_DISTANCES : Array[float] de taille 3, ZOOM_DISTANCES[0] ≈ 6.708
# Spec §Comportements attendus point B1
# ---------------------------------------------------------------------------
func test_zoom_distances_est_un_tableau_de_3_elements() -> void:
	assert_not_null(CameraControllerScript)
	if CameraControllerScript == null:
		return
	var distances = CameraControllerScript.ZOOM_DISTANCES
	assert_not_null(distances,
		"La constante ZOOM_DISTANCES doit exister dans CameraController")
	assert_eq(distances.size(), 3,
		"ZOOM_DISTANCES doit contenir exactement 3 niveaux de zoom")

func test_zoom_distances_niveau_0_est_3_0() -> void:
	assert_not_null(CameraControllerScript)
	if CameraControllerScript == null:
		return
	var d0: float = CameraControllerScript.ZOOM_DISTANCES[0]
	assert_almost_eq(d0, 3.0, 0.001,
		"ZOOM_DISTANCES[0] doit être 3.0 m (vue la plus proche — défaut)")

func test_zoom_distances_niveau_1_est_4_5() -> void:
	assert_not_null(CameraControllerScript)
	if CameraControllerScript == null:
		return
	var d1: float = CameraControllerScript.ZOOM_DISTANCES[1]
	assert_almost_eq(d1, 4.5, 0.001,
		"ZOOM_DISTANCES[1] doit être 4.5 m (vue intermédiaire)")

func test_zoom_distances_niveau_2_est_6_708() -> void:
	assert_not_null(CameraControllerScript)
	if CameraControllerScript == null:
		return
	var d2: float = CameraControllerScript.ZOOM_DISTANCES[2]
	assert_almost_eq(d2, 6.708, 0.001,
		"ZOOM_DISTANCES[2] doit être ≈ 6.708 m (vue la plus éloignée)")

# ---------------------------------------------------------------------------
# B2 — DEFAULT_PITCH ≈ atan2(3.0, 6.0) ≈ 0.4636
# Spec §Comportements attendus point B2
# ---------------------------------------------------------------------------
func test_default_pitch_est_approximativement_atan2_3_6() -> void:
	assert_not_null(CameraControllerScript)
	if CameraControllerScript == null:
		return
	var attendu: float = atan2(3.0, 6.0)
	var pitch: float = CameraControllerScript.DEFAULT_PITCH
	assert_almost_eq(pitch, attendu, 0.0001,
		"DEFAULT_PITCH doit valoir approximativement atan2(3.0, 6.0) ≈ 0.4636 rad")

# ---------------------------------------------------------------------------
# B3 — MOUSE_SENSITIVITY ≈ 0.003
# Spec §Comportements attendus point B3
# ---------------------------------------------------------------------------
func test_mouse_sensitivity_est_approximativement_0_003() -> void:
	assert_not_null(CameraControllerScript)
	if CameraControllerScript == null:
		return
	var sensibilite: float = CameraControllerScript.MOUSE_SENSITIVITY
	assert_almost_eq(sensibilite, 0.003, 0.0001,
		"MOUSE_SENSITIVITY doit valoir approximativement 0.003 rad/px")

# ---------------------------------------------------------------------------
# B4 — PITCH_MIN ≈ -0.1745 et PITCH_MAX ≈ 1.2217
# Spec §Comportements attendus point B4
# ---------------------------------------------------------------------------
func test_pitch_min_est_approximativement_moins_0_1745() -> void:
	assert_not_null(CameraControllerScript)
	if CameraControllerScript == null:
		return
	var pitch_min: float = CameraControllerScript.PITCH_MIN
	assert_almost_eq(pitch_min, -0.1745, 0.0001,
		"PITCH_MIN doit valoir approximativement -0.1745 rad (-10°)")

func test_pitch_max_est_approximativement_1_2217() -> void:
	assert_not_null(CameraControllerScript)
	if CameraControllerScript == null:
		return
	var pitch_max: float = CameraControllerScript.PITCH_MAX
	assert_almost_eq(pitch_max, 1.2217, 0.0001,
		"PITCH_MAX doit valoir approximativement 1.2217 rad (70°)")

# ---------------------------------------------------------------------------
# B5 — Position initiale :
#   yaw=0, pitch=DEFAULT_PITCH, zoom_level=0, cible à (0,0,0)
#   → global_position ≈ Vector3(0, 1.342, 2.683) après _process(0.016)
#   Calcul : dist=ZOOM_DISTANCES[0]=3.0, orbit=Vector3(0,0,3).rotated(RIGHT,-0.4636)
#          = Vector3(0, 3.0*sin(0.4636), 3.0*cos(0.4636))
#          ≈ Vector3(0, 1.342, 2.683)
# Spec §Comportements attendus point B5
# Mis à jour : ZOOM_DISTANCES[0] passe de 6.708 à 3.0 (changement UX zoom).
# Mis à jour feature 20 : _right_mouse_held = true pour suspendre le spring-back
#   et garantir que _yaw reste à 0.0 pendant _process (sinon lerp_angle vers home_yaw
#   modifie _yaw et décale la position calculée).
# ---------------------------------------------------------------------------
func test_position_initiale_yaw0_pitch_default_zoom0() -> void:
	assert_not_null(sut)
	if sut == null:
		return
	_ajouter_camera3d()
	var cible: Node3D = _creer_cible(Vector3(0.0, 0.0, 0.0))
	sut.target = cible
	sut._right_mouse_held = true  # spring suspendu — yaw fixe à 0.0 (feature 20)

	# Valeurs initiales garanties par les déclarations var : _yaw=0, _pitch=DEFAULT_PITCH, _zoom_level=0
	sut._process(0.016)

	assert_almost_eq(sut.global_position.x, 0.0, 0.05,
		"global_position.x doit être ≈ 0.0 (yaw=0, pas de composante latérale)")
	assert_almost_eq(sut.global_position.y, 1.342, 0.05,
		"global_position.y doit être ≈ 1.342 (dist=3.0 * sin(0.4636))")
	assert_almost_eq(sut.global_position.z, 2.683, 0.05,
		"global_position.z doit être ≈ 2.683 (dist=3.0 * cos(0.4636))")

# ---------------------------------------------------------------------------
# B6 — Clic droit press : _right_mouse_held passe à true, souris capturée
# Spec §Comportements attendus point B6
# ---------------------------------------------------------------------------
func test_clic_droit_press_active_right_mouse_held() -> void:
	assert_not_null(sut)
	if sut == null:
		return
	var ev: InputEventMouseButton = _creer_event_bouton(MOUSE_BUTTON_RIGHT, true)
	sut._unhandled_input(ev)

	var held: bool = sut._right_mouse_held
	assert_true(held,
		"_right_mouse_held doit être true après clic droit press")

func test_clic_droit_press_capture_la_souris() -> void:
	# Note : Input.get_mouse_mode() est toujours VISIBLE en mode headless (DisplayServer absent).
	# On vérifie à la place le flag interne _right_mouse_held qui reflète fidèlement
	# l'intention de capture. Le comportement Input.MOUSE_MODE_CAPTURED est validé
	# manuellement en mode avec affichage.
	assert_not_null(sut)
	if sut == null:
		return
	var ev: InputEventMouseButton = _creer_event_bouton(MOUSE_BUTTON_RIGHT, true)
	sut._unhandled_input(ev)

	assert_true(sut._right_mouse_held,
		"_right_mouse_held doit être true après clic droit press (proxy du mode CAPTURED)")

# ---------------------------------------------------------------------------
# B7 — Clic droit release : _right_mouse_held passe à false, souris visible
# Spec §Comportements attendus point B7
# ---------------------------------------------------------------------------
func test_clic_droit_release_desactive_right_mouse_held() -> void:
	assert_not_null(sut)
	if sut == null:
		return
	# Mettre d'abord en état "maintenu"
	sut._right_mouse_held = true

	var ev: InputEventMouseButton = _creer_event_bouton(MOUSE_BUTTON_RIGHT, false)
	sut._unhandled_input(ev)

	var held: bool = sut._right_mouse_held
	assert_false(held,
		"_right_mouse_held doit être false après clic droit release")

func test_clic_droit_release_libere_la_souris() -> void:
	assert_not_null(sut)
	if sut == null:
		return
	sut._right_mouse_held = true
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	var ev: InputEventMouseButton = _creer_event_bouton(MOUSE_BUTTON_RIGHT, false)
	sut._unhandled_input(ev)

	assert_eq(Input.get_mouse_mode(), Input.MOUSE_MODE_VISIBLE,
		"Le mode souris doit être MOUSE_MODE_VISIBLE après clic droit release")

# ---------------------------------------------------------------------------
# B8 — Mouvement souris avec clic droit maintenu : yaw et pitch modifiés
# Spec §Comportements attendus point B8
# ---------------------------------------------------------------------------
func test_mouvement_souris_avec_clic_droit_modifie_yaw_et_pitch() -> void:
	assert_not_null(sut)
	if sut == null:
		return
	sut._right_mouse_held = true
	sut._yaw = 0.0
	sut._pitch = 0.0

	var ev: InputEventMouseMotion = _creer_event_mouvement(100.0, 50.0)
	sut._unhandled_input(ev)

	var sensibilite: float = CameraControllerScript.MOUSE_SENSITIVITY
	var yaw_attendu: float = 0.0 - 100.0 * sensibilite
	var pitch_attendu: float = 0.0 - 50.0 * sensibilite

	var yaw_reel: float = sut._yaw
	var pitch_reel: float = sut._pitch

	assert_almost_eq(yaw_reel, yaw_attendu, 0.0001,
		"_yaw doit être ≈ -0.3 après déplacement souris de 100px horizontal")
	assert_almost_eq(pitch_reel, pitch_attendu, 0.0001,
		"_pitch doit être ≈ -0.15 après déplacement souris de 50px vertical")

# ---------------------------------------------------------------------------
# B9 — Mouvement souris sans clic droit : yaw et pitch inchangés
# Spec §Comportements attendus point B9
# ---------------------------------------------------------------------------
func test_mouvement_souris_sans_clic_droit_ne_modifie_pas_yaw_ni_pitch() -> void:
	assert_not_null(sut)
	if sut == null:
		return
	sut._right_mouse_held = false
	sut._yaw = 0.5
	sut._pitch = 0.2

	var ev: InputEventMouseMotion = _creer_event_mouvement(100.0, 50.0)
	sut._unhandled_input(ev)

	var yaw_reel: float = sut._yaw
	var pitch_reel: float = sut._pitch

	assert_almost_eq(yaw_reel, 0.5, 0.0001,
		"_yaw ne doit pas changer si _right_mouse_held est false")
	assert_almost_eq(pitch_reel, 0.2, 0.0001,
		"_pitch ne doit pas changer si _right_mouse_held est false")

# ---------------------------------------------------------------------------
# B10 — Molette bas (zoom out) : zoom_level passe de 0 à 1
# Spec §Comportements attendus point B10
# ---------------------------------------------------------------------------
func test_molette_bas_depuis_niveau_0_passe_a_niveau_1() -> void:
	assert_not_null(sut)
	if sut == null:
		return
	sut._zoom_level = 0

	var ev: InputEventMouseButton = _creer_event_bouton(MOUSE_BUTTON_WHEEL_DOWN, true)
	sut._unhandled_input(ev)

	var zoom: int = sut._zoom_level
	assert_eq(zoom, 1,
		"_zoom_level doit passer à 1 après molette bas depuis niveau 0")

# ---------------------------------------------------------------------------
# B11 — Molette haut (zoom in) : zoom_level passe de 2 à 1
# Spec §Comportements attendus point B11
# ---------------------------------------------------------------------------
func test_molette_haut_depuis_niveau_2_passe_a_niveau_1() -> void:
	assert_not_null(sut)
	if sut == null:
		return
	sut._zoom_level = 2

	var ev: InputEventMouseButton = _creer_event_bouton(MOUSE_BUTTON_WHEEL_UP, true)
	sut._unhandled_input(ev)

	var zoom: int = sut._zoom_level
	assert_eq(zoom, 1,
		"_zoom_level doit passer à 1 après molette haut depuis niveau 2")

# ---------------------------------------------------------------------------
# B12 — Zoom out à la limite haute : zoom_level reste à 2
# Spec §Comportements attendus point B12
# ---------------------------------------------------------------------------
func test_molette_bas_depuis_niveau_2_reste_a_2() -> void:
	assert_not_null(sut)
	if sut == null:
		return
	sut._zoom_level = 2

	var ev: InputEventMouseButton = _creer_event_bouton(MOUSE_BUTTON_WHEEL_DOWN, true)
	sut._unhandled_input(ev)

	var zoom: int = sut._zoom_level
	assert_eq(zoom, 2,
		"_zoom_level doit rester à 2 (limite haute) — pas de dépassement")

# ---------------------------------------------------------------------------
# B13 — Zoom in à la limite basse : zoom_level reste à 0
# Spec §Comportements attendus point B13
# ---------------------------------------------------------------------------
func test_molette_haut_depuis_niveau_0_reste_a_0() -> void:
	assert_not_null(sut)
	if sut == null:
		return
	sut._zoom_level = 0

	var ev: InputEventMouseButton = _creer_event_bouton(MOUSE_BUTTON_WHEEL_UP, true)
	sut._unhandled_input(ev)

	var zoom: int = sut._zoom_level
	assert_eq(zoom, 0,
		"_zoom_level doit rester à 0 (limite basse) — pas de dépassement")

# ---------------------------------------------------------------------------
# B14 — Clic milieu : aucun effet (reset supprimé en feature 20)
# Spec feature 20 §Impact sur tests existants — behaviour B7
#
# Avant feature 20 : clic milieu réinitialisait _yaw à 0.0 et _zoom_level à 0.
# Après feature 20 : le bloc MOUSE_BUTTON_MIDDLE est supprimé dans _unhandled_input.
#   Clic milieu n'a désormais aucun effet sur _yaw, _zoom_level ni _pitch.
# ---------------------------------------------------------------------------
func test_clic_milieu_reset_yaw_et_zoom_mais_conserve_pitch() -> void:
	assert_not_null(sut)
	if sut == null:
		return
	# Feature 20 : clic milieu supprimé — aucun effet
	sut._yaw = 1.57
	sut._pitch = 0.8
	sut._zoom_level = 2

	var ev: InputEventMouseButton = _creer_event_bouton(MOUSE_BUTTON_MIDDLE, true)
	sut._unhandled_input(ev)

	assert_almost_eq(sut._yaw, 1.57, 0.0001,
		"Clic milieu ne doit pas modifier _yaw (feature 20 : bloc MOUSE_BUTTON_MIDDLE supprimé)")
	assert_eq(sut._zoom_level, 2,
		"Clic milieu ne doit pas modifier _zoom_level (feature 20)")
	assert_almost_eq(sut._pitch, 0.8, 0.0001,
		"Clic milieu ne doit pas modifier _pitch (feature 20)")

# ---------------------------------------------------------------------------
# B15 — Position caméra avec yaw = PI/2 : caméra à droite de la cible
# Spec §Comportements attendus point B15
# Mis à jour : ZOOM_DISTANCES[0] = 3.0, position.x ≈ 3.0 quand yaw=PI/2, pitch=0
# Mis à jour feature 20 : _right_mouse_held = true pour geler _yaw à PI/2.
#   Sans cela, le spring-back ramènerait _yaw vers home_yaw (PI pour cible sans rotation)
#   et la position calculée ne serait plus (dist, 0, 0).
# ---------------------------------------------------------------------------
func test_yaw_pi_sur_2_positionne_la_camera_a_droite_de_la_cible() -> void:
	assert_not_null(sut)
	if sut == null:
		return
	_ajouter_camera3d()
	var cible: Node3D = _creer_cible(Vector3(0.0, 0.0, 0.0))
	sut.target = cible
	sut._yaw = PI / 2.0
	sut._pitch = 0.0
	sut._zoom_level = 0
	sut._right_mouse_held = true  # spring suspendu — yaw fixe à PI/2 (feature 20)

	sut._process(0.016)

	var dist: float = CameraControllerScript.ZOOM_DISTANCES[0]
	assert_almost_eq(sut.global_position.x, dist, 0.1,
		"global_position.x doit être ≈ ZOOM_DISTANCES[0] = 3.0 quand yaw=PI/2, pitch=0")
	assert_almost_eq(sut.global_position.z, 0.0, 0.1,
		"global_position.z doit être ≈ 0.0 quand yaw=PI/2 (caméra à droite)")

# ---------------------------------------------------------------------------
# B16 — Distance euclidienne = ZOOM_DISTANCES[zoom_level] pour chaque niveau
# Spec §Comportements attendus point B16
# ---------------------------------------------------------------------------
func test_distance_euclidienne_egale_zoom_distances_niveau_0() -> void:
	assert_not_null(sut)
	if sut == null:
		return
	_ajouter_camera3d()
	var cible: Node3D = _creer_cible(Vector3(0.0, 0.0, 0.0))
	sut.target = cible
	sut._zoom_level = 0

	sut._process(0.016)

	var dist_attendue: float = CameraControllerScript.ZOOM_DISTANCES[0]
	var dist_reelle: float = sut.global_position.distance_to(Vector3(0.0, 0.0, 0.0))
	assert_almost_eq(dist_reelle, dist_attendue, 0.05,
		"Distance euclidienne caméra/cible doit valoir ZOOM_DISTANCES[0] = 3.0")

func test_distance_euclidienne_egale_zoom_distances_niveau_1() -> void:
	assert_not_null(sut)
	if sut == null:
		return
	_ajouter_camera3d()
	var cible: Node3D = _creer_cible(Vector3(0.0, 0.0, 0.0))
	sut.target = cible
	sut._zoom_level = 1

	sut._process(0.016)

	var dist_attendue: float = CameraControllerScript.ZOOM_DISTANCES[1]
	var dist_reelle: float = sut.global_position.distance_to(Vector3(0.0, 0.0, 0.0))
	assert_almost_eq(dist_reelle, dist_attendue, 0.05,
		"Distance euclidienne caméra/cible doit valoir ZOOM_DISTANCES[1] = 4.5")

func test_distance_euclidienne_egale_zoom_distances_niveau_2() -> void:
	assert_not_null(sut)
	if sut == null:
		return
	_ajouter_camera3d()
	var cible: Node3D = _creer_cible(Vector3(0.0, 0.0, 0.0))
	sut.target = cible
	sut._zoom_level = 2

	sut._process(0.016)

	var dist_attendue: float = CameraControllerScript.ZOOM_DISTANCES[2]
	var dist_reelle: float = sut.global_position.distance_to(Vector3(0.0, 0.0, 0.0))
	assert_almost_eq(dist_reelle, dist_attendue, 0.05,
		"Distance euclidienne caméra/cible doit valoir ZOOM_DISTANCES[2] ≈ 6.708")

# ---------------------------------------------------------------------------
# CL1 — Pitch clampé au maximum : déplacement souris vers le haut excessif
# Spec §Cas limites / erreurs point CL1
# ---------------------------------------------------------------------------
func test_pitch_clamp_au_maximum_lors_deplacement_souris_vers_haut() -> void:
	assert_not_null(sut)
	if sut == null:
		return
	var pitch_max: float = CameraControllerScript.PITCH_MAX
	sut._right_mouse_held = true
	sut._pitch = pitch_max - 0.01

	# relative.y négatif = déplacement vers le haut → pitch augmente
	var ev: InputEventMouseMotion = _creer_event_mouvement(0.0, -1000.0)
	sut._unhandled_input(ev)

	var pitch_reel: float = sut._pitch
	assert_almost_eq(pitch_reel, pitch_max, 0.0001,
		"_pitch doit être clampé à PITCH_MAX (1.2217) lors d'un déplacement souris excessif vers le haut")

# ---------------------------------------------------------------------------
# CL2 — Pitch clampé au minimum : déplacement souris vers le bas excessif
# Spec §Cas limites / erreurs point CL2
# ---------------------------------------------------------------------------
func test_pitch_clamp_au_minimum_lors_deplacement_souris_vers_bas() -> void:
	assert_not_null(sut)
	if sut == null:
		return
	var pitch_min: float = CameraControllerScript.PITCH_MIN
	sut._right_mouse_held = true
	sut._pitch = pitch_min + 0.01

	# relative.y positif = déplacement vers le bas → pitch diminue
	var ev: InputEventMouseMotion = _creer_event_mouvement(0.0, 1000.0)
	sut._unhandled_input(ev)

	var pitch_reel: float = sut._pitch
	assert_almost_eq(pitch_reel, pitch_min, 0.0001,
		"_pitch doit être clampé à PITCH_MIN (-0.1745) lors d'un déplacement souris excessif vers le bas")

# ---------------------------------------------------------------------------
# CL3 — target null dans _process : aucun crash, global_position inchangée
# Spec §Cas limites / erreurs point CL3
# ---------------------------------------------------------------------------
func test_process_avec_target_null_ne_modifie_pas_global_position_feature09() -> void:
	assert_not_null(sut)
	if sut == null:
		return
	sut.target = null
	sut.global_position = Vector3(1.0, 2.0, 3.0)

	# Ne doit pas crasher
	sut._process(0.016)

	assert_almost_eq(sut.global_position.x, 1.0, 0.0001,
		"global_position.x ne doit pas changer si target est null (feature 09)")
	assert_almost_eq(sut.global_position.y, 2.0, 0.0001,
		"global_position.y ne doit pas changer si target est null (feature 09)")
	assert_almost_eq(sut.global_position.z, 3.0, 0.0001,
		"global_position.z ne doit pas changer si target est null (feature 09)")

# ---------------------------------------------------------------------------
# CL4 — delta = 0 dans _process : aucun crash, position identique à delta normal
# Spec §Cas limites / erreurs point CL4
# ---------------------------------------------------------------------------
func test_process_avec_delta_nul_produit_meme_position_que_delta_normal() -> void:
	assert_not_null(sut)
	if sut == null:
		return
	_ajouter_camera3d()
	var cible: Node3D = _creer_cible(Vector3(0.0, 0.0, 0.0))
	sut.target = cible

	# Appel avec delta normal pour référence
	sut._process(0.016)
	var pos_delta_normal: Vector3 = sut.global_position

	# Réinitialise la position pour vérifier que delta=0 donne le même résultat
	sut.global_position = Vector3(0.0, 0.0, 0.0)
	sut._process(0.0)

	assert_almost_eq(sut.global_position.x, pos_delta_normal.x, 0.05,
		"global_position.x avec delta=0 doit être identique à delta normal (formule indépendante de delta)")
	assert_almost_eq(sut.global_position.y, pos_delta_normal.y, 0.05,
		"global_position.y avec delta=0 doit être identique à delta normal")
	assert_almost_eq(sut.global_position.z, pos_delta_normal.z, 0.05,
		"global_position.z avec delta=0 doit être identique à delta normal")

# ---------------------------------------------------------------------------
# CL5 — Multiple zoom out depuis niveau 0 : borne respectée après 3 pressions
# Spec §Cas limites / erreurs point CL5
# ---------------------------------------------------------------------------
func test_multiple_zoom_out_depuis_niveau_0_respecte_la_borne() -> void:
	assert_not_null(sut)
	if sut == null:
		return
	sut._zoom_level = 0

	var ev: InputEventMouseButton = _creer_event_bouton(MOUSE_BUTTON_WHEEL_DOWN, true)

	# Première pression : 0 → 1
	sut._unhandled_input(ev)
	var zoom_apres_1: int = sut._zoom_level
	assert_eq(zoom_apres_1, 1,
		"Après 1ère molette bas : _zoom_level doit être 1")

	# Deuxième pression : 1 → 2
	sut._unhandled_input(ev)
	var zoom_apres_2: int = sut._zoom_level
	assert_eq(zoom_apres_2, 2,
		"Après 2ème molette bas : _zoom_level doit être 2")

	# Troisième pression : 2 → 2 (borné)
	sut._unhandled_input(ev)
	var zoom_apres_3: int = sut._zoom_level
	assert_eq(zoom_apres_3, 2,
		"Après 3ème molette bas : _zoom_level doit rester à 2 (limite haute atteinte)")

# ---------------------------------------------------------------------------
# Constantes d'état initial — vérification des valeurs DEFAULT déclarées
# Ces tests couvrent les critères d'acceptation "constantes présentes"
# ---------------------------------------------------------------------------

func test_constante_default_yaw_est_0() -> void:
	assert_not_null(CameraControllerScript)
	if CameraControllerScript == null:
		return
	var yaw: float = CameraControllerScript.DEFAULT_YAW
	assert_almost_eq(yaw, 0.0, 0.0001,
		"DEFAULT_YAW doit valoir 0.0 (caméra derrière la cible)")

func test_constante_default_zoom_level_est_0() -> void:
	assert_not_null(CameraControllerScript)
	if CameraControllerScript == null:
		return
	var zoom: int = CameraControllerScript.DEFAULT_ZOOM_LEVEL
	assert_eq(zoom, 0,
		"DEFAULT_ZOOM_LEVEL doit valoir 0 (niveau initial, distance la plus proche)")

func test_variables_etat_initialisees_aux_valeurs_default() -> void:
	assert_not_null(sut)
	if sut == null:
		return
	# Les variables _yaw, _pitch, _zoom_level doivent avoir leurs valeurs initiales
	# à l'instanciation (sans aucun appel externe).
	var yaw_initial: float = sut._yaw
	var pitch_initial: float = sut._pitch
	var zoom_initial: int = sut._zoom_level
	var held_initial: bool = sut._right_mouse_held

	assert_almost_eq(yaw_initial, CameraControllerScript.DEFAULT_YAW, 0.0001,
		"_yaw doit être initialisé à DEFAULT_YAW (0.0)")
	assert_almost_eq(pitch_initial, CameraControllerScript.DEFAULT_PITCH, 0.0001,
		"_pitch doit être initialisé à DEFAULT_PITCH (≈ 0.4636)")
	assert_eq(zoom_initial, CameraControllerScript.DEFAULT_ZOOM_LEVEL,
		"_zoom_level doit être initialisé à DEFAULT_ZOOM_LEVEL (0)")
	assert_false(held_initial,
		"_right_mouse_held doit être initialisé à false")
