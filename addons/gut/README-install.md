# Installation de GUT (Godot Unit Test)

GUT v9.4 ou supérieur est requis pour Godot 4.6 (la branche 9.4+ supporte Godot 4.4+).
Ce dossier doit contenir l'addon complet avant de pouvoir exécuter les tests headless.

## Option 1 — Via l'AssetLib de l'éditeur Godot

1. Ouvrir le projet dans l'éditeur Godot 4.6.
2. Aller dans AssetLib (onglet en haut).
3. Rechercher "GUT" et installer la version 9.4 ou supérieure.
4. Activer le plugin dans Projet > Paramètres du projet > Plugins.

## Option 2 — Copie manuelle depuis GitHub

```
git clone https://github.com/bitwes/Gut.git /tmp/gut
cp -r /tmp/gut/addons/gut/ addons/gut/
```

Ou télécharger l'archive de la release depuis :
https://github.com/bitwes/Gut/releases

Extraire le dossier `addons/gut/` à la racine du projet (en remplacement de ce dossier placeholder).

## Vérification

Une fois GUT installé, le fichier `addons/gut/plugin.cfg` doit exister.
La commande de validation est :

```
godot --headless -s res://addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

Le code de sortie 0 indique que tous les tests sont verts.
