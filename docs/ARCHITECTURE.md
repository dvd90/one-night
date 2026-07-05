# ARCHITECTURE — "ONE NIGHT" (Godot 4.7)

## 0. Goals

Idiomatic Godot (nodes/scenes/signals, no bolted-on ECS), deterministic combat via
the physics tick, broad reach (native desktop/mobile + web), and a PS1 look that
doubles as the performance strategy. Maximize what Claude Code can do in text
(GDScript, Resources, shaders, `.tscn`), minimize required editor clicking.

## 1. Engine, language, renderer

- **Godot 4.7 stable.** Cross-platform export (Win/Mac/Linux, Android/iOS, Web) from
  one project.
- **Typed GDScript.** Optional static typing gives type safety while staying the
  best-supported, most agent-friendly language in Godot. `class_name` for shared
  types. *C# is possible but complicates web export — only if we drop web.*
- **Compatibility renderer** (OpenGL ES3 / WebGL2). Best for web + low-end mobile,
  and the low-fi aesthetic doesn't need Forward+. *Mobile renderer is the fallback
  if we ever drop the web target.*

> If any of these change, update this file and `CLAUDE.md`.

## 2. High-level shape

Everything is nodes and scenes. Cross-cutting concerns go through **autoload
singletons** and **signals**, not global references or an ECS.

```
Autoloads (singletons, always loaded):
  Game          top-level state machine (boot → menu → district → safehouse → ...)
  EventBus       signal hub for decoupled events (hit_landed, enemy_downed, ...)
  Config         loads tunable Resources (moves, enemies, economy) once at boot
  MusicDirector  interactive music; reacts to combat intensity
  SaveManager    load/save to user://, versioned

Scenes (composed of nodes):
  Player (CharacterBody3D) ── StateMachine, Hitbox/Hurtbox (Area3D), AnimationTree
  Ally   (CharacterBody3D) ── same combat parts, command-driven AI
  Enemies: Bruiser/Boss = full scenes; Fodder = MultiMesh + FodderManager (no nodes)
  District (Node3D) ── geometry, NavigationRegion3D, spawns, pickups, props
  UI (CanvasLayer) ── HUD, menus, safehouse (Control nodes + Theme)
```

## 3. Determinism & the game loop

Godot gives us a fixed timestep for free:

- **`_physics_process(delta)`** runs at the **Physics Tick Rate** (set 60 Hz). *All*
  gameplay, AI, combat frame-stepping, and movement live here → deterministic.
- **`_process(delta)`** is render-rate only (camera smoothing, cosmetic VFX). No sim
  logic here.
- Enable **Physics Interpolation** (Project Settings → Physics → Common) so motion
  is smooth even when render fps ≠ tick rate. We do **not** hand-roll interpolation.
- Cap max physics steps per frame to avoid a spiral of death on slow frames.

Combat "frames" are physics ticks. Move data is authored in ticks @ 60 Hz.

## 4. Composition model (instead of ECS)

- **Behavior via child nodes / small scripts.** e.g. a `Health` node, a `Hurtbox`
  Area3D, a `StateMachine` node — attached under an actor scene. Actors stay small
  and readable.
- **Signals for decoupling.** A `Hitbox` emits `hit(target, data)`; systems react.
  Global events (combat intensity changed, enemy downed) go through `EventBus`.
- **Data via Resources.** Custom `Resource` classes are the tunables layer:
  - `MoveData` — `startup`, `active`, `recovery`, `damage`, `knockback`,
    `hitbox_shape`, `cancel_window` (all in ticks).
  - `EnemyData` — hp, speed, archetype, move set, ai profile.
  - `GangData` / `DistrictData` — composition, spawn tables, music set, navmesh ref.
  - `EconomyData`, `HeatData` — costs and curves.
  Resources are typed, editor-editable, and serializable → the agent tunes `.tres`
  data, not code.

## 5. Combat system

- Each combatant has a **state machine** (`idle/move/attack/block/dodge/hitstun/
  down`). Attack states step through a `MoveData`'s startup→active→recovery in ticks.
- **Hit detection:** `Hitbox` = `Area3D` enabled only during active ticks; overlap
  with an enemy `Hurtbox` (`Area3D`) → resolve. Broadphase handled by Godot's
  physics/area layers; use collision layers/masks to keep player/enemy hitboxes
  cheap and correct.
- On confirmed hit: apply damage, hitstun (tick count), knockback vector, stagger;
  handle blocking / guard-break; dodge grants i-frame ticks.
- **Hitstop:** briefly pause both actors' state timers on impact (a global tick
  freeze on the involved actors) for weighty feedback.
- **Pure math is node-free** (`scripts/combat_math.gd`, static funcs) → GUT-testable.

## 6. AI & crowds

- **Fodder** (the "musou-lite" crowd): rendered with **`MultiMeshInstance3D`** and
  driven by a **`FodderManager`** that updates transforms + a cheap FSM over plain
  arrays in `_physics_process`. No node per fodder. Simple seek + separation.
- **Bruisers / specialists:** full scenes with real state machines (spacing, block,
  react to player dodge/block).
