# Godot Networking — Quick Reference

Last verified: 2026-10-19 | Engine: Godot 4.7

## What Changed Since ~4.3 (LLM Cutoff)

### 4.7 Changes (2026-06-18)
Sources: migration guide (https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.7.html), changelog (https://github.com/godotengine/godot/blob/master/CHANGELOG.md, "4.7 - 2026-06-18"), release notes (https://godotengine.org/releases/4.7/). "Verified" = checked on the Godot 4.7.1 stable binary.
- **No networking API breaks** in the 4.7 migration guide. Fixes only: ENet DTLS server peer leak, UDP server peer
  connections, shortened IPv6 address parsing, HTTPRequest redirect status codes, incomplete downloads removed,
  WebSocket send optimization (Web).

### 4.6 Changes
- **Socket base classes** (official 4.6 migration guide; GDScript-compatible): `StreamPeerTCP.disconnect_from_host()`,
  `get_status()`, `poll()` moved to base class `StreamPeerSocket`; `TCPServer.is_connection_available()`,
  `is_listening()`, `stop()` moved to base class `SocketServer`.

### 4.5 Changes
- **No major networking API breaks** — core multiplayer API remains stable

## Current API Patterns

### High-Level Multiplayer
```gdscript
# Server
func host_game(port: int = 9999) -> void:
    var peer := ENetMultiplayerPeer.new()
    peer.create_server(port)
    multiplayer.multiplayer_peer = peer
    multiplayer.peer_connected.connect(_on_peer_connected)
    multiplayer.peer_disconnected.connect(_on_peer_disconnected)

# Client
func join_game(address: String, port: int = 9999) -> void:
    var peer := ENetMultiplayerPeer.new()
    peer.create_client(address, port)
    multiplayer.multiplayer_peer = peer
```

### RPCs
```gdscript
# Server-authoritative pattern
@rpc("any_peer", "call_local", "reliable")
func request_action(action_data: Dictionary) -> void:
    if not multiplayer.is_server():
        return
    # Validate on server, then broadcast
    _execute_action.rpc(action_data)

@rpc("authority", "call_local", "reliable")
func _execute_action(action_data: Dictionary) -> void:
    # All peers execute the validated action
    pass
```

### MultiplayerSpawner and MultiplayerSynchronizer
```gdscript
# Use MultiplayerSpawner for automatic node replication
# Use MultiplayerSynchronizer for property synchronization

# MultiplayerSynchronizer setup:
# 1. Add as child of the node to sync
# 2. Configure replication properties in editor
# 3. Set visibility filters for relevancy
```

### SceneMultiplayer Configuration
```gdscript
func _ready() -> void:
    var scene_mp := multiplayer as SceneMultiplayer
    scene_mp.auth_callback = _authenticate_peer
    scene_mp.server_relay = false  # Direct peer connections

func _authenticate_peer(id: int, data: PackedByteArray) -> void:
    # Custom authentication logic
    pass
```

## Common Mistakes
- Not using `"any_peer"` for client-to-server RPCs (defaults to authority only)
- Trusting client data without server-side validation
- Using `"unreliable"` for game state changes (use for position updates only)
- Not setting multiplayer authority (`set_multiplayer_authority()`) on spawned nodes
