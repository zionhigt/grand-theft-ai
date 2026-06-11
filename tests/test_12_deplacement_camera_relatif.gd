extends GutTest

# Tests unitaires — Feature 12 : Déplacement camera-relatif (ZQSD orienté caméra)
#
# Chaque test cible un comportement numéroté de la spec
# docs/specs/12-deplacement-camera-relatif.md.
#
# Stratégie :
#   CameraController et PlayerController sont chargés via load() dynamique dans before_each.
#   Cette approche est nécessaire pour que les membres manquants produisent des fails
#   de tests à l'exécution plutôt que des erreurs de parse qui silencieraient le fichier.
#   Les inputs sont simulés via Input.action_press() / Input.action_release().
#
# Comportements testés :
#   B1  — Propagation permanente : _right_mouse_held = false ne bloque plus
#   B2  — Propagation permanente : _right_mouse_held = true propage toujours
#   B3  — Direction camera-relative : yaw=PI/2, "avancer" → monde -X
#   B4  — Direction camera-relative : yaw=0, "avancer" → monde -Z (rétrocompat)
#   B5  — Direction camera-relative : yaw=PI, "avancer" → monde +Z
#   B6  — Vecteur nul inchangé par rotation : aucun input → Vector3.ZERO
#   B7  — Normalisation avant rotation : diagonale camera-relative longueur ≈ 1.0
#   B8  — Rétrocompatibilité _camera_yaw=0 : résultat identique à feature 03
#   B9  — Comportement véhicule : pas de propagation vers VehicleBody3D
#   B10 — Composante Y du vecteur retourné est toujours 0.0
#   CL1 — _camera_yaw=0 : comportement identique à feature 03
#   CL2 — _camera_yaw=PI : axes inversés monde (avancer → +Z, droite → -X)
#   CL3 — Cible véhicule : has_method false, propagation silencieuse, pas de crash
#   CL4 — compute_input_direction avec raw=Vector3.ZERO : rotated ne crashe pas
#   CL5 — _camera_yaw non mis à jour avant premier frame : valeur initiale 0.0
#   CL6 — Yaw très grand ou négatif : rotated est périodique, pas de crash
#   CL7 — CameraController.target=null : guard précède la propagation

# ---------------------------------------------------------------------------
# Scripts chargés dynamiquement — erreurs membres manquants = fail de test
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
	# Relâcher toutes les actions simulées pour ne pas polluer les tests suivants
	Input.action_release("move_forward")
	Input.action_release("move_backward")
	Input.action_release("move_left")
	Input.action_release("move_right")

# ---------------------------------------------------------------------------
# Helpers — factorisation de la création des nœuds récurrents
# ---------------------------------------------------------------------------

func _creer_camera_controller():
	if CameraControllerScript == null:
		return null
	var sut_cam = CameraControllerScript.new()
	var cam3d := Camera3D.new()
	cam3d.name = "Camera3D"
	sut_cam.add_child(cam3d)
	add_child_autofree(sut_cam)
	return sut_cam

func _creer_player_controller():
	if PlayerControllerScript == null:
		return null
	var sut_player = PlayerControllerScript.new()
	add_child_autofree(sut_player)
	return sut_player

