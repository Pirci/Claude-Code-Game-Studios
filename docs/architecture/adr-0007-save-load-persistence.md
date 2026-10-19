# ADR-0007: Save/Load Persistence

## Status

Accepted (2026-10-19 — `/architecture-review` C-17, [report](architecture-review-2026-10-19.md))

> **Amendment 2026-10-19 (C-53, cross-review W-D/W-F):** the `game` block saves `ruh` and
> `boons` (choices); `modifiers` are derived on load (ADR-0006 amended) and not saved.
> Autosave listens to `turn_ended`, which is emitted only after the end check and only while
> `ONGOING`; victory persistence is owned by `scene-flow.md` (C-35).
>
> **Amendment 2026-10-19 (C-35, *proposed for C-56 / C-62* — status stays Accepted):** `design/gdd/scene-flow.md`
> §3.4 asks for: (1) a **scene-entry save S2** written once when the Kök Böri objective panel is dismissed
> (turn 1, before any action) into the `campaign` slot **and** a `scene_entry` slot (same document format;
> the `slot` id already exists) — it holds the carry-over snapshot (`ruh`, `boons`, `chapters_completed`) so
> "Retry scene" works even after Continue; overwritten at every scene entry; (2) **scene-complete save S3** =
> after the last mandatory boon pick, before the outro: `chapters_completed ∪ {c}`, `current_chapter =
> min(c+1, K)` (the next scene; stays `c` when `c == K`), `map: null`, `gold: 0`; (3) load validation:
> `chapters_completed` must be a prefix `{1…m}`, `m ≤ K` (else `CORRUPT`), and a new `LoadResult.Code.CONTENT_MISSING`
> when the save references a scene beyond the build's campaign length K (Continue disabled, file untouched);
> (4) defeat and "leave scene" write nothing. Open: whether the snapshot is a second slot (recommended) or a
> schema field — decided in the scene-flow ADR (C-62).

> **Implementation note 2026-10-19 (C-56):** built in `game/features/save/`. Two as-built refinements:
> (1) `SaveStore.read(slot) -> String` became `read_candidates(slot) -> PackedStringArray` (final → `.bak` →
> `.tmp`) so `SaveController` can validate each candidate and fall back — the store stays content-agnostic;
> (2) `LoadResult.Code.CONTENT_MISSING` (C-35 amendment) is returned when `map_factory(chapter_id)` yields no
> content. `chapters_completed` prefix validation is in; S2/S3 slots wait for the scene flow (C-40/C-62).
> Settings persistence (step 4) — done in C-65: `SettingsSnapshot` + pure `SettingsSerializer` (own `schema_version`),
> slot `settings` of the same store (`user://saves/settings.json`, not `user://settings.json`), written on every
> settings change, applied by `RootContext` before any UI; invalid or newer file → defaults. A newer-version save is never overwritten
> (`save_failed(&"newer_save_present")`).

## Date

2026-10-18

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7 |
| **Domain** | Core / File I/O |
| **Knowledge Risk** | MEDIUM — `FileAccess.store_*` return `bool` since 4.4 (breaking-changes.md); everything else used (`JSON`, `DirAccess`, `FileAccess`) is stable pre-4.4 API |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `breaking-changes.md`, `current-best-practices.md`, `deprecated-apis.md` |
| **Post-Cutoff APIs Used** | `FileAccess.store_string()` returning `bool` (4.4+) — checked; `@abstract` (4.5+) |
| **Verification Required** | Verified on 4.7.1 Linux (C-17, 2026-10-19): rename onto an existing file overwrites on POSIX (Windows/macOS **unverified** — the `.bak` rotation below does not rely on it); JSON numbers parse as `float` (exact to 2^53), `1e999` parses to INF without error, `int(INF/NAN/1e30)` = INT64_MIN; a UTF-8 BOM breaks `parse()`; parsed containers are untyped and keys are `String`; `@abstract class`/`@abstract func` (no body) work, `SaveStore.new()` is a parse error. Remaining: Windows rename, `user://` path per OS |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (RootContext owns `GameState` lifecycle and the Continue transition), ADR-0003 (DI), ADR-0004 (state segregation), ADR-0006 (modifiers are rebuilt from saved choices) |
| **Enables** | "Continue" menu entry; resource-system open question #6; any cross-session feature |
| **Blocks** | Save/load implementation stories; settings persistence |
| **Ordering Note** | **Partially supersedes ADR-0004**: its "migrate state to `Resource` for save/load" plan is replaced by this ADR (state stays `RefCounted`). ADR-0006 `ModifierSource` remains a `Resource` (read-only content, never saved). |

