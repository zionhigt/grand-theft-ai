# Cahier des charges — Grand Theft AI

Document maître, vivant. Mis à jour par l'agent `specifier` à chaque nouvelle feature et par `developer` quand une feature passe au statut "implémenté".

## Vision

Un jeu 3D navigateur, inspiré de GTA : ville ouverte minimale, personnage à pied, voitures conduisibles, caméra troisième personne. Objectif court terme : **prototype jouable v0.1**.

## Stack imposée

- Godot 4 (moteur, rendu 3D, physique intégrée)
- GDScript (langage)
- GUT (Godot Unit Test) pour les tests unitaires

## État des features

Colonnes : `Design` couvre design doc + bon de commande graphique. `Assets` indique si le bon de commande a effectivement été matérialisé dans le projet (dossiers et placeholders créés par le developer).

| N° | Feature | Design | Assets | Spec | Tests | Implémentation |
|----|---------|--------|--------|------|-------|----------------|
| 01 | Bootstrap projet (Godot 4 + GUT) | à faire | n/a | à faire | à faire | à faire |
| 02 | Scène 3D minimale (sol + ciel + caméra) | à faire | à faire | à faire | à faire | à faire |
| 03 | Personnage joueur déplaçable (ZQSD) | à faire | à faire | à faire | à faire | à faire |
| 04 | Caméra troisième personne | à faire | n/a | à faire | à faire | à faire |
| 05 | Ville minimale (sol + bâtiments cubiques) | à faire | à faire | à faire | à faire | à faire |
| 06 | Voiture (mesh + physique de base) | à faire | à faire | à faire | à faire | à faire |
| 07 | Entrer / sortir d'un véhicule (touche E) | à faire | n/a | à faire | à faire | à faire |
| 08 | Conduite (accélérer, freiner, tourner) | à faire | n/a | à faire | à faire | à faire |

## Critères du prototype v0.1 jouable

- [ ] Le projet s'ouvre dans Godot 4 et lance `main.tscn` sans erreur
- [ ] La commande `godot --headless -s res://addons/gut/gut_cmdln.gd -gdir=res://tests -gexit` retourne 0 (tous tests verts)
- [ ] Le joueur voit une ville minimale en 3D
- [ ] Le joueur déplace son personnage au clavier
- [ ] Le joueur peut entrer dans une voiture et la conduire
- [ ] La caméra suit le joueur ou la voiture en 3e personne

## Conventions

- Numérotation des features : ordre de prise en charge, sur 2 chiffres.
- Les fichiers `design/`, `specs/` et `tests/` partagent le même préfixe `NN-<slug>`.
- Statuts possibles : `à faire`, `design écrit`, `spec écrite`, `tests rouges`, `implémenté`.
