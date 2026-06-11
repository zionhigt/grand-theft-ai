# Bons de commande graphique

Un fichier par feature, rédigé par l'agent `designer` en même temps que le design doc.

## Format de nom

`<NN>-<slug-feature>.md` — même préfixe que le design (`docs/design/`) et la spec (`docs/specs/`).

## Contenu attendu

Voir la structure obligatoire détaillée dans `.claude/agents/designer.md`. Récapitulatif :

- **Résumé** : quoi et combien d'assets.
- **Arborescence cible** : arbre ASCII des dossiers `assets/` créés ou modifiés par la feature.
- **Liste détaillée** : table (chemin `res://...`, type, format, source, livré oui/non, notes techniques).
- **Conventions de nommage** : snake_case, suffixes texture (`_albedo`, `_normal`, `_roughness`, ...).
- **Budget polycount / mémoire** : ordre de grandeur par catégorie.
- **Mocks obligatoires** : pour chaque asset non livré, le nœud Godot mock qui le remplace dans la scène (forme, dimensions, couleur, commentaire `# MOCK — à remplacer par <chemin>`).
- **Hors-périmètre** : ce que cette feature ne commande pas.

## Features sans asset graphique

Pour les features purement techniques (bootstrap, contrôles abstraits, caméra logique, etc.), le fichier existe quand même et contient une unique ligne :

> Cette feature n'a pas d'asset graphique. Statut `Assets` dans le cahier des charges = `n/a`.

## Règle d'or

Le jeu doit toujours pouvoir être lancé. Si un asset final n'existe pas, son **mock primitif** (BoxMesh, CapsuleMesh, CSGBox, CSGCylinder, SphereMesh, etc.) tient son rôle dans la scène, exactement à l'emplacement et avec les dimensions prévues par ce bon de commande. C'est le `developer` qui matérialise ces mocks lors de l'implémentation.

---

## Procédure d'import d'assets Mixamo

### Prérequis

- Compte Mixamo gratuit : [mixamo.com](https://www.mixamo.com)
- **FBX2glTF** : déjà présent dans le projet à `assets/import/FBX2glTF/FBX2glTF-windows-x86_64/FBX2glTF-windows-x86_64.exe` — aucune installation supplémentaire requise.
  - Note : Ne pas utiliser `assimp` (version 3.3 installée via scoop) — incompatible avec les FBX version 7700 exportés par Mixamo (Autodesk FBX SDK 2020+).

### Étapes

1. **Consulter `docs/assets/ASSETS-STATUS.md`** — section "Assets à télécharger". Cette liste est tenue à jour automatiquement par l'agent `mixamo`.

2. **Sur Mixamo** :
   - Sélectionne le personnage (Characters tab) ou l'animation (Animations tab)
   - Paramètres d'export recommandés : **Format FBX Binary (.fbx)**, **With Skin**, **30 FPS**
   - Pour les animations : coche **In Place** si disponible

3. **Nommer le fichier** : renomme le FBX téléchargé **exactement** comme le GLB attendu (même nom, extension `.fbx`).
   - Ex. : bon de commande attend `player_idle.glb` → nommer le FBX `player_idle.fbx`

4. **Déposer** le FBX dans `assets/import/`

5. **Invoquer l'agent mixamo** : il convertit, place et met à jour le registre automatiquement.

### Registre des assets

**`docs/assets/ASSETS-STATUS.md`** — mis à jour à chaque invocation de l'agent `mixamo`. Contient :
- ❌ Assets manquants (à télécharger) avec instructions Mixamo
- ✅ Assets présents (convertis et en place)
- ⚠️ Assets à mettre à jour (FBX plus récent déposé)
- 🗑️ Assets dépréciés (supprimés car non référencés)

---

## Arborescence `assets/` de référence

```
assets/
├── import/           # dépôt des FBX (géré par mixamo agent)
│   └── processed/    # FBX archivés après conversion
├── characters/       # personnages (joueur, PNJ)
├── vehicles/         # voitures, motos, etc.
├── environment/      # bâtiments, props ville, sol
├── textures/         # textures partagées
├── materials/        # ressources .tres (matériaux Godot)
├── audio/
│   ├── sfx/
│   └── music/
├── ui/               # icônes, polices, HUD
└── skybox/
```
