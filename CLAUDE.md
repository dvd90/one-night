# CLAUDE.md

> Operating guide for Claude Code on this project. Read this first, every session.
> Treat `docs/ROADMAP.md` as the source of truth for *what to build next*.

## Project: "ONE NIGHT" (working title)

A 3D gang brawler for **desktop, mobile, and web**. Mix of **The Warriors**
(Rockstar) gang combat + **GTA** urban flavor, in a deliberate **PS1/PS2 low-poly
aesthetic**. Single-player, story-driven, **short and finished is the goal**
(~2–4 hours). Built in **Godot 4.7** and distributed **native-first**: Steam
(desktop), Android/iOS (native), and a Web/itch.io build as a demo.

## Build strategy & sequencing (read before picking up any task)

**Code-first. Find the fun, then write the story.**

1. **Build the playable vertical slice (the Docks) before any content or story.**
   Every M0–M2 task should move the Docks brawl closer to playable.
2. **The story is a FROZEN SPINE, not a script.** The premise in `docs/GAME_DESIGN.md`
   (framed crew · one night home · 6-gang escalation) is enough. **Do not write
   dialogue, cutscene beats, or lock names** until M5/M7.
3. **Combat feel is the only real risk — de-risk it first.** There is an explicit
   **FIND-THE-FUN gate after M2**. If the brawl isn't fun, iterate combat; do not
   advance to content or story.
4. **Let mechanics shape the story, not the reverse.**
5. **Story rewrites are free and expected.** Never let a narrative decision block an
   engineering task; log it in `OPEN_QUESTIONS.md` and keep moving.

## Stack (pinned — do not change without updating ARCHITECTURE.md)

- **Engine:** Godot **4.7** stable.
- **Language:** **typed GDScript** (always annotate types; `class_name` on shared
  types). *Alt: C# — only if we drop the web target.*
- **Renderer:** **Compatibility** (OpenGL ES3 / WebGL2) — best reach (web + low-end
  mobile) and ideal for the low-fi look. *Alt: Mobile renderer if we drop web.*
- **Physics:** **Jolt** (Godot 4.7 default). `CharacterBody3D` for controllers.
- **Determinism:** gameplay runs in `_physics_process` (fixed 60 Hz tick). Enable
  **physics interpolation** for smooth rendering. Never run sim logic in `_process`.
- **Data/tunables:** custom **Resource** classes (`.tres`) + a `Config` autoload.
- **Audio:** Godot audio buses + **`AudioStreamInteractive`** for dynamic music.
- **UI:** Godot **Control** nodes + a shared `Theme`. (No HTML/web UI.)
- **Input:** Godot **Input Map** actions + on-screen touch controls.
- **Crowds:** **`MultiMeshInstance3D`** + a data-oriented manager for fodder.
- **Test:** **GUT** (Godot Unit Test) on pure logic. Keep combat math in static,
  node-free functions so it's testable.
- **VCS:** git with the standard Godot `.gitignore` (ignore `.godot/`, exports).

## Hard rules

1. **Typed GDScript.** Annotate params, returns, vars. No bare `Variant`/untyped
   without a `# reason:` comment. Treat GDScript warnings as errors in CI.
2. **Determinism in combat.** All gameplay/AI/hit resolution in `_physics_process`.
   Rendering smoothness comes from physics interpolation, not from sim in `_process`.
3. **No magic numbers.** Tunables live in Resource files under `data/` (move frames,
   speeds, damage, costs, heat). Scripts read data; they don't hardcode balance.
4. **Compose with nodes & signals. Do NOT build an ECS.** Use scenes, node
   composition, and the `EventBus` autoload for cross-cutting events. Idiomatic
   Godot beats a bolted-on framework.
5. **Pool, don't churn.** Enemies, pickups, VFX, and audio players are pooled.
   Fodder crowds are `MultiMesh` + a manager, not one node per enemy.
