# Godot Input — Quick Reference

Last verified: 2026-10-19 | Engine: Godot 4.7

## What Changed Since ~4.3 (LLM Cutoff)

### 4.7 Changes (2026-06-18)
Sources: migration guide (https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.7.html), changelog (https://github.com/godotengine/godot/blob/master/CHANGELOG.md, "4.7 - 2026-06-18"), release notes (https://godotengine.org/releases/4.7/). "Verified" = checked on the Godot 4.7.1 stable binary.
- **Keyboard and mouse events now carry a device ID**: `InputEvent.DEVICE_ID_KEYBOARD` (= 16) and
  `InputEvent.DEVICE_ID_MOUSE` (= 32) (verified; `DEVICE_ID_EMULATION` also exists). Before, both were `0`,
  which could collide with a joypad using ID 0. Compare against the constants; never hard-code `0`.
  Input-map actions saved before the change still match (changelog fix).
- **Project setting `input_devices/joypads/ignore_joypad_on_unfocused_application`** (verified, default `false`):
  ignore gamepad input while the window is unfocused.
- Gamepad extras (not used by this project): joypad motion sensors/gyro, vibration check, SDL3 driver on iOS,
  Home LED on Switch controllers, `misc2`-`misc6` buttons; `VirtualJoystick` node for touch.
- Linux Wayland: initial touch support; X11 pressed events released on true focus loss.
- Focus API (`grab_focus(hide_focus)`, `has_focus(ignore_hidden_focus)`, `gui/common/show_focus_state_on_pointer_event`)
  is unchanged since 4.6 and re-verified on 4.7.1 - see `ui.md`.

### 4.6 Changes
- **Dual-focus system**: Mouse/touch focus is now separate from keyboard/gamepad focus
  - Visual feedback differs by input method
  - Custom focus implementations may need updating
- **Select Mode keybind changed**: "Select Mode" is now `v` key; old mode renamed "Transform Mode" (`q` key)

### 4.5 Changes
- **SDL3 gamepad driver**: Gamepad handling delegated to SDL library for better cross-platform support
- **Recursive Control disable**: Single property disables mouse/focus for entire node hierarchies

### 4.3 Changes (in training data)
- **InputEventShortcut**: Dedicated event type for menu shortcuts (optional)

## Current API Patterns

### Input Actions (unchanged)
```gdscript
func _physics_process(delta: float) -> void:
    var input_dir: Vector2 = Input.get_vector(
        &"move_left", &"move_right", &"move_forward", &"move_back"
    )
    if Input.is_action_just_pressed(&"jump"):
        jump()
```

### Input Events (unchanged)
```gdscript
func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
            handle_click(event.position)
    elif event is InputEventKey:
        if event.keycode == KEY_ESCAPE and event.pressed:
            toggle_pause()
```

### Focus Management (4.6 — CHANGED)
```gdscript
# Mouse/touch and keyboard/gamepad focus are now SEPARATE
# Visual styles may differ depending on which input method is active
# If you have custom focus drawing, test with both input methods

# Standard approach still works:
func _ready() -> void:
    %StartButton.grab_focus()  # Keyboard/gamepad focus

# But be aware: mouse hover focus != keyboard focus in 4.6
```

### Gamepad (4.5+ — SDL3 backend)
```gdscript
# API unchanged, but SDL3 provides:
# - Better device detection across platforms
# - Improved rumble support
# - More consistent button mapping

func _input(event: InputEvent) -> void:
    if event is InputEventJoypadButton:
        if event.button_index == JOY_BUTTON_A and event.pressed:
            confirm_selection()
```

## Common Mistakes
- Not testing both mouse and keyboard focus paths (dual-focus in 4.6)
- Assuming `grab_focus()` affects mouse focus (it only affects keyboard/gamepad in 4.6)
- Using string literals instead of `StringName` (`&"action"`) for action names in hot paths
- Treating `event.device == 0` as "keyboard/mouse" (4.7: use `InputEvent.DEVICE_ID_KEYBOARD` / `DEVICE_ID_MOUSE`)
