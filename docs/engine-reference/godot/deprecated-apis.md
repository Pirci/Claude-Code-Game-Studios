# Godot — Deprecated APIs

Last verified: 2026-10-19 | Engine: Godot 4.7

If an agent suggests any API in the "Deprecated" column, it MUST be replaced
with the "Use Instead" column.

## Nodes & Classes

| Deprecated | Use Instead | Since | Notes |
|------------|-------------|-------|-------|
| `TileMap` | `TileMapLayer` | 4.3 | One node per layer instead of multi-layer node |
| `VisibilityNotifier2D` | `VisibleOnScreenNotifier2D` | 4.0 | Renamed for clarity |
| `VisibilityNotifier3D` | `VisibleOnScreenNotifier3D` | 4.0 | Renamed for clarity |
| `YSort` | `Node2D.y_sort_enabled` | 4.0 | Property on Node2D, not a separate node |
| `Navigation2D` / `Navigation3D` | `NavigationServer2D` / `NavigationServer3D` | 4.0 | Server-based API |
| `EditorSceneFormatImporterFBX` | `EditorSceneFormatImporterFBX2GLTF` | 4.3 | Renamed |

## Methods & Properties

| Deprecated | Use Instead | Since | Notes |
|------------|-------------|-------|-------|
| `yield()` | `await signal` | 4.0 | GDScript 2.0 coroutine syntax |
| `connect("signal", obj, "method")` | `signal.connect(callable)` | 4.0 | Callable-based connections |
| `instance()` | `instantiate()` | 4.0 | Renamed |
| `PackedScene.instance()` | `PackedScene.instantiate()` | 4.0 | Renamed |
| `get_world()` | `get_world_3d()` | 4.0 | Explicit 2D/3D split |
| `OS.get_ticks_msec()` | `Time.get_ticks_msec()` | 4.0 | Time singleton preferred |
| `duplicate()` for nested resources | `duplicate_deep()` | 4.5 | Explicit deep copy control |
| `Skeleton3D` signal `bone_pose_updated` | `skeleton_updated` | 4.3 | Renamed |
| `AnimationPlayer.method_call_mode` | `AnimationMixer.callback_mode_method` | 4.3 | Moved to base class |
| `AnimationPlayer.playback_active` | `AnimationMixer.active` | 4.3 | Moved to base class |

## Deprecated / Removed in 4.7

Sources: changelog (https://github.com/godotengine/godot/blob/master/CHANGELOG.md) and migration guide (https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.7.html);
"verified" = checked on the Godot 4.7.1 binary (2026-10-19). The binary cannot report deprecation flags, so
"deprecated" status comes from the changelog; existence / absence was checked on the binary.

| Deprecated / Removed | Use Instead | Since | Notes |
|----------------------|-------------|-------|-------|
| `type_exists()` (global function) | `ClassDB.class_exists()` | 4.7 | Deprecated (changelog GH-116899); still works on 4.7.1. Replacement is the natural equivalent and verified to exist; the changelog does not name it. |
| `TabContainer.all_tabs_in_front` | (none - option is now always off / useless) | 4.7 | Deprecated (changelog); property still present on 4.7.1. |
| `object_cast_to`, `classdb_get_class_tag` (GDExtension interface) | `is_class`-style casts | 4.7 | GDExtension authors only (changelog). |
| `AudioEffectSpectrumAnalyzer.tap_back_pos` | (removed, no replacement) | 4.7 | REMOVED; verified `get_tap_back_pos` is gone. |
| `RichTextLabel.add_image/update_image(width_in_percent: bool, height_in_percent: bool)` | `width_unit` / `height_unit` (`RichTextLabel.ImageUnit`) | 4.7 | Parameters renamed + retyped (verified). |
| `RichTextLabel.ImageUpdateMask.UPDATE_WIDTH_IN_PERCENT` | `ImageUpdateMask.UPDATE_WIDTH_UNIT` | 4.7 | Renamed (verified). |
| `EditorSceneFormatImporter.IMPORT_SCENE` and the other `IMPORT_*` constants | `EditorSceneFormatImporter.ImportFlags` enum | 4.7 | Editor plugins only (migration guide). |
| `Control.accessibility_live` typed with `DisplayServer.AccessibilityLiveMode` | `AccessibilityServer.AccessibilityLiveMode` | 4.7 | Type moved (migration guide). |
| `event.device == 0` to detect keyboard/mouse | `InputEvent.DEVICE_ID_KEYBOARD` / `DEVICE_ID_MOUSE` | 4.7 | Verified constants 16 / 32; `0` is no longer used for them. |

## Patterns (Not Just APIs)

| Deprecated Pattern | Use Instead | Why |
|--------------------|-------------|-----|
| String-based `connect()` | Typed signal connections | Type-safe, refactor-friendly |
| `$NodePath` in `_process()` | `@onready var` cached reference | Performance: path lookup every frame |
| Untyped `Array` / `Dictionary` | `Array[Type]`, typed variables | GDScript compiler optimizations |
| `Texture2D` in shader parameters | `Texture` base type | Changed in 4.4 |
| Manual post-process viewport chains | `Compositor` + `CompositorEffect` | Structured post-processing (4.3+) |
| GodotPhysics3D for new projects | Jolt Physics 3D | Default since 4.6; better stability |
| Tweening `position` / `scale` of Container children | `offset_transform_*` properties on `Control` | 4.7: Containers reset child transforms on every re-sort; offset transform survives it |
| Hard-coded `0` as keyboard/mouse device | `InputEvent.DEVICE_ID_KEYBOARD` / `DEVICE_ID_MOUSE` | 4.7 gave them real IDs (16 / 32) |
| Untyped override of a typed-return method without `return` | Explicit `return` (e.g. `return null`) or typed override | 4.7 inherits the parent's return type |
