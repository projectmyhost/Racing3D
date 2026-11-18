# ASSET_MANIFEST.md â€” Sunset Street Racing Asset Registry
**Project:** Sunset Street Racing Â· **Format:** Markdown & JSON (`res://data/asset_manifest.json`) Â· **Standard:** DESIGN.md Â§12, Â§14

---

## 1. Vehicles & Wheels

| ID | Type | Path | Source | Tool / Method | License | Attribution | Version | Tris | Materials | Replaceable | Notes |
|---|---|---|---|---|---|---|---|---|---|---|---|
| `veh_showcase_coupe_01` | Mesh / Scene | `res://assets/vehicles/showcase_car/veh_showcase_coupe_01.glb` | Generated | Procedural / SurfaceTool Mesh Generator | Original | Antigravity AI Team | 1.0 | 48,200 | 11 | Yes | Hero Japanese wide-body sports coupe with contract nodes |
| `veh_fallback_coupe_01` | Scene | `res://scenes/vehicles/fallback_coupe.tscn` | Generated | GDScript Procedural Assembly | Original | Antigravity AI Team | 1.0 | 4,800 | 10 | Yes | Fallback primitive coupe with identical node contract |
| `veh_wheel_multispoke_01` | Mesh / Scene | `res://assets/vehicles/wheels/veh_wheel_multispoke_01.tscn` | Generated | Procedural 10 split-spoke generator | Original | Antigravity AI Team | 1.0 | 3,200 | 3 | Yes | Deep concave 10 thin split-spoke with brake caliper |
| `tex_veh_showcase_badge` | Texture | `res://assets/textures/vehicles/tex_veh_showcase_badge.png` | Generated | SVG Rasterizer | Original | Antigravity AI Team | 1.0 | â€” | 1 | Yes | Original geometric "SR" monogram |
| `tex_veh_paint_detail_01` | Texture | `res://assets/textures/vehicles/tex_veh_paint_detail_01.png` | Generated | Procedural Noise | Original | Antigravity AI Team | 1.0 | â€” | 1 | Yes | Clearcoat micro-flake normal map |

---

## 2. Environment & Architecture

| ID | Type | Path | Source | Tool / Method | License | Attribution | Version | Tris | Materials | Replaceable | Notes |
|---|---|---|---|---|---|---|---|---|---|---|---|
| `env_sky_sunset_01` | Shader / Texture | `res://assets/shaders/sky_sunset.gdshader` | Generated | Procedural Gradient Shader | Original | Antigravity AI Team | 1.0 | â€” | 1 | Yes | Sunset sky: purple zenith, pink band, orange horizon, low sun |
| `env_city_skyline_far_01` | Mesh | `res://assets/environments/city/skyline/env_city_skyline_far_01.tscn` | Generated | Procedural Extrusion | Original | Antigravity AI Team | 1.0 | 2,800 | 1 | Yes | 14 skyscraper silhouettes 60â€“240 m with lit window dots |
| `env_city_skyline_mid_01` | Mesh | `res://assets/environments/city/skyline/env_city_skyline_mid_01.tscn` | Generated | Procedural Extrusion | Original | Antigravity AI Team | 1.0 | 4,200 | 1 | Yes | 10 mid-distance towers 60â€“140 m |
| `env_landmark_tower_01` | Mesh | `res://assets/environments/city/landmarks/env_landmark_tower_01.tscn` | Generated | Procedural Extrusion | Original | Antigravity AI Team | 1.0 | 1,800 | 2 | Yes | Focal glass tower (68% x screen), 220 m tall with setbacks |
| `tex_env_windows_atlas_2k` | Texture | `res://assets/textures/environments/tex_env_windows_atlas_2k.png` | Generated | Canvas Grid Generator | Original | Antigravity AI Team | 1.0 | â€” | â€” | Yes | 2048x1024 warm skyscraper window atlas |
| `env_highway_curve_01` | Mesh | `res://assets/environments/highway/env_highway_curve_01.tscn` | Generated | Procedural Extrusion | Original | Antigravity AI Team | 1.0 | 6,400 | 2 | Yes | Curved elevated ramp from left, radius 55 m, pillars |
| `env_highway_straight_01` | Mesh | `res://assets/environments/highway/env_highway_straight_01.tscn` | Generated | Procedural Extrusion | Original | Antigravity AI Team | 1.0 | 3,600 | 2 | Yes | 90 m overpass crossing behind car |
| `env_waterfront_edge_01` | Mesh | `res://assets/environments/waterfront/env_waterfront_edge_01.tscn` | Generated | Plane & Quay Generator | Original | Antigravity AI Team | 1.0 | 800 | 2 | Yes | Reflective water plane and concrete quay |

