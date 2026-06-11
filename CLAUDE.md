# Grand Theft AI

Jeu 3D desktop inspiré de GTA, développé sous **Godot 4.6** par une équipe de quatre agents Claude spécialisés et coordonnés.

## Objectif

Itérer jusqu'à obtenir un **premier prototype jouable** : un personnage que l'on déplace dans un environnement 3D, qui peut monter dans un véhicule et le conduire dans une ville minimale, le tout exécuté par le moteur Godot 4.6 sur poste.

## Stack technique

- **Moteur** : **Godot 4.6** (rendu 3D natif, physique intégrée, éditeur visuel, scènes `.tscn`). `config/features` du projet est figé sur `"4.6"`.
- **Langage** : GDScript (scripts `.gd`)
- **Tests unitaires** : GUT (Godot Unit Test) v9.6 — addon installé dans `addons/gut/` (chemin réel, pas `addons/Gut-9.6.0/`)
- **Exécution headless des tests** :
  ```
  /c/Users/larch/godot/Godot_v4.6.2-stable_win64_console.exe --headless -s res://addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
  ```
- **Lancement du jeu** : ouvrir le projet dans l'éditeur Godot et lancer la scène principale `main.tscn`, ou en ligne de commande :
  ```
  /c/Users/larch/godot/Godot_v4.6.2-stable_win64_console.exe --path . res://main.tscn
  ```

Pas de navigateur, pas de Web, pas de bundler, pas de TypeScript. Tout passe par Godot.

## Architecture des agents

Cinq agents coexistent et coopèrent. **Chaque tâche doit être exécutée par l'agent dont c'est le rôle** — pas de chevauchement. Les agents sont définis dans `.claude/agents/` et invoqués via le tool `Agent`.

