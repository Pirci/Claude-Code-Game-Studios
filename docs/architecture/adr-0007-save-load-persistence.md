# ADR-0007: Save/Load Persistence

## Status

Proposed

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
| **Verification Required** | `DirAccess.rename` behaviour when the target exists (POSIX replaces; Windows may fail) — the `.bak` rotation below avoids relying on overwrite; `JSON` number typing (all numbers parse as `float` — ints re-cast on load; exact up to 2^53); `@abstract` (4.5+) on `SaveStore` |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (RootContext owns `GameState` lifecycle), ADR-0003 (DI), ADR-0004 (state segregation) |
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
    "modifiers": [ { "source_id": "boon:bereket", "stat_id": "gold_income", "kind": 0, "value": 1.0, "stacks": 1 } ],  // C-31: Bereket = FLAT +1
    "map": { "current_turn": 4, "chapter_id": 1, "last_erlik_spread_turn": 3, "player_tamga_id": "...", "enemy_tamga_id": "...",
             "regions": { "r1": { "owner": 1, "army_count": 3, "corruption_level": 0, "...": 0 } } }
  }
}
```

- Only **saved game state** is written. Derived/static data (region geometry, adjacency, polygons, names) is **not** saved: it is reconstructed from `ChapterMapDefinition` content by `chapter_id` and only the **mutable fields** of each region are stored.
- Enums are stored as ints with a documented table; ids as strings.
- `modifiers` store `StatModifier` records (ADR-0006), **not** sources; sources are content.
- The pending Kök Böri boon offer is **not** saved: it is derived from `ruh` and the boon list on load (`spirit-system.md` §3.4, TR-spirit-008, C-31).
- `MapState.game_result` (C-32) is **not** saved: the end-of-turn autosave only runs while the result is `ONGOING`; a won/lost scene is handed to the scene flow (`scene-flow.md`, C-35), which owns how scene completion is persisted.

### Components

```
SaveController (RefCounted service, bind_services(store, map_factory))
   ├─ save_campaign()  ← called by MapController.turn_ended (via GameContext wiring)
   ├─ load_campaign() -> GameState | null
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
- **Deterministic output:** `JSON.stringify(data, "\t", true)` (indent + `sort_keys`) so saves diff cleanly; floats are validated with `is_finite` before stringify (JSON cannot hold NaN/INF).
- **Parsing:** `JSON.new().parse()` (gives line + message on error) and `typeof(json.data) == TYPE_DICTIONARY`; never `str_to_var`, `bytes_to_var`, `get_var(true)`, `ResourceLoader`, or `load()` on user files.
- **Validation:** `from_dict` is total — checks types, ranges and known region ids; unknown keys are ignored; any structural error returns `null` with an error code (`CORRUPT`, `VERSION_TOO_NEW`, `MISSING`). Never partially applies.
- **Version policy:** `schema_version` greater than the build's → refuse (`VERSION_TOO_NEW`, do not overwrite). Lower → run migrations in order, then load; the file is rewritten at the next save.
- **Number handling:** JSON numbers are floats; the serializer casts counters back to `int` and rejects non-integral values for int fields.

### Save timing and scope (decision: turn-end autosave, one slot)

- Autosave **once per turn end, after the full end-of-turn pipeline** (income, enemy AI, Erlik spread) has finished and `turn_ended` is emitted. At that point there is no in-flight state: `actions_remaining` is reset, `selected_region_id` is empty and is **not saved**.
- Resource-system open question #6 resolved: gold and production counters are saved as they are at turn end; **no mid-turn saves** in this scope.
- One active campaign slot. The format and `SaveStore` take a `slot` id so multi-slot / manual save can be added without a format change.
- "Continue" in the main menu is enabled iff `read()` + `from_dict()` succeed.
- When a chapter ends (victory), the autosave records it in `chapters_completed` and writes `map: null`, so Continue opens chapter selection rather than a finished map. Defeat leaves the last turn-end autosave untouched (the player may reload it). Neither deletes the file.

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
signal loaded(game_state: GameState)
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
| Float drift in saved modifier values | Values are authored decimals; round-trip test uses exact values; consumers round per GDD |
| Player edits JSON (cheating) | Out of scope for a single-player game; `from_dict` validates ranges so edits cannot crash the game. Revisit before Steam release (`/security-audit`) |

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| `game-concept.md` / TR-concept-002 | Campaign progress persists between sessions | Turn-end autosave + Continue |
| `game-concept.md` / TR-concept-004 | Boons accumulate across scenes within a run | `modifiers` saved in `GameState` |
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
2. Implement `to_dict`/`from_dict` for `GameState`, `MapState`, `RegionData`, `StatModifier`; write the round-trip + corruption + version tests.
3. Wire `SaveController` into `GameContext` (autosave on `turn_ended`) and `MenuContext` (Continue).
4. Persist `AccessibilitySettings` through the same pair.
5. Update ADR-0004 status note (migration plan superseded) and ADR-0006 (`StatModifier` serialized by dict, not `Resource`).

**Rollback**: Persistence is additive; removing it leaves state classes unchanged.

## Validation Criteria

- [ ] Round trip: `from_dict(to_dict(s))` equals `s` for a fully populated fixture.
- [ ] Corrupt JSON, wrong types, unknown region id, negative counts → `LoadResult.Code.CORRUPT`, no crash, no partial state (also NaN/INF).
- [ ] `schema_version` > build → `VERSION_TOO_NEW`; save not overwritten.
- [ ] v1 fixture loads through the migration chain once a v2 exists.
- [ ] Simulated failure at each step of the write sequence (failing `SaveStore` double) leaves a loadable `final`, `.bak` or `.tmp`.
- [ ] Same state serializes to byte-identical text twice (sorted keys).
- [ ] No use of `load()`, `ResourceLoader`, `str_to_var`, `bytes_to_var`, `get_var(true)` on `user://` content (grep check).

## Related Decisions

- ADR-0004 (partially superseded), ADR-0006 (modifiers), ADR-0001/0003.
- `design/gdd/resource-system.md` open question #6; `game-concept.md` TR-concept-002.
- Follow-ups: C-17 (architecture review), C-39 (ruh/boon fields), security audit before release.
