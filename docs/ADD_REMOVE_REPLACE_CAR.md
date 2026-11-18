# GUIDE: ADDING, REPLACING, AND REMOVING VEHICLES
**Project**: Sunset Street Racing
**Architecture**: 100% Data-Driven Universal Physics

---

## 1. Principles
The vehicle physics engine (`res://vehicles/core/`) is completely universal and decoupled. 
- You NEVER need to write GDScript code to add a car.
- You NEVER need to modify `VehiclePhysicsCore.gd` or `VehicleVisualAdapter.gd`.
- Every car is defined solely by a `.tres` (Resource) file placed in `res://vehicles/configs/` and its 3D model scene in `res://assets/models/cars/`.

---

## 2. How to Add a New Car

### Step 1: Place 3D Model Prefab
Place your `.tscn` model scene inside `res://assets/models/cars/car_<your_car_id>.tscn`.
The model should contain:
- A root `Node3D`.
- A `Body` Node3D containing the car body meshes.
- Four wheel nodes: `Wheel_FL`, `Wheel_FR`, `Wheel_RL`, `Wheel_RR`.
  - Vehicle forward direction is along `-Z`.
  - Vehicle right is along `+X`.
  - Vehicle up is along `+Y`.

### Step 2: Create VehicleConfig (.tres)
Create a new file `res://vehicles/configs/<your_car_id>.tres` in the Godot Inspector (or duplicate an existing `.tres` in `vehicles/configs/`).
Configure the properties:
- `id`: `<your_car_id>` (lowercase string, e.g. `corvette`)
- `display_name`: Human-readable name (e.g. `Corvette Stingray`)
- `vehicle_class`: Class name (e.g. `Sport`, `Hypercar`, `Muscle`, `Offroad`)
- `mass`: Vehicle mass in kilograms (e.g. `1450.0`)
- `wheelbase`: Distance from front axle to rear axle in meters (e.g. `2.72`)
- `track_width_front` & `track_width_rear`: Width between left and right wheel centers (e.g. `1.60`)
- `wheel_radius`: Tire radius in meters (e.g. `0.34`)
- `peak_power_kw`: Engine maximum power in kilowatts (e.g. `340.0`)
- `drivetrain_type`: `0` for FWD, `1` for RWD, `2` for AWD
- `visual_scene_path`: `res://assets/models/cars/car_<your_car_id>.tscn`

### Step 3: Validate Contract
Run the automated validation tool from terminal:
```powershell
godot --headless --script "res://vehicles/tools/validate_vehicle.gd"
```
Or validate your specific car:
```powershell
godot --headless --script "res://vehicles/tools/validate_vehicle.gd" -- <your_car_id>
```
If the test reports `PASSED`, your vehicle is fully ready.

---

## 3. How to Replace an Existing Car Asset
1. Replace or update the `.tscn` file at `res://assets/models/cars/car_<car_id>.tscn`.
2. Ensure the four wheel nodes (`Wheel_FL`, `Wheel_FR`, `Wheel_RL`, `Wheel_RR`) exist in the new model.
3. Open `res://vehicles/configs/<car_id>.tres` and adjust dimensions (`wheelbase`, `track_width`, `wheel_radius`) to match the new visual model.
4. Run `godot --headless --script "res://vehicles/tools/validate_vehicle.gd"`.
Zero physics code modified.

---

## 4. How to Remove a Car
1. Delete `res://vehicles/configs/<car_id>.tres`.
2. (Optional) Delete `res://assets/models/cars/car_<car_id>.tscn`.
3. If the car was registered in player save profiles, `VehicleRegistry` will automatically fall back to `sedan` without crashing.

