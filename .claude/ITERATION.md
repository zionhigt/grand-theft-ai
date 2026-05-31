# Boucle d'itération

Cette note décrit comment l'orchestrateur (l'agent principal) doit faire avancer le projet jusqu'au prototype v0.1 jouable.

## Algorithme

```
tant que (critères du cahier des charges non tous cochés) :
    feature = première feature "à faire" dans le cahier des charges
    invoquer agent designer  → produit docs/design/NN-<slug>.md
    invoquer agent specifier → produit docs/specs/NN-<slug>.md + maj cahier
    invoquer agent tester    → produit tests/NN-<slug>.test.ts (rouges)
    invoquer agent developer → produit src/... jusqu'à tests verts
    si tests verts ET tsc vert :
        marquer la feature "implémenté"
    sinon :
        lire docs/exchanges/ ouverts, débloquer, recommencer
fin
```

## Règles d'orchestration

1. Une seule feature en cours à la fois.
2. Jamais sauter une étape (pas de spec sans design, pas de test sans spec, pas de code sans test rouge).
3. Avant chaque invocation d'agent, vérifier qu'aucun échange ouvert ne le concerne.
4. Si un agent renvoie un blocage, on traite l'échange avant de continuer.
5. À la fin de chaque feature, lancer :
   ```
   godot --headless -s res://addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
   ```
   et vérifier que le code retour est 0.

## Critère d'arrêt

Toutes les cases de la section "Critères du prototype v0.1 jouable" du cahier des charges sont cochées.
