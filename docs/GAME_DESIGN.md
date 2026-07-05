# GAME DESIGN — "ONE NIGHT" (working title)

## 1. Vision

A short, punchy, story-driven 3D gang brawler. You lead a small crew that has to
fight its way **across a hostile city in a single night** to get home / settle a
score. Each district is a self-contained chapter ruled by one themed rival gang.
The combat fantasy is **The Warriors**: scrappy, brutal, environmental, crew-based.
The world flavor is **GTA**: a stylized, satirical urban sandbox with attitude,
graffiti, reactive pedestrians, and a soundtrack that carries the mood. Wrapped in
a **PS1/PS2 low-poly skin** that is both an aesthetic choice and a performance
strategy.

**North star:** *finished, polished, short, and sellable.* A tight 2–4 hour
experience beats an unfinished open world every time.

## 2. Design pillars

1. **Brawls that feel physical.** Weighty hits, hitstun, knockback, environmental
   weapons, crowds that react. Combat is the core loop; everything serves it.
2. **You lead a crew.** A handful of AI allies you can command. Mobbing a lone
   rival, getting surrounded in an alley — the crew is the identity.
3. **One night, one journey.** Linear-by-district structure gives a clear arc and a
   natural, sellable scope. Each district is a vibe, a gang, a gauntlet.
4. **Style over fidelity.** PS1 crunch, neon, fog, grain, a killer soundtrack. The
   look is cohesive and intentional, not "low budget."
5. **Respect the player's time.** No filler. Every district introduces something
   new (mechanic, enemy, set-piece).

## 3. Setting & tone

Late-90s / early-2000s stylized metropolis — call it **HOLLOW CITY** for now
(rename freely). Grimy, neon-soaked, satirical. Curfew has emptied the streets to
gangs, drunks, and the occasional patrol. Tone: pulpy, stylized, a little funny, a
little mean — *The Warriors* film by way of GTA radio satire.

> All names below are a **starting palette** — rewrite to taste.

## 4. Story spine (the "One Night" structure)

> **This section is a FROZEN SPINE, not a script.** It exists to give direction,
> not to be implemented early. Per the build strategy (CLAUDE.md), **do not write
> dialogue, beats, or lock names until M5/M7** — after the combat is proven fun.
> Treat everything below as soft and rewritable; let the mechanics shape the final
> narrative.

**Setup:** Your crew (the **STRAYS**) is framed for something they didn't do at a
city-wide gang summit. Every gang in Hollow City now wants your heads, and bounty's
out on the radio. You're on the wrong side of town. **Get home before dawn.**

**Structure:** 6 districts = 6 chapters. Each: arrive → fight through the
district's gang → mini-boss (the gang's leader) → story beat → travel to next.
Difficulty and stakes escalate. Final district = the truth + final showdown.

**Arc beats:** betrayal (open) → survival (mid districts) → a reveal (who framed
you and why) → reckoning (final district). Keep it pulpy and tight; dialogue in
short barks and a few longer cutscene-lite moments (static PS1-style talking-head
panels are cheap and on-theme — no need for full cinematics).

## 5. Districts & gangs (ship target: all 6)

> Names are a starting palette — rename to taste. The structure is locked: **6
> districts, 6 distinct gangs.** Each district = one chapter, one gang, one *new*
> thing to learn. The finale gang **remixes earlier archetypes**, so enemy work
> compounds rather than restarts — six gangs, but not six from-scratch rosters.

| # | District | Gang | Combat identity / what it teaches |
|---|---|---|---|
| 1 | The Docks *(tutorial)* | **Wharf Rats** — scrappy dockhands; rusted bats, hooks, chains | Core combat, environmental weapons, crew commands. Weak but many. |
| 2 | Neon Strip | **The Voltz** — neon skaters/ravers; hit-and-run | Fast rushers → dodging, spacing, crowd control. |
| 3 | Old Market | **The Cleavers** — butcher heavies; armored, cleavers | Guard-break, heavy attacks, reading armored enemies. |
| 4 | Metro Tunnels | **The Undertow** — ambushers in the dark; throwers | Ranged threats, environmental hazards, awareness in fog. |
| 5 | The Heights | **Gold Crowns** — rich-kid mob + hired muscle | Big crowds, rage/special usage, protecting crew (hold-the-line). |
| 6 | Home Block *(finale)* | **The Hollowmen** — the gang that secretly runs Hollow City and framed you | Everything combined; an elite mixed roster (one specialist pulled from each earlier gang) + the final boss, their leader = the betrayer. |