- **Boss:** scripted phase machine + telegraphed patterns.
- **Crew allies:** combatant AI biased by current command, leashed to the player.
- **Pathing:** Godot **NavigationRegion3D** + **NavigationAgent3D** per district
  (built-in navmesh). Bake the district navmesh in-editor.

## 7. PS1/PS2 render pipeline

Achieved with built-in settings + a couple of shaders:

1. **Low internal resolution** — set a small **base viewport size** and Project
   Settings → Display → Window → **Stretch = `viewport`**, aspect `keep`, with
   **nearest** texture filtering. The whole game renders low-res and upscales. This
   is the biggest perf + authenticity lever and is built in.
2. **Vertex snapping (PS1 jitter)** — a spatial `shader` (`ps1_snap.gdshader`) that
   snaps vertex clip-space position to a coarse grid. Applied via a shared material.
3. **Affine texture mapping (optional)** — drop perspective-correct UVs in-shader for
   the wobble. Toggleable; use sparingly.
4. **Nearest filter + small textures** — set on import; disable mipmaps for crunch.
5. **Vertex/unshaded-ish lighting** — lean lighting; bake where possible.
6. **Fog** — `WorldEnvironment` fog to hide draw distance (very PS1; also culls work).
7. **Post** (`ps1_post.gdshader` on a full-screen quad / environment): dithering,
   posterize/limited color depth, optional scanline/CRT (off by default).

All toggleable in Settings (shader params + environment tweaks). Per-district color
grade via environment.

## 8. Performance tactics

- **MultiMesh** for crowds and repeated props; **pool** enemies/pickups/VFX/audio.
- **Occlusion/frustum culling** + aggressive fog distance.
- **LOD**: Godot visibility ranges / simple LOD meshes; impostor billboards for far
  fodder if needed.
- Cap simultaneous full-`AnimationTree` actors; fodder use cheap/shared animation.
- Compatibility renderer keeps GPU cost low across web + old devices.

## 9. Input

- **Input Map** actions (`move_*`, `attack_light`, `attack_heavy`, `grab`, `block`,
  `dodge`, `interact`, `command`, `pause`) defined in Project Settings → Input Map.
  Bindings cover keyboard + gamepad.
- **Touch:** on-screen virtual joystick + `TouchScreenButton`s (an addon or a small
  custom control), scalable/repositionable, feeding the same actions.
- Gameplay reads **actions only**, never raw devices.

## 10. Audio

- **Buses:** Master → Music, SFX, UI (bus layout resource).
- **Dynamic music:** `MusicDirector` drives an **`AudioStreamInteractive`** graph
  (base + combat-low/mid/high + boss clips with beat-synced transitions), selecting
  clips from the current combat intensity. `AudioStreamSynchronized` is the fallback
  for simple synced stems with volume automation.
- **SFX:** pooled `AudioStreamPlayer3D` for positional hits; `AudioStreamPlayer` for
  UI. Duck music on pause / dialogue.

## 11. UI

- **Control** nodes on a `CanvasLayer`, styled by a shared **`Theme`** resource.
- HUD: health, crew status, rage, heat, objective marker, weapon/durability.
- Menus: title, settings (incl. PS1 toggles + input remap), pause, safehouse upgrade,
  district transition. Keep the gameplay HUD light.

## 12. Save system

- `SaveManager` autoload; write JSON (or `ConfigFile`) to **`user://`** behind a
  small interface. Persist: current district, upgrades, flash, crew roster,
  collectibles, settings. Autosave on safehouse + district complete. **Versioned**
  schema with a migration function (GUT-tested).

## 13. Build, packaging & distribution (native-first)

| Target | How |
|---|---|
| **Steam (desktop)** | Native Godot export (Win/Mac/Linux). Steamworks via the **GodotSteam** GDExtension for achievements/overlay. |
| **Android** | Native AAB export (Google Play). |
| **iOS** | Native export (requires macOS + Xcode). |
| **Web / itch.io (demo)** | HTML5/WASM export using the **Compatibility** renderer. Enable the cross-origin isolation headers itch provides (for threads/SharedArrayBuffer). Keep it a slim demo build. |

- **Export presets** are `[EDITOR]` tasks; Claude Code documents exact settings.
- Code + data are text (`.gd`, `.tres`, `.tscn`, `.gdshader`) → git-friendly. Ignore
  `.godot/` and `export/`.

## 14. Testing

- **GUT** for pure logic: combat math (damage/knockback/hitstun), heat curves, save
  migrations, economy. Keep this logic node-free (static functions) so tests don't
  need a running scene.
- Optional: a headless smoke scene that spawns the Docks, runs a scripted input
  sequence, and asserts no errors / stable frame budget.

## 15. Open technical risks (track in OPEN_QUESTIONS.md)

- **Jolt on web export** — verify Jolt works in the WASM/Compatibility web build
  early; fall back to Godot Physics for web if needed.
- **Web perf for 3D on mobile browsers** — likely the weakest target; treat web as a
  demo and lean on native mobile for the real mobile experience.
- **MultiMesh + per-instance animation** for fodder — prototype the animation
  approach (shader/vertex-anim vs shared AnimationPlayer) in M3.
- **AudioStreamInteractive** authoring workflow — validate beat-synced transitions
  early in M6.
- **Touch combat ergonomics** — prototype virtual controls in M1, not late.
