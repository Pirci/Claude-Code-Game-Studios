# ADR-0008: Audio Architecture — Persistent AudioController, Bus Layout, SFX Library

## Status

Accepted (2026-10-19 — C-23; small, as-built decision within the patterns of ADR-0001/0003.
Re-validate at the next `/architecture-review`.)

## Date

2026-10-19

## Last Verified

2026-10-19 (Godot 4.7.1, headless tests + Xvfb run with the dummy audio driver)

## Decision Makers

Technical direction (night-mode autonomous run, recommended option accepted per user instruction).

## Summary

ULUS had no audio infrastructure: the settings screen already wrote `Music` and `SFX` bus
volumes, but no bus layout existed, so those sliders did nothing, and the art bible's
selection "click" (the colour-blind fallback for selection, §4) could not be played. We add a
project bus layout (`Master` → `Music`, `SFX`), a persistent `AudioController` owned by
`RootContext` and injected into contexts, and a data-driven `SfxLibrary` resource mapping SFX
ids to streams.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7 |
| **Domain** | Audio |
| **Knowledge Risk** | LOW — `AudioServer`, `AudioStreamPlayer`, `AudioBusLayout` unchanged 4.4–4.6 (`modules/audio.md`); typed `Dictionary[StringName, AudioStream]` export (4.4+) verified |
| **References Consulted** | `docs/engine-reference/godot/modules/audio.md`, `VERSION.md` |
| **Post-Cutoff APIs Used** | Typed dictionary export in a `Resource` (4.4+) — serialized as `Dictionary[StringName, AudioStream]({...})`, round-trips via `ResourceSaver`/`load()` |
| **Verification Required** | Real-device playback (the container has no sound card — dummy driver); per-OS latency not measured |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (RootContext owns long-lived services), ADR-0002 (`features/audio/`), ADR-0003 (injection via `bind_services`) |
| **Enables** | C-23 selection click; music per scene (later); UI button sounds; settings persistence of volumes (ADR-0007, C-56) |
| **Blocks** | None |
| **Ordering Note** | Volumes are not persisted yet — settings persistence is part of C-56 (ADR-0007 settings file) |

## Context

### Problem Statement
Sound must survive context switches (menu ↔ game) for future music, be controllable by
bus (Master/Music/SFX sliders already exist), and be callable from gameplay without a global
singleton (forbidden: autoloads, event bus).

### Current State (before)
`features/audio/` and `assets/audio/{music,sfx}` were empty; `SettingsScreen` called
`AudioServer.get_bus_index("Music"/"SFX")` which returned −1.

### Constraints
- No autoload, no event bus; call down / signal up (ADR-0001/0003).
- Gameplay must not depend on audio (missing library or unknown id must never crash).
- Pixel-art project, no 3D/positional audio needed.

### Requirements
- Bus layout with Music and SFX under Master; sliders scale them.
- One place that plays SFX by id; ids map to assets in data (swap a sound without code).
- Concurrent short SFX (rapid clicks) without cutting each other off.

## Decision