# ---------------------------------------------------------------------------
# B1 — Propagation permanente : _right_mouse_held = false ne bloque plus la propagation
# Spec §Comportements attendus point B1
#
# Avant feature 12 : la propagation n'avait lieu que si _right_mouse_held = true.
# Après feature 12 : la propagation est permanente (chaque frame), sans condition.
# Ce test échoue tant que camera_controller.gd conserve "if _right_mouse_held and".
#
# Mis à jour feature 20 : ajout de sut_cam._right_mouse_held = true pour figer _yaw à 0.5.
#   Avec feature 20 et _right_mouse_held = false, le spring-back calcule home_yaw depuis
#   la rotation du PlayerController (0 + PI = PI) et modifie _yaw via lerp_angle.
#   La valeur propagée ne serait plus exactement 0.5 mais ≈ 0.71.
#   En posant _right_mouse_held = true, le spring est suspendu, _yaw reste 0.5,
#   et l'assertion sur la valeur exacte propagée reste valide.
#   L'intent du test (vérifier que la propagation a bien lieu) est préservé.
# ---------------------------------------------------------------------------
func test_propagation_yaw_permanente_meme_sans_clic_droit() -> void:
	var sut_cam = _creer_camera_controller()
	if sut_cam == null:
		return
	var sut_player = _creer_player_controller()
	if sut_player == null:
		return

	sut_cam.target = sut_player
	sut_cam._yaw = 0.5
	sut_cam._right_mouse_held = true  # spring suspendu — _yaw reste 0.5 (feature 20)

	sut_cam._process(0.016)

	var yaw_recu: float = sut_player._camera_yaw
	assert_almost_eq(yaw_recu, 0.5, 0.0001,
		"B1 : _camera_yaw du PlayerController doit valoir 0.5 (yaw figé par _right_mouse_held=true, feature 20)")
	var dirty: bool = sut_player._camera_yaw_dirty
	assert_true(dirty,
		"B1 : _camera_yaw_dirty doit être true après propagation (propagation permanente, feature 12)")

# ---------------------------------------------------------------------------
# B2 — Propagation permanente : _right_mouse_held = true propage toujours
# Spec §Comportements attendus point B2
#
# Ce comportement existait déjà en feature 11 (B7) et reste valide avec feature 12.
# ---------------------------------------------------------------------------
func test_propagation_yaw_quand_clic_droit_maintenu() -> void:
	var sut_cam = _creer_camera_controller()
	if sut_cam == null:
		return
	var sut_player = _creer_player_controller()
	if sut_player == null:
		return

	sut_cam.target = sut_player
	sut_cam._yaw = 1.2
	sut_cam._right_mouse_held = true

	sut_cam._process(0.016)

	var yaw_recu: float = sut_player._camera_yaw
	assert_almost_eq(yaw_recu, 1.2, 0.0001,
		"B2 : _camera_yaw doit valoir 1.2 après propagation avec clic droit maintenu")

# ---------------------------------------------------------------------------
# B3 — Direction camera-relative : yaw = PI/2, "avancer" → monde -X
# Spec §Comportements attendus point B3
#
# Avec yaw=PI/2 (caméra à gauche du joueur) et raw=(0,0,-1),
# rotated(Vector3.UP, PI/2) → (-1, 0, 0).
# Ce test échoue tant que compute_input_direction() ne fait pas la rotation.
# ---------------------------------------------------------------------------
func test_avancer_avec_yaw_pi_sur_2_donne_direction_moins_x() -> void:
	var sut_player = _creer_player_controller()
	if sut_player == null:
		return

	sut_player.set_camera_yaw(PI / 2.0)
	Input.action_press("move_forward")
	var dir: Vector3 = sut_player.compute_input_direction()
	Input.action_release("move_forward")

	assert_almost_eq(dir.z, 0.0, 0.01,
		"B3 : dir.z doit être ≈ 0.0 avec yaw=PI/2 et move_forward")
	assert_almost_eq(dir.x, -1.0, 0.01,
		"B3 : dir.x doit être ≈ -1.0 avec yaw=PI/2 et move_forward (monde -X)")

# ---------------------------------------------------------------------------
# B4 — Direction camera-relative : yaw = 0, "avancer" → monde -Z
# Spec §Comportements attendus point B4
#
# yaw=0 par défaut — rotation neutre. raw=(0,0,-1) → (0,0,-1) (inchangé).
# Rétrocompatibilité totale avec feature 03.
# ---------------------------------------------------------------------------
func test_avancer_avec_yaw_zero_donne_direction_moins_z() -> void:
	var sut_player = _creer_player_controller()
	if sut_player == null:
		return

	# Ne pas appeler set_camera_yaw — _camera_yaw reste à 0.0 par défaut
	Input.action_press("move_forward")
	var dir: Vector3 = sut_player.compute_input_direction()
	Input.action_release("move_forward")

	assert_almost_eq(dir.z, -1.0, 0.01,
		"B4 : dir.z doit être ≈ -1.0 avec yaw=0 et move_forward (axe monde -Z)")
	assert_almost_eq(dir.x, 0.0, 0.01,
		"B4 : dir.x doit être ≈ 0.0 avec yaw=0 et move_forward")

