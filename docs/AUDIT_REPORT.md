# AUDIT REPORT — VEHICLE PHYSICS SYSTEM & ARCHITECTURE
**Project**: Sunset Street Racing (Godot 4.7.1)
**Date**: November 14, 2026
**Lead Investigators**: Principal Vehicle Dynamics Engineer, Senior Godot 3D Engineer, QA Automation Engineer

---

## 1. Engine & Project Settings Specification

| Parameter | Current Value | Evaluation & Impact |
| :--- | :--- | :--- |
| **Engine Version** | Godot 4.7.1.stable.official.a13da4feb | Modern Godot 4 architecture; supports Jolt and native GodotPhysics3D. |
| **Renderer** | `gl_compatibility` (OpenGL 3.3 / GLES3) | High framerate compatibility on varied hardware; lightweight shaders. |
| **Physics Engine** | `GodotPhysics3D` (Engine default) | Built-in 3D physics server. |
| **Physics Timestep (`physics_ticks_per_second`)** | 60 Hz (Default) | Adequate for basic simulation; 60 Hz requires sub-stepping or raycast spring damping to prevent suspension oscillation at high speeds (>180 km/h). |
| **Max Physics Steps Per Frame** | 8 | Prevents spiral of death during frame drops. |
| **Physics Interpolation** | `false` (Disabled) | **CRITICAL DEFECT**: `ChaseCamera` updates in `_process()` while `RaceCar3D` updates in `_physics_process()`. Without physics interpolation, micro-stutter and frame judder occur whenever render FPS diverges from 60 Hz. |
| **Default Gravity** | 9.8 m/s^2 downwards (`Vector3(0, -9.8, 0)`) | Standard Earth gravity. However, `RaceCar3D.gd` overrides this with a hardcoded artificial `gravity = 28.0` m/s^2. |

---

## 2. Vehicle Nodes, Scenes, and Hierarchy Audit

