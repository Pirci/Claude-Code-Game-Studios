# Godot — Current Best Practices

Last verified: 2026-10-19 | Engine: Godot 4.7

Practices that are **new or changed** since the model's training data (~4.3).
This supplements (not replaces) the agent's built-in knowledge.

## GDScript (4.5+)

- **Variadic arguments**: Functions can accept arbitrary parameter counts
  ```gdscript
  func log_values(prefix: String, values: Variant...) -> void:
      for v in values:
          print(prefix, ": ", v)
  ```

- **Abstract classes and methods**: Use `@abstract` to enforce inheritance
  ```gdscript
  @abstract
  class_name BaseEnemy extends CharacterBody3D

  @abstract func get_attack_pattern() -> Array[Attack]
  # Verified 4.7.1 (2026-10-19): an abstract function must NOT have a body
  # ("An abstract function cannot have a body"); a subclass that omits it fails to
  # compile; `BaseEnemy.new()` is a parse error.
  ```

- **Script backtracing**: Detailed call stacks available even in Release builds

## GDScript (4.7)

Sources: migration guide / changelog / release notes (see `breaking-changes.md`); "verified" = checked on the 4.7.1 binary.

- **Overrides inherit the parent's return type**: write an explicit `return` (or type the override). Verified:
  `func f(): pass` overriding `func f() -> int` is a parse error ("Not all code paths return a value").
- **Packed-array element writes don't hit the property setter** (verified): `obj.packed[i] = x` calls no setter on `packed`.
  If a setter must run (signals, dirty flags), assign the whole array: `obj.packed = new_array`.
- **`ClassDB.class_exists()` instead of `type_exists()`** (deprecated in 4.7).
- **`Tween.tween_await(signal)`** (verified) pauses a tween chain until a signal fires; useful for dialogue/cutscene sequencing.
- **`sprintf` Java-style argument index** works: `"%2$s-%1$s" % ["a", "b"]` -> `b-a` (verified).
- **`JSON.stringify({}, "\t")` yields `{}`** (verified); a UTF-8 BOM still breaks `JSON.parse()` (error 43, verified) but is skipped by `.tres` loading.
- Typed-array behavior (project-verified on 4.7.1): typed arrays are invariant at runtime, `.filter()` on a typed array
  stays typed, `Array[T](x)` does not compile (build the array and use `assign()`), typed `Dictionary` exports round-trip in `.tres`,
  `ResourceSaver` writes typed custom-resource arrays as `Array[ExtResource("id")]([...])`.
- `@abstract` (4.5+) is verified working: see the GDScript (4.5+) section above.
- **Quirk (project-verified on 4.7.1, C-38): don't index a `const` typed array of packed arrays with variables.**
  With `const M: Array[PackedInt32Array] = [[0, 8], [12, 4]]`, `M[r][c]` with runtime `r`, `c` returns `0` inside a
  function (static or instance, also via a temp `var row: PackedInt32Array = M[r]`), while literal indices `M[1][0]`
  and an untyped `const U: Array` return `12`. Use a flat `PackedInt32Array` (`M[r * w + c]`) or an untyped const.
- New warning `CONFUSABLE_TEMPORARY_MODIFICATION` (default WARN) - read it when it appears; trigger conditions not verified.
- `ResourceLoader.load_threaded_request/get` deadlock and race fixes (changelog) - threaded loading is safer than on 4.6.

## UI (4.7)

- **Offset transform**: use `offset_transform_*` (position / scale / rotation / pivot) to animate Controls inside Containers;
  it is visual-only by default (`offset_transform_visual_only`), so hover state does not flicker while an element moves.
- **Focus API** (introduced in 4.6, re-verified 4.7.1): `grab_focus(hide_focus := false)`, `has_focus(ignore_hidden_focus := false)`;
  project setting `gui/common/show_focus_state_on_pointer_event` = 0 Never / 1 Text Input Controls (default) / 2 Always.
  Pattern for "focus for keyboard navigation without a ring after a mouse click": `grab_focus(true)`.
- **Buttons fire `pressed` on `ui_accept` RELEASE** with the default `action_mode` (project-verified on 4.7.1) - tests that
  simulate keyboard activation must send press AND release.
- **PopupMenu** has an optional search bar (`search_bar_enabled`, `search_bar_min_item_count`, fuzzy search).
- **RichTextLabel images**: pass `width_unit` / `height_unit` (`RichTextLabel.ImageUnit`); `[img height=1em]` scales with the font.
- `Control.custom_maximum_size` complements `custom_minimum_size`.

## Rendering / 2D (4.7)

- **Stretch settings are explicit in the project file**: new-project defaults changed to `canvas_items` / `expand`, existing
  projects are untouched (verified). Pixel-art projects keep `stretch/mode="viewport"` + `scale_mode="integer"` (+ `aspect="keep"`).
- **Anti-aliased `draw_line()` / `draw_polyline()` are thinner** (no AA feather). Non-AA drawing (the default) is unchanged.
- **Pixel fonts**: importer default `hinting` is now 3 ("Light (Except Pixel Fonts)"). Keep `hinting=0` and `subpixel_positioning=0`
  pinned in the `.import` of pixel fonts; verify any re-import.
