# Grand Theft AI — v2

Jeu TPS 3D desktop inspiré de GTA, sous **Godot 4.6**, en GDScript.

**Reset v2 le 2026-06-11.** Le prototype v1 (20 features, pipeline 4 agents) est archivé dans l'historique git — commit `4dd3f71` « snapshot complet avant reset v2 ». Le code repart de zéro ; seuls le bootstrap Godot et les assets sont conservés.

## Stack

- **Godot 4.6.2** — binaire : `C:\Users\larch\godot\Godot_v4.6.2-stable_win64_console.exe` (Bash : `/c/Users/larch/godot/Godot_v4.6.2-stable_win64_console.exe`)
- **GDScript** uniquement (scripts `.gd`, scènes `.tscn`)
- **GUT v9.6** dans `addons/gut/` (tests headless)

## Commandes

```bash
# Lancer le jeu
/c/Users/larch/godot/Godot_v4.6.2-stable_win64_console.exe --path . res://main.tscn

# Tests GUT headless (code de sortie 0 = tout vert)
/c/Users/larch/godot/Godot_v4.6.2-stable_win64_console.exe --headless -s res://addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

## Structure

```
.
├── project.godot         # projet Godot 4.6 (input map ZQSD/WASD + interact + drive_* déjà déclarée)
├── main.tscn             # scène d'entrée (vide pour l'instant)
├── src/                  # scripts GDScript (à créer)
├── scenes/               # scènes .tscn (à créer)
├── tests/                # tests GUT (à créer)
├── assets/               # assets binaires conservés du v1
│   └── import/           # dépôt FBX Mixamo + outil FBX2glTF
├── docs/assets/ASSETS-STATUS.md  # registre des assets (tenu par l'agent mixamo)
└── .claude/agents/       # configurations des agents
```

## Assets disponibles (capital conservé du v1)

Registre complet : `docs/assets/ASSETS-STATUS.md`. En résumé :

| Asset | Chemin | Contenu |
|-------|--------|---------|
| Personnage | `assets/characters/player/player_body.glb` | mesh humanoïde Mixamo (Ch08) + textures PNG |
| Animations | `player_idle.glb`, `player_walk.glb`, `player_car_drive.glb`, `player_car_enter.glb`, `player_car_exit.glb` | clips Mixamo (les `car_*` sont Without Skin, squelette seul) |
| Voiture | `assets/vehicles/car/car_body.glb` | carrosserie complète |

## Workflow d'import Mixamo (inchangé, agent `mixamo`)

1. Télécharger le FBX sur [mixamo.com](https://www.mixamo.com), le nommer **exactement** comme le GLB attendu (même nom, extension `.fbx`), le déposer dans `assets/import/`.
2. Invoquer l'agent `mixamo` : il convertit avec **FBX2glTF** (`assets/import/FBX2glTF/FBX2glTF-windows-x86_64/FBX2glTF-windows-x86_64.exe --input <in.fbx> --output <sortie_sans_ext> --binary`), place le GLB, archive le FBX dans `assets/import/processed/` et met à jour le registre.
3. **Jamais assimp** — il ne supporte pas le format FBX de Mixamo.

## Pipeline de développement

**En cours de redéfinition** (prochaine étape du reset). Principes actés :

1. **Rien n'est « fini » tant que le jeu n'a pas été lancé réellement** — la validation se fait en jouant, pas seulement aux tests verts.
2. Boucle courte : mini-spec → implémentation → smoke tests → lancement du jeu → playtest utilisateur.
3. `ARCHITECTURE.md` (à créer avec le premier code) est la carte du projet : chaque fichier y est décrit en une ligne ; « call down, signal up » pour la communication entre nœuds.
4. Un bug se corrige sur place — il ne devient jamais une « feature ».
5. Code lisible avant tout : ~150 lignes max par script, un concept par fichier, commentaires en français.
6. Utiliser les nœuds Godot natifs : `CharacterBody3D` (joueur), `SpringArm3D` (caméra), `VehicleBody3D` (voiture) — ne pas réimplémenter ce que le moteur fournit.

⚠️ Les agents `.claude/agents/` designer / specifier / tester / developer décrivent le pipeline v1 et ne doivent **plus être invoqués** tant qu'ils n'ont pas été réécrits. Seul `mixamo` reste valide.
