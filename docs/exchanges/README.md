# Échanges inter-agents

Tout message d'un agent à un autre (question, blocage, désaccord, demande de clarification) prend la forme d'un fichier markdown ici.

## Format de nom

```
YYYY-MM-DD-from-<agent>-to-<agent>-<slug-sujet>.md
```

Exemples :
- `2026-05-30-from-tester-to-specifier-collision-voiture-piéton.md`
- `2026-05-30-from-developer-to-designer-quelle-vitesse-max.md`

## Structure d'un échange

```markdown
# <Sujet>

**De** : <agent émetteur>
**À** : <agent destinataire>
**Feature** : NN-<slug>
**Statut** : ouvert | répondu | résolu

## Question / blocage

## Contexte
(liens vers spec, design, tests, fichiers concernés)

## Réponse
(rempli par le destinataire ; quand statut = résolu, l'émetteur reprend son travail)
```

## Règle

Aucun agent ne devine. Si une info manque, on ouvre un échange. Pas de question en l'air dans le chat — tout est tracé ici.
