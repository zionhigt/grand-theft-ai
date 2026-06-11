# GDD — Grand Theft AI

*Une page, pas plus. Si une idée ne tient pas ici, elle va dans BACKLOG.md section « Plus tard ».*

## Pitch

Un mini GTA en 3D : tu marches dans une petite ville, tu montes dans une voiture, tu conduis, tu ressors. Caméra troisième personne. C'est tout — et c'est déjà un jeu.

## Boucle de jeu (v0.1)

Explorer la ville à pied → repérer une voiture → monter dedans (E) → conduire → descendre (E) → recommencer. Le plaisir vient du **feel** : un personnage réactif, une caméra fluide, une voiture qui a du poids.

## Contrôles

| Entrée | À pied | En voiture |
|--------|--------|------------|
| Z/W, S | avancer / reculer | accélérer / freiner-reculer |
| Q/A, D | pas latéraux (relatifs à la caméra) | tourner |
| Souris (clic droit maintenu) | orbiter la caméra | orbiter la caméra |
| Molette | zoom caméra | zoom caméra |
| E | entrer dans la voiture proche | sortir |

## Direction visuelle

Proto low-poly assumé : primitives colorées et assets Mixamo/CC0 cohabitent sans honte. Lumière directionnelle chaude, ciel procédural. La lisibilité prime sur le réalisme.

## Critères du jalon v0.1 (« c'est un jeu »)

- [ ] Le jeu se lance sans erreur console
- [ ] Ville visible : sol + bâtiments + ciel + lumière
- [ ] Personnage 3D animé (idle/marche) déplaçable, caméra TPS fluide
- [ ] Voiture : entrer (E), conduire avec du poids, sortir (E)
- [ ] La caméra suit le véhicule actif sans à-coup
- [ ] 5 minutes de playtest sans bug visible

## Plus tard (hors v0.1)

Tir / visée (le vrai « S » de TPS), PNJ et trafic, missions, audio, HUD, jour/nuit.
