# M0 — build notes & human verification checklist

M0 was implemented **text-first**: everything that lives in text files
(`project.godot`, scripts, shaders, `.tscn`, `.tres`, `export_presets.cfg`)
is done and committed. What normally counts as `[EDITOR]` work (renderer,
stretch, physics settings, autoload registration, export preset) is **encoded
in `project.godot` / `export_presets.cfg`** — your job is to verify it in the
editor, not to re-enter it.

## 1. Run it

1. Install **Godot 4.7 stable** (standard build) from https://godotengine.org/download.
2. Open the project (`project.godot`) in the editor. Godot will import
   resources and generate `.godot/` and `*.uid` sidecar files on first open —
   commit the `.uid` files if you want stable resource IDs (`.godot/` stays ignored).
3. Press **F5** (Run Project). You should see: a fog-shrouded dark scene, a
   grey ground slab, and a **crimson cube tumbling and bobbing with PS1 vertex
   jitter**, rendered at 640×360 and upscaled with hard pixels.

The jitter, wobble, fog, and low resolution are **intentional** (CLAUDE.md
hard rule 8).

## 2. Verify the project settings took effect

Open **Project → Project Settings** and confirm (enable *Advanced Settings*):

- **Rendering → Renderer → Rendering Method** = `gl_compatibility` (top-right
  of the editor viewport should say "Compatibility").
- **Display → Window**: Viewport Width/Height = 640×360, Window Width/Height
  Override = 1280×720, **Stretch Mode = viewport**, Aspect = keep.
- **Rendering → Textures → Canvas Textures → Default Texture Filter** = Nearest.
- **Physics → Common**: Physics Ticks per Second = 60, Max Physics Steps per
  Frame = 8, **Physics Interpolation = On**.
- **Physics → 3D → Physics Engine** = Jolt Physics.
- **Autoloads tab**: EventBus, Config, SaveManager, MusicDirector, Game — all
  enabled, in that order.

## 3. Install GUT (blocked in the dev sandbox — see OPEN_QUESTIONS.md)

The agent's sandbox couldn't reach the Asset Library, so tests currently run
on a tiny GUT-compatible runner. Headless, no editor needed:

```sh
godot --headless -s tests/lite_test_runner.gd
```

To install GUT properly:

1. In the editor: **AssetLib / Asset Store → search "GUT" → install** into
   `addons/gut/` (accept the default file list).
2. **Project → Project Settings → Plugins → enable "Gut"**.
3. Port the tests: in `tests/test_*.gd`, change
   `extends "res://tests/lite_test.gd"` to `extends GutTest` — the assertion
   calls (`assert_eq`, `assert_true`, `assert_false`) are already
   GUT-compatible. Then delete `tests/lite_test.gd` and
   `tests/lite_test_runner.gd`.
4. Run via the GUT panel, or headless:
   `godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit`.

## 4. Web export (the M0 acceptance gate)

1. **Editor → Export…** — the **Web** preset is already defined
   (`export_presets.cfg`, threads enabled for itch.io's cross-origin
   isolation). If prompted, click **Manage Export Templates → Download and
   Install** for 4.7.
2. Click **Export Project** → keep the path `export/web/index.html`.
3. Serve it locally (plain `python3 -m http.server` won't set the COOP/COEP
   headers threads need — use Godot's own one-click deploy instead: the
   **Remote Debug → Run in Browser** button runs a correctly-configured local
   server).
4. Verify the jittering cube on desktop browser **and on your phone's
   browser** (same LAN, or upload as a private itch.io page which sets the
   right headers).

If the web build fails physics-side, that's the known **Jolt-on-web** open
question — flip **Physics → 3D → Physics Engine** to `GodotPhysics3D` for a
retest and log the result in `docs/OPEN_QUESTIONS.md`.

## 5. PS1 toggles (settings store)

`Config` (autoload) persists settings to `user://settings.cfg` and pushes the
PS1 toggles into the shared materials. To smoke-test from any script or the
editor's debugger REPL:

```gdscript
Config.set_setting(&"ps1/vertex_snap", false)   # cube stops jittering
Config.set_setting(&"ps1/affine_mapping", false)
Config.set_setting(&"ps1/snap_resolution", 120.0)  # chunkier jitter
```

`ps1/scanlines` is stored but not consumed until `ps1_post.gdshader` (M6);
`camera/screenshake` is consumed by the camera rig from M1 on.

## 6. Decisions made during M0 (also logged in OPEN_QUESTIONS)

- **Godot 4.7 stable confirmed** (released 2026-06-18); Jolt is the engine
  default since 4.6 — pinned explicitly in `project.godot` anyway.
- **GUT deferred to a human editor session** (sandbox network policy); a
  minimal GUT-compatible runner keeps the suite green meanwhile.
- Base viewport locked at **640×360** (mobile/web budget row of CLAUDE.md);
  desktop still upscales cleanly.
- Godot 4.7 ships a built-in **VirtualJoystick** node — evaluate it in M1
  before reaching for an addon.

**Next up after your verification: M1 (character controller, camera, input).**
