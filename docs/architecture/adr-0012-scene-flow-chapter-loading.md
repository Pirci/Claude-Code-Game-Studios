# ADR-0012: Scene Flow & Chapter Loading

## Status

Accepted (2026-10-19 — C-62; night-mode decision, recommended option accepted per user
instruction; re-validate at the next `/architecture-review`. Implements the architecture side of
`design/gdd/scene-flow.md` (C-35, design-review APPROVED); code lands in C-40.)

## Date

2026-10-19

## Last Verified

2026-10-19 (against the as-built `RootContext`, `MenuContext`, `GameContext`, `SaveController`
(C-56) and `MapController` result latch (C-51/C-63) on Godot 4.7.1)

## Decision Makers

Technical direction (night-mode autonomous run).

## Summary

The campaign flow (main menu → scene intro → Kök Böri mark → play → victory beat → mandatory boon
picks → save → outro → chapter select, or defeat → retry/menu) is a **pure state machine**
(`SceneFlow`) owned by `RootContext`, which executes the actions it returns (switch context,
build/restore state, save, rebuild modifiers). Content is one `CampaignDefinition` resource
listing `SceneDefinition`s; each scene names its map by **path string** (`map_path`), loaded
with `load()` only when the scene starts — the single chapter-loading convention. Full-screen
narrative pages and the chapter select are their own light contexts; everything shown over the
map (objective panel, victory card, boon picks, defeat screen) is a modal in `GameContext`'s
`ModalQueue` (ADR-0011).

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7 |
| **Domain** | Core / Scene management |
| **Knowledge Risk** | LOW–MEDIUM — `ResourceLoader.load_threaded_request/get` (deadlock/race fixes in 4.7 changelog) for illustrations; everything else is plain GDScript and existing context switching |
| **References Consulted** | `docs/engine-reference/godot/current-best-practices.md` (threaded loading, 4.7), ADR-0001, ADR-0007, ADR-0011 |
| **Post-Cutoff APIs Used** | None new (threaded loading predates 4.4) |
| **Verification Required** | Threaded illustration load + cancel when skipping pages fast (C-40 test) |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (contexts, `load()` on transition), ADR-0003 (DI), ADR-0006 (`ModifierController.rebuild()`), ADR-0007 (+ C-35 amendment: S1/S2/S3, `scene_entry` slot), ADR-0009 (text), ADR-0011 (`ModalQueue`, passive views) |
| **Enables** | C-40 scene flow code, C-41 tutorial (hooks `scene_started`), C-36 (scene content), C-39 (mandatory picks at victory), M2 chapters |
| **Blocks** | C-40 |
| **Ordering Note** | Settles the C-35 open items: class names, `scene_entry` = second slot, narrative screens = own context |

## Context

### Problem Statement
`scene-flow.md` defines 11 flow states and 23 transitions, three save points, and content types
(`CampaignDefinition`, `SceneDefinition`, `NarrativePage`). Architecture must decide who owns the
flow, where each screen lives, how chapter content is found and loaded, and how saves are written
at the right moments — without a global flow singleton (forbidden) and without loading every
chapter at startup.

### Current State (before)
`RootContext` switches between `MenuContext` and `GameContext`; New Campaign starts chapter 1 with
`GameContext.CHAPTER_MAP_PATH_FORMAT % current_chapter` (C-57); Continue loads the campaign slot
(C-56); there are no narrative screens, no chapter select, no victory/defeat flow beyond the HUD label.

### Constraints
- No autoload / event bus; call down, signal up (technical preferences, ADR-0001).
- `RootContext` never preloads large scenes (ADR-0001); illustrations are large → threaded load.
- Saves only at S1/S2/S3 (scene-flow §3.4); defeat and leaving write nothing.
- Flow rules must be unit-testable without nodes.