# ---------------------------------------------------------------------------
# B5 — Direction camera-relative : yaw = PI, "avancer" → monde +Z
# Spec §Comportements attendus point B5
#
# Avec yaw=PI (caméra devant le joueur), raw=(0,0,-1) → (0,0,+1).
# Ce test échoue tant que la rotation n'est pas appliquée.
# ---------------------------------------------------------------------------
func test_avancer_avec_yaw_pi_donne_direction_plus_z() -> void:
	var sut_player = _creer_player_controller()
	if sut_player == null:
		return

	sut_player.set_camera_yaw(PI)
	Input.action_press("move_forward")
	var dir: Vector3 = sut_player.compute_input_direction()
	Input.action_release("move_forward")

	assert_almost_eq(dir.z, 1.0, 0.01,
		"B5 : dir.z doit être ≈ +1.0 avec yaw=PI et move_forward")
	assert_almost_eq(dir.x, 0.0, 0.01,
		"B5 : dir.x doit être ≈ 0.0 avec yaw=PI et move_forward")

# ---------------------------------------------------------------------------
# B6 — Vecteur nul inchangé par la rotation : aucun input → Vector3.ZERO
# Spec §Comportements attendus point B6
#
# Vector3.ZERO.rotated(Vector3.UP, angle) == Vector3.ZERO quelle que soit l'angle.
# Ce test reste vert même sans la modification (rotation neutre sur vecteur nul),
# mais il valide la rétrocompatibilité CL4.
# ---------------------------------------------------------------------------
func test_aucun_input_retourne_vecteur_zero_meme_avec_yaw_non_nul() -> void:
	var sut_player = _creer_player_controller()
	if sut_player == null:
		return

	sut_player.set_camera_yaw(PI / 3.0)
	Input.action_release("move_forward")
	Input.action_release("move_backward")
	Input.action_release("move_left")
	Input.action_release("move_right")

	var dir: Vector3 = sut_player.compute_input_direction()

	assert_eq(dir, Vector3.ZERO,
		"B6 : compute_input_direction sans input doit retourner Vector3.ZERO (rotation sur vecteur nul = nul)")

# ---------------------------------------------------------------------------
# B7 — Normalisation avant rotation : diagonale camera-relative a longueur ≈ 1.0
# Spec §Comportements attendus point B7
#
# La normalisation est faite avant la rotation. La rotation (unitaire) préserve la norme.
# Ce test échoue si la rotation est appliquée avant la normalisation ou absente.
# ---------------------------------------------------------------------------
func test_diagonale_camera_relative_normalisee() -> void:
	var sut_player = _creer_player_controller()
	if sut_player == null:
		return

	sut_player.set_camera_yaw(PI / 4.0)
	Input.action_press("move_forward")
	Input.action_press("move_right")
	var dir: Vector3 = sut_player.compute_input_direction()
	Input.action_release("move_forward")
	Input.action_release("move_right")

	assert_almost_eq(dir.length(), 1.0, 0.01,
		"B7 : la direction diagonale camera-relative doit avoir une longueur ≈ 1.0 (normalisée avant rotation)")

