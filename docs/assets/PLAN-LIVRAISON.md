# Plan de livraison des assets — contrat vivant

Tenu par l'agent `asset-director`, négocié avec l'utilisateur. L'agent `mixamo` s'y réfère pour placer les fichiers. L'état réel des fichiers sur disque est dans `ASSETS-STATUS.md`.

Mis à jour le : 2026-06-11

## Livrés (capital v1 — rien à re-télécharger)

| GLB | Destination | Utilisé par (backlog) | Licence |
|-----|-------------|------------------------|---------|
| `player_body.glb` (+ textures PNG) | `assets/characters/player/` | itération 3 | Mixamo/Adobe |
| `player_idle.glb` | `assets/characters/player/` | itération 3 | Mixamo/Adobe |
| `player_walk.glb` | `assets/characters/player/` | itération 3 | Mixamo/Adobe |
| `player_car_drive.glb` (Without Skin) | `assets/characters/player/` | itération 7 | Mixamo/Adobe |
| `player_car_enter.glb` (Without Skin) | `assets/characters/player/` | itérations 6–7 | Mixamo/Adobe |
| `player_car_exit.glb` (Without Skin) | `assets/characters/player/` | itérations 6–7 | Mixamo/Adobe |
| `car_body.glb` | `assets/vehicles/car/` | itération 5 | (source v1) |

Sauvegarde hors dépôt : `C:\Users\larch\gta-assets-backup\` (GLB + FBX originaux).

## À livrer (accord trouvé)

*(rien — la route v0.1 est entièrement couverte par les assets livrés et les mocks)*

## En discussion (options ouvertes, à négocier avec `asset-director`)

| Besoin | Option A (zéro effort) | Option B (~10 min) | Option C (effort ciblé) | Recommandation |
|--------|------------------------|--------------------|-------------------------|----------------|
| Bâtiments ville (itération 4) | BoxMesh colorés | pack CC0 Kenney « City Kit » (kenney.nl) | — | A pour v0.1, B en polish |
| Animation course du joueur | réutiliser walk accéléré | — | Mixamo « Running » Without Skin, 30 FPS, In Place → `player_run.fbx` | C quand le déplacement est jouable |
| Skybox / ambiance | ciel procédural Godot | HDRI PolyHaven (polyhaven.com) | — | A pour v0.1 |

## Conventions de dépôt

1. Nommer le fichier **exactement** comme le GLB attendu (`player_run.fbx` → produira `player_run.glb`).
2. Déposer dans `assets/import/` (formats : `.fbx` converti automatiquement, `.glb` placé tel quel).
3. Invoquer l'agent `mixamo`.
4. Réglages Mixamo : mesh = With Skin + T-Pose ; animation seule = **Without Skin**, FBX Binary, 30 FPS, In Place si disponible.
