# Bons de commande graphique

Un fichier par feature, rédigé par l'agent `designer` en même temps que le design doc.

## Format de nom

`<NN>-<slug-feature>.md` — même préfixe que le design et la spec.

## Contenu

Voir la structure obligatoire décrite dans `.claude/agents/designer.md`. Récapitulatif :

- résumé,
- arborescence cible sous `assets/`,
- table détaillée des assets (chemin, type, format, source, notes),
- conventions de nommage,
- budget polycount / mémoire,
- **mocks obligatoires** : pour chaque asset pas encore livré, la primitive Godot qui le remplace dans le jeu en attendant (forme, dimensions, couleur, commentaire à inscrire),
- hors-périmètre.

## Règle

Le jeu doit toujours pouvoir être lancé. Si un asset final n'existe pas, son mock primitif l'incarne au même emplacement logique dans la scène. Le `developer` matérialise ces mocks lors de l'implémentation.
