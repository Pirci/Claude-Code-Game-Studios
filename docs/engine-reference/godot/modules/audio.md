# Godot Audio — Quick Reference

Last verified: 2026-10-19 | Engine: Godot 4.7

## What Changed Since ~4.3 (LLM Cutoff)

### 4.7 Changes (2026-06-18)
Sources: migration guide (https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.7.html), changelog (https://github.com/godotengine/godot/blob/master/CHANGELOG.md, "4.7 - 2026-06-18"), release notes (https://godotengine.org/releases/4.7/). "Verified" = checked on the Godot 4.7.1 stable binary.
- **`area_mask` default changed 1 -> 0 (disabled)** on `AudioStreamPlayer2D` and `AudioStreamPlayer3D`
  (verified = 0 on both; plain `AudioStreamPlayer` has no `area_mask`). This only matters if you use
  `Area2D/Area3D.audio_bus_override`: such areas stop affecting players that relied on the old default - set the
  player's `area_mask` back to layer 1. Other masks are unaffected. Disabled players also exit early (less overhead).
- **`AudioEffectSpectrumAnalyzer.tap_back_pos` removed** (verified: `get_tap_back_pos` no longer exists);
  analyzer jitter and Hann window fixed.
- `AudioStreamInteractive.TRANSITION_TO_TIME_PREVIOUS_POSITION` is now bound; `AudioEffectFilter` cutoff slider is
  exponential (editor); audio bus editor UI revamped; multi-viewport 3D volume calculation fixed.

No major breaking changes to the audio API in 4.4–4.6. The core audio system
remains stable. 4.7 has two small breaks (area_mask default, spectrum analyzer property removal).
Key updates are workflow improvements:

### 4.6 Changes
- **No audio-specific breaking changes** in this release

### 4.5 Changes
- **No audio-specific breaking changes** in this release

## Current API Patterns

### Playing Audio
```gdscript
@onready var sfx_player: AudioStreamPlayer = %SFXPlayer
@onready var music_player: AudioStreamPlayer = %MusicPlayer

func play_sfx(stream: AudioStream) -> void:
    sfx_player.stream = stream
    sfx_player.play()

func play_music(stream: AudioStream, fade_time: float = 1.0) -> void:
    var tween: Tween = create_tween()
    tween.tween_property(music_player, "volume_db", -80.0, fade_time)
    await tween.finished
    music_player.stream = stream
    music_player.volume_db = 0.0
    music_player.play()
```

### 3D Spatial Audio
```gdscript
@onready var audio_3d: AudioStreamPlayer3D = %AudioPlayer3D

func _ready() -> void:
    audio_3d.max_distance = 50.0
    audio_3d.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
    audio_3d.unit_size = 10.0
```

### Audio Buses
```gdscript
# Set bus volumes
AudioServer.set_bus_volume_db(AudioServer.get_bus_index(&"Music"), volume_db)
AudioServer.set_bus_volume_db(AudioServer.get_bus_index(&"SFX"), volume_db)

# Mute a bus
AudioServer.set_bus_mute(AudioServer.get_bus_index(&"Music"), true)
```

### Object Pooling for SFX
```gdscript
# Pre-create multiple AudioStreamPlayer nodes for concurrent sounds
var _sfx_pool: Array[AudioStreamPlayer] = []

func _ready() -> void:
    for i in range(8):
        var player := AudioStreamPlayer.new()
        player.bus = &"SFX"
        add_child(player)
        _sfx_pool.append(player)

func play_pooled(stream: AudioStream) -> void:
    for player in _sfx_pool:
        if not player.playing:
            player.stream = stream
            player.play()
            return
```

## Common Mistakes
- Creating new AudioStreamPlayer nodes at runtime instead of pooling
- Not using audio buses for volume categories (Music, SFX, UI, Voice)
- Using `_process()` for audio timing instead of signals (`finished`)
- Relying on the old `area_mask = 1` default together with `audio_bus_override` (4.7 default is 0)
- Reading `AudioEffectSpectrumAnalyzer.tap_back_pos` (removed in 4.7)
