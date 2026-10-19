# Godot Rendering — Quick Reference

Last verified: 2026-10-19 | Engine: Godot 4.7

## What Changed Since ~4.3 (LLM Cutoff)

### 4.7 Changes (2026-06-18)
Sources: migration guide (https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.7.html), changelog (https://github.com/godotengine/godot/blob/master/CHANGELOG.md, "4.7 - 2026-06-18"), release notes (https://godotengine.org/releases/4.7/). "Verified" = checked on the Godot 4.7.1 stable binary.
- **CanvasItem lines lose the antialiasing feather**: `draw_line()` / `draw_polyline()` with `antialiased = true`
  now draw at the requested width (before, the feather made them look thicker). Default is `antialiased = false`
  (signature verified), so non-AA lines are unchanged. Also: `Line2D` now applies viewport oversampling.
- **New-project stretch defaults** are `canvas_items` + `expand`. Existing projects are NOT migrated: verified
  that a `project.godot` with `stretch/mode="viewport"` and no `stretch/aspect` key still reads `aspect = keep`
  on 4.7.1. Pixel-art projects must keep `mode="viewport"` + `scale_mode="integer"` explicitly.
- **HDR output** (Windows, macOS, iOS, visionOS, Linux Wayland): `display/window/hdr/request_hdr_output`
  (basic setting, default `false` - verified) and `Window.hdr_output_requested` (verified). Leave off for SDR pixel art.
- **2D additions**: `DrawableTexture2D` (class verified), `GradientTexture2D.FILL_CONIC` (verified),
  `TextureRect` tiling of `AtlasTexture`, `CollisionShape2D.one_way_collision_direction` (see `physics.md`).
- **2D fixes (changelog)**: Polygon2D fast path and culling against a stale AABB after editing vertices,
  y-sort modulation division by zero, GLES3 batching skipping items for certain buffer sizes, GLES3 texture repeat,
  canvas-renderer deadlock / write-combined reads.
- **API changes**: `Image.save_exr()` / `save_exr_to_buffer()` gained `color_image`, `max_linear_value`
  (verified); `ImageTexture.get_format()` / `PortableCompressedTexture2D.get_format()` moved to `Texture2D`
  (verified); `RenderingServer.viewport_set_size()` gained `view_count`;
  `RenderingServer.particles_request_process_time()` renamed `time` -> `process_time`, added `process_time_residual`;
  `CPUParticles*/GPUParticles*.request_particles_process()` gained `process_time_residual`.
- **Defaults/behavior**: `rendering/reflections/sky_reflections/roughness_layers` 7 -> 8 (verified = 8);
  visual shader `LinearToSRGB` no longer clamps to [0, 1] on Mobile/Forward+.
- **3D (not used by this project)**: `AreaLight3D` (class verified), `Viewport.SCALING_3D_MODE_NEAREST` (verified),
  clearcoat fixes, per-pass environment uniform buffers, 3D particle scale/rotation, Vulkan subsampled images (XR).

### 4.6 Changes
- **D3D12 is the default rendering backend on Windows** (was Vulkan)
- **Glow processes before tonemapping** (was after) — uses screen blending mode
- **AgX tonemapper**: new white point and contrast controls
- **SSR overhauled**: better realism, visual stability, and performance

### 4.5 Changes
- **Shader Baker**: Pre-compiles shaders to reduce startup time
- **SMAA 1x**: New anti-aliasing option (sharper than FXAA, cheaper than TAA)
- **Stencil buffer support**: Enables selective geometry masking/portal effects
- **Bent normal maps**: Directional occlusion encoded in normal map textures
- **Specular occlusion**: Ambient occlusion now correctly affects reflections

### 4.4 Changes
- **`RenderingDevice.draw_list_begin`**: Many parameters removed; optional `breadcrumb` added
- **Shader texture types**: Changed from `Texture2D` to `Texture` base type
- **Particles `.restart()`**: Added optional `keep_seed` parameter

### 4.3 Changes (in training data)
- **Compositor node**: `Compositor` + `CompositorEffect` for post-processing chains

## Current API Patterns

### Post-Processing (4.3+)
```gdscript
# Use Compositor node — NOT manual viewport shader chains
# Add Compositor as child of WorldEnvironment or Camera3D
# Create CompositorEffect resources for each post-process step
```

### Anti-Aliasing Options (4.6)
```
Project Settings → Rendering → Anti Aliasing:
- MSAA 2D/3D: Hardware MSAA (quality but expensive)
- Screen Space AA: FXAA (fast, blurry) or SMAA (sharp, moderate cost)  # SMAA new in 4.5
- TAA: Temporal (best quality, ghosting on fast motion)
```

### Rendering Backend Selection (4.6)
```
Project Settings → Rendering → Renderer:
- Forward+ (default): Full featured, desktop-focused
- Mobile: Optimized for mobile/low-end, limited features
- Compatibility: OpenGL 3.3 / WebGL 2, broadest hardware support

Windows default backend: D3D12 (was Vulkan pre-4.6)
```

## Common Mistakes
- Assuming Vulkan is the default backend on Windows (D3D12 since 4.6)
- Using manual viewport chains instead of Compositor for post-processing
- Using `Texture2D` in shader uniform types (use `Texture` since 4.4)
- Not using Shader Baker for projects with many shader variants
- Using `antialiased = true` on `draw_line()` and expecting 4.6 thickness (4.7 draws thinner; widen the line)
- Assuming new-project stretch defaults apply to old projects (they do not; the project file is authoritative)
