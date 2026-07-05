# OPEN QUESTIONS

Decisions to revisit. Agents: when blocked by ambiguity, **pick a sensible default
to keep moving** and log it here.

## Decided
- [x] Engine: **Godot 4.7** stable.
- [x] Language: **typed GDScript** (C# only if we drop the web target).
- [x] Renderer: **Compatibility** (web + low-end reach).
- [x] Physics: **Jolt** (Godot 4.7 default).
- [x] Architecture: **nodes/scenes/signals + Resources**, no ECS.
- [x] Districts: **6 districts, 6 distinct gangs** (3-district cut is emergency-only).
- [x] Vehicles: **fully cut**.
- [x] Distribution: **native-first** (Steam + Android/iOS); Web/itch.io is a demo.

## Decided in M0 (2026-07-05)
- [x] **Godot 4.7 stable confirmed** (released 2026-06-18, "Lights, Camera,
      Action!"); Jolt is the engine default since 4.6. Pinned explicitly in
      `project.godot` regardless.
- [x] **Test harness:** GUT couldn't be fetched from the agent's sandbox (network
      policy blocks the Asset Library/GitHub downloads), so `tests/` ships a minimal
      **GUT-compatible lite runner** (`lite_test_runner.gd` + `lite_test.gd`, same
      `assert_eq/assert_true/assert_false` signatures). Install GUT in an editor
      session and port by swapping the `extends` — steps in `docs/M0_NOTES.md` §3.
- [x] **Base viewport: 640×360** (mobile/web budget row), window override 1280×720.
- [x] Godot 4.7 ships a built-in **VirtualJoystick** node — prefer it over a
      community addon in M1 (supersedes the touch-controls question below;
      re-evaluate then).

## Technical (open)
- [ ] **Jolt on web export** — confirm it works in the WASM/Compatibility build in
      M0/M3; fall back to Godot Physics for web if needed.
- [ ] **Fodder animation** — shader/vertex animation vs shared AnimationPlayer for
      MultiMesh crowds. Decide in M3 perf pass.
- [ ] Sim rate on mobile/web: lock 60 vs 30. Measure in M1. Default 60.
- [ ] Pathing: NavigationRegion3D navmesh from the start vs a simpler grid for the
      Docks. Default navmesh (built-in).
- [ ] Dynamic music: `AudioStreamInteractive` vs `AudioStreamSynchronized` stems.
      Prototype both in M6. Default AudioStreamInteractive.
- [ ] Touch controls: use a community virtual-joystick addon vs a small custom
      Control. Decide in M1.

## Design (open)
- [ ] Final city / gang / crew names (placeholders in GAME_DESIGN).
- [ ] Rage meter payoff: personal power state vs crew-wide special vs both.
- [ ] Cops as a second heat source, or rival-gangs only? Default: rivals only.

## Production (open)
- [ ] Soundtrack: license a cohesive pack vs commission one composer.
- [ ] Art: commission low-poly vs source PS1-style packs for greybox.
- [ ] iOS shipping needs a Mac + Apple dev account — confirm availability before M7.
