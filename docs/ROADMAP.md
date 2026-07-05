# ROADMAP — "ONE NIGHT" (Godot 4.7)

> **Source of truth for what to build next.** Work top-down, one task (or small
> group) at a time. Check the box, run the **GUT** suite, keep GDScript warning-free,
> and append a note if a decision changed scope.
>
> **Vertical-slice strategy:** M0–M6 deliver a *fully playable District 1* (the
> Docks). M7 scales to the full 6-district game. If time runs out after M6 you still
> have a shippable slice.
>
> **Code-first, story last.** Build the slice before content. Story stays a frozen
> one-page spine (GAME_DESIGN §4) until M5/M7. Clear the **FIND-THE-FUN gate after
> M2** before investing in content or narrative.

**Ownership tags:** `[SCRIPT]` Claude Code owns · `[SCENE]` agent edits `.tscn`,
human verifies in editor · `[EDITOR]` human does in editor, agent gives exact steps.
Legend: `[ ]` todo · `[~]` wip · `[x]` done · ⛏ perf-sensitive · 🎚 data Resource.

---

## M0 — Project foundations
**Goal:** a Godot 4.7 project that boots, runs deterministically, and renders one
cube in the PS1 style, on desktop and in a web export.

- [x] `[EDITOR]` Create Godot 4.7 project; set **Compatibility** renderer.
      *(encoded in `project.godot`; verify per `docs/M0_NOTES.md` §2)*
- [x] `[EDITOR]` `git init` + Godot `.gitignore` (ignore `.godot/`, `export/`).
- [x] `[EDITOR]` Display → Window: small base resolution, **Stretch = viewport**,
      aspect `keep`, default texture filter **nearest** ⛏. *(640×360 base; in `project.godot`)*
- [x] `[EDITOR]` Physics: tick rate 60, enable **physics interpolation**, cap max
      steps/frame. *(in `project.godot`; Jolt pinned explicitly)*
- [~] `[EDITOR]` Install **GUT** addon; add a `tests/` folder + one passing sample test.
      *(tests exist and pass on a GUT-compatible lite runner; GUT install itself needs
      the editor — steps in `docs/M0_NOTES.md` §3, decision in OPEN_QUESTIONS)*
- [x] `[SCRIPT]` Autoload stubs: `game.gd`, `event_bus.gd`, `config.gd`,
      `music_director.gd`, `save_manager.gd` (registered in `project.godot`).
- [x] `[SCENE]` `test_level.tscn`: ground + a cube (MeshInstance3D) + camera + light.
      *(human: verify node wiring in-editor)*
- [x] `[SCRIPT]` `shaders/ps1_snap.gdshader` (vertex snapping + affine) on shared
      materials (`assets/materials/ps1_*.tres`) ⛏.
- [x] `[SCENE]` `WorldEnvironment` with fog + per-scene environment 🎚
      (`data/environments/test_level_env.tres`).
- [x] `[SCRIPT]` Settings store + PS1 toggles (snap/affine/scanline/screenshake) in
      `autoload/config.gd`, persisted to `user://settings.cfg`.
- [~] `[EDITOR]` Web export preset; confirm the cube runs in a browser build.
      *(`export_presets.cfg` committed with a threads-enabled Web preset; human runs
      the export + browser check per `docs/M0_NOTES.md` §4)*

**Acceptance:** a jittering low-res cube runs in-editor *and* as a web export; GUT
sample test passes; no GDScript warnings.

> **M0 note (2026-07-05):** implemented text-first in a sandboxed session (no Godot
> editor, Asset Library unreachable). All `[EDITOR]` state that lives in
> `project.godot`/`export_presets.cfg` is committed; the two `[~]` items above need a
> human editor session — exact steps in `docs/M0_NOTES.md`. Tests run headless via
> `godot --headless -s tests/lite_test_runner.gd`.

---

## M1 — Character controller, camera, input
**Goal:** drive a blocky hero around a test level with a good third-person camera, on
keyboard/gamepad *and* touch.

- [x] `[EDITOR]` Input Map actions: move, attack_light/heavy, grab, block, dodge,
      interact, command, pause (keyboard + gamepad + mouse; in `project.godot`).
- [x] `[SCENE]` `player.tscn` = `CharacterBody3D` + collision + `SpringArm3D` camera
      (collision-aware follow). *(human: verify wiring in-editor)*
- [x] `[SCRIPT]` `player.gd`: move/accel/decel, gravity, slopes, facing, in
      `_physics_process` 🎚 (`data/player_movement.tres`; base logic in
      `scripts/combatant.gd`).
- [x] `[SCRIPT]` Camera rig logic (spring arm follow, soft lag, auto-yaw, hit
      shake) 🎚 (`scenes/player/camera_rig.gd`).
- [~] `[SCENE]` Placeholder hero `.glb` + `AnimationTree` (idle/run blend).
      *(primitive-mesh hero for now; a real .glb + AnimationTree needs art — deferred
      to the M4 art pass)*