| Agent | Rôle | Flux |
|---|---|---|
| `designer` | Conçoit le game design **et** émet le bon de commande graphique (liste d'assets + arborescence `assets/`) | pipeline feature |
| `specifier` | Rédige la spécification technique GDScript / Godot avant toute implémentation | pipeline feature |
| `tester` | Écrit les tests GUT (TDD strict) qui doivent échouer avant que le code n'existe | pipeline feature |
| `developer` | Implémente la feature en GDScript / scènes `.tscn` jusqu'à ce que les tests passent | pipeline feature |
| `mixamo` | Convertit les FBX déposés dans `assets/import/` en GLB, les place dans `assets/`, tient à jour le registre des assets | **hors pipeline** — invoqué à la demande |

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
- **`docs/assets/<NN>-<slug>.md`** — bon de commande graphique (rédigé par `designer`). Spécifie les assets, leurs chemins exacts dans `assets/`, le budget polycount, les mocks primitives et la **section Mixamo** (instructions de téléchargement).
- **`docs/specs/<NN>-<slug>.md`** — spec technique Godot / GDScript (rédigée par `specifier`).
- **`docs/exchanges/`** — fichiers d'échange entre agents. Format : `YYYY-MM-DD-from-<agent>-to-<agent>-<sujet>.md`.
- **`docs/assets/ASSETS-STATUS.md`** — registre vivant de tous les assets déclarés dans les bons de commande. Tenu à jour par `mixamo`. Indique le statut de chaque GLB (manquant, présent, déprécié). Source de vérité pour l'état de la production graphique.

## Arborescence du projet

```
.
├── project.godot         # projet Godot 4.6
├── main.tscn             # scène d'entrée
├── src/                  # scripts GDScript de production (.gd)
├── scenes/               # scènes .tscn réutilisables
├── assets/               # modèles, textures, sons, matériaux (arborescence figée par les bons de commande)
│   └── import/           # dossier de dépôt des FBX Mixamo (géré par l'agent mixamo)
│       ├── *.fbx         # FBX déposés par l'utilisateur, en attente de conversion
│       └── processed/    # FBX déjà convertis (archivés après traitement)
├── tests/                # tests GUT (test_*.gd)
├── addons/gut/           # framework de test GUT v9.6
├── docs/                 # documentation vivante
│   └── assets/
│       └── ASSETS-STATUS.md  # registre des assets (tenu par mixamo)
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
- [ ] La commande `Godot_v4.6.2-stable_win64_console.exe --headless -s res://addons/gut/gut_cmdln.gd -gdir=res://tests -gexit` retourne un code 0

## Workflow d'import d'assets Mixamo

Les assets 3D (personnages, animations, véhicules) proviennent de [Mixamo](https://www.mixamo.com) et sont convertis en `.glb` par l'agent `mixamo`.

### Comment ça marche

1. Le **designer** émet un bon de commande avec une **section Mixamo** listant pour chaque asset : le nom du fichier GLB attendu, les termes de recherche Mixamo, les réglages d'animation (loop, FPS).
2. Le **`docs/assets/ASSETS-STATUS.md`** recense automatiquement les assets manquants — consulte-le pour savoir quoi télécharger.
3. **L'utilisateur** va sur Mixamo, télécharge en FBX, **nomme le fichier exactement comme le GLB attendu** (même nom, extension `.fbx`), et le dépose dans `assets/import/`. Si le fichier est déjà en `.glb` (produit par un autre outil), le nommer comme le GLB attendu et le déposer directement — aucune conversion ne sera effectuée.
4. L'utilisateur invoque l'**agent `mixamo`** qui : convertit les FBX en GLB (ou déplace les GLB directs), les place dans `assets/`, met à jour le registre, archive les fichiers traités dans `assets/import/processed/`.

### Convention de nommage obligatoire

Le fichier FBX déposé dans `assets/import/` doit porter **exactement le même nom** que le GLB attendu. Exemples :
- Bon de commande attend `player_idle.glb` → déposer `player_idle.fbx`
- Bon de commande attend `car_body.glb` → déposer `car_body.fbx`

### Outil de conversion

L'agent `mixamo` utilise **FBX2glTF v0.13.1** (outil officiel Godot Engine, déjà présent dans le projet) :
```
assets/import/FBX2glTF/FBX2glTF-windows-x86_64/FBX2glTF-windows-x86_64.exe --input <input.fbx> --output <chemin_sortie_sans_extension> --binary
```
Le flag `--binary` produit un `.glb`. L'outil ajoute automatiquement l'extension `.glb` au chemin de sortie.

FBX2glTF est le seul outil supportant les FBX version 7700 (format Autodesk FBX SDK 2020+ utilisé par Mixamo).
Ne pas utiliser `assimp` — la version disponible (3.3) ne supporte pas ce format et échoue sur tous les FBX Mixamo récents.

## Règles non négociables

1. Pas de code dans `src/` ou `scenes/` sans test correspondant dans `tests/`.
2. Pas de test sans spec dans `docs/specs/`.
3. Pas de spec sans design **et** bon de commande dans `docs/design/` + `docs/assets/`.
4. Pas d'asset ajouté sous `assets/` sans bon de commande qui le déclare.
5. **Tant qu'un asset final n'est pas livré, il est obligatoirement remplacé par un mock primitif Godot** (CSGBox, CSGCylinder, BoxMesh, CapsuleMesh, etc.) placé exactement au chemin et au rôle prévus par le bon de commande, avec dimensions et couleur spécifiées et un commentaire `# MOCK — à remplacer par <chemin du futur asset>` au-dessus du nœud / de l'instanciation. Le jeu doit toujours être lançable, jamais bloqué en attente d'un asset.
6. **Dès qu'un asset final est livré (`assets/` contient le GLB), il est intégré intégralement par du code GDScript** : `load()` / `preload()` dans `_ready()`, attachement au SceneTree, câblage des sous-nœuds (AnimationPlayer, Skeleton3D, etc.). L'utilisateur ne doit **jamais** avoir à ouvrir l'éditeur Godot pour compléter une intégration d'asset. L'éditeur est le dernier recours, uniquement pour ce qui est techniquement impossible en code.
7. Toute question ou blocage d'un agent vers un autre passe par un fichier dans `docs/exchanges/`.
8. Le cahier des charges est la source de vérité de l'état du projet : chaque agent met à jour la ou les colonnes qui le concernent à la fin de son tour.
9. **`docs/assets/ASSETS-STATUS.md`** est la source de vérité de l'état des assets graphiques : l'agent `mixamo` le met à jour à chaque invocation.