6. **Performance budget is a feature** (see below). Flag any change that blows it.
7. **Mobile-first input.** Every action reachable via touch *and* keyboard/gamepad
   through the Input Map. No mouse-only/hover-only interactions.
8. **The PS1 look is the optimization.** Low base resolution + `viewport` stretch,
   vertex snapping, nearest filtering, fog. Don't "fix" these — they're intentional.

## Task ownership tags (used in ROADMAP)

- `[SCRIPT]` — pure GDScript / Resources / shaders. **Claude Code owns these fully.**
- `[SCENE]` — `.tscn` scene work. Claude Code can generate/edit scene text, but the
  **human verifies in the editor** (node setup, references).
- `[EDITOR]` — project settings, import flags, input map, export presets, bus layout.
  **Human does this in the Godot editor**; Claude Code provides exact steps.

Prefer `[SCRIPT]` solutions where a choice exists, to maximize what the agent can do.

## Project structure

```
res://
  project.godot
  /autoload      game.gd, event_bus.gd, config.gd, music_director.gd, save_manager.gd
  /scenes
    /player      player.tscn + player.gd (CharacterBody3D)
    /crew        ally.tscn + ally.gd
    /enemies     fodder (multimesh-driven), bruiser.tscn, boss scenes
    /districts   docks.tscn, ...
    /ui          hud.tscn, menus, safehouse
    /vfx         hit_spark.tscn, decals, ...
  /scripts       shared base classes + node-free logic (combat_math.gd, fsm.gd)
  /data          *.tres: move_data, enemy_data, gang_data, district_data, economy
  /shaders       ps1_snap.gdshader, ps1_post.gdshader
  /assets        models (.glb), textures, audio (music stems, sfx)
  /addons        gut, virtual_joystick, ...
/docs            GAME_DESIGN.md, ARCHITECTURE.md, ROADMAP.md, OPEN_QUESTIONS.md
/tests           GUT test scripts (test_*.gd)
```

## Performance budgets (enforce, don't aspire)

| Target | Desktop (native) | Mobile / Web |
|---|---|---|
| Frame time | 16.6 ms (60fps) | 33 ms (30fps) min, 60 ideal |
| Draw calls | < 200 | < 120 |
| Visible triangles | < 400k | < 150k |
| Active full-AI combatants | ~24 | ~12 |
| Fodder crowd (MultiMesh + cheap AI) | ~80 | ~40 |
| Base viewport (upscaled via stretch) | 480–540p | 360–432p |
| Web export size (gzip, first district) | — | keep lean; measure early |
| Texture size | 256px max, mostly 128px | — |

Crowd feel = **MultiMesh rendering + cheap manager AI + capped full-AI actors**, not
hundreds of `CharacterBody3D` nodes.

## How to work

- Pick the next unchecked task in `docs/ROADMAP.md`. One task/small group at a time.
- Respect the ownership tag. For `[EDITOR]`/`[SCENE]`, write precise editor steps in
  the response so the human can do or verify them.
- Before marking done: run the **GUT** suite; ensure no GDScript warnings.
- Update the ROADMAP checkbox; append a note if a decision changed scope.
- Conventional commits: `feat:`, `fix:`, `perf:`, `refactor:`, `chore:`, `docs:`,
  `test:`.
- If blocked by an ambiguous design question, log it in `OPEN_QUESTIONS.md`, pick a
  sensible default, and keep moving.

## Definition of Done (per task)

- [ ] Typed GDScript, no warnings; GUT tests pass.
- [ ] Touch + keyboard/gamepad both work for any new interaction.
- [ ] No per-frame churn in the hot path (pooled; fodder via MultiMesh).
- [ ] Tunables in `data/*.tres`, not hardcoded.
- [ ] Stays within perf budget (note if not).
- [ ] Editor steps written out for any `[EDITOR]`/`[SCENE]` work.
- [ ] ROADMAP checkbox updated.
