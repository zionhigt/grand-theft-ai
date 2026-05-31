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

## Arborescence `assets/` de référence

```
assets/
├── characters/
├── vehicles/
├── environment/
├── textures/
├── materials/
├── audio/
│   ├── sfx/
│   └── music/
├── ui/
└── skybox/
```