## Context

### Problem Statement

`TR-concept-002` requires campaign progress to persist between sessions.
Nothing is persisted today: `GameState`, `MapState`, `RegionData` are
`RefCounted` data classes and `AccessibilitySettings` (and other settings) reset
on every launch. ADR-0004 deferred the decision and sketched migrating state to
`Resource` + `ResourceSaver`. Two things argue against that plan:

1. **Load safety.** A `.tres`/`.res` file can reference scripts and sub-resources;
   loading an untrusted (shared, modded, tampered) save through `ResourceLoader`
   can instantiate arbitrary script classes — code execution from a data file.
   The game targets Steam, where shared/modded saves are normal.
2. **Versioning.** The state schema will change many times (modifiers, ruh,
   corruption, production counters are all pending). `.tres` property drift gives
   silent `null`s; we need explicit, testable migrations.

`resource-system.md` open question #6 also asks how mid-scene gold and production
counters are stored.

### Constraints

- ADR-0004: state objects stay data + pure getters; serialization logic must live elsewhere.
- No autoloads, no event bus (technical preferences).
- Determinism and testability: round-trip must be exactly reproducible; GDUnit4 unit tests do no real file I/O (testing standards) → path/IO behind an injectable interface.
- PC only; single input method; no cloud saves in scope (Steam Cloud may sync the `user://` files later, which favours plain, portable, human-inspectable files).
- Turn-based game: consistent state exists at turn boundaries.

### Requirements

- Campaign progress (current chapter, completed chapters, gold, modifiers/boons, ruh, map state with regions) persists across sessions.
- Settings (accessibility, language, audio) persist independently of campaign state.
- Loading a hostile or corrupt file must never execute code and never crash; failure falls back safely.
- Schema versioning with forward migrations; old saves keep loading.
- A crash or power loss during a write must not destroy the previous save.

## Decision

Keep state classes `RefCounted` and add a **pure `SaveSerializer`** plus a thin
**`SaveStore`** (file I/O) and a **`SaveController`** (when to save/load).
Persist as **versioned JSON text**.

### Format

```jsonc
{
  "schema_version": 1,
  "saved_at": "2026-10-18T12:00:00Z",       // informational only, never read by logic
  "game": {                                  // GameState
    "current_chapter": 1, "gold": 6,
    "chapters_completed": [],
    "ruh": 10, "boons": ["bereket"],         // choices; modifiers are rebuilt from boons on load (C-53)
    "map": { "current_turn": 4, "chapter_id": 1, "last_erlik_spread_turn": 3,   // tamga ids are content — not saved (C-17)
             "regions": { "r1": { "owner": 1, "army_count": 3, "corruption_level": 0, "...": 0 } } }
  }
}
```

- Only **saved game state** is written. Derived/static data (region geometry, adjacency, polygons, names) is **not** saved: it is reconstructed from `ChapterMapDefinition` content by `chapter_id` and only the **mutable fields** of each region are stored.
- Enums are stored as ints with a documented table; ids as strings.
- `modifiers` are **not** saved: they are derived from saved choices (`boons`, later council state) on load (ADR-0006 amendment, C-53).
- The pending Kök Böri boon offer is **not** saved: it is derived from `ruh` and the boon list on load (`spirit-system.md` §3.4, TR-spirit-008, C-31).
- `MapState.game_result` (C-32) is **not** saved: the end-of-turn autosave only runs while the result is `ONGOING`; a won/lost scene is handed to the scene flow (`scene-flow.md`, C-35), which owns how scene completion is persisted.

### Components

```
SaveController (RefCounted service OWNED BY RootContext — C-17 D4; bind_services(store, map_factory))
   ├─ save_campaign(game_state)  ← GameContext calls it on MapController.turn_ended (controller injected by RootContext)
   ├─ load_campaign() -> LoadResult  ← RootContext on MenuContext.continue_requested
   │
SaveSerializer (pure, static, no shared state):
                                to_dict(GameState) -> Dictionary
                                from_dict(Dictionary, map_factory) -> LoadResult  (state XOR error)
                                migrate(Dictionary) -> Dictionary                 (v1→v2→… chain)
SaveStore (I/O; @abstract base + FileSaveStore impl + in-memory test double):
   write(slot: StringName, text: String) -> bool     # tmp + .bak rotation, see Atomicity
   read(slot: StringName) -> String                  # "" if nothing loadable
```

