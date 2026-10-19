# Godot — Breaking Changes

Last verified: 2026-10-19 | Engine: Godot 4.7

Changes between Godot versions, focused on post-LLM-cutoff changes (4.4+).

## 4.6 → 4.7 (2026-06-18 — POST-CUTOFF, MEDIUM RISK)

Sources: migration guide (https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.7.html), changelog (https://github.com/godotengine/godot/blob/master/CHANGELOG.md, section "4.7 - 2026-06-18"),
release notes (https://godotengine.org/releases/4.7/). "Verified" = checked on the Godot 4.7.1 stable binary (2026-10-19).
The migration guide calls 4.6 → 4.7 "relatively safe" for most projects.

### Breaking / behavior changes that can affect GDScript projects

| Subsystem | Change | Details |
|-----------|--------|---------|
| GDScript | Overrides inherit the parent's typed return | A method that overrides one with a typed return (even if the override is untyped) now has that return type, so it needs an explicit `return`. Verified: `func f(): pass` overriding `func f() -> int` fails with "Not all code paths return a value". Fix: add `return null` (or a real value). |
| GDScript | Packed-array element assignment no longer calls the whole-property setter | `obj.packed[i] = x` no longer triggers `set(v)` on the PackedArray property. Verified: a property with a setter saw 0 setter calls after `arr[1] = 9`. |
| GDScript | `type_exists()` deprecated | Use `ClassDB.class_exists()` (verified present). Still works on 4.7.1. |
| GDScript | New warning `CONFUSABLE_TEMPORARY_MODIFICATION` | Project setting `debug/gdscript/warnings/confusable_temporary_modification` exists, default 1 (WARN) - verified. What exactly triggers it is not verified. |
| Input | Keyboard / mouse events get device IDs | `InputEvent.device` was `0`; now `InputEvent.DEVICE_ID_KEYBOARD` (16) / `DEVICE_ID_MOUSE` (32) - verified. Do not compare with `0`. |
| Audio | `AudioStreamPlayer2D/3D.area_mask` default 1 → 0 | Only matters with `Area2D/3D.audio_bus_override` (set the player's mask back to layer 1). Verified = 0 on both; plain `AudioStreamPlayer` has no `area_mask`. |
| Audio | `AudioEffectSpectrumAnalyzer.tap_back_pos` removed | Verified: `get_tap_back_pos` absent. |
| Rendering | CanvasItem lines lose the AA feather | `draw_line` / `draw_polyline` with `antialiased=true` look thinner; widen if needed. Default `antialiased=false` unchanged. |
| Rendering | Visual shader `LinearToSRGB` no longer clamps to [0, 1] | Mobile / Forward+ only. |
| GUI | `RichTextLabel.add_image()` / `update_image()` | `width`/`height` are `float`; `width_in_percent`/`height_in_percent` bools replaced by `width_unit`/`height_unit` (`RichTextLabel.ImageUnit`: PIXEL / PERCENT / EM); `ImageUpdateMask.UPDATE_WIDTH_IN_PERCENT` → `UPDATE_WIDTH_UNIT`. Verified. |
| GUI | `Control.accessibility_live` type | `DisplayServer.AccessibilityLiveMode` → `AccessibilityServer.AccessibilityLiveMode` (GDScript-compatible; C# break). |
| GUI | `TreeItem.select()` adds `set_as_cursor`; `Font.find_variation()` adds `palette_index`, `custom_colors` | Optional parameters. |
| Core | `Object.is_class()` takes `StringName` | Was `String`; GDScript-compatible. `ZIPPacker.start_file()` gains `permissions`, `modified_time`; `OptimizedTranslation.generate()` returns `bool` (was `void`). |
| Core | `JSON.stringify()` prints empty `Dictionary` compactly | Verified: `JSON.stringify({}, "\t")` → `{}`. Only matters for string/golden-file comparisons, not for parse round-trips. |
| Core | `.tres` loading skips a UTF-8 BOM | Verified: a `.tres` with a BOM loads. `JSON.parse()` still fails on a BOM (error 43, verified) - strip it yourself. |
| Core | `ResourceLoader.load_threaded_*` fixes | Deadlocks, a request race, and resources never unloaded after `load_threaded_get` fixed (changelog). |
| Physics 2D | `PhysicsServer2D.body_set_shape_as_one_way_collision()` adds optional `direction` | `PhysicsServer2DExtension` version has a required extra parameter (GDExtension break). New `CollisionShape2D.one_way_collision_direction` (verified). |
| Physics 3D (Jolt) | Several behavior changes | `WorldBoundaryShape3D.plane.d` sign flipped; `SoftBody3D` default mass 1 kg total and different `linear_stiffness`; `Area3D` reports `SoftBody3D` overlaps; Jolt 5.5.0. 3D only. |
| Animation | `Animation.length` metadata float → double; `AnimationNodeBlendSpace1D/2D.add_blend_point()` adds `name` | GDScript-compatible. |
| Rendering API | `Image.save_exr()` / `save_exr_to_buffer()` add `color_image`, `max_linear_value`; `ImageTexture.get_format()` & `PortableCompressedTexture2D.get_format()` move to `Texture2D`; `RenderingServer.viewport_set_size()` adds `view_count`; `RenderingServer.particles_request_process_time()` renames `time` → `process_time`; `*Particles*.request_particles_process()` adds `process_time_residual` | Save_exr args and `Texture2D.get_format` verified. |
| Editor / XR | `EditorSceneFormatImporter.IMPORT_*` constants move to enum `ImportFlags`; `EditorVCSInterface._commit` adds `amend`; `OpenXRExtensionWrapper._on_register_metadata` adds `interaction_profile_metadata` | Plugin / GDExtension authors only. |

### Changed defaults

| Subsystem | Old → New | Details |
|-----------|-----------|---------|
| Project template | Stretch mode / aspect `disabled` / `keep` → `canvas_items` / `expand` | NEWLY CREATED projects only. Verified: an existing `project.godot` with `stretch/mode="viewport"` and no aspect key still reads `aspect = keep` on 4.7.1. |
| Import | `ResourceImporterDynamicFont.hinting` 1 → 3 | 3 = "Light (Except Pixel Fonts)" (class reference): hinting is auto-disabled for pixel-style fonts. Applies to new imports; `.import` files that pin `hinting=0` are unchanged. |
| Core | `rendering/reflections/sky_reflections/roughness_layers` 7 → 8 | Verified = 8. |
| Animation | `LookAtModifier3D.relative` true → false | Verified = false. |
| GUI | `RichTextLabel.add_image()` unit params `false` → `0` | Follows from the enum change above. |

### New in 4.7 (non-breaking, for awareness)

| Area | Feature | Notes |
|------|---------|-------|
| UI | Control offset transform (`offset_transform_*`, `offset_transform_visual_only`) | Verified properties. Animate Container children without layout fights. |
| UI | `Control.custom_maximum_size`, `translation_context`, `_get_cursor_shape()`; PopupMenu search bar; RichTextLabel `em` image units; TextureRect AtlasTexture tiling; accessibility landmark navigation; VirtualJoystick | Properties/classes verified except TextureRect tiling. |
| Rendering | HDR output (`display/window/hdr/request_hdr_output`, default false - verified; `Window.hdr_output_requested`); `DrawableTexture2D`; `AreaLight3D`; `Viewport.SCALING_3D_MODE_NEAREST`; `GradientTexture2D.FILL_CONIC` | Classes / constants verified. |
| Animation | `Tween.tween_await(signal)`, `Tween.has_tweeners()`; SpriteFrames `LOOP_PINGPONG` | Verified. |
| Input | `input_devices/joypads/ignore_joypad_on_unfocused_application`; gamepad motion sensors | Setting verified. |
| Editor | Asset Store replaces Asset Library; export template downloader per platform; 2D scene painter (`B`); inline text-shader previews; GDExtensions listed in Project Settings; MeshLibrary editor | Release notes only. |
| Platform | Standalone Android export (GABE), Android XR / Steam Frame support, Wayland touch, Perfetto tracing | Release notes only. |

## 4.5 → 4.6 (Jan 2026 — POST-CUTOFF, HIGH RISK)

| Subsystem | Change | Details |
|-----------|--------|---------|
| Physics | Jolt is now the DEFAULT 3D physics engine | New projects use Jolt automatically. Existing projects keep their setting. Some HingeJoint3D properties (like `damp`) only work with GodotPhysics. |
| Rendering | Glow processes BEFORE tonemapping | Was after tonemapping. Scenes with glow will look different. Adjust intensity/blend in WorldEnvironment. |
| Rendering | D3D12 default on Windows | Was Vulkan. For better driver compatibility. |
| Rendering | AgX tonemapper new controls | White point and contrast parameters added. |
| Core | Quaternion initializes to identity | Was zero. Unlikely to affect most code but technically breaking. |
| UI | Dual-focus system | Mouse/touch focus now separate from keyboard/gamepad focus. Visual feedback differs by input method. |
| Animation | IK system fully restored | CCDIK, FABRIK, Jacobian IK, Spline IK, TwoBoneIK via SkeletonModifier3D nodes. |
| Editor | New "Modern" theme default | Grayscale replaces blue-tint. Restore: Editor Settings → Interface → Theme → Style: Classic |
| Editor | "Select Mode" keybind changed | New "Select Mode" (v key) prevents accidental transforms. Old mode renamed "Transform Mode" (q key). |
| 2D | TileMapLayer scene tile rotation | Scene tiles can now be rotated like atlas tiles. |
| Localization | CSV plural form support | No longer requires Gettext for plurals. Context columns added. |
| C# | Automatic string extraction | Translation strings auto-extracted from C# code. |
| Plugins | New EditorDock class | Specialized container for plugin docks with layout control. |
| UI | `Control.grab_focus(hide_focus := false)`, `has_focus(ignore_hidden_focus := false)`, `LineEdit.edit(hide_focus)` | Added in 4.6 (GH-110250 / GH-111117, official 4.6 migration guide); setting `gui/common/show_focus_state_on_pointer_event`. Re-verified on 4.7.1. |
| Navigation | AStar returns an empty path from a disabled / solid start | `AStar2D/3D.get_point_path`, `AStarGrid2D.get_id_path/get_point_path` return `[]` when `from_id` is disabled/solid (official 4.6 migration guide). |
| Core | TSCN format change | `load_steps` no longer written; unique node IDs are saved. Backward/forward compatible, but re-saving a 4.5 scene produces big diffs (Project > Tools > Upgrade Project Files). |
| Rendering | Glow / volumetric fog defaults | Glow blend mode Soft Light → Screen, intensity 0.8 → 0.3; volumetric fog blending brighter (official 4.6 migration guide). |
| Core | `FileAccess.get_as_text()` loses `skip_cr`; `Performance.add_custom_monitor()` gains `type` | Official 4.6 migration guide. |
| Animation | `AnimationPlayer.current_animation` / `assigned_animation` / `autoplay` are `StringName` | GDScript-compatible; C# break (official 4.6 migration guide). |
| Editor | `EditorFileDialog` members moved to `FileDialog` | Plugin authors (official 4.6 migration guide). |
| Networking | `StreamPeerTCP` / `TCPServer` methods moved to `StreamPeerSocket` / `SocketServer` | GDScript-compatible (official 4.6 migration guide). |

## 4.4 → 4.5 (Late 2025 — POST-CUTOFF, HIGH RISK)

| Subsystem | Change | Details |
|-----------|--------|---------|
| GDScript | Variadic arguments added | Functions can accept `...` arbitrary params — new language feature |
| GDScript | `@abstract` decorator | Abstract classes and methods now enforceable |
| GDScript | Script backtracing | Detailed call stacks available even in Release builds |
| Rendering | Stencil buffer support | New capability for advanced visual effects |
| Rendering | SMAA 1x antialiasing | New post-processing AA option |
| Rendering | Shader Baker | Pre-compiles shaders — reportedly 20x faster startup on some demos |
| Rendering | Bent normal maps, specular occlusion | New material features |
| Accessibility | Screen reader support | Control nodes work with accessibility tools via AccessKit |
| Editor | Live translation preview | Test GUI layouts in different languages in-editor |
| Physics | 3D interpolation rearchitected | Moved from RenderingServer to SceneTree. API unchanged but internals differ. |
| Animation | BoneConstraint3D | New: AimModifier3D, CopyTransformModifier3D, ConvertTransformModifier3D |
| Resources | `duplicate_deep()` added | New explicit method for deep duplication of nested resources |
| Navigation | Dedicated 2D navigation server | No longer a proxy to 3D navigation; smaller export for 2D games |
| UI | FoldableContainer node | New accordion-style container for collapsible UI sections |
| UI | Recursive Control behavior | Disable mouse/focus interactions across entire node hierarchies |
| Platform | visionOS export support | New platform target |
| Platform | SDL3 gamepad driver | Delegated gamepad handling to SDL library |
| Platform | Android 16KB page support | Required for Google Play targeting Android 15+ |

## 4.3 → 4.4 (Mid 2025 — NEAR CUTOFF, VERIFY)

| Subsystem | Change | Details |
|-----------|--------|---------|
| Core | `FileAccess.store_*` return `bool` | Was `void`. Methods: `store_8`, `store_16`, `store_32`, `store_64`, `store_buffer`, `store_csv_line`, `store_double`, `store_float`, `store_half`, `store_line`, `store_pascal_string`, `store_real`, `store_string`, `store_var` |
| Core | `OS.execute_with_pipe` | Added optional `blocking` parameter |
| Core | `RegEx.compile/create_from_string` | Added optional `show_error` parameter |
| Rendering | `RenderingDevice.draw_list_begin` | Many parameters removed; `breadcrumb` parameter added |
| Rendering | Shader texture types | Parameter/return types changed from `Texture2D` to `Texture` |
| Particles | `.restart()` method | Added optional `keep_seed` parameter (CPU/GPU 2D/3D) |
| GUI | `RichTextLabel.push_meta` | Added optional `tooltip` parameter |
| GUI | `GraphEdit.connect_node` | Added optional `keep_alive` parameter |

## 4.2 → 4.3 (In Training Data — LOW RISK)

| Subsystem | Change | Details |
|-----------|--------|---------|
| Animation | `Skeleton3D.add_bone` returns `int32` | Was `void` |
| Animation | `bone_pose_updated` signal | Replaced by `skeleton_updated` |
| TileMap | `TileMapLayer` replaces `TileMap` | One node per layer instead of multi-layer single node |
| Navigation | `NavigationRegion2D` | Removed `avoidance_layers`, `constrain_avoidance` properties |
| Editor | `EditorSceneFormatImporterFBX` | Renamed to `EditorSceneFormatImporterFBX2GLTF` |
| Animation | AnimationMixer base class | AnimationPlayer and AnimationTree now extend AnimationMixer |
