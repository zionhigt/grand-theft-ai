# Backlog — Grand Theft AI

*Source de vérité de l'avancement. Une entrée = une itération de la boucle de dev. Les bugs de playtest se corrigent **sur place** (section Bugs), ils ne deviennent jamais des features.*

Statuts : `à faire` → `en cours` → `jouable` (validé par playtest utilisateur).

## Route vers v0.1

| # | Itération | Statut | Assets nécessaires |
|---|-----------|--------|--------------------|
| 1 | **Monde minimal** : sol 200×200, ciel procédural, lumière directionnelle | jouable | aucun (mocks) |
| 2 | **Joueur + caméra TPS** : capsule déplaçable camera-relatif, caméra souris libre + zoom + amortissement | jouable | aucun (mock capsule) |
| 3 | **Personnage 3D animé** : intégration `player_body.glb` + idle/walk, transitions d'anim | jouable | ✅ déjà livrés |
| 4 | **Ville en blocs** : 8–12 bâtiments BoxMesh avec collisions, rues praticables | jouable | aucun (mocks) — packs CC0 négociables plus tard |
| 5 | **Voiture conduisible** : VehicleBody3D + `car_body.glb`, accélérer/freiner/tourner | jouable | ✅ déjà livré |
| 6 | **Entrer / sortir (E)** : machine à états A_PIED ↔ EN_VOITURE, caméra qui suit la cible active | jouable | ✅ anims car_enter/exit livrées (intégration optionnelle ici, peaufinage en 7) |
| 7 | **Polish v0.1** : animations véhicule, feel caméra (dont caméra qui se replace doucement derrière le sens de marche), corrections du grand playtest | à faire | — |

## Bugs ouverts (issus des playtests)

- **[corrigé ✓ validé playtest]** *(itér. 5)* On démarrait dans la voiture / conduite lourde / la voiture se retournait facilement et restait bloquée sur le toit. Correctifs : démarrage à pied + entrer-sortir (E) via `game.gd` (fusion itér. 6) ; moteur 1200→2600 N, masse 1000→850, frein-moteur réduit ; centre de masse abaissé (−0,4 m) + auto-redressement après ~1,5 s renversée.
- **[corrigé ✓ validé playtest]** *(itér. 6)* À la descente après avoir roulé, le joueur tombait à l'infini (caméra dans le sol). Cause : le joueur inactif gardait son `_physics_process` (gravité + `move_and_slide`) collision coupée → chute accumulée hors-jeu, puis transpercement au repositionnement. Correctif : joueur inactif **gelé** (sortie immédiate de `_physics_process`) + vitesse remise à zéro à chaque (dé)activation.
- **[corrigé ✓ validé playtest]** *(itér. 3)* Root motion Mixamo : le perso glissait en avant puis se réinitialisait à chaque boucle (« mini-film ») et orbitait en cercle en tournant. Correctif : neutralisation du déplacement horizontal du bassin (`_verrouiller_sur_place`), anim jouée sur place, déplacement géré par le code.
- **[corrigé ✓ validé playtest]** *(itér. 3)* Demi-tour mécanique. Correctif : rotation lissée (framerate-indépendante) + pivot « engagé » (`_facteur_avance` ralentit au-delà de ~90°).
- **[corrigé ✓ validé playtest]** *(itér. 3)* Le joueur tombait au démarrage (spawn à y=1,5 au lieu de 0,9). Correctif : spawn à y=0,9 dans `main.tscn`.
- **[corrigé ✓ validé playtest]** *(itér. 2)* Caméra figée « sur trépied » : elle ne suivait pas du tout le joueur (la capsule fuyait hors champ). Cause : `@export var cible: Node3D` câblé via `NodePath` dans le `.tscn` ne se résout pas → `cible` null → `_process` ne déplaçait jamais le rig. Correctif : export d'un `cible_path: NodePath` (résolu par `get_node` dans `_ready`), `cible` devient un champ runtime. Test comportemental ajouté.
- **[corrigé ✓ validé playtest]** *(itér. 2)* En un point précis du sol, la capsule passait en vue FPS (le `SpringArm3D` se rétractait à zéro car son rayon heurtait la capsule du joueur). Correctif : couches de collision séparées — joueur sur couche 2, bras de caméra `collision_mask = 1` (n'observe que l'environnement, jamais le joueur). L'exclusion par RID seule n'était pas fiable.

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

