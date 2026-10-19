# Godot Physics — Quick Reference

Last verified: 2026-10-19 | Engine: Godot 4.7

## What Changed Since ~4.3 (LLM Cutoff)

### 4.7 Changes (2026-06-18)
Sources: migration guide (https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.7.html), changelog (https://github.com/godotengine/godot/blob/master/CHANGELOG.md, "4.7 - 2026-06-18"), release notes (https://godotengine.org/releases/4.7/). "Verified" = checked on the Godot 4.7.1 stable binary.
- **`CollisionShape2D.one_way_collision_direction`** (verified): one-way collision in any local direction
  (was implicitly "local up"). `PhysicsServer2D.body_set_shape_as_one_way_collision()` gained an optional
  `direction`; `PhysicsServer2DExtension._body_set_shape_as_one_way_collision` gained a required `direction`
  (GDExtension break). 2D physics is otherwise unchanged.
- **Jolt (3D only) behavior changes**: Jolt updated to 5.5.0; `WorldBoundaryShape3D.plane.d` sign is interpreted
  the opposite way vs 4.6 (flip it); `SoftBody3D` default mass is now 1 kg total (was auto 1 kg per point) and
  `linear_stiffness` is applied differently (re-tune stiffness/damping); `Area3D` now reports overlaps with `SoftBody3D`;
  gravity application for dynamic bodies reworked; `ConeTwistJoint3D` uses cone-shaped limits.

### 4.6 Changes
- **Jolt Physics is the DEFAULT 3D engine** for new projects
  - Existing projects keep their current physics engine setting
  - Better determinism, stability, and performance than GodotPhysics3D
  - Some HingeJoint3D properties (`damp`) only work with GodotPhysics3D
  - 2D physics UNCHANGED (still Godot Physics 2D)

### 4.5 Changes
- **3D physics interpolation rearchitected**: Moved from RenderingServer to SceneTree
  - User-facing API unchanged, but internal behavior may differ in edge cases

## Physics Engine Selection (4.6)

```
Project Settings → Physics → 3D → Physics Engine:
- Jolt Physics (DEFAULT for new projects)
- GodotPhysics3D (legacy, still available)
```

### Jolt vs GodotPhysics3D

| Feature | Jolt (default) | GodotPhysics3D |
|---------|---------------|----------------|
| Determinism | Better | Inconsistent |
| Stability | Better | Adequate |
| Performance | Better for complex scenes | Adequate |
| HingeJoint3D `damp` | NOT supported | Supported |
| Runtime warnings | Yes, for unsupported properties | No |
| Collision margins | May behave differently | Original behavior |

## Current API Patterns

### Basic Physics Setup (unchanged)
```gdscript
# CharacterBody3D movement — API unchanged across engines
extends CharacterBody3D

@export var speed: float = 5.0
@export var jump_velocity: float = 4.5

func _physics_process(delta: float) -> void:
    if not is_on_floor():
        velocity += get_gravity() * delta

    if Input.is_action_just_pressed("jump") and is_on_floor():
        velocity.y = jump_velocity

    var input_dir: Vector2 = Input.get_vector("left", "right", "forward", "back")
    var direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
    velocity.x = direction.x * speed
    velocity.z = direction.z * speed

    move_and_slide()
```

### Raycasting (unchanged)
```gdscript
var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
var query := PhysicsRayQueryParameters3D.create(from, to)
query.collision_mask = collision_mask
var result: Dictionary = space_state.intersect_ray(query)
if result:
    var hit_point: Vector3 = result.position
    var hit_normal: Vector3 = result.normal
```

## Common Mistakes
- Assuming GodotPhysics3D is the default (Jolt since 4.6)
- Using HingeJoint3D `damp` property without checking physics engine (Jolt ignores it)
- Not testing collision edge cases when switching between physics engines
- Rotating a `CollisionShape2D` or editing its polygon just to change the one-way direction (use `one_way_collision_direction`, 4.7)