1. **Bus layout** — `game/default_bus_layout.tres` (Godot's default path): `Master`, `Music →
   Master`, `SFX → Master`. The settings screen keeps writing bus volumes through `AudioServer`.
2. **`AudioController`** (`features/audio/audio_controller.gd`, `extends Node`) — created by
   `RootContext._ready()` as a persistent child (survives context switches), configured with
   `bind_services(library: SfxLibrary)` and injected into contexts
   (`GameContext.bind_services(game_state, accessibility, audio = null)`). Plays SFX by id on the
   `SFX` bus from a small round-robin pool of `AudioStreamPlayer`s (`SFX_POOL_SIZE = 4`, the
   oldest is reused when full). Unknown id / no library → returns `false` (warning for unknown id).
3. **`SfxLibrary`** (`features/audio/sfx_library.gd`, `Resource`, content in
   `features/audio/data/sfx_library.tres`) — `streams: Dictionary[StringName, AudioStream]`.
   SFX ids are constants on `AudioController` (e.g. `SFX_REGION_SELECT = &"region_select"`).
4. **Who plays what** — contexts call down on gameplay signals (e.g. `GameContext` plays
   `region_select` on `MapController.region_selected`). Controllers/services never touch audio.
5. **Assets** — `assets/audio/sfx/sfx_<category>_<name>.wav` (16-bit mono 44.1 kHz for SFX).
   M1 uses generated placeholders (`sfx_ui_region_select.wav`, synthesized, deterministic).

### Architecture

```
RootContext ──owns──▶ AudioController (Node, persistent) ──▶ AudioStreamPlayer ×4 (bus SFX)
     │ bind_services(..., audio)                ▲ play_sfx(id)
     ▼                                          │
GameContext ── on MapController.region_selected ┘      SfxLibrary (.tres): id → AudioStream
SettingsScreen ──▶ AudioServer.set_bus_volume_db(Master | Music | SFX)
```

### Key Interfaces

```gdscript
class_name AudioController extends Node
const SFX_BUS: StringName = &"SFX"
const MUSIC_BUS: StringName = &"Music"
const SFX_POOL_SIZE: int = 4
const SFX_REGION_SELECT: StringName = &"region_select"
func bind_services(library: SfxLibrary) -> void
func play_sfx(id: StringName) -> bool          # false: no library / unknown id
func get_sfx_players() -> Array[AudioStreamPlayer]   # tests / debug

class_name SfxLibrary extends Resource
@export var streams: Dictionary[StringName, AudioStream]
func get_stream(id: StringName) -> AudioStream   # null if undefined
```

### Implementation Guidelines
- New SFX: add the asset, add the id constant, add the mapping in `sfx_library.tres`.
- Never instantiate `AudioStreamPlayer`s for UI/gameplay SFX outside `AudioController`.
- Music (later) gets its own player on the `Music` bus inside `AudioController`; crossfades
  use `Tween` on `volume_db` (pixel-art "no alpha fade" rule is visual only).

## Alternatives Considered

### Alternative 1: Autoload `Audio` singleton
- **Pros**: callable from anywhere. **Cons**: forbidden pattern (technical preferences);
  hidden dependency. **Rejected.**

### Alternative 2: Each context owns its own players
- **Pros**: no injection. **Cons**: sound cut on context switch (music), duplicated pools.
  **Rejected** — persistence across contexts is the main requirement.

### Alternative 3: Signal hub that audio listens to
- **Cons**: central event bus is forbidden. **Rejected.**

## Consequences

### Positive
- The existing volume sliders now work (Music/SFX buses exist).
- Gameplay stays audio-agnostic; tests can pass `null` audio.
- Swapping a sound is a data change.

### Negative
- `GameContext.bind_services` grows by one optional argument (QQ-01 in `architecture.md`).

### Neutral
- Volumes are session-only until settings persistence (C-56).

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| SFX spam (rapid clicks) clips | Low | Low | 4-player round robin |
| Placeholder sounds ship by accident | Medium | Low | Asset manifest / audio pass before release (C-46 / audio-director) |
| Bus names drift from settings code | Low | Medium | Constants on `AudioController`; test asserts buses exist and the SFX slider scales the bus |

## Performance Implications

| Metric | Expected | Budget |
|--------|----------|--------|
| CPU | Negligible (a few players) | 16.6 ms |
| Memory | < 1 MB of SFX for M1 | 512 MB |

## Migration Plan
Done in C-23: bus layout, `AudioController`, `SfxLibrary`, placeholder click, RootContext /
GameContext wiring, tests. Later: menu/button SFX, music per scene (`scene-flow.md`), volume
persistence (C-56).

## Validation Criteria
- [x] `Music` and `SFX` buses exist and send to `Master`.
- [x] Selecting a region plays `region_select` on the `SFX` bus.
- [x] The SFX slider changes the `SFX` bus volume.
- [x] Unknown id / missing library never crashes.
- [ ] Audible on a real device (manual check on the user's machine).

## GDD Requirements Addressed

| Source | Requirement | How |
|--------|-------------|-----|
| Art bible §4 | Selection "click" as the colour-blind fallback for selection | `region_select` SFX on selection |
| `game-concept.md` MVP | "Ses/müzik (placeholder yeterli)" | Placeholder SFX + bus layout |
| Settings screen (C-07 era) | Master/Music/SFX sliders | Buses now exist |

## Related
- `architecture.md` §2/§3 (Presentation: audio), ADR-0001, ADR-0003, ADR-0007 (settings file).
- Implemented in `game/features/audio/`, `game/default_bus_layout.tres`,
  `game/assets/audio/sfx/sfx_ui_region_select.wav`, tests `game/tests/unit/audio/`.
