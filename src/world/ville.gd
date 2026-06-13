extends Node3D
## Ville mock : pose 8 bâtiments BoxMesh avec collision, en blocs séparés par des rues praticables.
## MOCK — chaque bâtiment sera remplacé par res://assets/city/buildings/batiment_N.glb une fois livré.

const ESPACEMENT := 22.0  # distance entre centres de cellules ; laisse ~10-12 m de rue

# taille = largeur(x) × hauteur(y) × profondeur(z) ; cellule (colonne, rangée) d'une grille 3×3 (centre vide = spawn).
const BATIMENTS := [
	{"taille": Vector3(6, 12, 6), "cellule": Vector2(-1, -1)},
	{"taille": Vector3(8, 8, 8), "cellule": Vector2(0, -1)},
	{"taille": Vector3(5, 6, 10), "cellule": Vector2(1, -1)},
	{"taille": Vector3(10, 5, 6), "cellule": Vector2(-1, 0)},
	{"taille": Vector3(6, 10, 6), "cellule": Vector2(1, 0)},
	{"taille": Vector3(7, 7, 7), "cellule": Vector2(-1, 1)},
	{"taille": Vector3(4, 14, 4), "cellule": Vector2(0, 1)},
	{"taille": Vector3(12, 4, 5), "cellule": Vector2(1, 1)},
]


func _ready() -> void:
	for i in BATIMENTS.size():
		_poser_batiment(i, BATIMENTS[i])


func _poser_batiment(index: int, spec: Dictionary) -> void:
	var taille: Vector3 = spec.taille
	var cellule: Vector2 = spec.cellule
	var corps := StaticBody3D.new()
	corps.name = "Batiment%d" % (index + 1)
	corps.collision_layer = 1  # couche 1 = environnement (joueur mask=1 et bras de caméra mask=1 collisionnent)
	# y = moitié de la hauteur pour poser la boîte sur le sol.
	corps.position = Vector3(cellule.x * ESPACEMENT, taille.y * 0.5, cellule.y * ESPACEMENT)

	var mesh := MeshInstance3D.new()
	var boite := BoxMesh.new()
	boite.size = taille
	mesh.mesh = boite
	mesh.material_override = _materiau(index)
	corps.add_child(mesh)

	var collision := CollisionShape3D.new()
	var forme := BoxShape3D.new()
	forme.size = taille
	collision.shape = forme
	corps.add_child(collision)

	add_child(corps)


## Gris légèrement varié pour distinguer les blocs sans bruit visuel.
func _materiau(index: int) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	var teinte := 0.42 + 0.09 * (index % 3)
	mat.albedo_color = Color(teinte, teinte, teinte * 1.06)
	return mat
