# Grand Theft AI

Jeu 3D inspiré de GTA, développé par une équipe de quatre agents Claude spécialisés et coordonnés.

## Objectif

Itérer jusqu'à obtenir un **premier prototype jouable** : un personnage que l'on déplace dans un environnement 3D, qui peut monter dans un véhicule et le conduire dans une ville minimale.

## Stack technique

- **Moteur** : Three.js (rendu WebGL navigateur)
- **Physique** : cannon-es
- **Bundler** : Vite
- **Langage** : TypeScript
- **Tests** : Vitest

## Architecture des agents

Quatre agents coexistent et coopèrent. **Chaque tâche doit être exécutée par l'agent dont c'est le rôle** — pas de chevauchement. Les agents sont définis dans `.claude/agents/` et invoqués via le tool `Agent`.

| Agent | Rôle | Tools |
|---|---|---|
| `specifier` | Rédige les spécifications techniques avant toute implémentation | Read, Write, Edit, Bash (lecture) |
| `designer` | Spécifie les éléments de game design (mondes, véhicules, IA, contrôles) | Read, Write, Edit |
| `tester` | Écrit les tests unitaires **avant** que le code ne soit développé (TDD) | Read, Write, Edit, Bash |
| `developer` | Implémente la feature pour faire passer les tests | Read, Write, Edit, Bash |

### Flux obligatoire d'une feature

```
designer ──► specifier ──► tester ──► developer ──► (boucle si tests rouges)
```

1. **`designer`** décrit la feature côté game design dans `docs/design/`.
2. **`specifier`** écrit la spécification technique correspondante dans `docs/specs/` et met à jour le cahier des charges.
3. **`tester`** écrit les tests unitaires dans `tests/` à partir de la spec. Les tests doivent échouer (red).
4. **`developer`** implémente le code dans `src/` jusqu'à ce que tous les tests passent (green).

Aucun agent ne peut sauter une étape. Le `developer` ne commence **jamais** sans tests rouges existants. Le `tester` ne commence **jamais** sans spec écrite.

## Documents partagés

- **`docs/cahier-des-charges.md`** — document maître, vivant, qui liste l'ensemble des features décidées et leur état d'avancement. Mis à jour par le `specifier` à chaque nouvelle feature.
- **`docs/design/`** — un fichier markdown par feature, rédigé par `designer`.
- **`docs/specs/`** — un fichier markdown par feature, rédigé par `specifier`.
- **`docs/exchanges/`** — fichiers d'échange entre agents (questions, clarifications, blocages). Format : `YYYY-MM-DD-from-<agent>-to-<agent>-<sujet>.md`.

## Boucle d'itération

Une itération = une feature complète passée par les quatre agents. La boucle s'arrête quand le **prototype jouable v0.1** est atteint :

- [ ] Une scène 3D s'affiche dans le navigateur
- [ ] Un personnage est rendu et déplaçable au clavier (ZQSD/WASD)
- [ ] Une ville minimale (sol + quelques bâtiments cubiques) existe
- [ ] Une voiture est présente, le joueur peut y entrer
- [ ] La voiture se conduit (avancer, reculer, tourner)
- [ ] Caméra à la troisième personne qui suit le joueur ou la voiture
- [ ] Tous les tests unitaires écrits passent (`npm test`)
- [ ] `npm run dev` lance le jeu sans erreur

## Règles non négociables

1. Pas de code dans `src/` sans test correspondant dans `tests/`.
2. Pas de test sans spec dans `docs/specs/`.
3. Pas de spec sans design dans `docs/design/`.
4. Toute question d'un agent à un autre passe par un fichier dans `docs/exchanges/`.
5. Le cahier des charges (`docs/cahier-des-charges.md`) est la source de vérité de l'état du projet.
