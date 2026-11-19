class_name VehicleConfig
extends Resource

## World-scale factor aligning 1:1 metric car specs with the 1.48x CityMap track & props.
const WORLD_SCALE: float = 1.48

# Universal Data-Driven Vehicle Configuration.
# Holds all physical, powertrain, suspension, tire, and visual parameters
# for any vehicle in the game without writing custom physics code.

var _world_scale_applied: float = 1.0

func get_world_scale() -> float:
	return _world_scale_applied

func create_world_scaled_copy(target_scale: float = WORLD_SCALE) -> VehicleConfig:
	if absf(_world_scale_applied - 1.0) > 0.01 or absf(target_scale - 1.0) <= 0.001:
		return self
	var c := duplicate(false) as VehicleConfig
	var s := target_scale
	var inv_sqrt_s := 1.0 / sqrt(s)
	c._world_scale_applied = s
	c.wheelbase *= s
	c.track_width_front *= s
	c.track_width_rear *= s
	c.chassis_size *= s
	c.chassis_offset *= s
	c.center_of_mass_offset *= s
	c.ground_clearance_chamfer *= s
	c.suspension_rest_length *= s
	c.suspension_travel *= s
	c.spring_stiffness_front /= s
	c.spring_stiffness_rear /= s
	c.bump_damping_front *= inv_sqrt_s
	c.bump_damping_rear *= inv_sqrt_s
	c.rebound_damping_front *= inv_sqrt_s
	c.rebound_damping_rear *= inv_sqrt_s
	c.bump_stop_stiffness /= s
	c.bump_stop_damping *= inv_sqrt_s
	c.wheel_radius *= s
	c.wheel_width *= s
	c.final_drive_ratio *= s
	c.front_brake_torque *= s
	c.rear_brake_torque *= s
	c.handbrake_torque *= s
	c.visual_scale *= s
	c.visual_offset *= s
	return c

@export_group("Identification")
@export var id: String = "sedan"
@export var display_name: String = "Sedan"
@export var vehicle_class: String = "Standard"

@export_group("Mass & Dimensions")
@export var mass: float = 1350.0
@export var center_of_mass_offset: Vector3 = Vector3(0.0, -0.42, -0.05)
@export var moment_of_inertia_scale: Vector3 = Vector3(1.0, 1.0, 1.0)
@export var wheelbase: float = 2.65
@export var track_width_front: float = 1.60
@export var track_width_rear: float = 1.60
@export var chassis_size: Vector3 = Vector3(1.85, 0.85, 4.40)
@export var chassis_offset: Vector3 = Vector3(0.0, 0.50, 0.0)
@export var ground_clearance_chamfer: float = 0.10

@export_group("Powertrain")
# Drivetrain: 0 = FWD, 1 = RWD, 2 = AWD
@export_enum("FWD", "RWD", "AWD") var drivetrain_type: int = 1
@export var peak_power_kw: float = 220.0
@export var max_engine_rpm: float = 7000.0
@export var idle_engine_rpm: float = 850.0
@export var peak_torque_rpm: float = 4200.0
@export var gear_ratios: Array[float] = [3.65, 2.25, 1.55, 1.18, 0.95, 0.78]
@export var reverse_gear_ratio: float = 3.40
@export var final_drive_ratio: float = 3.75
@export var shift_time_seconds: float = 0.18

@export_group("Brakes")
@export var front_brake_torque: float = 3000.0
@export var rear_brake_torque: float = 1800.0
@export var handbrake_torque: float = 2600.0

@export_group("Steering")
@export var max_steer_angle_deg: float = 34.0
@export var min_steer_angle_deg: float = 12.0
@export var high_speed_steer_angle_deg: float = 5.4
@export var steer_speed: float = 6.4
@export var return_speed: float = 11.5
@export var counter_steer_speed: float = 18.0
@export var ackermann_factor: float = 0.85
@export_range(0.0, 1.0) var stability_assist: float = 0.82

