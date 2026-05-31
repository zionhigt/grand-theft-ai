# Design 01 — Bootstrap projet (Godot 4.6 + GUT)

## Pitch (1 phrase)

Mettre en place le squelette technique du projet Godot 4.6 pour que la commande `godot --path . res://main.tscn` se lance sans erreur et que la suite GUT puisse s'exécuter en mode headless.

## Pourquoi cette feature (valeur joueur)

Néant — feature purement technique. Aucun joueur n'interagit avec ce qui est mis en place ici. La valeur est pour l'équipe de développement : sans ce socle, aucune feature de gameplay ne peut être implémentée ni testée.

## Description détaillée

À l'issue de cette feature, le projet présente l'état minimal suivant :

- Un fichier `project.godot` valide, configuré pour Godot 4.6 (nom du projet : "Grand Theft AI", point d'entrée : `res://main.tscn`).
- Une scène principale `main.tscn` qui se lance et affiche un fond uni (couleur de fond par défaut du moteur, aucun contenu 3D). Aucune interaction n'est possible.
- L'addon GUT est présent et activé dans `addons/gut/`. La commande headless `godot --headless -s res://addons/gut/gut_cmdln.gd -gdir=res://tests -gexit` s'exécute et retourne le code 0 (suite vide, aucun test échoue).
- Les dossiers `src/`, `scenes/`, `assets/`, `tests/` existent (vides ou avec un `.gitkeep`).

Le joueur qui lancerait le jeu à cette étape verrait uniquement un écran vide avec la couleur de fond Godot par défaut (gris foncé). Aucune scène 3D, aucun personnage, aucun son.

## Contrôles / inputs

Néant — aucune touche clavier n'est mappée à cette étape.

## Feedback joueur

Néant — aucun feedback visuel, sonore ou de caméra n'est produit. L'écran reste statique avec le fond par défaut de Godot.

## Règles et limites

Néant — aucune règle de gameplay. Contraintes techniques uniquement :

- Le projet doit être ouvert et exécutable avec Godot 4.6.
- GUT doit être la version compatible Godot 4.6 (v9.4 ou supérieure).
- La commande headless doit retourner le code de sortie 0 avec une suite de tests vide.

## Dépendances de design

Aucune — c'est la feature racine du projet.

## Hors-périmètre

- Toute scène 3D (sol, ciel, éclairage) : feature 02.
- Tout personnage, véhicule, bâtiment : features 03, 05, 06.
- Toute configuration d'inputs clavier : feature 03 et suivantes.
- Tout écran de menu ou HUD.
