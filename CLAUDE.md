# Grand Theft AI

Jeu 3D desktop inspiré de GTA, développé sous **Godot 4** par une équipe de quatre agents Claude spécialisés et coordonnés.

## Objectif

Itérer jusqu'à obtenir un **premier prototype jouable** : un personnage que l'on déplace dans un environnement 3D, qui peut monter dans un véhicule et le conduire dans une ville minimale, le tout exécuté par le moteur Godot 4 sur poste.

## Stack technique

- **Moteur** : Godot 4 (rendu 3D natif, physique intégrée, éditeur visuel, scènes `.tscn`)
- **Langage** : GDScript (scripts `.gd`)
- **Tests unitaires** : GUT (Godot Unit Test) — addon installé dans `addons/gut/`
- **Exécution headless des tests** :
  ```
  godot --headless -s res://addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
  ```
- **Lancement du jeu** : ouvrir le projet dans l'éditeur Godot et lancer la scène principale `main.tscn`, ou en ligne de commande :
  ```
  godot --path . res://main.tscn
  ```

Pas de navigateur, pas de Web, pas de bundler, pas de TypeScript. Tout passe par Godot.

## Architecture des agents

Quatre agents coexistent et coopèrent. **Chaque tâche doit être exécutée par l'agent dont c'est le rôle** — pas de chevauchement. Les agents sont définis dans `.claude/agents/` et invoqués via le tool `Agent`.

| Agent | Rôle |
|---|---|
| `designer` | Conçoit le game design **et** émet le bon de commande graphique (liste d'assets + arborescence `assets/`) |
| `specifier` | Rédige la spécification technique GDScript / Godot avant toute implémentation |
| `tester` | Écrit les tests GUT (TDD strict) qui doivent échouer avant que le code n'existe |
| `developer` | Implémente la feature en GDScript / scènes `.tscn` jusqu'à ce que les tests passent |

### Flux obligatoire d'une feature

```
designer ──► specifier ──► tester ──► developer ──► (boucle si tests rouges)
```

1. **`designer`** produit `docs/design/<NN>-<slug>.md` (game design) **et** `docs/assets/<NN>-<slug>.md` (bon de commande graphique).
2. **`specifier`** produit `docs/specs/<NN>-<slug>.md` (API GDScript, structure de scènes, comportements numérotés testables) et met à jour le cahier des charges.
3. **`tester`** produit `tests/test_<NN>_<slug>.gd` (GUT, rouges).
4. **`developer`** produit le code dans `src/` (scripts `.gd`), les scènes dans `scenes/` (`.tscn`), et matérialise les dossiers et mocks d'assets définis par le bon de commande, jusqu'à ce que les tests GUT passent au vert.

Aucun agent ne saute une étape. Le `developer` ne commence **jamais** sans tests rouges existants. Le `tester` ne commence **jamais** sans spec écrite. Le `specifier` ne commence **jamais** sans design **et** bon de commande.

## Documents partagés

- **`docs/cahier-des-charges.md`** — document maître, vivant. Liste les features décidées et leur état d'avancement. Source de vérité.
- **`docs/design/<NN>-<slug>.md`** — game design d'une feature (rédigé par `designer`).
- **`docs/assets/<NN>-<slug>.md`** — bon de commande graphique (rédigé par `designer`). Spécifie les assets, leurs chemins exacts dans `assets/`, le budget polycount et les mocks primitives en attendant les assets finaux.
- **`docs/specs/<NN>-<slug>.md`** — spec technique Godot / GDScript (rédigée par `specifier`).
- **`docs/exchanges/`** — fichiers d'échange entre agents. Format : `YYYY-MM-DD-from-<agent>-to-<agent>-<sujet>.md`.

## Arborescence du projet

```
.
├── project.godot         # projet Godot 4
├── main.tscn             # scène d'entrée
├── src/                  # scripts GDScript de production (.gd)
├── scenes/               # scènes .tscn réutilisables
├── assets/               # modèles, textures, sons, matériaux (arborescence figée par les bons de commande)
├── tests/                # tests GUT (test_*.gd)
├── addons/gut/           # framework de test GUT
├── docs/                 # documentation vivante
└── .claude/agents/       # configurations des agents
```

## Boucle d'itération

Une itération = une feature complète passée par les quatre agents. La boucle s'arrête quand le **prototype jouable v0.1** est atteint :

- [ ] Le projet Godot s'ouvre sans erreur et `main.tscn` se lance
- [ ] Une scène 3D s'affiche (sol, ciel, éclairage)
- [ ] Une ville minimale (sol + quelques bâtiments cubiques) est visible
- [ ] Un personnage est rendu et déplaçable au clavier (ZQSD / WASD)
- [ ] Une caméra troisième personne suit le joueur (et la voiture quand il y monte)
- [ ] Une voiture est présente, le joueur peut y entrer / sortir (touche E)
- [ ] La voiture se conduit (accélérer, freiner, tourner)
- [ ] La commande `godot --headless -s res://addons/gut/gut_cmdln.gd -gdir=res://tests -gexit` retourne un code 0

## Règles non négociables

1. Pas de code dans `src/` ou `scenes/` sans test correspondant dans `tests/`.
2. Pas de test sans spec dans `docs/specs/`.
3. Pas de spec sans design **et** bon de commande dans `docs/design/` + `docs/assets/`.
4. Pas d'asset ajouté sous `assets/` sans bon de commande qui le déclare.
5. **Tant qu'un asset final n'est pas livré, il est obligatoirement remplacé par un mock primitif Godot** (CSGBox, CSGCylinder, BoxMesh, CapsuleMesh, etc.) placé exactement au chemin et au rôle prévus par le bon de commande, avec dimensions et couleur spécifiées et un commentaire `# MOCK — à remplacer par <chemin du futur asset>` au-dessus du nœud / de l'instanciation. Le jeu doit toujours être lançable, jamais bloqué en attente d'un asset.
6. Toute question ou blocage d'un agent vers un autre passe par un fichier dans `docs/exchanges/`.
7. Le cahier des charges est la source de vérité de l'état du projet : chaque agent met à jour la ou les colonnes qui le concernent à la fin de son tour.
