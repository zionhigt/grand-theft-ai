# Backlog — Grand Theft AI

*Source de vérité de l'avancement. Une entrée = une itération de la boucle de dev. Les bugs de playtest se corrigent **sur place** (section Bugs), ils ne deviennent jamais des features.*

Statuts : `à faire` → `en cours` → `jouable` (validé par playtest utilisateur).

## Route vers v0.1

| # | Itération | Statut | Assets nécessaires |
|---|-----------|--------|--------------------|
| 1 | **Monde minimal** : sol 200×200, ciel procédural, lumière directionnelle | jouable | aucun (mocks) |
| 2 | **Joueur + caméra TPS** : capsule déplaçable camera-relatif, SpringArm3D orbite souris + zoom | en cours | aucun (mock capsule) |
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

#### Itération 2 — Joueur + caméra TPS
- **Comportement** :
  - Une capsule (MOCK joueur) se déplace au clavier Z/Q/S/D, **relative à la caméra** (avancer = vers où regarde la caméra).
  - Mouvement avec accélération/décélération (du poids, pas du tout-ou-rien) ; gravité simple pour rester au sol.
  - La capsule s'oriente vers sa direction de déplacement.
  - Caméra TPS : `Node3D` (pivot) → `SpringArm3D` → `Camera3D`. Clic droit **maintenu** + souris = orbite (yaw/pitch borné). Molette = zoom (longueur du bras bornée). Le bras évite de buter sur la cible.
  - La caméra suit la cible (`cible: Node3D`) par lerp, sans connaître sa nature.
- **Critère jouable** : je me déplace dans toutes les directions relativement à la caméra, je tourne la vue au clic droit, je zoome à la molette, la capsule reste posée au sol, aucun à-coup.
- **Tests smoke** : instanciation `player.tscn` (CharacterBody3D + collision), `camera_rig.tscn` (SpringArm3D + Camera3D current), `definir_cible()` assigne la cible, `_direction_voulue()` = ZERO sans input, `main.tscn` contient Joueur + CameraRig.
