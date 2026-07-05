# ONE NIGHT (working title) — Godot 4.7

A short, story-driven 3D gang brawler for **desktop, mobile, and web**. **The
Warriors** (Rockstar) crew combat × **GTA** urban flavor, in a **PS1/PS2 low-poly**
skin. Built in **Godot 4.7** with **typed GDScript**, developed with Claude Code,
and shipped **native-first**: Steam + Android/iOS, with a Web/itch.io demo.

> **North star:** finished, polished, short, sellable. ~2–4 hours of content.

## ▶ Play the current build

**Web demo (auto-deployed from `main`):** https://dvd90.github.io/one-night/

Current state: the **Docks arena** — an endless-wave brawl exercising the M1+M2
core (movement, camera, light combo, heavy, block, dodge, wave spawner, HUD).

| Action | Keyboard | Mouse | Gamepad | Touch |
|---|---|---|---|---|
| Move | WASD / arrows | — | Left stick | Virtual joystick |
| Light attack (combo ×3) | J | Left click | X | ATK |
| Heavy (guard-break) | K | Right click | Y | HVY |
| Dodge (i-frames) | Space | — | A | DGE |
| Block | Shift | — | LB | BLK |

To run locally: install [Godot 4.7](https://godotengine.org/download), open
`project.godot`, press F5. Tests: `godot --headless -s tests/lite_test_runner.gd`.

## Docs (read in this order)

0. **[KICKOFF.md](./KICKOFF.md)** — how to start with Claude Code + the literal first
   prompt. **Start here.**
1. **[CLAUDE.md](./CLAUDE.md)** — agent operating guide, build strategy, stack,
   conventions, `[SCRIPT]/[SCENE]/[EDITOR]` task ownership, perf budgets, DoD.
2. **[docs/GAME_DESIGN.md](./docs/GAME_DESIGN.md)** — vision, pillars, story (a frozen
   spine), 6 districts/gangs, combat, crew, progression, audio, guardrails.
3. **[docs/ARCHITECTURE.md](./docs/ARCHITECTURE.md)** — Godot architecture: nodes/
   signals (no ECS), `_physics_process` determinism, Resources for data, PS1 pipeline,
   MultiMesh crowds, audio, save, native+web distribution.
4. **[docs/ROADMAP.md](./docs/ROADMAP.md)** — milestones M0–M7 + the FIND-THE-FUN
   gate, with ownership tags. **The source of truth for what to build next.**
5. **[docs/OPEN_QUESTIONS.md](./docs/OPEN_QUESTIONS.md)** — decisions log.

## Stack

Godot 4.7 · typed GDScript · Compatibility renderer (web + low-end) · Jolt physics
(4.7 default) · deterministic `_physics_process` + physics interpolation · custom
Resources for tunables · `AudioStreamInteractive` music · Control-node UI · Input Map
+ touch · MultiMesh crowds · GUT tests. Packaging: Steam (GodotSteam), Android/iOS
native, Web/itch.io.

## For the agent

Start at **M0** in `docs/ROADMAP.md` (see `KICKOFF.md`). Build **code-first**: get the
playable Docks slice working before content or story. The story is a **frozen spine**
until M5/M7. Clear the **FIND-THE-FUN gate after M2** before advancing. Keep gameplay
in `_physics_process`, tunables in `data/*.tres`, compose with nodes/signals (no ECS),
crowds via MultiMesh, and don't "fix" the intentional PS1 look. Respect the
`[SCRIPT]/[SCENE]/[EDITOR]` tags — hand the human exact editor steps for the latter two.
