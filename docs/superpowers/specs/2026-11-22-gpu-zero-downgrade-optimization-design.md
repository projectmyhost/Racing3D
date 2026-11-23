# GPU Optimization Without Visual Downgrade — Design Specification

**Date:** 2026-11-22
**Engine:** Godot 4.7.1 (`Forward+` Vulkan renderer, desktop/laptop Windows)
**Target Hardware Baseline:** RTX 5050 Laptop (1080p @ locked 60 FPS, scalable cleanly to RTX 2050 & lower tiers)

---

## 1. Problem Statement & Verified Root Causes

Profiling and static inspection of the repository reveal five compounding bottlenecks causing up to **100% GPU usage and unstable frame pacing** even on an RTX 5050 laptop:

1. **Redundant & Full-Res Post-Processing in `Tier.ULTRA`** (`scripts/core/quality_settings.gd:128-163`):
   - `_detect_default_tier` automatically routes `"5050"` GPUs to `Tier.ULTRA`.
   - `Tier.ULTRA` enables `MSAA_2X` simultaneously with `use_taa = true` (forcing ~2× multisample buffer/resolve overhead alongside TAA), full-resolution SSAO (`ssao_half = false`, `ENV_SSAO_QUALITY_HIGH`), `ssil = true`, `ssr_steps = 48`, `volumetric_fog = true` (`64×64` + filter), and `glow_bicubic = true`.
   - `EnvironmentMaterialEnhancer` (`scripts/core/environment_material_enhancer.gd:96-119`) also applies `clearcoat = 0.85`, `roughness = 0.045`, and `metallic >= 0.74` across skyscraper glass and tangent-space normals to architectural concrete across hundreds of buildings, magnifying SSR and PBR fragment cost.
2. **Oversized Shadow Atlas Coverage & Filter Cost** (`scripts/core/quality_settings.gd:129-132, 287-290`, `scenes/race/RaceTrack3D.tscn:74-91`):
   - `4096×4096` 4-split directional shadow map with `SHADOW_QUALITY_SOFT_HIGH`, `directional_shadow_blend_splits = true`, `shadow_max_dist = 420.0` (an 840m diameter shadow frustum rendering geometry behind and far around the camera), and `directional_shadow_pancake_size = 0.0`.
3. **CityMap Draw-Call Explosion, 100% Double-Sided Materials, & Zero Occlusion Culling** (`assets/models/environment/city_map/source/Untitled.glb`):
   - Contains **2,780 separate `MeshInstance3D` nodes** (`2,338` `unit_*`, `433` `prop_*`, `8` `backdrop_*`, `1` `chevron_*`) averaging only ~75 triangles each (`207,499` tris total).
   - **100 of 100 materials** in `Untitled.glb` are exported `doubleSided = true`, causing 2× vertex/fragment shading on backfaces.
   - `use_occlusion_culling` is disabled and zero `OccluderInstance3D` nodes exist, causing heavy overdraw behind dense Kowloon apartment blocks.
4. **Over-Dense Vehicle Meshes, Uncompressed VRAM Textures, & Heavy Exhaust Particles**:
   - Individual vehicles reach **415 mesh nodes / 500,000 tris** (`Mexico_Seltos_PE_pc13.glb`) and **380 mesh nodes / 536,595 tris** (`kia_carnival.glb`, `109` double-sided materials), including tens of thousands of triangles on occluded cabin interiors rendered from the exterior chase camera. `mesh_lod_threshold = 0.4` delays LOD transitions unnecessarily.
   - Exhaust emitters (`RaceCar3D.gd:111-132, 302`) emit continuously behind camera center using `SHADING_MODE_PER_PIXEL`, `DISTANCE_FADE_PIXEL_ALPHA`, and `proximity_fade_enabled = true`.
   - Dozens of large 3D textures (up to `13.5 MB` PNGs like `alcantara_nm.png`) use `compress/mode=0` (uncompressed VRAM) in `.import`.