#### Itération 3 — Personnage 3D animé
- **Comportement** :
  - La capsule mock est remplacée par le vrai personnage Mixamo (`player_idle.glb`, ~1,7 m, échelle 1.0) ; la collision reste une capsule.
  - L'anim de marche est injectée depuis `player_walk.glb` dans l'`AnimationPlayer` du modèle idle (mêmes pistes squelette).
  - Bascule **idle ↔ marche** en fondu enchaîné selon la vitesse horizontale du joueur (`definir_vitesse`, appel descendant).
  - Le personnage s'oriente vers sa direction de marche (déjà en place depuis l'itér. 2).
- **Critère jouable** : je vois un vrai bonhomme (plus de capsule), à la bonne taille, posé au sol ; il reste en idle à l'arrêt et marche quand j'avance, transition douce, orienté vers où il va.
- **Tests smoke** : `player.tscn` a un nœud `Modele` ; après `_ready` le modèle expose un `AnimationPlayer` avec l'idle (`mixamo_com`) **et** la marche injectée ; `definir_vitesse()` bascule l'anim logique.

#### Itération 4 — Ville en blocs
- **Comportement** :
  - 8 bâtiments mock BoxMesh (tailles variées, gris) disposés en grille 3×3 (la cellule centrale = place de spawn), séparés par des rues praticables (~10–12 m).
  - Chaque bâtiment est un `StaticBody3D` couche 1 avec collision boîte : le joueur ne traverse pas les murs, la caméra (bras `mask=1`) évite de passer à travers.
  - Les 4 piliers-repères temporaires de l'itér. 2 sont remplacés par la ville.
  - Génération par code (`ville.gd`) pour pouvoir, plus tard, swapper chaque mock par `batiment_N.glb` une fois livré.
- **Critère jouable** : une petite ville en blocs autour de moi ; je circule dans les rues sans traverser les murs ; la caméra ne traverse pas les bâtiments quand je m'en approche.
- **Tests smoke** : `world.tscn` a un nœud `Ville` avec 8 `StaticBody3D`, chacun doté d'une `CollisionShape3D`.

#### Itération 5 — Voiture conduisible
- **Comportement** :
  - `Voiture` = `VehicleBody3D` (masse ~1000 kg) + 4 `VehicleWheel3D` (avant = direction, arrière = traction), carrosserie = `car_body.glb` à l'échelle 0,01 (~1,67 × 1,35 × 4,26 m).
  - Quand `actif` : `drive_forward/backward` → force moteur, `drive_left/right` → braquage progressif, frein au relâché. Quand inactif : moteur coupé, frein serré.
  - Le joueur reçoit un flag `actif` symétrique (couture pour l'itér. 6). Pour cette itération : joueur parqué (`actif=false`), voiture active, caméra ciblée sur la voiture.
- **Critère jouable** : je conduis la voiture (avance/recule, freine, tourne) avec du poids ; elle ne traverse pas les bâtiments ; la caméra la suit sans à-coup.
- **Tests smoke** : `car.tscn` instancie un `VehicleBody3D` avec 4 `VehicleWheel3D` ; voiture inactive → `engine_force == 0` ; `main.tscn` contient `Voiture` et la caméra la cible.

#### Itération 6 — Entrer / sortir (E) *(fusionnée avec la 5 suite au playtest)*
- **Comportement** : orchestrateur `game.gd` (sur `Main`). Démarrage **à pied**. Près de la voiture (<4 m), **E** monte (joueur masqué/inactif, voiture active, caméra sur la voiture) ; **E** redescend le joueur sur le flanc gauche, au sol. `game.gd` est le seul à changer l'état (`actif`, `definir_cible`).
- **Critère jouable** : je démarre à pied, je marche jusqu'à la voiture, E pour conduire, E pour ressortir, la caméra suit toujours la bonne cible.
- **Tests smoke** : `_monter()`/`_descendre()` basculent `actif` joueur/voiture et la cible caméra ; au démarrage la caméra cible le joueur.
