# Registre des assets — Grand Theft AI

Source de vérité de l'état de production des assets binaires (`.glb`, `.png`, `.tres`, `.ogg`, etc.).
Tenu à jour par l'agent `mixamo` à chaque invocation.

Mis à jour le : 2026-06-07

---

## Resume

| Statut | Nombre |
|--------|--------|
| OK Présent | 7 |
| Manquant (pas de FBX) | 8 |
| Déprécié | 1 |
| Supprimé | 1 |

---

## Assets présents (statut OK)

| GLB | Destination | Bon de commande | Converti le | Taille |
|-----|-------------|-----------------|-------------|--------|
| `player_body.glb` | `assets/characters/player/player_body.glb` | `docs/assets/10-personnage-3d.md` | 2026-05-31 | ~85 Mo |
| `player_idle.glb` | `assets/characters/player/player_idle.glb` | `docs/assets/10-personnage-3d.md` | 2026-05-31 | ~85 Mo |
| `player_walk.glb` | `assets/characters/player/player_walk.glb` | `docs/assets/10-personnage-3d.md` | 2026-05-31 (mis à jour) | ~85 Mo |
| `car_body.glb` | `assets/vehicles/car/car_body.glb` | `docs/assets/06-voiture.md` | 2026-05-31 | ~26 Mo |
| `player_car_drive.glb` | `assets/characters/player/player_car_drive.glb` | `docs/assets/19-animations-vehicule.md` | 2026-06-07 (remplacé) | ~153 Ko |
| `player_car_enter.glb` | `assets/characters/player/player_car_enter.glb` | `docs/assets/19-animations-vehicule.md` | 2026-06-07 (remplacé) | ~168 Ko |
| `player_car_exit.glb` | `assets/characters/player/player_car_exit.glb` | `docs/assets/19-animations-vehicule.md` | 2026-06-07 (remplacé) | ~176 Ko |

Notes de conversion :

- `player_body.glb`, `player_idle.glb` : converti lors du tour précédent (FBX2glTF v0.13.1). Avertissement non bloquant `Mat [Ch08_hair]: Can't handle texture for TransparentColor; discarding.`
- `player_walk.glb` : reconverti depuis `player_walk.fbx` (FBX2glTF v0.13.1). Avertissement non bloquant identique. Fichier précédent remplacé.
- `car_body.glb` : GLB direct déposé dans `assets/import/`, déplacé sans conversion vers `assets/vehicles/car/`.
- `wheel.glb` : GLB direct déposé dans `assets/import/`, déplacé sans conversion vers `assets/vehicles/car/`. Déprécié en feature 13, officialisé en feature 16 — voir section Assets dépréciés.
- `player_car_drive.glb` : **remplacé ce tour** — ancienne version With Skin (~85 Mo) supprimée. Nouveau export Without Skin depuis `Driving.fbx` (renommé `player_car_drive.fbx`). FBX2glTF v0.13.1. Avertissement non bloquant `eInheritRrSs` (squelette Mixamo, non bloquant). Animation `mixamo.com` : frames 0-150 (5 s à 30 FPS, bouclée). Taille : ~153 Ko. Aucun dossier `.fbm` généré — confirme l'absence de mesh (Without Skin conforme).
- `player_car_enter.glb` : **remplacé ce tour** — ancienne version With Skin (~85 Mo) supprimée. Nouveau export Without Skin depuis `Entering Car.fbx` (renommé `player_car_enter.fbx`). FBX2glTF v0.13.1. Avertissement identique. Animation `mixamo.com` : frames 0-164 (~5.5 s à 30 FPS). Taille : ~168 Ko. Without Skin conforme.
- `player_car_exit.glb` : **remplacé ce tour** — ancienne version With Skin (~85 Mo) supprimée. Nouveau export Without Skin depuis `Exiting Car.fbx` (renommé `player_car_exit.fbx`). FBX2glTF v0.13.1. Avertissement identique. Animation `mixamo.com` : frames 0-174 (~5.8 s à 30 FPS). Taille : ~176 Ko. Without Skin conforme.

---

## Assets à télécharger (FBX manquants — action requise)

> Ces assets ne proviennent pas de Mixamo. Ils requièrent un artiste 3D ou Blender.
> Aucun FBX à déposer dans `assets/import/` pour ces features.

### Feature 05 — Ville minimale (bon de commande 05)

| GLB attendu | Destination | Bon de commande | Source | Notes |
|-------------|-------------|-----------------|--------|-------|
| `batiment_1.glb` | `assets/city/buildings/` | `docs/assets/05-ville-minimale.md` | artiste 3D | 6x12x6 m, mock BoxMesh gris en place |
| `batiment_2.glb` | `assets/city/buildings/` | `docs/assets/05-ville-minimale.md` | artiste 3D | 8x8x8 m, mock BoxMesh en place |
| `batiment_3.glb` | `assets/city/buildings/` | `docs/assets/05-ville-minimale.md` | artiste 3D | 5x6x10 m, mock BoxMesh en place |
| `batiment_4.glb` | `assets/city/buildings/` | `docs/assets/05-ville-minimale.md` | artiste 3D | 10x5x6 m, mock BoxMesh en place |
| `batiment_5.glb` | `assets/city/buildings/` | `docs/assets/05-ville-minimale.md` | artiste 3D | 6x10x6 m, mock BoxMesh en place |
| `batiment_6.glb` | `assets/city/buildings/` | `docs/assets/05-ville-minimale.md` | artiste 3D | 7x7x7 m, mock BoxMesh en place |
| `batiment_7.glb` | `assets/city/buildings/` | `docs/assets/05-ville-minimale.md` | artiste 3D | 4x14x4 m, mock BoxMesh en place |
| `batiment_8.glb` | `assets/city/buildings/` | `docs/assets/05-ville-minimale.md` | artiste 3D | 12x4x5 m, mock BoxMesh en place |