5. **Heavy Sky Shader, Unthrottled HomeScreen Stage/Preload, & Exposed 120/Unlimited FPS UI**:
   - `Sky_sunset` (`env_racetrack.tres:18-21`) evaluates two 5-octave FBM procedural noise loops on a static sky (`sky_sunset.gdshader:34-44, 77-78`) with `process_mode = 1`.
   - `HomeScreen` (`home_screen.tscn`) renders the full `1,422m × 1,212m` city map behind the menu with `420m` shadow passes while `ShowcaseCar` eagerly queues 16 vehicle rigs after `0.35s`.
   - `FpsOption` (`home_screen_ui.tscn:1141-1157`) exposes `120 FPS` and `Unlocked` (`max_fps = 0`).

---

## 2. Goals & Global Constraints

### Goals
1. Eliminate GPU saturation on RTX 5050 at **locked 60 FPS (1080p)** with target GPU frame time well below the `16.67 ms` budget (measured via Godot's `RenderingServer` GPU timer & draw-call counters before and after each phase).
2. Enforce a **60 FPS maximum ceiling** in engine runtime defaults and Settings UI (`30 FPS` and `60 FPS` options only for the current release).
3. Implement **3-Zone Hybrid Culling ("render only what needs to be seen")** with **0% visual pop-in**, **0% shadow popping**, and **0% stutter** during fast 360° camera orbit drags.

### Hard Constraints (Non-Negotiable)
1. **Zero Visual Downgrade:** Car lacquer shaders (`car_paint_aaa.gdshader`, `clearcoat`, micro-flakes, orange peel), asphalt shading (`asphalt_aaa.gdshader`), `AgX` tonemapping, `VolumetricFog`, `SSR`, `SSIL`, `SSAO`, `Glow`, and golden-hour sky visuals must remain 100% AAA fidelity (close-up car/road shadows actually sharpen by focusing the `4096×4096` shadow atlas from `420m` to `260m`).
2. **Protect Road Albedo & Imports:** Never alter `Untitled_Image_49.png` or `Untitled_Image_72.png` albedo textures or their `.import` files (`environment_material_enhancer.gd:6`).
3. **Protect Collision & Track Integrity:** `CollisionGuard.gd` (`TrackColliders`, `BackdropRoadCollision`, `RoadSurfacesCollision`) and all 4 race checkpoints must remain 100% functional (`0 anomalies`). Keep `backdrop_grp_*` (8 nodes) intact and unmerged.
4. **Protect Vehicle Visual Exceptions:** Preserve `porsche_mission_x` rims/calipers/badges untouched (`VehicleMaterialEnhancer.gd:178`) and Porsche Carrera GT `body6a` suppression intact.
5. **UI Copy Accuracy & Cleanup:** Keep UI text clean, accurate, and remove `120 FPS` / `Unlocked` options without breaking `SettingsModal` signal bindings or layout.

---

## 3. Architecture Design

### Section 1 — Hard 60 FPS Cap, Pacing & Telemetry Profiler
- **Files:** `scenes/ui/home_screen_ui.tscn`, `scripts/ui/home_screen_ui.gd`, `scripts/debug/gpu_perf_overlay.gd` (new), `tools/benchmark_gpu.gd` (new).
- Limit `FpsOption` to 2 entries (`0`: `30 FPS`, `1`: `60 FPS`, default `1`). Clamp runtime FPS index `[0, 1]` and invoke `_apply_fps_limit(_selected_fps_index)` immediately in `HomeScreenUI._ready()` so startup enforces consistent pacing (`VSYNC_ENABLED + Engine.max_fps = 60` on ~60Hz panels; `VSYNC_DISABLED + Engine.max_fps = 60` on high-refresh >62Hz panels to prevent 120/144Hz spin or uneven pull-down).
- Add a lightweight `F3`-toggled `GPUPerfOverlay` (default hidden in release gameplay, toggleable for QA + scripted headless/windowed benchmark runner) reporting FPS, CPU/GPU frame time (`RenderingServer.viewport_get_measured_render_time_gpu`), Draw Calls, Objects, Primitives, and Video RAM.

### Section 2 — Phase 1: Pipeline, Shadow, Sky, VFX & VRAM Optimization
- **Files:** `scripts/core/quality_settings.gd`, `assets/materials/environments/env_racetrack.tres`, `assets/shaders/sky_sunset_fast.gdshader` (new), `assets/textures/environments/sky_sunset_clouds.exr` (baked by `tools/bake_sunset_panorama.gd`), `scripts/race/RaceCar3D.gd`, `scripts/race/ModernSpeedometer.gd`, `scripts/race/ModernMinimap.gd`, `scripts/vehicle/showcase_car.gd`, `scenes/main/home_screen.tscn`, `assets/{models,textures}/**/*.import`.
- **`Tier.ULTRA` Cleanup (`quality_settings.gd`):**
  - Remove `MSAA_2X` when `use_taa = true` (`Viewport.MSAA_DISABLED`).
  - Set `ssao_half = true` (retain `ENV_SSAO_QUALITY_HIGH`), `shadow_quality = SHADOW_QUALITY_SOFT_MEDIUM`, `shadow_max_dist = 260.0` (with tighter splits `0.06 / 0.18 / 0.45`), `mesh_lod_threshold = 0.85`, `ssr_steps = 32`.
  - Restore `sun.directional_shadow_pancake_size = 12.0` (and verify on elevated ramps with A/B screenshot).
- **Sky Pre-Baking:** Render the 2× 5-octave FBM sunset clouds + Rayleigh sky dome once at build-time into a `2048×1024` HDR `.exr` (`tools/bake_sunset_panorama.gd`), sampled by a lightweight `sky_sunset_fast.gdshader` that keeps the mathematical HDR solar disc/corona edge razor-sharp and respects `hdr_sky_intensity`. Set `Sky_sunset.process_mode = 2` (`PROCESS_MODE_INCREMENTAL`).
- **Exhaust Particle Fillrate:** Separate `_build_exhaust_material()` in `RaceCar3D.gd` using `SHADING_MODE_UNSHADED` + vertex alpha fade (dropping per-pixel lighting & depth proximity fade on constant behind-car exhaust puffs).
- **VRAM Compression:** Convert 3D model `.import` textures (`>128KB` outside `assets/ui` and `Untitled_Image_49/72`) from `compress/mode=0` to `compress/mode=2` (`uastc_level=1`, preserving normal map flags cleanly for `*_nm` / `Normal` maps).
- **HUD Redraw Guard & HomeScreen Pacing:** Redraw `ModernSpeedometer` only when speed/RPM/needle angle delta is visible (`>0.15 deg` / `0.2 km/h`) and `ModernMinimap` when position/heading changes cleanly or paused skips redraws. In `ShowcaseCar`, load idle garage rigs **only after `garage_open == true`** (stop pre-warming all 16 vehicles at startup after 0.35s!). In `HomeScreen`, cap `SunLight.directional_shadow_max_distance` to `120.0` (overriding `QualitySettings` for the close-up `8.2m` showcase framing without touching `RaceTrack3D`).

### Section 3 — Phase 2: 3-Zone Zero-Pop-In Culling & Geometry Architecture
Replaces naive "camera frustum script toggling" (which breaks during fast mouse drags and causes shadow popping) with engine-native multi-layer culling:

1. **Baked Conservative Software Occlusion Culling:**
   - Generate `tools/build_optimized_city_map.gd` to produce `assets/models/environment/city_map/city_map_optimized.scn` (binary `PackedScene`, keeping `Untitled.glb` raw asset untouched as source of truth).
   - For thick opaque building blocks (`unit_*` with height `>= 12m`, minimum thickness `>= 6m`, OPAQUE materials only), create inward-shrunk conservative bounding boxes (shrunk `>= 2.0m` per horizontal axis and `1.5m` top so no building corner/roof edge ever pops prematurely during high-speed turns or 360° camera pans) and pack them into an `ArrayOccluder3D` on `OccluderInstance3D`.
   - Enable `rendering/occlusion_culling/use_occlusion_culling=true` in `project.godot`.
2. **Spatial Sector Batching (`2,771` unit/prop nodes → `<120` spatial chunks):**
   - Partition `unit_*` meshes (`2,338` nodes) and `prop_*` meshes (`433` nodes) into a `140m × 140m` X/Z spatial grid (preserving `CityMap` parent transform and `backdrop_grp_*` intact for `CollisionGuard.gd`).
   - Within each grid cell, merge static meshes sharing the same calibrated material key using `SurfaceTool` (preserving vertices, normals, tangents, UVs, and surface material identity so `EnvironmentMaterialEnhancer` upgrades asphalt to `asphalt_aaa.gdshader` seamlessly).
   - Keep **small `prop_*` (`MaxDim <= 8.0m`, cones/signs/bollards)** in dedicated per-cell small-prop chunks with:
     - **Zona 1 (360° Always-Resident Near Ring `0–160m`)**: 100% visible in full 360° around the camera regardless of yaw pan speed.
     - **Zona 2 (`160–210m`)**: `visibility_range_end = 190.0`, `visibility_range_end_margin = 20.0`, `visibility_range_fade_mode = VISIBILITY_RANGE_FADE_SELF`, and `cast_shadow = SHADOW_CASTING_SETTING_OFF` on micro-props (`<2m` cones/chevrons) so tiny objects don't pollute 4× shadow cascades.
     - **Zona 3 (`>210m`)**: All major buildings, roads, bridges, and skyline silhouettes stay rendered (`visibility_range_end = 0.0`, occluded cleanly only when behind tall buildings via `ArrayOccluder3D`).
3. **Material Culling Audit (`CULL_BACK` Safe Subset):**
   - Audit which `unit_*` materials represent closed solid building structures vs thin/billboard/alpha foliage (`BLEND` materials `material_041_38/42/55/68` and verified 1-sided thin surfaces remain `CULL_DISABLED`). Only verified solid closed chunks use `CULL_BACK`, cutting unnecessary backface fragment/vertex work without creating transparent holes.
   - Simplify `EnvironmentMaterialEnhancer` concrete/facade normal-map and glass clearcoat on distant/secondary city blocks while keeping hero foreground reflections & `asphalt_aaa` intact.
4. **High-Poly Vehicle Interior Shadow & Distance Culling:**
   - In `VehicleMaterialEnhancer.enhance_vehicle_materials()` / `VehicleVisualAdapter`, automatically identify opaque occluded cabin interior meshes (`_is_interior(...)` on closed-roof vehicles) and set `mi.cast_shadow = SHADOW_CASTING_SETTING_OFF` + `mi.visibility_range_end = 90.0` (with exterior chassis, wheels, glass, spoilers, lights kept at unlimited distance & shadows enabled). Preserves `angkot_dki` driver/cabin visibility completely inside 90m chase & showroom distances!

---

## 4. Verification & Success Criteria

1. **Automated Scene & Collision Checks:**
   - `tools/verify_racetrack.gd` passes (`0` collision anomalies in `CollisionGuard`).
   - `tools/verify_all_cars.gd` passes across all cars (including `angkot_dki`, `porsche_mission_x`, `porsche_carrera_gt`, `kia_seltos`, `kia_carnival`, `mclaren`).
2. **Measured Performance Benchmark (`tools/benchmark_gpu.gd`):**
   - Measures baseline vs post-Phase-1 vs post-Phase-2 on `HomeScreen` and `RaceTrack3D` (driving along dense city corridor + rapid 360° yaw orbit sweep):
     - Significant reduction in GPU render time (`ms`), Draw Calls (`2,780+` scene nodes -> `< 200` chunks/calls), Primitives, and Video RAM.
3. **Visual Parity Verification (1920×1080 Side-by-Side Comparison):**
   - Before vs After PNG screenshots on `HomeScreen` and `RaceTrack3D` (straightaway, elevated ramp shadows, dense building corridor, car reflections, fast yaw look-back) inspected side-by-side confirming **0% visual downgrade, sharper vehicle shadows, 0 missing faces/holes, and 0 pop-in**.
