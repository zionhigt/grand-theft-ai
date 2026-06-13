extends Node3D
## Modèle 3D animé du joueur : charge le mesh Mixamo (idle) et y injecte l'anim de marche,
## puis bascule idle <-> marche selon la vitesse, en fondu enchaîné via l'AnimationPlayer.
## Remplace le mock capsule ; la capsule de collision reste côté CharacterBody3D parent.

const CHEMIN_IDLE := "res://assets/characters/player/player_idle.glb"
const CHEMIN_MARCHE := "res://assets/characters/player/player_walk.glb"
const ANIM_IDLE := "mixamo_com"   # nom natif de l'animation dans les GLB Mixamo
const ANIM_MARCHE := "marche"     # anim de marche injectée sous ce nom
const SEUIL_MARCHE := 0.6         # m/s au-dessus duquel on joue la marche
const FONDU := 0.2                # durée du fondu enchaîné, en secondes

var _player: AnimationPlayer
var _anim_courante := ""


func _ready() -> void:
	var modele: Node = load(CHEMIN_IDLE).instantiate()
	add_child(modele)
	_player = modele.find_child("AnimationPlayer", true, false)
	var idle: Animation = _player.get_animation(ANIM_IDLE)
	idle.loop_mode = Animation.LOOP_LINEAR
	_verrouiller_sur_place(idle)
	_injecter_marche()
	_jouer(ANIM_IDLE)


## Récupère l'anim de marche d'un second GLB (mêmes pistes squelette) et l'ajoute à notre AnimationPlayer.
func _injecter_marche() -> void:
	var source: Node = load(CHEMIN_MARCHE).instantiate()
	var ap_source: AnimationPlayer = source.find_child("AnimationPlayer", true, false)
	var marche: Animation = ap_source.get_animation(ANIM_IDLE).duplicate()
	marche.loop_mode = Animation.LOOP_LINEAR
	_verrouiller_sur_place(marche)
	_player.get_animation_library("").add_animation(ANIM_MARCHE, marche)
	source.free()


## Neutralise le déplacement horizontal du bassin (root motion Mixamo non « In Place ») :
## le code déplace le corps, l'anim ne doit plus glisser ni se réinitialiser à chaque boucle.
## On verrouille X/Z sur la 1re clé et on garde Y (balancement vertical naturel).
func _verrouiller_sur_place(anim: Animation) -> void:
	for i in anim.get_track_count():
		if anim.track_get_type(i) != Animation.TYPE_POSITION_3D:
			continue
		if not str(anim.track_get_path(i)).contains("Hips"):
			continue
		var n := anim.track_get_key_count(i)
		if n == 0:
			return
		var base: Vector3 = anim.track_get_key_value(i, 0)
		for k in n:
			var v: Vector3 = anim.track_get_key_value(i, k)
			anim.track_set_key_value(i, k, Vector3(base.x, v.y, base.z))
		return


## Appelée par le joueur (call down) avec sa vitesse horizontale en m/s.
func definir_vitesse(vitesse: float) -> void:
	_jouer(ANIM_MARCHE if vitesse > SEUIL_MARCHE else ANIM_IDLE)


func _jouer(nom: String) -> void:
	if nom == _anim_courante:
		return
	_anim_courante = nom
	_player.play(nom, FONDU)
