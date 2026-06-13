# Architecture — Grand Theft AI

*La carte du code. Mise à jour à CHAQUE commit qui touche `src/` ou `scenes/`. Si un fichier n'est pas explicable en une ligne ici, il n'a pas le droit d'exister.*

## Carte des fichiers

| Fichier | Rôle (une ligne) |
|---------|------------------|
| `main.tscn` | scène d'entrée — assemble monde, joueur, caméra (voiture à venir) ; câble `CameraRig.cible = Joueur` |
| `scenes/world.tscn` | monde : sol 200×200 + collision, soleil directionnel à ombres, ciel procédural, nœud `Ville` |
| `src/world/ville.gd` | attaché à `Ville` : pose par code 8 bâtiments mock BoxMesh (`StaticBody3D` couche 1) en grille 3×3, rues praticables — à swapper par `batiment_N.glb` une fois livrés |
| `src/player/player.gd` + `scenes/player.tscn` | joueur à pied : déplacement camera-relatif, gravité, orientation — `CharacterBody3D` couche 2, collision capsule + nœud `Modele` visuel animé |
| `src/player/modele_anime.gd` | attaché à `Modele` : charge `player_idle.glb` (mesh+squelette), injecte la marche de `player_walk.glb`, bascule idle↔marche en fondu via `definir_vitesse()` |
| `src/camera/camera_rig.gd` + `scenes/camera_rig.tscn` | caméra TPS classique : souris libre (curseur capturé), Échap libère, zoom molette, suit une `cible: Node3D` avec amortissement — `Node3D` → `SpringArm3D` → `Camera3D` |

### Structure cible (plan, pas encore créée)

| Fichier prévu | Rôle prévu | Nœud racine |
|---------------|------------|-------------|
| `src/vehicles/car.gd` + `scenes/car.tscn` | voiture conduisible | `VehicleBody3D` + 4 `VehicleWheel3D` |
| `src/core/game.gd` (attaché à `main.tscn`) | orchestre l'état global et le basculement à pied ↔ en voiture | `Node3D` |

## Machine à états du joueur (dans `game.gd`)

```
A_PIED ──(E près d'une voiture)──► EN_VOITURE
EN_VOITURE ──(E)──► A_PIED
```

- `A_PIED` : le `player` reçoit les inputs, la caméra cible le player, la voiture est inerte.
- `EN_VOITURE` : la voiture reçoit les inputs, la caméra cible la voiture, le player est masqué/désactivé (jamais détruit).
- Un seul endroit décide de l'état : `game.gd`. Personne d'autre ne bascule quoi que ce soit.

## Règles de communication

1. **Call down, signal up** : un parent appelle ses enfants ; un enfant émet un signal, jamais `get_parent()`.
2. La caméra ne connaît qu'une `target: Node3D` — elle ignore si c'est un joueur ou une voiture.
3. Les inputs sont lus par l'entité active uniquement (le `game.gd` active/désactive `set_process_*`).
4. Aucun autoload tant qu'un nœud de `main.tscn` suffit.

## Règles de code

- ≤ 150 lignes par script, un concept par fichier, noms et commentaires en français.
- Nœuds natifs Godot d'abord (`CharacterBody3D`, `SpringArm3D`, `VehicleBody3D`) — on ne réimplémente pas le moteur.
- Tout visuel en attente d'asset : mock primitif + `# MOCK — à remplacer par res://assets/...`.
- Tout asset livré est intégré par code (`load()` dans `_ready()`), jamais par manipulation manuelle dans l'éditeur.