- [x] `[SCRIPT]` `[SCENE]` Touch controls: virtual joystick + action buttons,
      scalable/repositionable ⛏ (custom Controls in `scenes/ui/touch_*.gd`, self-drawn,
      export-tunable radius/size; shown only on touch devices).
- [ ] `[EDITOR]` Test on a real phone (native or web) — movement + camera usable.

**Acceptance:** hero runs smoothly on desktop and a real phone; camera never clips
into walls.

> **M1 note (2026-07-05):** touch controls are a small custom Control pair rather
> than the 4.7 built-in VirtualJoystick node — implemented sight-unseen in a sandbox,
> so hand-rolled code beat an unverifiable node API. Swap later if the built-in is
> nicer (logged in OPEN_QUESTIONS).

---

## M2 — Combat core (the heart of the game)
**Goal:** fight one enemy with weighty, deterministic melee.

- [x] `[SCRIPT]` `MoveData` Resource + a light-combo and a heavy move as `.tres` 🎚
      (`data/moves/player_light_1..3.tres`, `player_heavy.tres`).
- [x] `[SCRIPT]` Combatant state machine; attack states step MoveData in ticks ⛏
      (`scripts/combatant.gd`: idle/move/attack/block/dodge/hitstun/down).
- [x] `[SCENE]` `Hitbox`/`Hurtbox` as `Area3D` with proper collision layers/masks
      (named layers in `project.godot`; player hitboxes only see enemy hurtboxes and
      vice versa).
- [x] `[SCRIPT]` Hit resolution: damage, hitstun, knockback, stagger, KO ⛏
      (`Combatant.take_hit`, pure math in `scripts/combat_math.gd`).
- [x] `[SCRIPT]` Block + guard-break; dodge with i-frame ticks 🎚 (frontal-arc block,
      heavies guard-break, dodge window in `CombatantData`).
- [x] `[SCENE]` `[SCRIPT]` One fodder enemy (as a full scene for now) with basic FSM
      (`scenes/enemies/fodder.*`: seek + separation, telegraphed jab, KO despawn).
- [x] `[SCRIPT]` Hit feedback: hitstop, camera shake, particle sparks, SFX
      hooks ⛏ (hitstop freezes both actors; shake respects the screenshake toggle;
      pooled `CPUParticles3D` sparks; SFX hook = `EventBus.hit_landed`).
- [x] `[SCRIPT]` GUT tests: frame/tick resolution, damage/knockback, i-frame windows
      (`tests/test_combat_math.gd`, runs on the lite runner until GUT is installed).

**Acceptance:** beating up a dummy *feels* good — hitstop, knockback, readable
telegraphs; combat math covered by tests.

> **M2 note (2026-07-05):** the Docks arena (`scenes/districts/docks_arena.tscn`,
> now the main scene) is an endless-wave brawl to exercise all of this: wave spawner,
> HUD, lose/retry loop, combat-intensity events. Feel numbers are first-pass `.tres`
> guesses — the FIND-THE-FUN gate below is where they get tuned by hand, on a phone.

---

## 🎯 GATE — FIND THE FUN (mandatory checkpoint after M2)
**Do not pass until the core brawl is genuinely fun.** This is the whole bet.

- [ ] Hitting an enemy feels weighty (hitstop, knockback, sound).
- [ ] Telegraphs readable; dodge/block feel fair and good.
- [ ] You *want* to keep fighting with no story or art yet.
- [ ] It feels good on a real phone via touch.

If **no**: iterate combat (tick data, feedback, camera, controls) and re-test. **Do
not advance to M3+ content, world, or story until this is a clear yes.** Pivots are
cheap here, expensive later.

---

## M3 — Crew & crowds (the identity)
**Goal:** lead one ally; fight a real mob; beat a mini-boss.

- [ ] `[SCENE]` `[SCRIPT]` `ally.tscn` + AI; downed/revive states.
- [ ] `[SCRIPT]` Crew command system (Mob up / Hold / Wreck / Regroup) via signals 🎚.
- [ ] `[SCRIPT]` **Fodder crowd: `MultiMeshInstance3D` + `FodderManager`** (data-
      oriented, no node per enemy), seek + separation steering ⛏.
- [ ] `[SCRIPT]` Prototype fodder animation approach (shader/vertex vs shared) ⛏.
- [ ] `[SCENE]` `[SCRIPT]` Bruiser enemy (full AI: spacing, block, react to dodge).
- [ ] `[SCENE]` `[SCRIPT]` Docks gang leader (boss): phase machine + telegraphs 🎚.
- [ ] `[SCRIPT]` Object pooling for enemies/VFX; enforce actor caps ⛏.
- [ ] `[EDITOR]` Perf pass: hit crowd budget on mobile/web ⛏.

**Acceptance:** you + ally vs a mob + leader holds the perf budget on mobile.

---

## M4 — District 1 world & sandbox layer
**Goal:** turn the test level into the playable **Docks**.

