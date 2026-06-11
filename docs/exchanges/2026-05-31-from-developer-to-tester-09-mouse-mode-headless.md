# Échange developer → tester — Feature 09 : test_clic_droit_press_capture_la_souris inutilisable en headless

**Date :** 2026-05-31  
**De :** developer  
**À :** tester  
**Sujet :** test_09_camera_orbitale.gd — `test_clic_droit_press_capture_la_souris` ne peut pas passer en mode headless

## Constat

Lors de l'implémentation de la feature 09, tous les tests passent sauf un :

```
test_clic_droit_press_capture_la_souris
[Failed]: [0] expected to equal [2]:  Le mode souris doit être MOUSE_MODE_CAPTURED après clic droit press
```

## Cause racine

En mode headless de Godot (sans DisplayServer), l'appel `Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)` est une opération sans effet. `Input.get_mouse_mode()` reste à `0` (MOUSE_MODE_VISIBLE) quelle que soit la valeur demandée.

Preuve par test direct :

```
Before: 0
After CAPTURED: 0
After set_mouse_mode CAPTURED: 0
```

Commande utilisée : `Godot_v4.6.2-stable_win64_console.exe --headless --path . -s test_mouse_mode.gd`

## Comportement symétrique

Le test `test_clic_droit_release_libere_la_souris` (B7) PASSE car :
1. `Input.set_mouse_mode(CAPTURED)` est appelé manuellement dans le test (ligne 245) — no-op en headless, mode reste VISIBLE.
2. Notre implémentation appelle `Input.mouse_mode = MOUSE_MODE_VISIBLE` — no-op également.
3. L'assertion `== MOUSE_MODE_VISIBLE` passe trivialement car le mode est toujours VISIBLE.

## Ce qui est implémenté et correct

La logique de capture de souris est bien présente dans `src/camera/camera_controller.gd` :
```gdscript
if mb.pressed:
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
else:
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
```

Le flag `_right_mouse_held` est correctement mis à `true`/`false` (testé par les tests B6 et B7 qui passent).

## Demande

Ce test (`test_clic_droit_press_capture_la_souris`) doit être adapté pour être testable en headless. Options possibles :

1. **Supprimer l'assertion sur `Input.get_mouse_mode()`** dans ce test (trop couplée à l'OS/display) et ne garder que l'assertion sur `_right_mouse_held`.
2. **Ajouter un guard** : `if not OS.has_feature("headless"): assert_eq(...)` — le test est skippé en headless mais passe en mode avec display.
3. **Mock de `Input`** via une variable injectable dans `CameraController` — mais cela change l'API publique au-delà de la spec 09.

La solution 2 est la moins invasive et la plus honnête vis-à-vis du comportement réel.

## État actuel

166/167 tests passent. Exit code 1 à cause uniquement de ce test.  
Tous les autres tests feature 09 (31/32) et tous les tests des features précédentes (135/135) sont verts.
