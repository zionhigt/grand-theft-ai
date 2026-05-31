# Grand Theft AI

Jeu 3D inspiré de GTA, développé par une équipe de quatre agents Claude spécialisés et coordonnés.

## Objectif

Itérer jusqu'à obtenir un **premier prototype jouable** : un personnage que l'on déplace dans un environnement 3D, qui peut monter dans un véhicule et le conduire dans une ville minimale.

## Stack technique

- **Moteur** : Godot 4 (rendu 3D natif, éditeur intégré)
- **Langage** : GDScript
- **Tests unitaires** : GUT (Godot Unit Test) — addon dans `addons/gut/`
- **Exécution headless des tests** : `godot --headless -s res://addons/gut/gut_cmdln.gd -gdir=res://tests -gexit`
- **Lancement du jeu** : ouvrir le projet dans l'éditeur Godot, ou `godot --path . res://main.tscn`

## Architecture des agents

Quatre agents coexistent et coopèrent. **Chaque tâche doit être exécutée par l'agent dont c'est le rôle** — pas de chevauchement. Les agents sont définis dans `.claude/agents/` et invoqués via le tool `Agent`.

| Agent | Rôle | Tools |
|---|---|---|
| `specifier` | Rédige les spécifications techniques avant toute implémentation | Read, Write, Edit, Bash (lecture) |
| `designer` | Spécifie le game design **et** émet le bon de commande graphique (assets + arborescence `assets/`) | Read, Write, Edit |
| `tester` | Écrit les tests unitaires **avant** que le code ne soit développé (TDD) | Read, Write, Edit, Bash |
| `developer` | Implémente la feature pour faire passer les tests | Read, Write, Edit, Bash |

### Flux obligatoire d'une feature

```
designer ──► specifier ──► tester ──► developer ──► (boucle si tests rouges)
```

1. **`designer`** décrit la feature côté game design dans `docs/design/` **et** émet le bon de commande graphique dans `docs/assets/` (liste des modèles/textures/sons + arborescence `assets/` cible).
2. **`specifier`** écrit la spécification technique correspondante dans `docs/specs/` et met à jour le cahier des charges. Il s'appuie sur le bon de commande pour figer les chemins d'assets dans la spec.
3. **`tester`** écrit les tests unitaires dans `tests/` à partir de la spec. Les tests doivent échouer (red).
4. **`developer`** implémente le code dans `src/` (et les scènes dans `scenes/`) jusqu'à ce que tous les tests passent (green). Il crée aussi les dossiers et placeholders d'assets définis par le bon de commande.

Aucun agent ne peut sauter une étape. Le `developer` ne commence **jamais** sans tests rouges existants. Le `tester` ne commence **jamais** sans spec écrite.

## Documents partagés

- **`docs/cahier-des-charges.md`** — document maître, vivant, qui liste l'ensemble des features décidées et leur état d'avancement. Mis à jour par le `specifier` à chaque nouvelle feature.
- **`docs/design/`** — un fichier markdown par feature, rédigé par `designer`.
- **`docs/assets/`** — un bon de commande graphique par feature, rédigé par `designer`. Spécifie la liste des assets, leurs chemins exacts dans `assets/`, et l'arborescence cible.
- **`docs/specs/`** — un fichier markdown par feature, rédigé par `specifier`.
- **`docs/exchanges/`** — fichiers d'échange entre agents (questions, clarifications, blocages). Format : `YYYY-MM-DD-from-<agent>-to-<agent>-<sujet>.md`.

## Boucle d'itération

Une itération = une feature complète passée par les quatre agents. La boucle s'arrête quand le **prototype jouable v0.1** est atteint :

- [ ] Une scène 3D s'affiche dans le navigateur
- [ ] Un personnage est rendu et déplaçable au clavier (ZQSD/WASD)
- [ ] Une ville minimale (sol + quelques bâtiments cubiques) existe
- [ ] Une voiture est présente, le joueur peut y entrer
- [ ] La voiture se conduit (avancer, reculer, tourner)
- [ ] Caméra à la troisième personne qui suit le joueur ou la voiture
- [ ] Tous les tests GUT écrits passent (commande `godot --headless -s res://addons/gut/gut_cmdln.gd -gdir=res://tests -gexit`)
- [ ] Ouvrir le projet dans Godot et lancer `main.tscn` ne produit aucune erreur

## Règles non négociables

1. Pas de code dans `src/` sans test correspondant dans `tests/`.
2. Pas de test sans spec dans `docs/specs/`.
3. Pas de spec sans design **et** bon de commande dans `docs/design/` + `docs/assets/`.
4. Pas d'asset (modèle, texture, son) ajouté dans `assets/` sans bon de commande qui le déclare.
5. **Tant qu'un asset final n'est pas livré, il est obligatoirement remplacé par un mock — primitive Godot (CSGBox, CSGCylinder, CSGSphere, BoxMesh, etc.) avec un matériau uni de couleur identifiable** — placé exactement au chemin prévu par le bon de commande. Le jeu doit toujours être lançable, jamais bloqué en attente d'un asset.
6. Chaque mock doit être tracé : le bon de commande indique `placeholder = oui` pour les assets non encore finalisés, et le scene/script qui l'utilise contient un commentaire `# MOCK — à remplacer par <chemin du futur asset>`.
7. Toute question d'un agent à un autre passe par un fichier dans `docs/exchanges/`.
8. Le cahier des charges (`docs/cahier-des-charges.md`) est la source de vérité de l'état du projet.