### Requirements
- One owner of "which state are we in"; all 23 transitions covered by tests.
- Chapter content found by `chapter_id` through one convention; `K = number of scenes`.
- Victory order: all state committed → mandatory picks → S3 → outro (scene-flow §3.6, spirit §3.4).
- Retry restores the scene-entry snapshot even after Continue.

## Decision

1. **`SceneFlow`** (`features/campaign/scene_flow.gd`, `RefCounted`, pure): `enum State` (the
   states of scene-flow §3.3, with `KOK_BORI_MARK` split into its pages (A) and panel (B) parts) and `transition(state, event, facts) -> FlowStep` where `FlowStep`
   holds `next_state`, `chapter_id` and an ordered list of **action ids** (`&"new_state"`,
   `&"build_map"`, `&"capture_entry"`, `&"save_entry"`, `&"rebuild_modifiers"`, `&"commit_scene"`,
   `&"save_completed"`, `&"restore_entry"`, …). `facts` carries the inputs the guards need
   (save present, `LoadResult` code, map present, boons pending `k`, `c == K`). Unknown
   (state, event) pairs return the current state with no actions (and a log line) — scene-flow
   "ignored" rule.
2. **`RootContext` executes** the actions in order (it already owns `GameState`, `SaveController`,
   `AccessibilitySettings`, `AudioController`) and switches contexts. It re-emits the flow signals
   up for audio/tutorial: `scene_started(chapter_id, first_entry)`, `scene_completed(chapter_id)`,
   `scene_failed(chapter_id)`, `campaign_completed`.
3. **Screens:**
   - `MAIN_MENU` → `MenuContext` (exists).
   - `INTRO_NARRATIVE`, `KOK_BORI_MARK` A, `OUTRO_NARRATIVE`, `STORY_REPLAY`, `CAMPAIGN_END` →
     **`NarrativeContext`** (`contexts/narrative_context/`): pages from `NarrativePage` data,
     illustrations via `ResourceLoader.load_threaded_request()` one page ahead; emits
     `pages_finished` / `skip_requested` / `escape_requested`.
   - `CHAPTER_SELECT` → **`ChapterSelectContext`** (`contexts/chapter_select_context/`).
   - `KOK_BORI_MARK` B (objective panel), `VICTORY_BEAT` (result card), `BOON_PICKS`
     (`BoonOfferModal`, mandatory), `DEFEAT` → modals in **`GameContext`'s `ModalQueue`** (the map
     stays visible; input/focus rules of ADR-0011). `GameContext` signals up `objective_dismissed`,
     `victory_acknowledged`, `boon_picks_finished`, `retry_requested`, `menu_requested`.
4. **Content and chapter loading:** `CampaignDefinition` (`features/campaign/data/campaign.tres`,
   small, `load()`ed by `RootContext` at startup) holds `scenes: Array[SceneDefinition]`
   (`chapter_id` 1…K, contiguous) and `end_pages`. `SceneDefinition.map_path: String` names the
   `ChapterMapDefinition`; it is `load()`ed **only** when the scene's map is built (T11/T22) or a
   save is loaded (ADR-0007 `map_factory`). `GameContext.CHAPTER_MAP_PATH_FORMAT` (C-57) is
   replaced by `CampaignDefinition.scene(chapter_id).map_path`; a save naming a `chapter_id > K`
   yields `LoadResult.Code.CONTENT_MISSING` (C-56). A content test asserts every scene's
   `title_key == ChapterMapDefinition.chapter_name_key` and every `map_path` exists.
5. **Saves (ADR-0007 + C-35 amendment):** S1 stays in `GameContext` (`turn_ended`). **S2** is the
   `save_entry` action at T12: `SaveController.save_campaign(state)` **and**
   `save_scene_entry(state)` — `scene_entry` is a **second slot** with the same document format
   (chosen over a schema field: the campaign document stays one shape; Retry reads one slot).
   **S3** is the `save_completed` action at COMMIT (T18): `chapters_completed ∪ {c}`,
   `current_chapter = min(c + 1, K)`, `map = null`, `gold = 0`. Defeat (T14), leaving (T15/T23)
   and OS close write nothing.