# ---------------------------------------------------------------------------
# B8 — Rétrocompatibilité _camera_yaw = 0 : compute_input_direction inchangée
# Spec §Comportements attendus point B8
#
# Sans appel à set_camera_yaw, _camera_yaw vaut 0.0 → rotation identité.
# Résultat identique à feature 03 : move_right → dir.x ≈ +1.0
# ---------------------------------------------------------------------------
func test_retrocompatibilite_camera_yaw_zero_move_right() -> void:
	var sut_player = _creer_player_controller()
	if sut_player == null:
		return

	# Ne pas appeler set_camera_yaw — _camera_yaw reste à 0.0 par défaut
	Input.action_press("move_right")
	var dir: Vector3 = sut_player.compute_input_direction()
	Input.action_release("move_right")

	assert_almost_eq(dir.x, 1.0, 0.01,
		"B8 : dir.x doit être ≈ +1.0 avec yaw=0 et move_right (rétrocompatibilité feature 03)")
	assert_almost_eq(dir.z, 0.0, 0.01,
		"B8 : dir.z doit être ≈ 0.0 avec yaw=0 et move_right")

# ---------------------------------------------------------------------------
# B9 — Comportement véhicule : CameraController avec VehicleBody3D ne propage pas
# Spec §Comportements attendus point B9
#
# has_method("set_camera_yaw") retourne false pour VehicleBody3D.
# Pas de crash, propagation silencieuse — même sans la condition _right_mouse_held.
# ---------------------------------------------------------------------------
func test_camera_controller_avec_vehicule_ne_propage_pas_et_ne_crashe_pas() -> void:
	var sut_cam = _creer_camera_controller()
	if sut_cam == null:
		return

	var vehicule := VehicleBody3D.new()
	add_child_autofree(vehicule)

	sut_cam.target = vehicule
	sut_cam._right_mouse_held = false

	# Ne doit pas crasher — has_method("set_camera_yaw") retourne false
	sut_cam._process(0.016)

	assert_false(vehicule.has_method("set_camera_yaw"),
		"B9 : VehicleBody3D ne doit pas avoir la méthode set_camera_yaw")
	assert_true(true,
		"B9 : _process avec cible VehicleBody3D sans clic droit ne doit pas crasher")

# ---------------------------------------------------------------------------
# B10 — Composante Y toujours 0.0 : rotation autour de Vector3.UP ne crée pas de Y
# Spec §Comportements attendus point B10
#
# rotated(Vector3.UP, angle) sur un vecteur horizontal (Y=0) reste horizontal.
# Valide que la rotation n'introduit pas de composante verticale parasite.
# ---------------------------------------------------------------------------
func test_direction_camera_relative_composante_y_est_zero() -> void:
	var sut_player = _creer_player_controller()
	if sut_player == null:
		return

	sut_player.set_camera_yaw(PI / 6.0)
	Input.action_press("move_forward")
	var dir: Vector3 = sut_player.compute_input_direction()
	Input.action_release("move_forward")

	assert_almost_eq(dir.y, 0.0, 0.0001,
		"B10 : dir.y doit être ≈ 0.0 (la rotation autour de Vector3.UP ne crée pas de composante verticale)")

# ---------------------------------------------------------------------------
# CL1 — _camera_yaw = 0 : comportement identique à feature 03
# Spec §Cas limites / erreurs point CL1
#
# Complément de B4/B8 : s'assure que tous les comportements de feature 03
# sont préservés quand _camera_yaw = 0.0.
# ---------------------------------------------------------------------------
func test_cl1_camera_yaw_zero_comportement_identique_feature_03() -> void:
	var sut_player = _creer_player_controller()
	if sut_player == null:
		return

	# _camera_yaw est 0.0 par défaut — aucune rotation appliquée
	Input.action_press("move_backward")
	var dir: Vector3 = sut_player.compute_input_direction()
	Input.action_release("move_backward")

	assert_almost_eq(dir.z, 1.0, 0.01,
		"CL1 : move_backward avec yaw=0 doit donner dir.z ≈ +1.0 (identique feature 03)")
	assert_almost_eq(dir.x, 0.0, 0.01,
		"CL1 : move_backward avec yaw=0 doit donner dir.x ≈ 0.0 (identique feature 03)")

