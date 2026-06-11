# Échange tester → developer — Feature 05 Ville minimale

**Date** : 2026-05-31
**De** : tester
**À** : developer

## Objet

Les tests GUT de la feature 05 ont été écrits dans `tests/test_05_ville_minimale.gd`.
Ils sont en phase rouge attendue : `scenes/city/city.tscn` n'existe pas encore et
`main.tscn` n'a pas encore le nœud `City` instancié.

## Impossibilité d'exécution GUT dans l'environnement CI

La commande :
```
godot --headless -s res://addons/Gut-9.6.0/addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```
ne peut pas être exécutée depuis le shell Bash sandboxé de l'agent (environnement Linux
qui ne peut pas invoquer les binaires `.exe` Windows, même si `godot.exe` est présent
dans `C:/Users/larch/godot/`).

Le code de retour attendu est **non zéro** (tests rouges) puisque les ressources
suivantes sont absentes :
- `res://scenes/city/city.tscn`
- Le nœud `City` dans `res://main.tscn`

## Ce que le developer doit faire

1. Implémenter `scenes/city/city.tscn` selon la spec `docs/specs/05-ville-minimale.md` :
   - Nœud racine `City : Node3D` sans script
   - 8 enfants `StaticBody3D` (Batiment1 à Batiment8) chacun avec un `CollisionShape3D`
     (BoxShape3D) et un `MeshInstance3D` (BoxMesh) décalés de `hauteur/2` sur Y
   - Positions, dimensions et couleurs exactes selon le tableau de la spec
2. Modifier `main.tscn` pour y ajouter le nœud `City` (instance de `city.tscn`)
   en dernière position parmi les enfants de `Main`, à `Vector3(0, 0, 0)`.
3. Valider que :
   ```
   godot --headless -s res://addons/Gut-9.6.0/addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
   ```
   retourne le code 0 (20 tests verts : B1–B15 + CL1–CL5).

## Fichier de test

`tests/test_05_ville_minimale.gd` — 20 fonctions de test (B1 à B15, CL1 à CL5).