@export_group("Suspension Geometry & Spring")
@export var suspension_rest_length: float = 0.32
@export var suspension_travel: float = 0.16
@export var spring_stiffness_front: float = 34000.0
@export var spring_stiffness_rear: float = 32000.0
@export var bump_damping_front: float = 3000.0
@export var bump_damping_rear: float = 2900.0
@export var rebound_damping_front: float = 5800.0
@export var rebound_damping_rear: float = 5600.0
@export var anti_roll_front: float = 6800.0
@export var anti_roll_rear: float = 6000.0
@export var bump_stop_stiffness: float = 28000.0
@export var bump_stop_damping: float = 4500.0

@export_group("Wheel & Tire Dynamics")
@export var wheel_radius: float = 0.34
@export var wheel_width: float = 0.24
@export var wheel_mass: float = 22.0
@export var tire_longitudinal_friction: float = 1.65
@export var tire_lateral_friction: float = 1.70
@export var slip_angle_peak_deg: float = 7.5
@export var slip_ratio_peak: float = 0.12
@export var rolling_resistance_coeff: float = 0.015

@export_group("Aerodynamics")
@export var drag_coefficient: float = 0.32
@export var frontal_area: float = 2.15
@export var downforce_coefficient: float = 0.30

@export_group("Visual Asset")
@export var visual_scene_path: String = "res://assets/models/cars/car_sedan.tscn"
@export var visual_scale: Vector3 = Vector3(1.0, 1.0, 1.0)
@export var visual_offset: Vector3 = Vector3.ZERO
@export var visual_yaw_offset_deg: float = 0.0

@export_group("Visual Node Mappings (Optional Overrides)")
@export var fl_wheel_node_path: String = ""
@export var fr_wheel_node_path: String = ""
@export var rl_wheel_node_path: String = ""
@export var rr_wheel_node_path: String = ""
@export var body_node_path: String = ""

# Validates configuration parameters and returns error strings
func validate() -> Array[String]:
	var errors: Array[String] = []
	if id.strip_edges().is_empty():
		errors.append("Vehicle id cannot be empty.")
	if mass < 1100.0 or mass > 1600.0:
		errors.append("Mass (%f) must be between 1100.0 and 1600.0 kg." % mass)
	if center_of_mass_offset.y < -0.55 or center_of_mass_offset.y > -0.30:
		errors.append("Center of mass Y offset (%f) must be between -0.55 and -0.30 m." % center_of_mass_offset.y)
	if suspension_travel < 0.12 or suspension_travel > 0.22:
		errors.append("Suspension travel (%f) must be between 0.12 and 0.22 m." % suspension_travel)
	if suspension_rest_length < 0.20 or suspension_rest_length > 0.45:
		errors.append("Suspension rest length (%f) must be between 0.20 and 0.45 m." % suspension_rest_length)
	if wheelbase <= 0.8 or wheelbase > 10.0:
		errors.append("Wheelbase (%f) must be between 0.8 and 10.0 m." % wheelbase)
	if track_width_front <= 0.5 or track_width_rear <= 0.5:
		errors.append("Track width must be greater than 0.5 m.")
	if peak_power_kw <= 10.0:
		errors.append("Peak power must be greater than 10.0 kW.")
	if gear_ratios.is_empty():
		errors.append("Gear ratios array must contain at least one gear.")
	if spring_stiffness_front <= 1000.0 or spring_stiffness_rear <= 1000.0:
		errors.append("Suspension spring stiffness must be greater than 1000.0 N/m.")
	if wheel_radius <= 0.1 or wheel_radius > 1.5:
		errors.append("Wheel radius (%f) must be between 0.1 and 1.5 m." % wheel_radius)
	if tire_longitudinal_friction <= 0.1 or tire_lateral_friction <= 0.1:
		errors.append("Tire friction coefficients must be positive.")
	if visual_scene_path.strip_edges().is_empty():
		errors.append("visual_scene_path must be specified.")
	elif not ResourceLoader.exists(visual_scene_path):
		errors.append("visual_scene_path does not exist: " + visual_scene_path)
	return errors