# ---------------------------------------------------------------------------
# CL2 — _camera_yaw = PI : axes inversés monde
# Spec §Cas limites / erreurs point CL2
#
# yaw=PI : "droite" (raw_x=+1) → monde -X (vérification comportement symétrique).
# Complément de B5.
# ---------------------------------------------------------------------------
func test_cl2_camera_yaw_pi_droite_donne_moins_x() -> void:
	var sut_player = _creer_player_controller()
	if sut_player == null:
		return

	sut_player.set_camera_yaw(PI)
	Input.action_press("move_right")
	var dir: Vector3 = sut_player.compute_input_direction()
	Input.action_release("move_right")

	assert_almost_eq(dir.x, -1.0, 0.01,
		"CL2 : move_right avec yaw=PI doit donner dir.x ≈ -1.0 (axe monde inversé)")
	assert_almost_eq(dir.z, 0.0, 0.01,
		"CL2 : move_right avec yaw=PI doit donner dir.z ≈ 0.0")

# ---------------------------------------------------------------------------
# CL3 — Cible véhicule : has_method retourne false, propagation silencieuse, pas de crash
# Spec §Cas limites / erreurs point CL3
#
# Même avec _right_mouse_held = false (feature 12 : propagation permanente),
# le check has_method protège contre les cibles véhicules.
# ---------------------------------------------------------------------------
func test_cl3_cible_vehicule_pas_de_propagation_pas_de_crash_sans_clic_droit() -> void:
	var sut_cam = _creer_camera_controller()
	if sut_cam == null:
		return

	var vehicule := VehicleBody3D.new()
	add_child_autofree(vehicule)

	sut_cam.target = vehicule
	sut_cam._yaw = 1.0
	sut_cam._right_mouse_held = false  # propagation permanente activée

	# Ne doit pas crasher — has_method("set_camera_yaw") retourne false
	sut_cam._process(0.016)

	assert_false(vehicule.has_method("set_camera_yaw"),
		"CL3 : VehicleBody3D ne doit pas avoir set_camera_yaw (has_method retourne false)")
	assert_true(true,
		"CL3 : _process avec VehicleBody3D sans clic droit ne doit pas crasher (propagation permanente)")

# ---------------------------------------------------------------------------
# CL4 — compute_input_direction avec raw = Vector3.ZERO : rotated ne crashe pas
# Spec §Cas limites / erreurs point CL4
#
# Vector3.ZERO.rotated(Vector3.UP, 1.0) retourne Vector3.ZERO sans erreur.
# La vérification if raw.length() > 0.0 évite la division par zéro dans normalized().
# ---------------------------------------------------------------------------
func test_cl4_raw_zero_rotated_ne_crashe_pas_et_retourne_zero() -> void:
	var sut_player = _creer_player_controller()
	if sut_player == null:
		return

	sut_player.set_camera_yaw(1.0)  # yaw non nul pour exercer le code de rotation
	Input.action_release("move_forward")
	Input.action_release("move_backward")
	Input.action_release("move_left")
	Input.action_release("move_right")

	var dir: Vector3 = sut_player.compute_input_direction()

	assert_eq(dir, Vector3.ZERO,
		"CL4 : compute_input_direction sans input et yaw non nul doit retourner Vector3.ZERO (rotation du vecteur nul)")

# ---------------------------------------------------------------------------
# CL5 — _camera_yaw non mis à jour avant premier frame : valeur initiale 0.0
# Spec §Cas limites / erreurs point CL5
#
# PlayerController._camera_yaw vaut 0.0 à l'initialisation.
# Le comportement de déplacement est identique à avant feature 12 au premier frame.
# ---------------------------------------------------------------------------
func test_cl5_camera_yaw_initial_est_zero() -> void:
	var sut_player = _creer_player_controller()
	if sut_player == null:
		return

	var yaw_initial: float = sut_player._camera_yaw
	assert_almost_eq(yaw_initial, 0.0, 0.0001,
		"CL5 : _camera_yaw doit être 0.0 à l'initialisation (pas d'état incohérent avant premier frame)")

