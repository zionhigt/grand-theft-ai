# Cahier des charges — Grand Theft AI

Document maître, vivant. Source de vérité unique de l'état du projet. Chaque agent met à jour la ou les colonnes qui le concernent à la fin de son tour.

## Vision

Un jeu 3D **desktop** sous **Godot 4**, inspiré de GTA : ville ouverte minimale, personnage à pied, voitures conduisibles, caméra troisième personne. Objectif court terme : **prototype jouable v0.1**.

## Stack imposée

- Godot 4 (moteur, rendu 3D, physique intégrée, éditeur visuel)
- GDScript (langage des scripts `.gd`)
- GUT — Godot Unit Test — addon dans `addons/gut/`

Aucune autre dépendance sans justification écrite dans une spec.

## Conventions de nommage

- Numérotation des features : ordre de prise en charge, sur 2 chiffres (`01`, `02`, ...).
- Fichiers de design : `docs/design/<NN>-<slug-feature>.md`.
- Bons de commande graphique : `docs/assets/<NN>-<slug-feature>.md`.
- Specs techniques : `docs/specs/<NN>-<slug-feature>.md`.
- Tests GUT : `tests/test_<NN>_<slug_feature>.gd` (snake_case, préfixe `test_` imposé par GUT).
- Scripts de production : `src/<NN>_<slug_feature>/*.gd` ou `src/<domaine>/*.gd` selon la spec.
- Scènes réutilisables : `scenes/<NN>_<slug_feature>/*.tscn`.

## Statuts possibles dans le tableau

`à faire`, `design écrit`, `bon de commande émis`, `spec écrite`, `tests rouges`, `implémenté`, `n/a` (colonne sans objet pour cette feature).

## État des features

Colonnes :
- **Design** : design doc rédigé par `designer`.
- **Assets** : bon de commande graphique rédigé par `designer`. `n/a` pour les features purement techniques sans asset.
- **Spec** : spec technique rédigée par `specifier`.
- **Tests** : tests GUT rouges écrits par `tester`.
- **Implémentation** : code GDScript / scènes en vert sous GUT par `developer`.

| N° | Feature | Design | Assets | Spec | Tests | Implémentation |
|----|---------|--------|--------|------|-------|----------------|
| 01 | Bootstrap projet (Godot 4 + GUT)             | design écrit | n/a    | spec écrite | tests rouges (non exécutés — godot indisponible) | implémenté (validation GUT à confirmer sur poste) |
| 02 | Scène 3D minimale (sol + ciel + lumière + caméra fixe) | design écrit | bon de commande émis | spec écrite | à faire | à faire |
| 03 | Personnage joueur déplaçable (ZQSD/WASD)     | à faire | à faire | à faire | à faire | à faire |
| 04 | Caméra troisième personne suivant le joueur  | à faire | n/a    | à faire | à faire | à faire |
| 05 | Ville minimale (sol étendu + bâtiments cubiques) | à faire | à faire | à faire | à faire | à faire |
| 06 | Voiture (mesh + corps physique de base)      | à faire | à faire | à faire | à faire | à faire |
| 07 | Entrer / sortir d'un véhicule (touche E)     | à faire | n/a    | à faire | à faire | à faire |
| 08 | Conduite (accélérer, freiner, tourner)       | à faire | n/a    | à faire | à faire | à faire |

## Critères du prototype v0.1 jouable

- [ ] Le projet Godot s'ouvre sans erreur dans l'éditeur Godot 4
- [ ] La commande `godot --headless -s res://addons/gut/gut_cmdln.gd -gdir=res://tests -gexit` retourne 0 (tous tests verts)
- [ ] `godot --path . res://main.tscn` lance le jeu sans erreur dans la console
- [ ] Le joueur voit une ville minimale en 3D (sol, ciel, bâtiments cubiques)
- [ ] Le joueur déplace son personnage au clavier (ZQSD/WASD)
- [ ] Le joueur peut entrer dans une voiture avec la touche E
- [ ] La voiture se conduit (accélérer, freiner, tourner)
- [ ] La caméra troisième personne suit le joueur ou la voiture sans à-coups visibles

## Règle d'or asset

Aucune référence d'asset ne pointe dans le vide. Tant qu'un asset final (`.glb`, `.png`, `.ogg`, ...) n'est pas livré, son **mock primitif Godot** (CSGBox, CSGCylinder, BoxMesh, CapsuleMesh, SphereMesh, etc.) le remplace au même rôle dans la scène, avec dimensions et couleur fixées par le bon de commande et un commentaire `# MOCK — à remplacer par <chemin>`.