- [ ] `[SCRIPT]` `DistrictData` Resource (spawns, props, objectives, music set) 🎚.
- [ ] `[SCENE]` Build Docks greybox → art pass (low-poly, atlas, fog, PS1 grade).
- [ ] `[EDITOR]` `[SCENE]` `NavigationRegion3D` + bake navmesh; `NavigationAgent3D`
      on AI.
- [ ] `[SCENE]` `[SCRIPT]` Pickups: environmental weapons (bat/pipe/bottle) + health
      + flash (Area3D) 🎚.
- [ ] `[SCRIPT]` Weapon hold/use/durability; throwables.
- [ ] `[SCENE]` `[SCRIPT]` Destructible clutter + light reactive pedestrians ⛏.
- [ ] `[SCRIPT]` Heat system: intensity scales reinforcements 🎚.
- [ ] `[SCRIPT]` `[SCENE]` Tagging interaction (spray turf → reward + heat) 🎚.

**Acceptance:** the Docks is explorable and fightable with weapons, pickups, heat,
and tagging — a place, not a box.

---

## M5 — Game loop, meta & flow
**Goal:** a complete session: title → play the Docks → safehouse → save.

- [ ] `[SCRIPT]` Objective/mission system (reach/clear/survive) 🎚.
- [ ] `[SCRIPT]` Progression: upgrades (health, combo enders, dodge, command,
      weapon prof) 🎚.
- [ ] `[SCRIPT]` Economy: flash earn/spend at the safehouse 🎚.
- [ ] `[SCRIPT]` `SaveManager`: `user://` JSON, versioned schema + migration (GUT).
- [ ] `[SCENE]` `[SCRIPT]` UI: title, pause, settings (PS1 toggles + input remap),
      HUD, safehouse upgrade screen (Control + Theme).
- [ ] `[SCRIPT]` District-transition flow + autosave; collectibles tracking.
- [ ] `[SCRIPT]` Lose/retry flow (downed → checkpoint).

**Acceptance:** a stranger can launch, understand the goal, play the Docks start to
finish, upgrade, save, and resume.

---

## M6 — Audio, juice & vertical-slice polish
**Goal:** the Docks feels like a *product*.

- [ ] `[EDITOR]` Audio bus layout (Master/Music/SFX/UI).
- [ ] `[SCRIPT]` `[EDITOR]` `MusicDirector` with `AudioStreamInteractive`: base +
      combat layers + boss, intensity-driven transitions 🎚.
- [ ] `[SCRIPT]` SFX banks + pooled `AudioStreamPlayer3D`; positional hits.
- [ ] `[SCENE]` `[SCRIPT]` VFX polish: decals, KO ragdoll-lite, dust, neon, grade.
- [ ] `[SCRIPT]` Camera juice (hit-react, boss intro framing).
- [ ] `[SCRIPT]` `[EDITOR]` Accessibility: input remap UI, touch scale, screenshake/
      flash toggles, subtitles.
- [ ] `[EDITOR]` Perf + export-size pass on mobile/web ⛏.
- [ ] `[SCENE]` Build a **vertical-slice trailer** of the Docks (the hook).

**Acceptance:** the Docks slice is demo-able to players/press and sells the game.

---

## M7 — Full content & ship
**Goal:** scale the proven slice to the full 6-district game and release.

- [ ] `[SCENE]` `[SCRIPT]` Author Districts 2–6 (data + greybox + art) reusing M0–M6.
- [ ] `[SCRIPT]` Per-gang specialists, leaders, music sets (Voltz, Cleavers,
      Undertow, Gold Crowns, Hollowmen). Hollowmen reuse earlier archetypes.
- [ ] `[SCENE]` `[SCRIPT]` Story beats + cutscene-lite panels (AnimationPlayer);
      intro + ending. *(First time story text gets written.)*
- [ ] `[SCRIPT]` Full progression curve + balancing across all districts 🎚.
- [ ] `[EDITOR]` Global perf/export pass; per-target budgets.
- [ ] `[EDITOR]` Packaging: **Steam** (GodotSteam), **Android** AAB, **iOS**,
      **Web/itch.io** demo.
- [ ] Store pages, screenshots, trailer, price, wishlist/launch plan.
- [ ] `[EDITOR]` RC QA matrix (OSes, phones, browsers); fix-list burndown.

**Acceptance:** a finished, polished, short game live on at least itch.io + Steam.

---

## Cut order if the schedule slips
1. Districts beyond 3 → **emergency only**; the goal is all 6.
2. Tagging/heat depth.
3. Crew size → ship with 1 ally.
4. Cosmetics / collectible meta.

**Never cut:** combat feel · one polished district · the soundtrack · the ending.

---

## Suggested first session for Claude Code
1. Do **M0** (project, renderer, low-res stretch, physics tick + interpolation,
   autoload stubs, PS1 snap shader, fog, GUT). Human handles the `[EDITOR]` steps
   with the agent's exact instructions.
2. Stop; verify the jittering cube in-editor and as a web export, on desktop + phone.
3. Then start **M1**. Re-read `CLAUDE.md` each session.