6. **Continue (T3/T4):** `RootContext` loads the campaign slot; `map ≠ null` → `GameContext` at the
   saved turn (no intro, no objective panel; a pending boon offer opens as at turn start);
   `map == null` → `ChapterSelectContext`. Modifiers are rebuilt from `boons` (ADR-0006) on every
   path that adopts a `GameState` (T3, T4, T11, T22).
7. **Retry (T22):** read `scene_entry` (fallback: in-memory snapshot captured at T11); restore
   `ruh`, `boons`, `chapters_completed`; rebuild the map from content; `rebuild_modifiers`; go to
   the objective panel (B) — narrative pages are not replayed.

### Architecture

```
RootContext ── owns ── SceneFlow (pure) ── transition(state, event, facts) → FlowStep(next, actions)
   │   executes actions: new_state / build_map / capture_entry / save_entry / rebuild_modifiers /
   │                     commit_scene / save_completed / restore_entry / switch context
   │   owns: GameState, SaveController (campaign + scene_entry slots), CampaignDefinition (load once)
   ├── MenuContext ................ MAIN_MENU
   ├── NarrativeContext ........... INTRO / KOK_BORI_MARK A / OUTRO / STORY_REPLAY / CAMPAIGN_END
   ├── ChapterSelectContext ....... CHAPTER_SELECT
   └── GameContext ................ PLAYING (+ ModalQueue: objective B, victory card, boon picks, defeat)
            signals up: objective_dismissed, victory_acknowledged, boon_picks_finished,
                        retry_requested, menu_requested, (turn_ended → S1 inside)
SceneDefinition.map_path ──load() on T11 / T22 / Continue──▶ ChapterMapDefinition.create_map_state()
```

### Key Interfaces

```gdscript
class_name SceneFlow extends RefCounted          # features/campaign/
enum State { MAIN_MENU, CHAPTER_SELECT, INTRO_NARRATIVE, KOK_BORI_MARK_PAGES, KOK_BORI_MARK_PANEL,
		PLAYING, VICTORY_BEAT, BOON_PICKS, OUTRO_NARRATIVE, DEFEAT, CAMPAIGN_END, STORY_REPLAY }
class FlowStep extends RefCounted:
	var next_state: State
	var chapter_id: int
	var actions: Array[StringName]
func transition(state: State, event: StringName, facts: Dictionary) -> FlowStep

class_name CampaignDefinition extends Resource   # content
@export var scenes: Array[SceneDefinition]
@export var end_pages: Array[NarrativePage]
func scene(chapter_id: int) -> SceneDefinition    # null if outside 1…K
func scene_count() -> int                         # K

class_name SceneDefinition extends Resource      # fields per scene-flow §3.10 (map_path: String)
class_name NarrativePage extends Resource        # illustration_path, text_key, title_key, sfx_id

# SaveController (C-56) gains:
func save_scene_entry(game_state: GameState) -> bool
func load_scene_entry() -> LoadResult
```

### Implementation Guidelines
- Keep every guard in `SceneFlow`; `RootContext` must not branch on flow state except to run actions.
- Action ids are constants on `SceneFlow`; a test walks all 23 transitions of scene-flow §3.3.
- Narrative screens never `preload` illustrations; cancel pending threaded loads on skip.
- The map is built in exactly two places (T11 new entry, T22 retry) and adopted in one (Continue).

## Alternatives Considered

### Alternative 1: A `CampaignContext` node between Root and Game owning the flow
- **Pros**: RootContext stays tiny. **Cons**: another persistent layer that must own GameState,
  saves and audio hand-offs already owned by RootContext (ADR-0001/C-17 D4) — split ownership.
  **Rejected.**

### Alternative 2: Flow logic spread over the contexts (each decides its successor)
- **Pros**: no new class. **Cons**: 23 transitions scattered, untestable as a whole, save timing
  easy to break. **Rejected.**

