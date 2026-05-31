# Boucle d'itération

Comment l'orchestrateur (l'agent principal) fait avancer le projet jusqu'au prototype v0.1 jouable sous Godot 4.

## Algorithme

```
tant que (critères du cahier des charges non tous cochés) :
    feature = première feature au statut "à faire" / partiellement faite du cahier des charges

    1. invoquer agent designer
       → produit docs/design/NN-<slug>.md
       → produit docs/assets/NN-<slug>.md (ou "n/a" si feature purement technique)
       → met à jour les colonnes Design et Assets

    2. invoquer agent specifier
       → produit docs/specs/NN-<slug>.md
       → met à jour la colonne Spec

    3. invoquer agent tester
       → produit tests/test_NN_<slug>.gd
       → exécute `godot --headless -s res://addons/gut/gut_cmdln.gd -gdir=res://tests -gexit`
       → met à jour la colonne Tests (tests rouges)

    4. invoquer agent developer
       → produit src/..., scenes/..., assets/... (dossiers + mocks)
       → boucle jusqu'à ce que la commande GUT retourne 0
       → met à jour la colonne Implémentation (implémenté)

    si un agent renvoie un blocage :
        lire docs/exchanges/ ouverts
        invoquer l'agent destinataire pour répondre
        reprendre l'étape interrompue
fin
```

## Règles d'orchestration

1. Une seule feature en cours à la fois.
2. Jamais sauter une étape (pas de spec sans design + bon de commande, pas de test sans spec, pas de code sans test rouge).
3. Avant chaque invocation d'agent, vérifier qu'aucun échange ouvert ne le concerne.
4. Si un agent renvoie un blocage, traiter l'échange avant de continuer.
5. À la fin de chaque feature, lancer la commande GUT depuis la racine du projet :
   ```
   godot --headless -s res://addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
   ```
   et vérifier que le code retour est 0 ET qu'il n'y a aucun fail dans le résumé.

## Si Godot n'est pas disponible dans l'environnement d'exécution

Le `tester` et le `developer` ne peuvent pas exécuter GUT. Dans ce cas :

- ils continuent d'écrire le code attendu (tests et implémentation),
- ils notent dans `docs/exchanges/` l'absence d'exécution réelle,
- la validation finale doit être effectuée par le mainteneur humain sur un poste avec Godot 4 installé.

## Critère d'arrêt

Toutes les cases de la section "Critères du prototype v0.1 jouable" du cahier des charges sont cochées.
