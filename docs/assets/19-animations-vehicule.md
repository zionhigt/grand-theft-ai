# Bon de commande 19 — Animations véhicule

## Résumé

3 fichiers GLB Mixamo d'animation uniquement : `player_car_enter.glb`, `player_car_drive.glb`, `player_car_exit.glb`. Destination : `assets/characters/player/` (dossier existant depuis la feature 03, étendu par la feature 10). Aucun nouveau dossier créé. En l'absence de ces GLB, la feature se comporte comme la feature 18 (transitions instantanées, aucun crash).

## Arborescence cible

```
assets/
├── characters/
│   └── player/                          (existant depuis feature 03 — étendu ici)
│       ├── player_body.glb              (livré — feature 10)
│       ├── player_idle.glb              (livré — feature 10)
│       ├── player_walk.glb              (livré — feature 10)
│       ├── player_car_enter.glb         (nouveau — animation entrer dans voiture)
│       ├── player_car_drive.glb         (nouveau — animation conduire/assis, boucle)
│       └── player_car_exit.glb          (nouveau — animation sortir de voiture)
├── vehicles/
│   └── car/
│       └── car_body.glb                 (livré — feature 13/18, inchangé)
├── environment/                         (inchangé)
├── materials/                           (inchangé)
├── city/                                (inchangé)
├── skybox/                              (inchangé)
├── textures/                            (inchangé)
├── audio/                               (inchangé)
└── ui/                                  (inchangé)
```