- Save path: `user://saves/campaign.json` (+ `.bak` previous good copy). Settings: `user://settings.json` (separate file, separate schema version, written on change).
- **Atomicity (no reliance on rename-overwrite):** `DirAccess.make_dir_recursive_absolute("user://saves")` first; then in the **same directory** (same volume): (1) `FileAccess.open(tmp, WRITE)` — on `null`, report `FileAccess.get_open_error()`; (2) `store_string()` must return `true`; (3) flush and **close** the file (`close()` / drop the reference) **before** any rename; (4) if `final` exists: remove old `.bak`, rename `final → .bak`; (5) rename `tmp → final`. **Every** `remove`/`rename` `Error` is checked; one retry on failure (antivirus/OneDrive locks). Disk-full or any failed step → `save_failed`, previous save untouched.
- **Load order:** `final` → if missing/invalid, `.bak` → (a crash between steps 4 and 5 leaves `final` missing with `.bak` and `.tmp` present: `.tmp` is tried last, only if it parses and validates). Stale `.tmp` is deleted after a successful save.
- **Deterministic output:** `JSON.stringify(data, "\t", true, true)` (indent + `sort_keys` + `full_precision`) so saves diff cleanly and floats round-trip (default precision writes `0.333333333333333`); floats are validated with `is_finite` before stringify (JSON cannot hold NaN/INF).
- **Parsing:** strip a leading UTF-8 BOM (`\uFEFF`, e.g. after a Notepad edit) → `JSON.new().parse()` (gives line + message on error) and `typeof(json.data) == TYPE_DICTIONARY`; never `str_to_var`, `bytes_to_var`, `get_var(true)`, `ResourceLoader`, or `load()` on user files.
- **Post-parse validation (C-17):** every number destined for an `int` field must pass `is_finite(v) and floor(v) == v` and its GDD range **before** `int(v)` (`int(INF)` = INT64_MIN); out-of-range → `LoadResult.Code.CORRUPT` → `.bak`. Parsed arrays/dictionaries are untyped with `String` keys: rebuild typed fields with `assign()` / element loops and convert ids with `StringName(k)`.
- **Validation:** `from_dict` is total — checks types, ranges and known region ids; unknown keys are ignored; any structural error returns a `LoadResult` with a non-OK code (`CORRUPT`, `VERSION_TOO_NEW`, `MISSING`) and `state = null`. Never partially applies. Consistency checks: `game.current_chapter == map.chapter_id` when `map` is present; `map: null` (written after a chapter victory) is valid and yields a `GameState` with `map_state = null` → Continue opens chapter selection.
- **Version policy:** `schema_version` greater than the build's → refuse (`VERSION_TOO_NEW`, do not overwrite). Lower → run migrations in order, then load; the file is rewritten at the next save.
- **Number handling:** JSON numbers are floats; the serializer casts counters back to `int` and rejects non-integral values for int fields.

### Save timing and scope (decision: turn-end autosave, one slot)

- Autosave **once per turn end, after the full end-of-turn pipeline** (enemy AI, Erlik spread, income, turn++, end check) has finished and `turn_ended` is emitted — `turn_ended` fires only after the end check and only while the result is `ONGOING` (`region-map-system.md` §3.4, C-53). At that point there is no in-flight state: `actions_remaining` is reset, `selected_region_id` is empty and is **not saved**.
- Resource-system open question #6 resolved: gold is saved as it is at turn end; production counters are always 0 at that point (reset in step 4) and are initialised to 0 on load; **no mid-turn saves** in this scope.
- One active campaign slot. The format and `SaveStore` take a `slot` id so multi-slot / manual save can be added without a format change.
- "Continue" in the main menu is enabled iff `read()` + `from_dict()` succeed. Flow (C-17 D4): `MenuContext` emits `continue_requested` → `RootContext` (owner of `GameState` and `SaveController`) calls `load_campaign()`; on `OK` it adopts the loaded `GameState` and switches to the game context, otherwise it shows the error and stays in the menu.
- When a chapter ends (victory) there is no turn end (mid-turn win latch, `region-map-system.md` §3.7). The **scene flow** (`scene-flow.md`, C-35) persists it after the mandatory boon picks: it records `chapters_completed` and writes `map: null`, so Continue opens chapter selection rather than a finished map. Defeat leaves the last turn-end autosave untouched (the player may reload it). Neither deletes the file.

