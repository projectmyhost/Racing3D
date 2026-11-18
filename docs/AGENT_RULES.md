# AGENT CODING RULES & CONSTRAINTS
**Project**: Sunset Street Racing (Godot 4.7)

---

## 1. Absolute Rules for AI Coding Agents
1. **NEVER Modify Physics Core for Vehicle Asset Changes**:
   Adding, editing, or deleting cars MUST be done exclusively in `res://vehicles/configs/*.tres` and `res://assets/models/cars/*.tscn`. Under no circumstances should you edit `res://vehicles/core/VehiclePhysicsCore.gd`, `VehicleVisualAdapter.gd`, or `VehicleCollisionBuilder.gd` to accommodate a specific car model.
2. **ZERO Double-Slash (//) Comments**:
   Never write code comments using double forward slashes (`//`) in any GDScript or shader file. In GDScript, only use hash (`#`).
3. **ZERO Emojis in Code and Documentation**:
   Never insert emoji symbols in code, comments, or documentation files.
4. **NEVER Override Linear Velocity Directly**:
   Do not overwrite `linear_velocity` or `transform` of `VehiclePhysicsCore` each frame. All motion must originate from physical forces applied via `apply_force()` or `apply_central_force()`.
5. **NEVER Implement Fake Animations in Place of Physics**:
   Do not manually tilt the chassis mesh with tweens or mathematical sine approximations to simulate roll/pitch. Body lean and wheel positions must derive dynamically from simulated suspension forces.
6. **Always Run Automated Tests Before Completing Work**:
   After making any change to vehicles or physics, execute:
   ```powershell
   godot --headless --script "res://vehicles/tools/validate_vehicle.gd"
   godot --headless --script "res://vehicles/tools/test_physics_simulation.gd"
   ```
   Never claim work is complete without demonstrating that both test suites report `VERIFICATION STATUS: SUCCESS`.

