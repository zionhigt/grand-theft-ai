# Backlog — Grand Theft AI

*Source de vérité de l'avancement. Une entrée = une itération de la boucle de dev. Les bugs de playtest se corrigent **sur place** (section Bugs), ils ne deviennent jamais des features.*

Statuts : `à faire` → `en cours` → `jouable` (validé par playtest utilisateur).

## Route vers v0.1

| # | Itération | Statut | Assets nécessaires |
|---|-----------|--------|--------------------|
| 1 | **Monde minimal** : sol 200×200, ciel procédural, lumière directionnelle | à faire | aucun (mocks) |
| 2 | **Joueur + caméra TPS** : capsule déplaçable camera-relatif, SpringArm3D orbite souris + zoom | à faire | aucun (mock capsule) |
| 3 | **Personnage 3D animé** : intégration `player_body.glb` + idle/walk, transitions d'anim | à faire | ✅ déjà livrés |
| 4 | **Ville en blocs** : 8–12 bâtiments BoxMesh avec collisions, rues praticables | à faire | aucun (mocks) — packs CC0 négociables plus tard |
| 5 | **Voiture conduisible** : VehicleBody3D + `car_body.glb`, accélérer/freiner/tourner | à faire | ✅ déjà livré |
| 6 | **Entrer / sortir (E)** : machine à états A_PIED ↔ EN_VOITURE, caméra qui suit la cible active | à faire | ✅ anims car_enter/exit livrées (intégration optionnelle ici, peaufinage en 7) |
| 7 | **Polish v0.1** : animations véhicule, feel caméra, corrections du grand playtest | à faire | — |

## Bugs ouverts (issus des playtests)

*(vide)*

## Plus tard (v0.2+)

Tir / visée, PNJ, trafic, audio, HUD, missions. Rien ici ne se discute avant que v0.1 soit jouable.

---

### Mini-spec (modèle à remplir au début de chaque itération)

```markdown
#### Itération N — <titre>
- **Comportement** : (3-8 lignes, ce que le joueur peut faire après)
- **Critère jouable** : (ce que l'utilisateur doit constater au playtest)
- **Tests smoke** : (ce qui s'ajoute dans tests/)
```