### Settings persistence

`AccessibilitySettings` (and future language/audio settings) use the same
serializer/store pair with their own file and `schema_version`; they are written
immediately on change and loaded at `RootContext` startup before any UI is built.

### Key Interfaces

```gdscript
class_name LoadResult extends RefCounted
enum Code { OK, CORRUPT, VERSION_TOO_NEW, MISSING }   # not "Error": avoids shadowing the global Error
var code: Code = Code.OK
var state: GameState = null          # non-null iff code == OK
var detail: String = ""              # human-readable, for logs

class_name SaveSerializer extends RefCounted
const SCHEMA_VERSION: int = 1
## Pure: no static vars, no I/O. map_factory signature: (chapter_id: int) -> MapState;
## validated with is_valid() before use.
static func to_dict(game_state: GameState) -> Dictionary
static func from_dict(data: Dictionary, map_factory: Callable) -> LoadResult
static func migrate(data: Dictionary) -> Dictionary

@abstract class_name SaveStore extends RefCounted   # 4.5+; tests subclass it
@abstract func write(slot: StringName, text: String) -> bool
@abstract func read(slot: StringName) -> String

class_name SaveController extends RefCounted        # service must stay referenced by its owner
signal save_failed(reason: StringName)
func bind_services(store: SaveStore, map_factory: Callable) -> void
func save_campaign(game_state: GameState) -> bool
func load_campaign() -> LoadResult
func has_campaign() -> bool
```

## Alternatives Considered

### Alternative 1: State as `Resource` + `ResourceSaver` (ADR-0004's plan)

- **Description**: State classes extend `Resource`, `@export` fields, save `.tres`.
- **Pros**: Least code; `duplicate_deep()` for slot copies.
- **Cons**: Loading executes whatever scripts the file references (unsafe for shared/modded saves); silent drift on schema changes; `.tres` text diffs are noisy; couples saved format to class/property names.
- **Rejection Reason**: Load-safety and versioning; ADR-0004 explicitly allowed revisiting.

### Alternative 2: Binary `store_var` / `ConfigFile`

- **Description**: `FileAccess.store_var(dict)` or `ConfigFile`.
- **Pros**: Compact; built in.
- **Cons**: Safe only if every read uses `allow_objects=false` (a default-dependent rule that is easy to regress); opaque to humans and diffs; no natural schema/version story; ConfigFile flattens nested state awkwardly.
- **Rejection Reason**: Weaker debuggability and versioning; JSON gives the same safety by construction.

### Alternative 3: Snapshot the whole `MapState` including geometry

- **Description**: Serialize every field of every `RegionData`.
- **Pros**: Simplest serializer.
- **Cons**: Saves duplicate static content; content updates (map fixes) would not apply to existing saves; larger files.
- **Rejection Reason**: Save only mutable state; rebuild static data from content.

## Consequences

### Positive

- Hostile/corrupt saves cannot execute code; errors are explicit and recoverable.
- Schema evolution is explicit and unit-tested (migration chain).
- State classes stay pure (ADR-0004 intact); serializer and store are injectable → no file I/O in unit tests.
- Content fixes reach existing saves because static data is not persisted.

### Negative

- Hand-written `to_dict`/`from_dict` per state class (new field ⇒ serializer + migration + test update). Mitigated by a round-trip test over a fully-populated fixture that fails when a new field is not covered.
- JSON number typing needs explicit casts.
- Supersedes part of ADR-0004 (documentation churn).

### Risks

