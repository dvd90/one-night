# KICKOFF — start here with Claude Code (Godot 4.7)

This repo is a **plan, ready to build** in Godot 4.7 with typed GDScript.

## 1. Set up

1. Install **Godot 4.7 stable** (standard build; the .NET build is only needed if
   you switch to C#, which we're not). Get it from https://godotengine.org.
2. Create an empty git repo and put these files at the **root** (`CLAUDE.md`,
   `README.md` at root; the rest under `docs/`). The Godot project files
   (`project.godot`, `/scenes`, etc.) get created during M0.
3. Open the folder in **Claude Code**. Claude Code reads `CLAUDE.md` automatically.
4. Keep the **Godot editor open** alongside Claude Code — you'll do the `[EDITOR]`
   steps (project settings, input map, export presets) as the agent instructs.

## 2. How work is split (important for Godot)

Godot is more editor-centric than a pure-code stack, so tasks are tagged:

- `[SCRIPT]` — GDScript, Resources, shaders. **Claude Code does these fully.**
- `[SCENE]` — `.tscn` scenes. Claude Code writes/edits the text; **you open the
  editor to verify** nodes wired up correctly.
- `[EDITOR]` — project settings, import flags, input map, audio buses, export
  presets. **You do these in the editor**; the agent gives exact click-by-click steps.

Whenever the agent hits an `[EDITOR]`/`[SCENE]` task, it should stop and hand you
precise instructions rather than pretend it clicked the buttons.

## 3. The first prompt (paste into Claude Code)

> Read `CLAUDE.md` and `docs/ROADMAP.md`, then implement **Milestone M0** for a
> Godot 4.7 project. Follow the conventions: typed GDScript (no warnings), gameplay
> in `_physics_process`, tunables in `data/*.tres`, compose with nodes/signals (no
> ECS), and the PS1 look via low base resolution + `viewport` stretch + nearest
> filtering + vertex-snap shader + fog (all intentional).
>
> For every `[EDITOR]` and `[SCENE]` task, give me exact step-by-step instructions
> for the Godot editor instead of assuming it's done — I'll perform them and confirm.
> For `[SCRIPT]` tasks, write the actual files.
>
> M0 scope only:
> - The `.gitignore` (ignore `.godot/`, `export/`) and folder structure from CLAUDE.md.
> - Autoload scripts: `game.gd`, `event_bus.gd`, `config.gd`, `music_director.gd`,
>   `save_manager.gd` (stubs), plus the exact steps to register them as autoloads.
> - A `test_level` scene (ground + cube + camera + light) — give me the node tree to
>   build, or generate the `.tscn` and tell me what to verify.
> - `shaders/ps1_snap.gdshader` (vertex snapping) applied via a shared material.
> - A settings store with PS1 toggles (snap/affine/scanline/screenshake).
> - The exact Project Settings for: Compatibility renderer, low base resolution +
>   Stretch=viewport + nearest filter, physics tick 60 + physics interpolation, and a
>   Web export preset.
> - Install GUT and add one passing sample test.
>
> When done, tell me exactly how to run the project and how to make the web export,
> check off the M0 tasks in `docs/ROADMAP.md`, and **stop** so I can verify the
> jittering low-res cube in-editor and in a browser, on desktop and my phone, before M1.

## 4. The rhythm after M0

- One milestone (or coherent group) per session. Re-read `CLAUDE.md` each time.
- After each task: run the **GUT** suite, keep GDScript warning-free, check the box
  in `docs/ROADMAP.md`.
- **M0 → verify the cube** (desktop + web + phone) → **M1** (controller + camera +
  touch) → **M2** (combat core).
- **Stop at the 🎯 FIND-THE-FUN gate after M2.** Play it. Don't build content, world,
  or story until the brawl is genuinely fun on a real phone. This gate is the bet.

## 5. What *not* to let the agent do early

- Don't write story dialogue/beats or lock names — frozen spine until M5/M7.
- Don't build an ECS — use Godot nodes/scenes/signals.
- Don't switch renderer/engine/language (Compatibility + Godot 4.7 + typed GDScript
  are locked) or add C# unless you decide to drop the web target.
- Don't "fix" the PS1 look (jitter, fog, low res are intentional).

## 6. Good first checkpoints to feel progress

1. **Jittering low-res cube** in-editor and in a browser (end of M0).
2. **Run around the Docks greybox on your phone** (end of M1).
3. **A dummy that's fun to beat up** (FIND-THE-FUN gate).

If #3 feels good, you have a real game. Everything after is content and polish.