### Alternative 3: Chapter path by naming convention only (`chapter_%d_map.tres`)
- **Pros**: zero content. **Cons**: no place for per-scene presentation data, K unknown, renaming
  maps breaks saves. **Rejected** for `SceneDefinition.map_path`.

### Alternative 4: `scene_entry` snapshot as a field inside the campaign document
- **Pros**: one file. **Cons**: two shapes for one document, every save carries the snapshot,
  Retry and Continue read different parts. **Rejected** for a second slot (C-35 recommendation).

## Consequences

### Positive
- The whole flow is unit-testable as data; save points are explicit actions.
- Chapters are content: adding a scene = adding a `SceneDefinition` (Modüler İnşa).
- Only the active scene's map and the current page's illustration are in memory.

### Negative
- `RootContext` grows an action executor (keep it a flat `match` over action ids).
- Two more contexts to build (narrative, chapter select).

### Neutral
- K = 1 for the M1 demo: chapter select is skipped after victory (scene-flow §3.9).

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| Flow state and context on screen diverge | Low | Medium | RootContext switches context only from `FlowStep.next_state` |
| Save written at a wrong moment | Low | High | Saves only via `save_entry` / `save_completed` actions + S1; transition tests assert actions |
| Threaded load races on fast skipping | Medium | Low | One-page lookahead, cancel on skip; 4.7 loader fixes |
| `scene_entry` slot missing/mismatched on Retry | Low | Low | In-memory snapshot fallback + warning (scene-flow §3.4) |

## Performance Implications

| Metric | Expected | Budget |
|--------|----------|--------|
| Context switch | < 1 s (map `load()` + build, ≤ 15 regions) | ADR-0001 1 s |
| Memory | One chapter map + one illustration (~0.4 MB each at 640×360) | 512 MB |

## Migration Plan
C-40: `features/campaign/` (`SceneFlow`, `CampaignDefinition`, `SceneDefinition`, `NarrativePage`,
`SceneFlowConfig`), `NarrativeContext`, `ChapterSelectContext`, GameContext modals (objective,
victory card, defeat; boon picks from C-39), `SaveController.save_scene_entry/load_scene_entry`,
RootContext action executor; replace `CHAPTER_MAP_PATH_FORMAT` by `map_path`. C-36 provides the
Prolog `SceneDefinition` content; C-54 the text keys.

## Validation Criteria
- [ ] All 23 transitions of scene-flow §3.3 covered by `SceneFlow` unit tests (next state + actions).
- [ ] Victory: `game_won` → card → k mandatory picks → S3 written once → outro; no S3 on defeat.
- [ ] S2 written once at objective dismissal into `campaign` and `scene_entry`; Retry after Continue restores the entry snapshot.
- [ ] Continue with `map ≠ null` opens the saved turn without intro; with `map == null` opens chapter select.
- [ ] Content test: every `SceneDefinition.map_path` loads; `title_key` matches the map's `chapter_name_key`; `chapter_id` contiguous 1…K.
- [ ] Only one chapter map loaded at a time (no `preload` of maps/illustrations by contexts — grep).

## GDD Requirements Addressed

| Source | Requirement | How |
|--------|-------------|-----|
| TR-concept-007 / scene-flow §3.3, §3.6 | Scene-end sequence on victory | Decisions 1, 3, 5 |
| TR-map-002 | Chapter content by `chapter_id`, `load()` | Decision 4 |
| TR-concept-001 | Menu → campaign → scene flow, Continue | Decisions 2, 6 |
| scene-flow §3.4 | Save points S1–S3, Retry snapshot | Decisions 5, 7 |

## Related
- ADR-0001, ADR-0006, ADR-0007 (C-35 amendment), ADR-0011; `design/gdd/scene-flow.md`.
- Implementation: C-40 (flow code), C-36 (Prolog content), C-39 (boon picks), C-54 (texts).