| Risk | Mitigation |
|------|-----------|
| New state field forgotten in serializer | Round-trip test with reflection-checked fixture: compare script variables of the state (`get_property_list()` filtered to `PROPERTY_USAGE_SCRIPT_VARIABLE`) vs. serialized keys; fails on uncovered fields |
| Rename semantics differ per OS / file locks | `.bak` rotation never relies on overwrite; every Error checked; one retry; load tries `final → .bak → .tmp` |
| Steam Cloud sync conflicts | Out of scope now; single file + `.bak`, `saved_at` kept for a future conflict policy |
| Disk full / write failure | `save_failed` signal, previous save intact, non-blocking UI warning |
| Save written while state is inconsistent | Save only from the turn-end hook after the pipeline completes; never from UI handlers |
| Float fields lose precision (e.g. future settings volume) | `JSON.stringify(..., full_precision = true)`; round-trip test with non-terminating decimals |
| Player edits JSON (cheating) | Out of scope for a single-player game; `from_dict` validates ranges so edits cannot crash the game. Revisit before Steam release (`/security-audit`) |

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| `game-concept.md` / TR-concept-002 | Campaign progress persists between sessions | Turn-end autosave + Continue |
| `game-concept.md` / TR-concept-004 | Boons accumulate across scenes within a run | `boons` saved in `GameState`; modifiers rebuilt on load |
| `resource-system.md` Open Q #6 | Where mid-scene gold / production counters live | Saved at turn end only; no mid-turn saves |
| `spirit-system.md` §3.3–3.4 | Persistent `ruh` and boon list across scenes | Fields included in `game` block (added with C-39) |
| `region-map-system.md` | Per-region owner/army persisted | Mutable region fields saved; geometry rebuilt from content |

## Performance Implications

- **CPU**: One JSON stringify of a few KB per turn end — well under 1 ms.
- **Memory**: Negligible (transient dictionary + string).
- **Load Time**: One-time parse at Continue; negligible.
- **Network**: N/A.

## Migration Plan

1. Add `game/features/save/` (`save_serializer.gd`, `save_store.gd`, `file_save_store.gd`, `save_controller.gd`) with unit tests and an in-memory `SaveStore` double.
2. Implement `to_dict`/`from_dict` for `GameState` (incl. `ruh`, `boons`), `MapState`, `RegionData`; the serializer restores `boons` only — `ModifierController.rebuild()` (ADR-0006) recreates the modifier records during `GameContext` setup; write the round-trip + corruption + version tests.
3. `RootContext` creates and owns `SaveController`; injects it into `GameContext` (autosave on `turn_ended` — requires C-51's corrected `turn_ended` order) and handles `MenuContext.continue_requested` (Continue).
4. Persist `AccessibilitySettings` through the same pair.
5. Update ADR-0004 status note (migration plan superseded). (ADR-0006 already amended: modifiers are derived, not serialized — C-53.)

**Rollback**: Persistence is additive; removing it leaves state classes unchanged.

## Validation Criteria

Status after C-56 (2026-10-19) — `tests/unit/save/`, `tests/integration/save/`, `tests/unit/contexts/save_flow_test.gd`:

- [x] Round trip: `from_dict(to_dict(s))` equals `s` for a fully populated fixture; a reflection test fails when a new state field is neither saved nor listed as derived/content.
- [x] Corrupt JSON, wrong types, unknown/missing region id, negative counts, out-of-range enums, owned region with 0 army → `LoadResult.Code.CORRUPT`, no crash, no partial state (also `1e999`).
- [x] `schema_version` > build → `VERSION_TOO_NEW`; save not overwritten.
- [ ] v1 fixture loads through the migration chain once a v2 exists (no v2 yet).
- [x] Simulated failure at each step of the write sequence (failing `FileSaveStore` subclass, real files) leaves a loadable `final`, `.bak` or `.tmp`; a corrupt `final` loads from `.bak`.
- [x] Same state serializes to byte-identical text twice (sorted keys).
- [x] No use of `load()`, `ResourceLoader`, `str_to_var`, `bytes_to_var`, `get_var(` in `features/save/` (grep step in `tools/ci/run-tests.sh`).
- [x] `map: null` loads as "chapter selection"; `current_chapter != map.chapter_id` → `CORRUPT`.
- [x] `1e999` → `CORRUPT` (no INT64_MIN reaches state); a BOM-prefixed **valid** file loads (the BOM is stripped — wording clarified).
- [ ] Loading the same save twice into a fresh `GameContext` yields identical modifiers — needs the boon catalog (C-39) to call `ModifierController.rebuild()` on load.

## Related Decisions

- ADR-0004 (partially superseded), ADR-0006 (modifiers), ADR-0001/0003.
- `design/gdd/resource-system.md` open question #6; `game-concept.md` TR-concept-002.
- Follow-ups: C-17 ✅ (architecture review 2026-10-19), C-39 (ruh/boon fields), C-56 (implementation, after C-51), security audit before release.
- Engine note (verified 4.7.1): `@abstract class_name SaveStore extends RefCounted` on one line and `@abstract func …` **without a body** are the valid syntax.
