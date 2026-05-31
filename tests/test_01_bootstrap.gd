extends GutTest

# Tests unitaires — Feature 01 : Bootstrap projet (Godot 4 + GUT)
#
# Chaque test cible un comportement numéroté de la spec docs/specs/01-bootstrap.md.
#
# Stratégie d'instanciation de Game :
#   Game étend Node et son comportement clé se déclenche dans _ready().
#   Pour tester sans montage dans une scène active, on charge le script,
#   on instancie le Node, puis on appelle _ready() directement.
#   Cela évite la dépendance à un SceneTree complet tout en validant
#   la logique applicative exposée par is_bootstrapped() et version_label.

# Préchargement des scripts sous test.
# Si les fichiers n'existent pas encore, GUT produira une erreur de chargement
# — comportement attendu en phase rouge (TDD).
const VersionInfoScript = preload("res://src/core/version_info.gd")
const GameScript = preload("res://src/core/game.gd")

# ---------------------------------------------------------------------------
# SUT Game — un Node instancié manuellement pour chaque test
# ---------------------------------------------------------------------------

var game: Node

func before_each() -> void:
	game = GameScript.new()

func after_each() -> void:
	if is_instance_valid(game):
		game.free()

# ---------------------------------------------------------------------------
# Comportement 1 — VersionInfo.GAME_NAME
# Spec §Comportements attendus point 1
# ---------------------------------------------------------------------------
func test_le_nom_du_jeu_est_grand_theft_ai() -> void:
	assert_eq(VersionInfoScript.GAME_NAME, "Grand Theft AI")

# ---------------------------------------------------------------------------
# Comportement 2 — VersionInfo.GAME_VERSION
# Spec §Comportements attendus point 2
# ---------------------------------------------------------------------------
func test_la_version_est_la_chaine_du_bootstrap() -> void:
	assert_eq(VersionInfoScript.GAME_VERSION, "0.1.0-bootstrap")

# ---------------------------------------------------------------------------
# Comportement 3 — VersionInfo.get_full_label()
# Spec §Comportements attendus point 3
# ---------------------------------------------------------------------------
func test_get_full_label_renvoie_le_nom_et_la_version_concatenes() -> void:
	var label: String = VersionInfoScript.get_full_label()
	assert_eq(label, "Grand Theft AI 0.1.0-bootstrap")

# ---------------------------------------------------------------------------
# Comportement 4 — Game non initialisé → is_bootstrapped() == false
# Spec §Comportements attendus point 4
# Note : _ready() n'est PAS appelé ici ; on vérifie l'état initial brut.
# ---------------------------------------------------------------------------
func test_un_game_avant_ready_n_est_pas_bootstrap() -> void:
	assert_false(game.is_bootstrapped())

# ---------------------------------------------------------------------------
# Comportement 5 — Game après _ready() → is_bootstrapped() == true
# Spec §Comportements attendus point 5
# ---------------------------------------------------------------------------
func test_un_game_apres_ready_est_bootstrap() -> void:
	game._ready()
	assert_true(game.is_bootstrapped())

# ---------------------------------------------------------------------------
# Comportement 6 — Game.version_label après _ready() = get_full_label()
# Spec §Comportements attendus point 6
# ---------------------------------------------------------------------------
func test_le_version_label_du_game_apres_ready_correspond_au_full_label() -> void:
	game._ready()
	assert_eq(game.version_label, VersionInfoScript.get_full_label())

# ---------------------------------------------------------------------------
# Cas limite — idempotence de _ready()
# Spec §Cas limites / erreurs point 1
# Deux appels consécutifs à _ready() :
#   - is_bootstrapped() reste true
#   - version_label n'est pas altéré (pas de duplication, pas de réinitialisation)
# ---------------------------------------------------------------------------
func test_ready_appele_deux_fois_reste_idempotent() -> void:
	game._ready()
	var label_apres_premier_appel: String = game.version_label
	game._ready()
	assert_true(game.is_bootstrapped())
	assert_eq(game.version_label, label_apres_premier_appel)
	assert_eq(game.version_label, "Grand Theft AI 0.1.0-bootstrap")