---

## 3. Vegetation & Props

| ID | Type | Path | Source | Tool / Method | License | Attribution | Version | Tris | Materials | Replaceable | Notes |
|---|---|---|---|---|---|---|---|---|---|---|---|
| `env_veg_palm_01` | Mesh | `res://assets/environments/vegetation/env_veg_palm_01.tscn` | Generated | Procedural Trunk + Crossed Fronds | Original | Antigravity AI Team | 1.0 | 2,100 | 2 | Yes | 9 m tall hero palm at screen 91% x |
| `env_veg_palm_02` | Mesh | `res://assets/environments/vegetation/env_veg_palm_02.tscn` | Generated | Procedural Fronds | Original | Antigravity AI Team | 1.0 | 1,400 | 2 | Yes | Cluster of 3 smaller palms |
| `tex_env_palm_leaf_1k` | Texture | `res://assets/textures/environments/tex_env_palm_leaf_1k.png` | Generated | Procedural Card Generator | Original | Antigravity AI Team | 1.0 | â€” | â€” | Yes | Alpha scissor palm frond card texture |
| `env_prop_billboard_01` | Mesh | `res://assets/environments/props/billboard/env_prop_billboard_01.tscn` | Generated | Procedural Steel Pole & Frame | Original | Antigravity AI Team | 1.0 | 950 | 2 | Yes | 14x6 m frame on 9 m pole tilted toward camera |
| `tex_env_billboard_art_01` | Texture | `res://assets/textures/environments/tex_env_billboard_art_01.png` | Generated | 2D Vector & Canvas | Original | Antigravity AI Team | 1.0 | â€” | â€” | Yes | "RACE BIGGER" white brush text, red paint slashes |
| `env_prop_streetlamp_01` | Mesh | `res://assets/environments/props/streetlamp/env_prop_streetlamp_01.tscn` | Generated | Procedural Pole & Head | Original | Antigravity AI Team | 1.0 | 450 | 1 | Yes | 9 m single-arm LED streetlamp |
| `env_prop_streetlamp_double_01` | Mesh | `res://assets/environments/props/streetlamp/env_prop_streetlamp_double_01.tscn` | Generated | Procedural Double Pole & Head | Original | Antigravity AI Team | 1.0 | 620 | 1 | Yes | 9 m double-arm streetlamp |
| `env_prop_barrier_jersey_01` | Mesh | `res://assets/environments/props/barrier/env_prop_barrier_jersey_01.tscn` | Generated | Procedural Extrusion | Original | Antigravity AI Team | 1.0 | 240 | 1 | Yes | 3 m modular concrete jersey barrier |
| `env_prop_fence_chainlink_01` | Mesh | `res://assets/environments/props/fence/env_prop_fence_chainlink_01.tscn` | Generated | Procedural Grid & Posts | Original | Antigravity AI Team | 1.0 | 180 | 1 | Yes | Chain-link fence panel with alpha scissor |
| `env_prop_guardrail_01` | Mesh | `res://assets/environments/props/guardrail/env_prop_guardrail_01.tscn` | Generated | Procedural W-Beam Rail | Original | Antigravity AI Team | 1.0 | 160 | 1 | Yes | W-beam highway guardrail |
| `env_road_plaza_01` | Mesh | `res://assets/environments/road/env_road_plaza_01.tscn` | Generated | Subdivided Plane | Original | Antigravity AI Team | 1.0 | 512 | 1 | Yes | 80x80 m wet plaza ground plane |
| `env_road_markings_01` | Mesh | `res://assets/environments/road/env_road_markings_01.tscn` | Generated | Decal Meshes | Original | Antigravity AI Team | 1.0 | 80 | 1 | Yes | Road paint lines and reflection decals |