**PS1 art direction — one cohesive palette, six grades:** Docks = foggy sodium-lit
rust · Strip = wet neon + arcade glow · Market = dim stalls, blood-orange · Tunnels
= near-black with flickering fluorescents + third-rail sparks · Heights = gold neon
+ skyline · Home Block = washed-out, melancholic, dawn breaking.

**MVP / vertical slice = District 1 (Docks) fully shipped.** Districts 2→6 reuse the
same systems (see ROADMAP M7); the Hollowmen finale reuses prior enemy archetypes.

## 6. Core combat

Real-time 3D brawler, lock-free targeting (auto-soft-target nearest threat).

- **Light attack** — fast combo string (3–4 hits to a finisher).
- **Heavy attack** — slow, high knockback, guard-breaking.
- **Grab / throw** — close-range; throw into others or off ledges.
- **Block** — reduces/negates frontal damage; can be guard-broken by heavies.
- **Dodge / roll** — i-frames, short cooldown.
- **Environmental weapons** — pick up bat / pipe / bottle / brick; throwable or
  melee; durability/limited uses. Signature Warriors flavor.
- **Rage meter** — builds on hits taken/landed; spend for a brief power state or a
  crew-wide special.

**Hit model:** hurtboxes/hitboxes, frame data (startup/active/recovery in config),
hitstun, knockback vectors, stagger, optional juggle. **Deterministic on the fixed
timestep.**

**Feel checklist (the "juice"):** hitstop on impact, screenshake scaled to hit
weight, impact particles, directional knockback, distinct SFX per weapon, blood/
spark decals, enemy ragdoll-lite on KO.

## 7. Crew system

- Start with 1 ally; recruit up to 3 across the game.
- **Command wheel / quick commands:** *Mob up* (focus your target), *Hold* (defend
  position), *Wreck* (aggressive/break stuff), *Regroup* (return to you).
- Allies have simplified combatant AI, can be downed and revived, and have light
  personality barks. They are a force multiplier and a liability to protect.

## 8. Enemy design

- **Fodder** — cheap FSM (approach → telegraph → attack → recover → stagger).
  Spawned in instanced crowds. The "musou-lite" feel comes from many of these.
- **Bruisers** — full-AI combatants, armor/guard, require timing.
- **Specialists** — per-gang gimmick (skater rushers, ambushers, throwers).
- **Gang leaders (mini-bosses)** — one per district, multi-phase, telegraphed
  patterns, the skill check of the chapter.

Caps from the perf budget: ~12–24 full-AI combatants + ~40–80 instanced fodder.

## 9. GTA-flavor sandbox layer (kept deliberately small)

- **District as a small open zone**, not a city. Explorable, but bounded.
- **Heat system** — aggression escalates as you fight/tag/cause chaos; rival
  reinforcements scale with heat. (Cops optional; rival gangs are the heat source.)
- **Tagging** — spray rival turf to claim it; rewards + raises heat. Warriors nod.
- **Pedestrians/props** — light reactive NPCs, destructible clutter, pickups.
- **No vehicles — fully cut.** No driving, not even scripted set-pieces. Keeps
  scope tight and the focus on on-foot combat and traversal.

## 10. Progression & economy

- **Per-district objectives** drive the chapter (reach X, beat leader, survive).
- **Upgrades** earned by progress / collectibles: max health, new combo enders,
  faster dodge, extra crew command, weapon proficiency.
- **Currency:** "Flash" (cash/respect) from fights and tags → spend at safehouses
  between districts on upgrades and cosmetics.
- **Collectibles:** hidden tags / cassette tapes (unlock soundtrack + lore).
- Keep the upgrade tree **shallow and readable** — this is a short game.

## 11. Audio & music (a core differentiator)

- **Dynamic, stem-based score.** Base exploration layer + combat layers that fade
  in by intensity (low/mid/high) + a boss theme. Crossfade on the fixed beat.
- **Style:** cohesive darksynth / synthwave / dirty electronic — one identity, not
  a genre grab-bag. License a cohesive pack or commission one artist.
- **Per-district musical identity** (small variations on the core palette).
- SFX: weighty, crunchy, distinct per weapon and surface.

## 12. Accessibility & options

Remappable controls, touch-control scale/opacity, screenshake toggle, photosensit-
ivity-safe flashing option, subtitle support, difficulty modes (Story / Standard /
Hard), colorblind-safe HUD.

## 13. Scope guardrails (the cut list)

If the schedule slips, cut in this order, guilt-free:
1. Districts beyond 3 (**emergency only** — the goal is all 6).
2. Tagging/heat depth (keep combat, simplify sandbox).
3. Crew size (ship with 1 ally).
4. Cosmetics / collectible meta.

**Never cut:** combat feel, one polished district, the soundtrack, the ending.
