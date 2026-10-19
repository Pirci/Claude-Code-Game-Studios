# Godot UI — Quick Reference

Last verified: 2026-10-19 | Engine: Godot 4.7

## What Changed Since ~4.3 (LLM Cutoff)

### 4.7 Changes (2026-06-18)
Sources: migration guide (https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.7.html), changelog (https://github.com/godotengine/godot/blob/master/CHANGELOG.md, "4.7 - 2026-06-18"), release notes (https://godotengine.org/releases/4.7/). "Verified" = checked on the Godot 4.7.1 stable binary.
- **Control offset transform (NEW)**: `offset_transform_enabled`, `offset_transform_position`,
  `offset_transform_position_ratio`, `offset_transform_scale`, `offset_transform_rotation`,
  `offset_transform_pivot`, `offset_transform_pivot_ratio`, `offset_transform_visual_only`
  (properties verified). Translate/rotate/scale a Control WITHOUT it being reset when a parent
  Container re-sorts. Purely visual by default (hover/click use the un-offset rect), so a
  button that slides/scales under the cursor does not lose its hover state.
- **`Control.custom_maximum_size` / `propagate_maximum_size`** (verified): upper size bound, complements `custom_minimum_size`.
- **`Control.translation_context`** (verified) + virtual `_get_cursor_shape()` (verified) +
  `_get_tooltip_auto_translate_mode_at()` (changelog).
- **PopupMenu search bar**: `search_bar_enabled`, `search_bar_min_item_count`,
  `search_bar_fuzzy_search_enabled`, `search_bar_fuzzy_search_max_misses`, `allow_search` (verified);
  `PopupMenu.set_item_index()` (changelog).
- **RichTextLabel images**: `add_image()` / `update_image()` take `width`/`height` as `float`, and the
  `width_in_percent` / `height_in_percent` bools became `width_unit` / `height_unit` of enum
  `RichTextLabel.ImageUnit` (`IMAGE_UNIT_PIXEL`, `IMAGE_UNIT_PERCENT`, `IMAGE_UNIT_EM`) (verified).
  `ImageUpdateMask.UPDATE_WIDTH_IN_PERCENT` -> `UPDATE_WIDTH_UNIT`. BBCode: `[img height=1em]path[/img]`
  scales an image with the font size. Triple-click selects a paragraph.
- **TextureRect** can tile an `AtlasTexture` (release notes, not verified). **GradientTexture2D**
  has `FILL_CONIC` (verified = 3).
- **TabContainer.all_tabs_in_front deprecated** (changelog; property still present on 4.7.1).
- **Accessibility**: landmark navigation (region role) for screen readers;
  `Control.accessibility_live` type moved to `AccessibilityServer.AccessibilityLiveMode` (GDScript
  unaffected; C# source/binary break).
- **VirtualJoystick** node (touch; not relevant for PC-only projects).
- **Focus (unchanged API since 4.6, re-verified on 4.7.1)**: `Control.grab_focus(hide_focus: bool = false)`,
  `Control.has_focus(ignore_hidden_focus: bool = false)` (both added in 4.6, GH-110250) and project
  setting `gui/common/show_focus_state_on_pointer_event` = 0 Never / 1 Text Input Controls (default) / 2 Always.
  4.7 only clarifies the setting description and fixes `TextEdit` showing focus on some mouse events.
- **Fonts / pixel text**: the DynamicFont importer default `hinting` changed 1 -> 3
  ("Light (Except Pixel Fonts)": hinting is disabled automatically for pixel-style fonts).
  Existing `.import` files that pin `hinting=0` / `subpixel_positioning=0` keep their values. Also in
  the changelog: FreeType rasterizer used when hinting is on, HarfBuzz 13.1.1 (optional `hb-raster`),
  `CanvasItem.oversampling_with_scale` (property verified, semantics unverified).
- **Button activation (project-verified on 4.7.1)**: `BaseButton` with default `action_mode` fires
  `pressed` on `ui_accept` RELEASE (not press).

### 4.6 Changes
- **Dual-focus system**: Mouse/touch focus is now SEPARATE from keyboard/gamepad focus
  - Visual feedback differs by input method
  - Custom focus implementations may need updating
- **TabContainer**: Tab properties editable directly in Inspector
- **TileMapLayer scene tile rotation**: Scene tiles can be rotated like atlas tiles

### 4.5 Changes
- **FoldableContainer**: New accordion-style UI node for collapsible sections
- **Recursive Control behavior**: Disable mouse/focus for entire node hierarchies
  with a single property
- **Screen reader support**: Control nodes work with AccessKit
- **Live translation preview**: Test different locales in-editor
- **`RichTextLabel.push_meta`**: Added optional `tooltip` parameter (from 4.4)

### 4.4 Changes
- **`GraphEdit.connect_node`**: Added optional `keep_alive` parameter

## Current API Patterns

### Theme and Style (4.6)
```gdscript
# Editor uses new "Modern" theme by default
# For game UI, use custom themes as before:
var theme := Theme.new()
theme.set_color(&"font_color", &"Label", Color.WHITE)
theme.set_font_size(&"font_size", &"Label", 24)
```

### Focus Management (4.6 — CHANGED)
```gdscript
# Keyboard/gamepad focus (grab_focus still works)
func _ready() -> void:
    %StartButton.grab_focus()

# IMPORTANT: In 4.6, mouse hover is separate from keyboard focus
# Both can be active simultaneously on different controls
# Test your UI with BOTH mouse and keyboard/gamepad

# Focus neighbors (unchanged)
%Button1.focus_neighbor_bottom = %Button2.get_path()
%Button1.focus_neighbor_right = %Button3.get_path()
```

### Offset Transform (4.7 - NEW)
```gdscript
# Slide / pop a button inside a Container without fighting the container layout
func pop_in(button: Button) -> void:
    button.offset_transform_enabled = true
    button.offset_transform_scale = Vector2(0.8, 0.8)
    var tween: Tween = create_tween()
    tween.tween_property(button, "offset_transform_scale", Vector2.ONE, 0.15)
# Tweening `position` / `scale` directly is lost on the next container sort.
```

### Focus Reveal (4.6 API, verified on 4.7.1)
```gdscript
# Give keyboard focus without showing the focus ring (e.g. after a mouse click)
control.grab_focus(true)             # hide_focus = true
if control.has_focus(true):          # ignore_hidden_focus = true -> counts hidden focus as focus
    pass
```


### FoldableContainer (4.5 — NEW)
```gdscript
# Accordion-style collapsible container
# Add as parent of content you want to make collapsible
# Children show/hide when header is clicked
# Configure via editor properties or code
```

### Recursive Disable (4.5 — NEW)
```gdscript
# Disable all mouse/focus interactions for a hierarchy
# Useful for disabling entire menu sections
%SettingsPanel.mouse_filter = Control.MOUSE_FILTER_IGNORE
# In 4.5+, this can propagate recursively to children
```

### Localization-Ready UI (best practice)
```gdscript
# Use tr() for all visible strings
label.text = tr("MENU_START_GAME")

# Use auto-wrap for labels (text length varies by language)
label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

# Test with live translation preview in editor (4.5+)
```


## Common Mistakes
- Assuming `grab_focus()` affects mouse focus (keyboard/gamepad only in 4.6)
- Not testing UI with both mouse and gamepad after upgrading to 4.6
- Hardcoding strings instead of using `tr()` for localization
- Not using `FoldableContainer` for collapsible UI (new in 4.5, cleaner than custom)
- Tweening `position` / `scale` of Container children instead of `offset_transform_*` (4.7) - the container resets them on re-sort
- Passing `width_in_percent` / `height_in_percent` bools to `RichTextLabel.add_image()` (4.7: `width_unit` / `height_unit` enum)
- Re-importing a pixel font with the importer defaults and expecting the old hinting value (default is now 3; pin `hinting=0` explicitly)