---

## 4. UI Assets & Icons

| ID | Type | Path | Source | Tool / Method | License | Attribution | Version | Tris | Materials | Replaceable | Notes |
|---|---|---|---|---|---|---|---|---|---|---|---|
| `ico_play_flag` | SVG | `res://assets/ui/icons/ico_play_flag.svg` | Generated | Vector Graphic | Original | Antigravity AI Team | 1.0 | â€” | â€” | Yes | Checkered racing flag icon |
| `ico_settings_gear` | SVG | `res://assets/ui/icons/ico_settings_gear.svg` | Generated | Vector Graphic | Original | Antigravity AI Team | 1.0 | â€” | â€” | Yes | Settings gear icon |
| `ico_garage_car` | SVG | `res://assets/ui/icons/ico_garage_car.svg` | Generated | Vector Graphic | Original | Antigravity AI Team | 1.0 | â€” | â€” | Yes | Garage sports car front icon |
| `ico_tuning_wrench` | SVG | `res://assets/ui/icons/ico_tuning_wrench.svg` | Generated | Vector Graphic | Original | Antigravity AI Team | 1.0 | â€” | â€” | Yes | Tuning wrench icon |
| `ico_paint_spray` | SVG | `res://assets/ui/icons/ico_paint_spray.svg` | Generated | Vector Graphic | Original | Antigravity AI Team | 1.0 | â€” | â€” | Yes | Paint spray can icon |
| `ico_profile_user` | SVG | `res://assets/ui/icons/ico_profile_user.svg` | Generated | Vector Graphic | Original | Antigravity AI Team | 1.0 | â€” | â€” | Yes | Profile avatar icon |
| `ico_coin` | SVG | `res://assets/ui/icons/ico_coin.svg` | Generated | Vector Graphic | Original | Antigravity AI Team | 1.0 | â€” | â€” | Yes | Gold coin currency icon |
| `ico_gem` | SVG | `res://assets/ui/icons/ico_gem.svg` | Generated | Vector Graphic | Original | Antigravity AI Team | 1.0 | â€” | â€” | Yes | Diamond gem currency icon |
| `ico_info` | SVG | `res://assets/ui/icons/ico_info.svg` | Generated | Vector Graphic | Original | Antigravity AI Team | 1.0 | â€” | â€” | Yes | Info badge icon |
| `tex_ui_avatar_default` | PNG | `res://assets/ui/textures/tex_ui_avatar_default.png` | Extracted / Generated | Canvas Image | Original | Project Asset | 1.0 | â€” | â€” | Yes | Default player portrait (DiazRaditya style) |
| `theme_racing` | Theme | `res://assets/ui/theme_racing.tres` | Generated | Godot Theme Resource | Original | Antigravity AI Team | 1.0 | â€” | â€” | Yes | Unified racing UI styling |

---

## 5. Scenes & Core Scripts

| ID | Type | Path | Purpose |
|---|---|---|---|
| `home_screen` | Scene | `res://scenes/main/home_screen.tscn` | Root scene holding Environment, Stage, Car, CameraRig, UI |
| `showcase_stage` | Scene | `res://scenes/environment/showcase_stage.tscn` | Complete environment stage |
| `showcase_car` | Scene | `res://scenes/vehicles/showcase_car.tscn` | Vehicle root with contract hierarchy and showcase script |
| `home_screen_ui` | Scene | `res://scenes/ui/home_screen_ui.tscn` | Full HUD, profile card, currency pill, nav buttons, bottom strip |
| `player_profile` | Script | `res://scripts/core/player_profile.gd` | Autoload for player stats, currency, XP, avatar management |
| `quality_settings` | Script | `res://scripts/core/quality_settings.gd` | Autoload managing Low, Medium, High graphics profiles |
| `showcase_camera_rig` | Script | `res://scripts/camera/showcase_camera_rig.gd` | Independent camera rig with procedural sine offsets and tweens |
