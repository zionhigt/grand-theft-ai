# Échanges inter-agents

Tout message d'un agent à un autre (question, blocage, désaccord, demande de clarification) prend la forme d'un fichier markdown dans ce dossier. Pas de question en l'air, tout est tracé.

## Format de nom

```
YYYY-MM-DD-from-<agent>-to-<agent>-<slug-sujet>.md
```

Exemples :
- `2026-05-30-from-tester-to-specifier-collision-voiture-pieton.md`
- `2026-05-30-from-developer-to-designer-quelle-vitesse-max-pour-la-voiture.md`
- `2026-05-30-from-developer-to-tester-test-bloque-godot-indisponible.md`

## Structure d'un échange

```markdown
# <Sujet>

**De** : <agent émetteur>
**À** : <agent destinataire>
**Feature** : <NN-slug>
**Statut** : ouvert | répondu | résolu

## Question / blocage

(formulation précise du point bloquant)

## Contexte

(liens vers spec, design, bon de commande, tests, fichiers du projet Godot concernés)

## Réponse

(rempli par le destinataire ; quand `statut = résolu`, l'émetteur reprend son travail)
```

## Règle

Aucun agent ne devine. Si une info manque, on ouvre un échange. Quand l'échange est `résolu`, l'agent émetteur reprend son tour à partir du point où il était bloqué.