---

## FBX archivés (traités)

| FBX archivé | GLB produit | Date |
|-------------|-------------|------|
| `assets/import/processed/player_body.fbx` | `assets/characters/player/player_body.glb` | 2026-05-31 |
| `assets/import/processed/player_idle.fbx` | `assets/characters/player/player_idle.glb` | 2026-05-31 |
| `assets/import/processed/player_walk.fbx` | `assets/characters/player/player_walk.glb` | 2026-05-31 (archivé — mise a jour) |
| `assets/import/processed/player_car_drive.fbx` | `assets/characters/player/player_car_drive.glb` | 2026-06-07 (original : `Driving.fbx`) — 1er tour With Skin |
| `assets/import/processed/player_car_enter.fbx` | `assets/characters/player/player_car_enter.glb` | 2026-06-07 (original : `Entering Car.fbx`) — 1er tour With Skin |
| `assets/import/processed/player_car_exit.fbx` | `assets/characters/player/player_car_exit.glb` | 2026-06-07 (original : `Exiting Car.fbx`) — 1er tour With Skin |
| `assets/import/processed/player_car_drive.fbx` | `assets/characters/player/player_car_drive.glb` | 2026-06-07 (remplacement : `Driving.fbx`) — Without Skin |
| `assets/import/processed/player_car_enter.fbx` | `assets/characters/player/player_car_enter.glb` | 2026-06-07 (remplacement : `Entering Car.fbx`) — Without Skin |
| `assets/import/processed/player_car_exit.fbx` | `assets/characters/player/player_car_exit.glb` | 2026-06-07 (remplacement : `Exiting Car.fbx`) — Without Skin |

---

## GLB directs archivés (passthrough, aucune conversion)

| Source archivée | GLB placé | Date |
|----------------|-----------|------|
| `assets/import/processed/car_body.glb.import` | `assets/vehicles/car/car_body.glb` | 2026-05-31 |
| `assets/import/processed/wheel.glb.import` | `assets/vehicles/car/wheel.glb` | 2026-05-31 |

---

## Assets dépréciés

| Fichier | Raison | Bon de commande source |
|---------|--------|------------------------|
| `assets/characters/player/player.glb` | Remplacé par `player_body.glb` (feature 10) — jamais livré, mock capsule en place | `docs/assets/03-personnage-joueur.md` |

---

## Assets supprimés

| Fichier | Raison | Décision |
|---------|--------|----------|
| `assets/vehicles/car/wheel.glb` | Supprimé par feature 18 — roue visuelle redondante avec `car_body.glb`. Plus aucune référence autorisée dans le code, les scènes ou les bons de commande. Suppression physique du disque (fichier `.glb` + `.import`) déléguée à l'agent `mixamo`. | `docs/assets/18-refonte-vehicule.md` |
| `assets/characters/player/player_car_drive.glb` (version With Skin) | Remplacé ce tour par la version Without Skin (~153 Ko). Ancienne version With Skin (~85 Mo) supprimée — dossier `player_car_drive.fbm` dans `assets/import/` supprimé également. | `docs/assets/19-animations-vehicule.md` |
| `assets/characters/player/player_car_enter.glb` (version With Skin) | Remplacé ce tour par la version Without Skin (~168 Ko). Ancienne version With Skin (~85 Mo) supprimée — dossier `player_car_enter.fbm` dans `assets/import/` supprimé également. | `docs/assets/19-animations-vehicule.md` |
| `assets/characters/player/player_car_exit.glb` (version With Skin) | Remplacé ce tour par la version Without Skin (~176 Ko). Ancienne version With Skin (~85 Mo) supprimée — dossier `player_car_exit.fbm` dans `assets/import/` supprimé également. | `docs/assets/19-animations-vehicule.md` |

---

## Fichiers résidus dans assets/import/ — nettoyés (reset v2, 2026-06-11)

Les résidus de conversion signalés ici (dossiers `*.fbm/`, PNG/JPG orphelins, `assimp605/`, zips) ont été supprimés lors du reset v2. **Aucun GLB ni FBX original n'a été touché** : les GLB sont en place dans `assets/`, les FBX originaux archivés dans `assets/import/processed/` (ignoré par git), et une copie de sécurité complète existe dans `C:\Users\larch\gta-assets-backup\`.

Note reset v2 : les bons de commande `docs/assets/NN-*.md` référencés dans ce registre ont été supprimés du working tree — ils restent consultables dans l'historique git (commit `4dd3f71`, snapshot avant reset).

---

## Instruction de dépôt pour les prochains FBX Mixamo

1. Télécharger les FBX depuis [mixamo.com](https://www.mixamo.com) selon les instructions du bon de commande.
2. Nommer chaque FBX exactement comme le GLB attendu (même nom, extension `.fbx`).
3. Déposer dans `assets/import/`.
4. Invoquer l'agent `mixamo` — il utilisera FBX2glTF pour convertir, placer et mettre à jour ce registre.

L'outil de conversion est **FBX2glTF** (pas assimp) :
```
assets/import/FBX2glTF/FBX2glTF-windows-x86_64/FBX2glTF-windows-x86_64.exe
```
