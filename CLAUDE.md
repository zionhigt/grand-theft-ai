# Grand Theft AI — v2

Jeu TPS 3D desktop inspiré de GTA, sous **Godot 4.6**, en GDScript. Le prototype v1 est archivé dans l'historique git (commit `4dd3f71`).

**Principe fondateur : rien n'est « fini » tant que le jeu n'a pas été lancé réellement.** La validation se fait en jouant — les tests verts sont un prérequis, jamais une preuve.

## Documents maîtres

| Document | Rôle | Tenu par |
|----------|------|----------|
| `GDD.md` | le jeu en une page (vision, contrôles, jalon v0.1) | session principale |
| `ARCHITECTURE.md` | carte du code — à jour à chaque commit touchant `src/`/`scenes/` | session principale |
| `BACKLOG.md` | itérations priorisées + bugs — source de vérité de l'avancement | session principale |
| `docs/assets/PLAN-LIVRAISON.md` | contrat de livraison des assets (négocié avec l'utilisateur) | agent `asset-director` |
| `docs/assets/ASSETS-STATUS.md` | état réel des fichiers d'assets sur disque | agent `mixamo` |

## Stack

- **Godot 4.6.2** — binaire : `C:\Users\larch\godot\Godot_v4.6.2-stable_win64_console.exe` (Bash : `/c/Users/larch/godot/Godot_v4.6.2-stable_win64_console.exe`)
- **GDScript** uniquement (scripts `.gd`, scènes `.tscn`)
- **GUT v9.6** dans `addons/gut/` (smoke tests headless)

## Commandes

```bash
# Lancer le jeu (validation réelle — obligatoire avant de livrer)
/c/Users/larch/godot/Godot_v4.6.2-stable_win64_console.exe --path . res://main.tscn

# Boot headless rapide (zéro erreur console attendu)
/c/Users/larch/godot/Godot_v4.6.2-stable_win64_console.exe --headless --path . --quit-after 3

# Suite de tests (code de sortie 0 = vert)
/c/Users/larch/godot/Godot_v4.6.2-stable_win64_console.exe --headless -s res://addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

## La boucle de développement

L'implémentation n'est **pas déléguée à un sous-agent** : la session principale Claude code, teste et lance le jeu elle-même. Une itération :

1. **Choisir** l'entrée `BACKLOG.md` la plus prioritaire (l'utilisateur arbitre).
2. **Mini-spec** : remplir le modèle en bas du backlog (comportement, critère jouable, tests smoke) — 15 lignes max.
3. **Implémenter** dans `src/` + `scenes/` — nœuds natifs d'abord (`CharacterBody3D`, `SpringArm3D`, `VehicleBody3D`), mock-first pour tout visuel.
4. **Tests smoke** dans `tests/` (GUT) : boot, instanciation des scènes, logique d'état critique. Suite complète verte. Rappel headless : `Input.set_mouse_mode()` est un no-op — tester les flags internes, jamais le mode souris.
5. **Lancer le jeu réellement** et lire la console — zéro erreur, comportement constaté.
6. **Agent `reviewer`** → corriger tous les findings bloquants/importants.
7. **Mettre à jour** `ARCHITECTURE.md` + `BACKLOG.md`, puis **commit** (un commit par itération minimum).
8. **Playtest utilisateur** (~5 min, critère jouable de la mini-spec). Son feedback en mots simples → bugs dans `BACKLOG.md`, corrigés sur place à l'itération suivante. Un bug ne devient jamais une feature.

## Règles de code

1. ≤ 150 lignes par script, un concept par fichier, noms et commentaires en **français**.
2. **Call down, signal up** — jamais de `get_parent()` pour appeler vers le haut.
3. Pas de code mort : un fichier que rien ne référence est supprimé.
4. Aucun `load`/`preload`/`ExtResource` vers un chemin inexistant.
5. Détail des structures et machines à états : voir `ARCHITECTURE.md`.

## Assets au fil de l'eau

Les assets arrivent progressivement — le développement ne les attend **jamais** :

1. **Mock d'abord** : tout visuel sans asset livré est une primitive Godot (BoxMesh, CapsuleMesh…) avec dimensions/couleur fixées et un commentaire `# MOCK — à remplacer par res://assets/...`. Le jeu est toujours lançable.
2. **Négociation** : l'utilisateur discute avec l'agent `asset-director` du meilleur compromis (mock / pack CC0 / Mixamo) — résultat dans `PLAN-LIVRAISON.md` avec nom de fichier exact, source et réglages d'export.
3. **Livraison** : l'utilisateur dépose le fichier dans `assets/import/` (nommé exactement comme le GLB attendu) et invoque l'agent `mixamo`, qui convertit (FBX2glTF — **jamais assimp**) et met à jour `ASSETS-STATUS.md`.
4. **Intégration** : au début de chaque itération, consulter `ASSETS-STATUS.md` — tout GLB nouvellement livré dont le mock existe est intégré **par code** (`load()` dans `_ready()`) dans cette itération. L'utilisateur n'ouvre jamais l'éditeur Godot pour finir une intégration.

Sauvegarde des assets hors dépôt : `C:\Users\larch\gta-assets-backup\` (ne jamais y toucher).

## Agents

| Agent | Rôle | Quand l'invoquer |
|-------|------|-------------------|
| `asset-director` | négocie le plan de livraison des assets, propose des options graduées (effort/rendu), spécifie les mocks | quand une itération à venir a besoin d'assets, ou à la demande de l'utilisateur |
| `mixamo` | convertit/place les fichiers déposés dans `assets/import/`, tient `ASSETS-STATUS.md` | quand l'utilisateur a déposé des fichiers |
| `reviewer` | revue de conformité (architecture, lisibilité, intégrité des ressources), lecture seule | fin de chaque itération, avant commit |

Pas d'autre agent : concevoir, spécifier, coder et tester se font en session principale, au plus près du jeu qui tourne.