- **HDR output** is opt-in (`display/window/hdr/request_hdr_output`, default false). Leave off for SDR pixel art.
- `CollisionShape2D.one_way_collision_direction` replaces rotating shapes to get a non-"up" one-way platform.
- `SpriteFrames.LoopMode.LOOP_PINGPONG` for ping-pong sprite animations (verified).

## Audio (4.7)

- `AudioStreamPlayer2D/3D.area_mask` now defaults to 0: re-enable layer 1 if you use `Area2D/3D.audio_bus_override`.
- `AudioEffectSpectrumAnalyzer.tap_back_pos` was removed.

## Input (4.7)

- Compare `InputEvent.device` with `InputEvent.DEVICE_ID_KEYBOARD` / `DEVICE_ID_MOUSE`, never with `0`.
- Optional `input_devices/joypads/ignore_joypad_on_unfocused_application` to drop gamepad input when the window is unfocused.

## Editor Workflow (4.7)

- New Asset Store replaces the Asset Library; export templates can be downloaded per platform / architecture;
  2D scene painter (`B`), inline text-shader previews, MeshLibrary editor, collapsible animation tracks (release notes).
- Headless import + test (project-verified on 4.7.1): `godot --headless --import` first, then GdUnit4 6.1.3 runs.

## Physics (4.6)

- **Jolt Physics is the default 3D engine** for new projects
  - Better determinism and stability than GodotPhysics3D
  - Some HingeJoint3D properties (`damp`) only work with GodotPhysics
  - Switch: Project Settings → Physics → 3D → Physics Engine
  - 2D physics unchanged (still Godot Physics 2D)

## Rendering (4.6)

- **D3D12 is the default backend on Windows** (was Vulkan) — for better driver compatibility
- **Glow now processes before tonemapping** with screen blending mode — existing glow setups may look different
- **SSR overhauled** — significant improvement in realism, stability, and performance
- **AgX tonemapper** — new white point and contrast controls

## Rendering (4.5)

- **Shader Baker**: Pre-compile shaders to eliminate startup hitching
- **SMAA 1x**: New AA option — sharper than FXAA, cheaper than TAA
- **Stencil buffer**: Available for advanced masking/portal effects
- **Bent normal maps**: Directional occlusion in normal map textures
- **Specular occlusion**: Ambient occlusion now affects reflections

## Accessibility (4.5+)

- **Screen reader support**: Control nodes integrate with accessibility tools via AccessKit
- **Live translation preview**: Test GUI layouts in different languages directly in-editor
- **FoldableContainer**: New accordion-style UI node for collapsible sections
- **Recursive Control disable**: Disable mouse/focus interactions for entire node hierarchies with a single property

## Animation (4.5+)

- **BoneConstraint3D**: Bind bones to other bones with modifiers
  - AimModifier3D, CopyTransformModifier3D, ConvertTransformModifier3D

## Animation (4.6)

- **IK system fully restored**: Complete inverse kinematics reintroduced for 3D
  - Available modifiers: CCDIK, FABRIK, Jacobian IK, Spline IK, TwoBoneIK
  - Applied via `SkeletonModifier3D` nodes

## Resources (4.5+)

- **`duplicate_deep()`**: Explicit deep duplication for nested resource trees
  - Old `duplicate()` behavior retained for backward compatibility
  - Use `duplicate_deep()` when you need per-instance copies of nested resources

## Navigation (4.5+)

- **Dedicated 2D navigation server**: No longer proxied through 3D NavigationServer
  - Reduces export binary size for 2D-only games

## UI (4.6)

- **Dual-focus system**: Mouse/touch focus is now separate from keyboard/gamepad focus
  - Visual feedback differs depending on input method
  - Consider this when designing custom focus behavior
  - API surface (4.6, GH-110250): `Control.grab_focus(hide_focus)`, `Control.has_focus(ignore_hidden_focus)`,
    `LineEdit.edit(hide_focus)`; unchanged in 4.7 (verified)

## Editor Workflow (4.6)

- Flexible dock drag-and-drop with blue outline preview (including bottom panel)
- Most panels support floating windows (except Debugger)
- New keyboard shortcuts: Alt+O (Output), Alt+S (Shader)
- Export variable auto-generation: drag resource from FileSystem into script editor
- Live preview in Quick Open dialog when "Live Preview" enabled
- New "Select Mode" (v key) prevents accidental transforms; old mode renamed "Transform Mode" (q key)

## Tooling

- **ripgrep has no `gdscript` type**: `*.gd` is registered under `gap` (GAP programming language).
  `rg --type gdscript` is a hard error — the search never executes.
  Always use `rg --glob "*.gd"` (shell) or `glob: "*.gd"` (Grep tool) to filter GDScript files.

## Platform (4.5+)

- **visionOS export**: First new platform since open-sourcing (windowed app mode)
- **SDL3 gamepad driver**: Better cross-platform gamepad support
- **Android**: Edge-to-edge display, camera feed access, 16KB page support (Android 15+)
- **Linux**: Wayland subwindow support for multi-window capability