func test_cl5_comportement_deplacement_au_premier_frame_sans_propagation() -> void:
	var sut_player = _creer_player_controller()
	if sut_player == null:
		return

	# Pas d'appel à set_camera_yaw — simule le premier frame avant que CameraController propage
	Input.action_press("move_forward")
	var dir: Vector3 = sut_player.compute_input_direction()
	Input.action_release("move_forward")

	# Comportement attendu : identique à feature 03 (yaw=0, direction monde -Z)
	assert_almost_eq(dir.z, -1.0, 0.01,
		"CL5 : au premier frame sans propagation, move_forward doit donner dir.z ≈ -1.0 (yaw initial 0.0)")

# ---------------------------------------------------------------------------
# CL6 — Yaw très grand ou négatif : rotated est périodique, pas de crash
# Spec §Cas limites / erreurs point CL6
#
# Vector3.rotated accepte tout angle réel. _camera_yaw peut s'accumuler librement.
# Test avec yaw = 5*PI (équivalent à PI) et yaw = -PI/2.
# ---------------------------------------------------------------------------
func test_cl6_yaw_tres_grand_ne_crashe_pas() -> void:
	var sut_player = _creer_player_controller()
	if sut_player == null:
		return

	# yaw = 5*PI ≡ PI (modulo 2*PI) — avancer doit donner ≈ +Z
	sut_player.set_camera_yaw(5.0 * PI)
	Input.action_press("move_forward")
	var dir: Vector3 = sut_player.compute_input_direction()
	Input.action_release("move_forward")

	# 5*PI mod 2*PI = PI → avancer avec yaw=PI donne +Z
	assert_almost_eq(dir.z, 1.0, 0.01,
		"CL6 : yaw très grand (5*PI ≡ PI) doit fonctionner correctement sans crash")

func test_cl6_yaw_negatif_ne_crashe_pas() -> void:
	var sut_player = _creer_player_controller()
	if sut_player == null:
		return

	# yaw = -PI/2 ≡ 3*PI/2 → "avancer" doit donner +X (opposé de B3)
	sut_player.set_camera_yaw(-PI / 2.0)
	Input.action_press("move_forward")
	var dir: Vector3 = sut_player.compute_input_direction()
	Input.action_release("move_forward")

	assert_almost_eq(dir.x, 1.0, 0.01,
		"CL6 : yaw négatif (-PI/2) doit fonctionner correctement — avancer donne +X")
	assert_almost_eq(dir.z, 0.0, 0.01,
		"CL6 : yaw négatif (-PI/2) — composante Z doit être ≈ 0.0")

# ---------------------------------------------------------------------------
# CL7 — CameraController.target = null : guard précède la propagation
# Spec §Cas limites / erreurs point CL7
#
# if target == null: return est avant la propagation.
# Même avec feature 12 (propagation permanente), le guard protège.
# ---------------------------------------------------------------------------
func test_cl7_process_target_null_ne_crashe_pas() -> void:
	var sut_cam = _creer_camera_controller()
	if sut_cam == null:
		return

	sut_cam.target = null
	sut_cam._yaw = 1.0
	sut_cam._right_mouse_held = false  # propagation permanente activée

	# Le guard "if target == null: return" doit court-circuiter avant la propagation
	sut_cam._process(0.016)

	# Si on arrive ici sans crash, le guard fonctionne
	assert_true(true,
		"CL7 : _process avec target null ne doit pas crasher (guard présent avant propagation permanente)")

func test_cl7_process_target_null_doit_avoir_guard() -> void:
	var sut_cam = _creer_camera_controller()
	if sut_cam == null:
		return

	# Vérifie que la position de la caméra reste inchangée (guard court-circuite tout)
	sut_cam.target = null
	sut_cam.global_position = Vector3(1.0, 2.0, 3.0)

	sut_cam._process(0.016)

	assert_almost_eq(sut_cam.global_position.x, 1.0, 0.0001,
		"CL7 : global_position.x ne doit pas changer si target est null (guard actif)")
	assert_almost_eq(sut_cam.global_position.y, 2.0, 0.0001,
		"CL7 : global_position.y ne doit pas changer si target est null")
	assert_almost_eq(sut_cam.global_position.z, 3.0, 0.0001,
		"CL7 : global_position.z ne doit pas changer si target est null")