### 2.1 Active In-Game Car Node
- **Location**: In [scenes/race/RaceTrack3D.tscn](file:///c:/Users/Pongo/OneDrive/Documents/racing/scenes/race/RaceTrack3D.tscn) as child node `RaceCar3D`.
- **Node Type**: `CharacterBody3D` (Extended by [scripts/race/RaceCar3D.gd](file:///c:/Users/Pongo/OneDrive/Documents/racing/scripts/race/RaceCar3D.gd)).
- **Attached Shape**: [ConvexPolygonShape3D](file:///c:/Users/Pongo/OneDrive/Documents/racing/scenes/race/RaceTrack3D.tscn#L28-L30) (16-point beveled ski-ramp box).
- **Collision Layer / Mask**: Layer 2 (Vehicle), Mask 1 (Track / Environment).

### 2.2 Visual Car Models (Prefabs)
Located in `assets/models/cars/`:
1. `car_sedan.tscn`
2. `car_mclaren.tscn`
3. `car_coupe.tscn`
4. `car_sport.tscn`
5. `car_hatchback.tscn`
6. `car_compact.tscn`
7. `car_wagon.tscn`
8. `car_minivan.tscn`
9. `car_suv.tscn`
10. `car_pickup.tscn`
11. `car_offroad.tscn`

**Structural Finding**:
All 11 car prefabs are purely visual node hierarchies (`Node3D` root -> `Body` MeshInstance3D + `Wheel_*` MeshInstance3D). None contain physics colliders or rigid body logic. However, `RaceCar3D.gd` at runtime instantiates these models into an internal `VisualPivot` node and attempts to unparent/reparent wheels into newly created `Wheel_*_SteerPivot` and `Wheel_*_SpinPivot` nodes.

### 2.3 Other Vehicle Scenes
- [scenes/vehicles/showcase_car.tscn](file:///c:/Users/Pongo/OneDrive/Documents/racing/scenes/vehicles/showcase_car.tscn) with [scripts/vehicle/showcase_car.gd](file:///c:/Users/Pongo/OneDrive/Documents/racing/scripts/vehicle/showcase_car.gd): Standalone turntable car for garage/showroom previews.
- [scenes/race/RaceScene.tscn](file:///c:/Users/Pongo/OneDrive/Documents/racing/scenes/race/RaceScene.tscn) with [scripts/race/RaceCar.gd](file:///c:/Users/Pongo/OneDrive/Documents/racing/scripts/race/RaceCar.gd): Legacy 2D prototype (CharacterBody2D).

---

## 3. Scripts and Ecosystem Dependencies

| Component | File Path | Role & Exposed Interface |
| :--- | :--- | :--- |
| **Race Controller** | [scripts/race/RaceTrack3D.gd](file:///c:/Users/Pongo/OneDrive/Documents/racing/scripts/race/RaceTrack3D.gd) | Manages lap timing, checkpoints, race finish, and `ChaseCamera`. Reads `car.speed_changed`, `car.forward_speed`, `car.rotation.y`, `car.current_steer_angle`, `car.max_steer_angle`. Sets `car.is_active = false` on finish. |
| **Vehicle Controller** | [scripts/race/RaceCar3D.gd](file:///c:/Users/Pongo/OneDrive/Documents/racing/scripts/race/RaceCar3D.gd) | Handles input, kinematics, visual suspension lerping, and wheel rotations. |
| **Player Profile (Autoload)** | [scripts/core/player_profile.gd](file:///c:/Users/Pongo/OneDrive/Documents/racing/scripts/core/player_profile.gd) | Stores `equipped_car: String`, `unlocked_cars: Array[String]`. Provides `equip_car(id)`, `buy_car(id, coins, gems)`, and F11 fullscreen toggle. |
| **Garage Screen** | [scenes/garage/GarageScreen.gd](file:///c:/Users/Pongo/OneDrive/Documents/racing/scenes/garage/GarageScreen.gd) | Vehicle catalog UI (`CAR_DATABASE`), purchase, and equip flow. |
| **Race Setup Screen** | [scenes/race/RaceSetupScreen.gd](file:///c:/Users/Pongo/OneDrive/Documents/racing/scenes/race/RaceSetupScreen.gd) | Track selection, difficulty selection, car stats preview, transitions to `RaceTrack3D.tscn`. |
| **Collision Guard** | [scripts/race/CollisionGuard.gd](file:///c:/Users/Pongo/OneDrive/Documents/racing/scripts/race/CollisionGuard.gd) | Runtime audit tool verifying invisible colliders and abnormal AABB ratios on map load. |

---

## 4. Vehicle Configurations & Inconsistencies Audit

In `RaceCar3D.gd`, a static dictionary `SUSPENSION_CONFIGS` (lines 45-144) defines parameters across 11 car models.

### Key Inconsistencies Discovered:
1. **Mass is Completely Missing**:
   Because `RaceCar3D` inherits from `CharacterBody3D`, mass does not exist in the simulation. Every vehicle interacts with obstacles, gravity, and momentum as if it had zero inertial mass.
2. **Fixed Engine Force & Drag Across All Vehicles**:
   Variables `@export var max_speed: float = 34.0`, `@export var acceleration: float = 18.0`, `@export var brake_force: float = 34.0`, and `@export var rolling_drag: float = 4.5` are uniform for all 11 cars unless modified globally in the Inspector. A sports car (McLaren) has the exact same acceleration and top speed as an Offroad or Minivan.
3. **Suspension is Visual-Only**:
   Parameters `max_roll_deg`, `max_pitch_deg`, `roll_stiffness`, etc., are only applied to `BodyPivot.rotation` and `BodyPivot.position` via `lerpf`. The actual collision body and wheels remain completely rigid.
4. **Hardcoded Fallbacks for Unregistered Cars**:
   In `get_suspension_config()` (lines 332-340), unlisted cars fall back to `"sedan"` or `"sport"` based on hardcoded string matching.

---

## 5. Track and Road Collision Geometry Audit

- **Road Surface Mesh**: [scenes/race/RaceTrack3D.tscn](file:///c:/Users/Pongo/OneDrive/Documents/racing/scenes/race/RaceTrack3D.tscn#L43-L119) under `TrackColliders/RoadSurfacesCollision`.
  - **Type**: `ConcavePolygonShape3D` (Trimesh).
  - **Complexity**: 63,703 triangles.
  - **Evaluation**: Trimesh collision accurately matches the visual elevation, ramps, overpasses, and banked turns of the city map.
- **Barriers & Props**:
  - `PropsCollision`: Trimesh (18,290 triangles).
  - `PillarsAndPolesCollision`: Trimesh (106,312 triangles).
  - Perimeter Boundaries: 4 BoxShape3D walls (`BoundaryNorth`, `BoundarySouth`, `BoundaryWest`, `BoundaryEast`).
  - Fall-through Safety Net: `BottomSafetyNet` at $Y = -20$.
- **Ramps and Incline Angles**:
  - Track ramps range from 6 degrees to 28 degrees.
  - Seam transitions between flat segments and inclines exhibit coplanar vertex alignments. In the current `CharacterBody3D` setup, bumper collision snagging was avoided by raising collider clearance to $0.08$ m and bevelling the collider front (ski-ramp profile). In a true raycast/shapecast suspension setup, wheels glide smoothly over these seams without chassis contact.

---

## 6. Concrete Root Causes (With File and Line Number References)

### Issue 1: Velocity Overwritten Every Frame
- **File**: [scripts/race/RaceCar3D.gd](file:///c:/Users/Pongo/OneDrive/Documents/racing/scripts/race/RaceCar3D.gd)
- **Lines**: 825, 827-829
- **Concrete Mechanism**:
  ```gdscript
  if is_on_floor():
      var floor_n = get_floor_normal()
      var slope_fwd = new_fwd_dir.slide(floor_n).normalized()
      var slope_right = new_right_dir.slide(floor_n).normalized()
      velocity = slope_fwd * current_fwd_speed + slope_right * current_lat_speed
  else:
      velocity.x = new_fwd_dir.x * current_fwd_speed + new_right_dir.x * current_lat_speed
      velocity.z = new_fwd_dir.z * current_fwd_speed + new_right_dir.z * current_lat_speed
      velocity.y -= gravity * safe_delta
  ```
- **Consequence**: Bypasses Newton's second law ($F = m \cdot a$). External impulses, natural collisions, kinetic energy transfer, and inertia are obliterated every physics frame.

### Issue 2: Direct Modification of Transform During Simulation
- **File**: [scripts/race/RaceCar3D.gd](file:///c:/Users/Pongo/OneDrive/Documents/racing/scripts/race/RaceCar3D.gd)
- **Lines**: 800-801, 856, 862
- **Concrete Mechanism**:
  ```gdscript
  position += rear_offset - rear_offset.rotated(transform.basis.y, delta_yaw)
  transform.basis = transform.basis.rotated(transform.basis.y, delta_yaw).orthonormalized()
  ...
  global_transform.basis = global_transform.basis.slerp(target_basis, clampf(safe_delta * align_rate, 0.0, 1.0)).orthonormalized()
  ...
  global_transform.basis = global_transform.basis.slerp(air_basis, clampf(safe_delta * 4.0, 0.0, 1.0)).orthonormalized()
  ```
- **Consequence**: The vehicle's orientation is artificially forced via trigonometric `slerp` towards ground normals or flat air headings instead of reacting dynamically to wheel contact forces. This causes the car to snap or float unnaturally when traversing sudden grade changes.

### Issue 3: Artificial and Dual Gravity
- **File**: [scripts/race/RaceCar3D.gd](file:///c:/Users/Pongo/OneDrive/Documents/racing/scripts/race/RaceCar3D.gd)
- **Lines**: 23, 829
- **Concrete Mechanism**:
  `@export var gravity: float = 28.0` is manually subtracted from `velocity.y` when `!is_on_floor()`. When `is_on_floor()`, gravity along the slope vector ($g \cdot \sin\theta$) is ignored completely.
- **Consequence**: Gravity does not assist vehicle acceleration downhill or impede uphill progress realistically.

### Issue 4: Artificial Downhill Speed Clamping & Scrub
- **File**: [scripts/race/RaceCar3D.gd](file:///c:/Users/Pongo/OneDrive/Documents/racing/scripts/race/RaceCar3D.gd)
- **Lines**: 752-753, 808-814
- **Concrete Mechanism**:
  ```gdscript
  if current_fwd_speed > max_speed:
      current_fwd_speed = max_speed
  ```
  And cornering scrub manually reduces speed down to a hardcoded `scrub_floor = 24.2` m/s.
- **Consequence**: The car cannot exceed $34$ m/s ($122.4$ km/h) even when plummeting down a 25-degree ramp under full throttle.

### Issue 5: Single-Point Center Ground Probe Raycast
- **File**: [scripts/race/RaceCar3D.gd](file:///c:/Users/Pongo/OneDrive/Documents/racing/scripts/race/RaceCar3D.gd)
- **Lines**: 840-848
- **Concrete Mechanism**:
  A single vertical ray query from $Y = +0.5$ to $Y = -1.2$ at the vehicle root origin.
- **Consequence**: Only samples ground directly under the chassis center. Individual wheel contact is non-existent; one wheel mounting a curb or obstacle produces zero chassis roll or suspension reaction.

### Issue 6: Timestep Divergence and Physics Micro-Stutter
- **File**: [scripts/race/RaceTrack3D.gd](file:///c:/Users/Pongo/OneDrive/Documents/racing/scripts/race/RaceTrack3D.gd)
- **Lines**: 103, 105, 179
- **Concrete Mechanism**:
  `_update_chase_camera(delta)` is executed in `_process(delta)` (variable display refresh rate) while `RaceCar3D` advances in `_physics_process(delta)` (fixed 60 Hz). `physics_interpolation` is disabled in `project.godot`.
- **Consequence**: Produces visual jitter and camera stutter when the camera interpolates towards a vehicle whose transform only updates at fixed 60 Hz intervals.

### Issue 7: Hardcoded Vehicle Strings and Asset Coupling
- **File**: [scripts/race/RaceCar3D.gd](file:///c:/Users/Pongo/OneDrive/Documents/racing/scripts/race/RaceCar3D.gd)
- **Lines**: 44-144 (`SUSPENSION_CONFIGS`), 147-168 (`MODEL_BASE_YAW_DEG`), 332-340 (`get_suspension_config`), 374-381 (`_load_visual_car_model`)
- **Consequence**: Adding, swapping, or deleting a car requires modifying code in `RaceCar3D.gd` in at least 4 distinct locations. This directly violates the core requirement of data-driven architecture.

### Issue 8: Fragile String Matching for Visual Nodes
- **File**: [scripts/race/RaceCar3D.gd](file:///c:/Users/Pongo/OneDrive/Documents/racing/scripts/race/RaceCar3D.gd)
- **Lines**: 400-430, 466-483, 587-596, 600-608, 662-685
- **Consequence**: Massive recursive string searches for node names like `"Body"`, `"wheel_fl"`, `"rim"`, etc. If an authored asset uses different nomenclature, wheels are not detected and the script executes an arbitrary mesh cloning fallback (lines 632-658).

---

## 7. Compatibility Matrix (Existing Features to Preserve)

| Feature | Dependent File / Node | Required Interface / Contract | Post-Overhaul Preservation Strategy |
| :--- | :--- | :--- | :--- |
| **Speedometer HUD** | [scripts/race/RaceTrack3D.gd](file:///c:/Users/Pongo/OneDrive/Documents/racing/scripts/race/RaceTrack3D.gd#L68) | Signal: `car.speed_changed(kmh: float)` | Emitted by `VehiclePhysicsCore` every physics tick with true airspeed in km/h. |
| **Race Finish Logic** | [scripts/race/RaceTrack3D.gd](file:///c:/Users/Pongo/OneDrive/Documents/racing/scripts/race/RaceTrack3D.gd#L221) | Property: `car.is_active = false` | Disables player input while physics continues naturally to a stop. |
| **Chase Camera Heading** | [scripts/race/RaceTrack3D.gd](file:///c:/Users/Pongo/OneDrive/Documents/racing/scripts/race/RaceTrack3D.gd#L123-L129) | Properties: `car.rotation.y`, `car.global_position`, `car.forward_speed`, `car.current_steer_angle`, `car.max_steer_angle` | Exposed cleanly on `VehiclePhysicsCore`. |
| **Checkpoints & Laps** | [scripts/race/RaceTrack3D.gd](file:///c:/Users/Pongo/OneDrive/Documents/racing/scripts/race/RaceTrack3D.gd#L87-L95) | `Area3D.body_entered` with `body == car` | Vehicle body is on Collision Layer 2. |
| **Track & Barrier Collisions** | `TrackColliders` StaticBody3D (Layer 1) | Collision Mask: 1 | Vehicle body and wheel raycasts collide with Layer 1. |
| **Player Profile & Garage** | [scripts/core/player_profile.gd](file:///c:/Users/Pongo/OneDrive/Documents/racing/scripts/core/player_profile.gd#L29-L30) | Car identifier string (e.g., `"sedan"`, `"mclaren"`, etc.) | Maintained via `VehicleRegistry` mapping car string IDs to `VehicleConfig` `.tres` resources. |
| **Fullscreen Hotkey** | [scripts/core/player_profile.gd](file:///c:/Users/Pongo/OneDrive/Documents/racing/scripts/core/player_profile.gd#L124-L132) | `F11` key | Preserved in Autoload. |
| **Restart & Return Home** | [scripts/race/RaceTrack3D.gd](file:///c:/Users/Pongo/OneDrive/Documents/racing/scripts/race/RaceTrack3D.gd#L286-L342) | `get_tree().reload_current_scene()` and scene switching | Fully decoupled; no persistent singleton physics leaks. |

---

## 8. Summary & Gate to Fase 1

Fase 0 Audit is complete. The system currently suffers from:
1. `CharacterBody3D` artificial kinematics pretending to be physics.
2. Complete absence of mass, inertia, and 4-wheel independent spring forces.
3. Rigid transform overwriting and artificial downhill velocity clamping.
4. Tightly-coupled hardcoded dictionaries requiring code edits for every car asset change.

### Proposed Architecture for Fase 1:
- `VehicleConfig` (Custom Resource `.tres`): Pure data defining mass, power, tire friction, suspension stiffness, damping, roll bars, and visual mesh offsets.
- `VehiclePhysicsCore` (`RigidBody3D`): 100% universal physics solver. Zero car names. 4 raycast/shapecast independent suspension units with Pacejka tire friction ellipse.
- `VehicleVisualAdapter`: Non-intrusive runtime adapter binding wheels and body without altering original mesh files.
- `VehicleRegistry`: Central data registry mapping IDs to `VehicleConfig`.
- `VehicleCollisionBuilder`: Procedural chassis convex hull generated from mesh bounds with anti-seam chamfers.

**Status**: Fase 0 Complete. Awaiting authorization to proceed to Fase 1.

