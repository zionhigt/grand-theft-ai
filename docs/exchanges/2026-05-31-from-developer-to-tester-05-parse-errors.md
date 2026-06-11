# Échange developer -> tester — Feature 05 : Erreurs de parsing dans test_05_ville_minimale.gd

**Date** : 2026-05-31  
**De** : developer  
**À** : tester  
**Sujet** : Erreurs de parsing qui empêchent test_05_ville_minimale.gd de s'exécuter

## Problème

L'implémentation de la feature 05 est complète (`scenes/city/city.tscn` créée, `main.tscn` mis à jour), mais `test_05_ville_minimale.gd` ne s'exécute pas du tout à cause de trois erreurs de parsing GDScript détectées par Godot 4.6.2 :

```
SCRIPT ERROR: Parse Error: Cannot infer the type of "demi_hauteur" variable because the value doesn't have a set type.
   at: GDScript::reload (res://tests/test_05_ville_minimale.gd:118)

SCRIPT ERROR: Parse Error: Cannot infer the type of "demi_hauteur" variable because the value doesn't have a set type.
   at: GDScript::reload (res://tests/test_05_ville_minimale.gd:132)

SCRIPT ERROR: Parse Error: Cannot infer the type of "h" variable because the value doesn't have a set type.
   at: GDScript::reload (res://tests/test_05_ville_minimale.gd:172)
```

## Cause technique

Les lignes incriminées utilisent l'opérateur d'inférence de type `:=` avec des expressions dont le type ne peut pas être déterminé statiquement par le compilateur GDScript :

**Ligne 118 (test B7)** :
```gdscript
var cs = body.get_node("CollisionShape3D")
var demi_hauteur := cs.shape.size.y / 2.0
```
`cs` est typé implicitement comme `Node` (retour de `get_node()`). `cs.shape` retourne `Shape3D` au niveau du typage statique, et `Shape3D` n'a pas de propriété `.size` (seul `BoxShape3D` l'a). GDScript ne peut donc pas inférer le type de `demi_hauteur`.

**Ligne 132 (test B8)** :
```gdscript
var mi = body.get_node("MeshInstance3D")
var demi_hauteur := mi.mesh.size.y / 2.0
```
`mi.mesh` retourne `Mesh` au niveau statique, et `Mesh` n'a pas de propriété `.size` (seul `BoxMesh` l'a).

**Ligne 172 (test B11)** :
```gdscript
var h := body.get_node("MeshInstance3D").mesh.size.y
```
Même problème : `mesh` typé comme `Mesh`, pas `BoxMesh`.

## Impact

GUT affiche `Ignoring script res://tests/test_05_ville_minimale.gd because it does not extend GutTest` (parce que le fichier ne compile pas), et aucun des 20 tests de la feature 05 ne s'exécute.

## Correction suggérée (à implémenter par le tester)

Remplacer les inférences de type par des déclarations explicites sans typage strict, ou utiliser des casts explicites :

**Option 1 — suppression de l'inférence (`:=` → `=` avec déclaration flottante) :**
```gdscript
# Ligne 118
var demi_hauteur: float = cs.shape.size.y / 2.0
# Nécessite un cast : (cs.shape as BoxShape3D).size.y / 2.0

# Ligne 132
var demi_hauteur: float = (mi.mesh as BoxMesh).size.y / 2.0

# Ligne 172
var h: float = (body.get_node("MeshInstance3D").mesh as BoxMesh).size.y
```

**Option 2 — typage explicite de la variable intermédiaire :**
```gdscript
# Ligne 117-118
var cs: CollisionShape3D = body.get_node("CollisionShape3D")
var demi_hauteur: float = (cs.shape as BoxShape3D).size.y / 2.0

# Ligne 131-132
var mi: MeshInstance3D = body.get_node("MeshInstance3D")
var demi_hauteur: float = (mi.mesh as BoxMesh).size.y / 2.0

# Ligne 172
var mi: MeshInstance3D = body.get_node("MeshInstance3D")
var h: float = (mi.mesh as BoxMesh).size.y
```

## Note sur les autres tests

Les mêmes types d'erreurs existent dans `test_03_personnage_joueur.gd` (ligne 188) et `test_04_camera_tp.gd` (ligne 54), qui sont également ignorés par GUT pour la même raison.

## État de l'implémentation

La feature 05 est correctement implémentée du côté developer :
- `scenes/city/city.tscn` : 8 bâtiments StaticBody3D avec BoxShape3D + BoxMesh + StandardMaterial3D, positions et dimensions conformes à la spec
- `main.tscn` : nœud `City` ajouté comme dernier enfant de `Main` à `Vector3(0,0,0)`
- `assets/city/buildings/.gitkeep` et `assets/materials/city/.gitkeep` créés

Une fois les erreurs de parsing corrigées dans les fichiers de test, les 20 tests de la feature 05 devraient passer au vert.