Dossiers modifiés par ce bon de commande :
- `assets/characters/player/` (existant — 3 nouveaux fichiers GLB d'animation y sont ajoutés)

Aucun dossier nouveau n'est créé.

## Liste détaillée des assets

| Chemin Godot (res://) | Type | Format | Source | Livré ? | Notes techniques |
|-----------------------|------|--------|--------|---------|------------------|
| `res://assets/characters/player/player_car_enter.glb` | Animation squelettale "entrer dans voiture" | .glb | Mixamo (animation) | non | Without Skin, FBX Binary, 30 FPS, non bouclée ; durée ~1.0 s ; doit utiliser le même squelette que `player_body.glb` |
| `res://assets/characters/player/player_car_drive.glb` | Animation squelettale "conduire/assis au volant" | .glb | Mixamo (animation) | non | Without Skin, FBX Binary, 30 FPS, bouclée ; durée cycle ~2.0 s ; personnage assis, buste légèrement oscillant |
| `res://assets/characters/player/player_car_exit.glb` | Animation squelettale "sortir de voiture" | .glb | Mixamo (animation) | non | Without Skin, FBX Binary, 30 FPS, non bouclée ; durée ~0.8 s ; doit utiliser le même squelette que `player_body.glb` |

**Note importante** : les trois animations doivent être exportées pour le même personnage Mixamo que `player_body.glb` (même squelette). Utiliser "Without Skin" pour ces animations uniquement (le mesh est déjà fourni par `player_body.glb`).

## Conventions de nommage

- snake_case pour tous les noms de fichiers.
- Préfixe `player_` pour tous les assets du personnage joueur.
- Suffixe `_car_enter`, `_car_drive`, `_car_exit` pour les animations véhicule (extensible en `_car_enter_passenger`, etc. pour les features futures).
- Les fichiers FBX déposés dans `assets/import/` portent exactement le même nom que le GLB attendu : `player_car_enter.fbx`, `player_car_drive.fbx`, `player_car_exit.fbx`.
- Suffixes de texture (non requis ici — animations sans mesh).

## Budget polycount / mémoire

| Asset | Budget proto | Notes |
|-------|-------------|-------|
| `player_car_enter.glb` — animation | ~40 Ko estimé | Données squelettales uniquement (Without Skin), ~30 frames à 30 FPS |
| `player_car_drive.glb` — animation | ~60 Ko estimé | Données squelettales uniquement, ~60 frames à 30 FPS (2 s de boucle) |
| `player_car_exit.glb` — animation | ~30 Ko estimé | Données squelettales uniquement, ~24 frames à 30 FPS |

Aucun mesh supplémentaire (Without Skin). Ces assets n'alourdissent pas le budget polycount.

## Mocks obligatoires en attendant les assets finaux

En l'absence des GLB d'animation, aucun nœud visuel supplémentaire n'est requis — le mock est comportemental : si l'animation demandée n'existe pas dans l'`AnimationPlayer`, la transition est instantanée (comportement feature 18). Le jeu reste lançable et jouable.

| Asset cible | Nœud Godot mock | Forme | Dimensions | Couleur (hex) | Commentaire à inscrire |
|-------------|-----------------|-------|------------|---------------|------------------------|
| `res://assets/characters/player/player_car_enter.glb` | `AnimationPlayer` existant (feature 10) — piste `"car_enter"` absente | n/a — transition instantanée | n/a | n/a | `# MOCK — animation car_enter absente, transition instantanée. À remplacer par res://assets/characters/player/player_car_enter.glb` |
| `res://assets/characters/player/player_car_drive.glb` | `AnimationPlayer` existant (feature 10) — piste `"car_drive"` absente | n/a — personnage masqué ou T-Pose | n/a | n/a | `# MOCK — animation car_drive absente. Fallback : visible = false pendant conduite (comportement feature 18). À remplacer par res://assets/characters/player/player_car_drive.glb` |
| `res://assets/characters/player/player_car_exit.glb` | `AnimationPlayer` existant (feature 10) — piste `"car_exit"` absente | n/a — transition instantanée | n/a | n/a | `# MOCK — animation car_exit absente, transition instantanée. À remplacer par res://assets/characters/player/player_car_exit.glb` |

**Règle de fallback** : dans `player_controller.gd`, avant tout appel d'animation véhicule, vérifier :

```gdscript
func _play_anim(anim_name: String) -> void:
    if _anim_player == null:
        return
    if not _anim_player.has_animation(anim_name):
        # MOCK — animation absente, transition instantanée
        _on_vehicle_anim_finished()
        return
    _anim_player.play(anim_name)
```

Ainsi, l'absence de tout GLB n'entraîne aucun crash et le jeu reste jouable avec les transitions immédiates de la feature 18.

## Structure interne des GLB attendue pour le code d'intégration

Le `developer` doit pouvoir intégrer ces animations sans ouvrir l'éditeur Godot. Voici ce qui est attendu après conversion FBX → GLB par l'agent `mixamo` :

| Élément | Valeur attendue | Remarque |
|---------|----------------|----------|
| Nœud racine du GLB (après `instantiate()`) | nœud `AnimationPlayer` ou nœud racine contenant un `AnimationPlayer` | Les GLB Mixamo d'animation "Without Skin" peuvent exposer directement un `AnimationPlayer` ou l'imbriquer dans un nœud `Armature` |
| Nom de l'animation dans `player_car_enter.glb` | `"mixamo_com"` ou `"car_enter"` — à confirmer au runtime | Mixamo nomme souvent l'animation `"mixamo_com"`. Le code d'intégration doit lire le premier clip disponible si le nom attendu est absent : `_anim_player.get_animation_list()[0]` |
| Nom de l'animation dans `player_car_drive.glb` | `"mixamo_com"` ou `"car_drive"` | Même remarque — lire le premier clip disponible |
| Nom de l'animation dans `player_car_exit.glb` | `"mixamo_com"` ou `"car_exit"` | Même remarque |
| Skeleton3D | présent (Without Skin inclut le squelette) | Même squelette que `player_body.glb` — nécessaire pour rétargeter sur le mesh |
| AnimationPlayer | 1 par GLB | Contient exactement 1 animation |
| Mesh | absent (Without Skin) | Pas de MeshInstance3D dans ces GLB |

**Stratégie d'intégration recommandée** : charger les trois GLB d'animation dans `_ready()`, extraire les `AnimationLibrary` ou les pistes individuelles, et les injecter dans l'`AnimationPlayer` principal de `scenes/player/player.tscn`. Cela évite de gérer plusieurs `AnimationPlayer` concurrents.

```gdscript
# Exemple d'intégration (à adapter par le developer)
const CAR_ENTER_GLB = "res://assets/characters/player/player_car_enter.glb"

func _load_vehicle_animations() -> void:
    if ResourceLoader.exists(CAR_ENTER_GLB):
        var anim_scene = load(CAR_ENTER_GLB)
        var anim_instance = anim_scene.instantiate()
        var src_player: AnimationPlayer = _find_anim_player(anim_instance)
        if src_player:
            var anim_list = src_player.get_animation_list()
            if anim_list.size() > 0:
                var anim = src_player.get_animation(anim_list[0])
                _anim_player.add_animation("car_enter", anim)
        anim_instance.queue_free()
    # répéter pour car_drive et car_exit
```

## Section Mixamo — Instructions de téléchargement

| Nom du fichier GLB attendu | Nom du FBX à déposer | Catégorie Mixamo | Termes de recherche | Réglages export | Description |
|----------------------------|----------------------|-------------------|---------------------|-----------------|-------------|
| `player_car_enter.glb` | `player_car_enter.fbx` | Animations > Sitting | "getting into car", "sit down", "get in car", "entering vehicle" | **Without Skin**, FBX Binary, 30 FPS, non bouclée | Animation d'installation dans un siège de voiture. Chercher une animation où le personnage se baisse et s'assoit. Durée cible ~1 s. Utiliser le même personnage que `player_body.fbx`. |
| `player_car_drive.glb` | `player_car_drive.fbx` | Animations > Sitting | "driving", "car driving", "steering wheel", "sitting idle" | **Without Skin**, FBX Binary, 30 FPS, **boucle activée** | Animation de conduite assis, mains sur le volant. Une légère oscillation du buste est souhaitable. Durée cycle ~2 s. Utiliser le même personnage que `player_body.fbx`. |
| `player_car_exit.glb` | `player_car_exit.fbx` | Animations > Sitting | "getting out of car", "stand up from chair", "exit vehicle" | **Without Skin**, FBX Binary, 30 FPS, non bouclée | Animation de descente de voiture. Le personnage se lève du siège. Durée cible ~0.8 s. Utiliser le même personnage que `player_body.fbx`. |

**Règle critique — Without Skin** : ces trois animations doivent être exportées en mode **Without Skin** (pas de mesh, squelette seul). Cela réduit la taille des fichiers et évite des conflits de mesh lors de l'intégration. Le mesh du personnage est déjà fourni par `player_body.glb`.

**Même personnage** : impérativement sélectionner le même personnage Mixamo que celui utilisé pour `player_body.fbx` avant de chercher les animations. Le squelette doit être identique pour que les animations se rétargetent correctement sur le mesh.

Règle de nommage obligatoire : le FBX déposé dans `assets/import/` doit porter **exactement le même nom** que le GLB attendu (même nom, extension `.fbx`).

Rappel workflow complet :
1. Sur [mixamo.com](https://www.mixamo.com), sélectionner d'abord le personnage (onglet "Characters") — **le même que pour `player_body.fbx`**.
2. Chercher l'animation "getting into car" (ou équivalent) → régler sur Without Skin, FBX Binary, 30 FPS → télécharger → nommer `player_car_enter.fbx`.
3. Chercher l'animation "driving" ou "steering wheel" (ou équivalent) → régler sur Without Skin, FBX Binary, 30 FPS, boucle activée → télécharger → nommer `player_car_drive.fbx`.
4. Chercher l'animation "getting out of car" (ou équivalent) → régler sur Without Skin, FBX Binary, 30 FPS → télécharger → nommer `player_car_exit.fbx`.
5. Déposer les 3 FBX dans `assets/import/`.
6. Invoquer l'agent `mixamo` pour conversion et placement.

## Hors-périmètre

- Sons de portière, d'assise, de moteur : non commandés.
- Animation démarrage moteur (séquence distincte de la conduite) : non commandée.
- Animation de collision / crash du personnage en voiture : non commandée.
- Blend d'animations (AnimationTree) : non commandé.
- Synchronisation oscillation personnage ↔ physique véhicule réelle : non commandée.
- Passagers / siège passager : non commandés.
- Autres véhicules (moto, camion) : non commandés.
- Animation run, sprint, saut du personnage à pied : non commandées (déjà hors périmètre feature 10).
- Animations PNJ en véhicule : non commandées.
