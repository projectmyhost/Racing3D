extends CharacterBody2D
class_name RaceCar

signal collided_with_wall(impact_strength: float)
signal checkpoint_passed(car: RaceCar, checkpoint_idx: int)
signal wrong_way_changed(car: RaceCar, is_wrong_way: bool)
signal lap_completed(car: RaceCar, lap_num: int, lap_time: float)
signal race_finished(car: RaceCar, total_time: float, best_lap: float)

@export var is_player: bool = false
@export var car_id: String = "starter_gt"
@export var driver_name: String = "Player"

# Physics parameters
var max_speed: float = 520.0
var accel_rate: float = 380.0
var brake_rate: float = 550.0
var reverse_max_speed: float = 180.0
var drag_coeff: float = 140.0
var steer_speed: float = 3.0
var drift_grip: float = 8.5 # Lateral grip recovery

# Current state
var current_speed: float = 0.0 # Forward speed
var lateral_velocity: Vector2 = Vector2.ZERO
var input_steer: float = 0.0
var input_throttle: float = 0.0 # -1 (brake/reverse) to 1 (accelerate)
var is_drifting: bool = false
var had_collision: bool = false
var is_active: bool = false # Enabled after 3-2-1-GO

# Race progress
var current_lap: int = 1
var max_laps: int = 2
var next_checkpoint_idx: int = 0
var total_checkpoints_count: int = 0
var checkpoints_passed_total: int = 0
var wrong_way: bool = false
var is_finished: bool = false

var current_lap_time: float = 0.0
var best_lap_time: float = 0.0
var total_time: float = 0.0
var lap_times: Array[float] = []

# AI Navigation
var waypoints: Array[Vector2] = []
var current_waypoint_idx: int = 0
var ai_difficulty: String = "normal"
var ai_speed_mult: float = 1.0

# Node references
var sprite: Sprite2D
var decal_sprite: Sprite2D
var collision_shape: CollisionShape2D
var engine_audio: AudioStreamPlayer2D

# Skid mark / drift effect
var skid_left: Line2D
var skid_right: Line2D
var _last_skid_pos_left: Vector2
var _last_skid_pos_right: Vector2

func _ready() -> void:
	_setup_nodes()
	_apply_car_stats()
	_setup_audio()

func _setup_nodes() -> void:
	# Car sprite
	sprite = Sprite2D.new()
	sprite.name = "Sprite"
	_load_car_texture()
	add_child(sprite)

	# Livery Decal overlay
	decal_sprite = Sprite2D.new()
	decal_sprite.name = "DecalSprite"
	decal_sprite.visible = false
	add_child(decal_sprite)

	# Collision Shape
	collision_shape = CollisionShape2D.new()
	collision_shape.name = "CollisionShape"
	var shape = CapsuleShape2D.new()
	shape.radius = 28.0
	shape.height = 110.0
	collision_shape.shape = shape
	add_child(collision_shape)

	# Set collision layer & mask
	collision_layer = 2 # Cars layer
	collision_mask = 1 | 2 # Collides with walls (1) and other cars (2)

func _load_car_texture() -> void:
	var tex_path = "res://assets/art/cars/car_top_starter.png"
	match car_id:
		"starter_gt":
			tex_path = "res://assets/art/cars/car_top_starter.png"
		"apex_cruiser":
			tex_path = "res://assets/art/cars/car_top_apex.png"
		"phantom_turbo":
			tex_path = "res://assets/art/cars/car_top_phantom.png"
	
	if ResourceLoader.exists(tex_path):
		sprite.texture = load(tex_path)
		# Normalize top-down car scale (140x280 -> scale down to ~60x120)
		sprite.scale = Vector2(0.48, 0.48)
		if decal_sprite:
			decal_sprite.scale = sprite.scale

func _setup_audio() -> void:
	engine_audio = AudioStreamPlayer2D.new()
	engine_audio.name = "EngineAudio"
	engine_audio.bus = "SFX" if AudioServer.get_bus_index("SFX") != -1 else "Master"
	engine_audio.max_distance = 1200.0
	
	var engine_sound_path = "res://assets/audio/engine.wav"
	if ResourceLoader.exists(engine_sound_path):
		var st = load(engine_sound_path)
		if st is AudioStreamWAV:
			st.loop_mode = AudioStreamWAV.LOOP_FORWARD
		engine_audio.stream = st
		engine_audio.volume_db = -12.0
		add_child(engine_audio)
		if is_player:
			engine_audio.play()

func _apply_car_stats() -> void:
	match car_id:
		"starter_gt":
			max_speed = 520.0
			accel_rate = 390.0
			brake_rate = 600.0
			drift_grip = 8.5
			steer_speed = 3.2
		"apex_cruiser":
			max_speed = 600.0
			accel_rate = 470.0
			brake_rate = 680.0
			drift_grip = 9.8
			steer_speed = 3.6
		"phantom_turbo":
			max_speed = 680.0
			accel_rate = 550.0
			brake_rate = 760.0
			drift_grip = 11.2
			steer_speed = 4.0
		_:
			max_speed = 520.0
			accel_rate = 400.0
			brake_rate = 600.0
			drift_grip = 8.5
			steer_speed = 3.2

	# AI adjustments based on difficulty
	if not is_player:
		match ai_difficulty:
			"easy":
				ai_speed_mult = 0.78
				steer_speed *= 0.85
			"normal":
				ai_speed_mult = 0.90
				steer_speed *= 0.95
			"hard":
				ai_speed_mult = 1.02
				steer_speed *= 1.05
		max_speed *= ai_speed_mult
		accel_rate *= ai_speed_mult

func apply_customization(paint_color: Color, decal_tex_path: String = "") -> void:
	if sprite:
		sprite.modulate = paint_color
	if decal_sprite and decal_tex_path != "" and ResourceLoader.exists(decal_tex_path):
		decal_sprite.texture = load(decal_tex_path)
		decal_sprite.visible = true

func _physics_process(delta: float) -> void:
	if not is_active:
		velocity = Vector2.ZERO
		return

	if not is_finished:
		current_lap_time += delta
		total_time += delta

	# Gather input
	if is_player:
		_process_player_input()
	else:
		_process_ai_input(delta)

	# Steering
	var sensitivity_mult = 1.0
	if is_player and has_node("/root/SaveManager"):
		var sm = get_node("/root/SaveManager")
		var sens = float(sm.get_setting("steering_sensitivity", 5))
		sensitivity_mult = 0.5 + (sens * 0.1) # 1.0 at 5, range 0.6 to 1.5

	# Turn car (car turns easier when moving)
	var speed_turn_factor = clampf(abs(current_speed) / (max_speed * 0.4), 0.1, 1.0)
	if current_speed < -10.0:
		# Invert steer in reverse
		speed_turn_factor = -speed_turn_factor

	rotation += input_steer * steer_speed * sensitivity_mult * speed_turn_factor * delta

	# Heading vectors (facing UP is forward in sprite)
	var forward_vec = Vector2.UP.rotated(rotation)
	var right_vec = Vector2.RIGHT.rotated(rotation)

	# Acceleration & Braking
	if input_throttle > 0.0:
		current_speed += accel_rate * input_throttle * delta
		current_speed = minf(current_speed, max_speed)
	elif input_throttle < 0.0:
		if current_speed > 10.0:
			# Braking
			current_speed += brake_rate * input_throttle * delta
		else:
			# Reversing
			current_speed += (accel_rate * 0.5) * input_throttle * delta
			current_speed = maxf(current_speed, -reverse_max_speed)
	else:
		# Passive drag / rolling friction
		if current_speed > 0.0:
			current_speed = maxf(0.0, current_speed - drag_coeff * delta)
		elif current_speed < 0.0:
			current_speed = minf(0.0, current_speed + drag_coeff * delta)

	# Forward velocity
	var target_forward_velocity = forward_vec * current_speed

	# Drift simulation: smoothly blend lateral drift into forward direction
	lateral_velocity = lateral_velocity.move_toward(Vector2.ZERO, drift_grip * delta * 50.0)
	var drift_slip = velocity.dot(right_vec)
	if abs(drift_slip) > 40.0:
		is_drifting = true
	else:
		is_drifting = false

	# Combine forward and drift
	velocity = target_forward_velocity + (lateral_velocity * 0.4)

	# Move and handle collisions
	var pre_vel = velocity
	move_and_slide()

	# Check collision against walls / barriers
	var col_count = get_slide_collision_count()
	if col_count > 0:
		for i in range(col_count):
			var col = get_slide_collision(i)
			var collider = col.get_collider()
			if collider is StaticBody2D or collider is TileMap or collider is TileMapLayer:
				had_collision = true
				var impact = pre_vel.length()
				if impact > 100.0:
					emit_signal("collided_with_wall", impact)
					# Wall bounce damping
					current_speed *= 0.65
					velocity = velocity.bounce(col.get_normal()) * 0.5
				break

	# Audio pitch modulation
	if engine_audio and engine_audio.playing:
		var speed_ratio = clampf(abs(current_speed) / max_speed, 0.0, 1.2)
		engine_audio.pitch_scale = lerpf(0.7, 1.8, speed_ratio)

func _process_player_input() -> void:
	input_steer = 0.0
	input_throttle = 0.0

	# Steer
	if Input.is_action_pressed("steer_left"):
		input_steer -= 1.0
	if Input.is_action_pressed("steer_right"):
		input_steer += 1.0

	# Auto-accelerate setting check
	var auto_accel = false
	if has_node("/root/SaveManager"):
		var sm = get_node("/root/SaveManager")
		auto_accel = bool(sm.get_setting("auto_accelerate", false))

	# Accelerate & Brake
	if Input.is_action_pressed("accelerate") or auto_accel:
		input_throttle += 1.0

	if Input.is_action_pressed("brake"):
		input_throttle = -1.0 # Brake overrides auto-accelerate

func _process_ai_input(delta: float) -> void:
	if waypoints.is_empty():
		input_throttle = 0.8
		input_steer = 0.0
		return

	var target_wp = waypoints[current_waypoint_idx]
	var to_target = target_wp - global_position
	var dist = to_target.length()

	# Advance waypoint if close
	if dist < 120.0:
		current_waypoint_idx = (current_waypoint_idx + 1) % waypoints.size()
		target_wp = waypoints[current_waypoint_idx]
		to_target = target_wp - global_position

	# Calculate angle to target
	var forward_vec = Vector2.UP.rotated(rotation)
	var desired_dir = to_target.normalized()
	var angle_diff = forward_vec.angle_to(desired_dir)

	# Steer towards target
	input_steer = clampf(angle_diff * 2.2, -1.0, 1.0)

	# Throttle control: brake on sharp corners
	if abs(angle_diff) > 0.8:
		# Sharp corner
		input_throttle = 0.35
	elif abs(angle_diff) > 0.4:
		# Medium corner
		input_throttle = 0.65
	else:
		# Straight
		input_throttle = 1.0

func notify_checkpoint(chk_idx: int) -> void:
	# Checkpoint validation
	var expected = next_checkpoint_idx
	if chk_idx == expected:
		# Valid forward checkpoint
		checkpoints_passed_total += 1
		next_checkpoint_idx = (next_checkpoint_idx + 1) % total_checkpoints_count
		if wrong_way:
			wrong_way = false
			emit_signal("wrong_way_changed", self, false)

		emit_signal("checkpoint_passed", self, chk_idx)

		# Check lap completion (cross finish line after passing all other checkpoints)
		if chk_idx == 0 and checkpoints_passed_total > 1:
			_on_lap_completed()

	elif chk_idx == (expected - 2 + total_checkpoints_count) % total_checkpoints_count:
		# Car passed a checkpoint backwards!
		if not wrong_way:
			wrong_way = true
			emit_signal("wrong_way_changed", self, true)

func _on_lap_completed() -> void:
	lap_times.append(current_lap_time)
	if best_lap_time <= 0.0 or current_lap_time < best_lap_time:
		best_lap_time = current_lap_time

	emit_signal("lap_completed", self, current_lap, current_lap_time)

	if current_lap >= max_laps:
		is_finished = true
		emit_signal("race_finished", self, total_time, best_lap_time)
	else:
		current_lap += 1
		current_lap_time = 0.0

func get_race_progress_score() -> float:
	# Continuous progress score for real-time race position calculation
	# Score = (lap * total_checkpoints + checkpoints_passed) + (1.0 - distance_to_next_checkpoint / 1000.0)
	var base_score = float(current_lap * 1000 + checkpoints_passed_total * 100)
	if waypoints.size() > 0 and next_checkpoint_idx < waypoints.size():
		var dist = global_position.distance_to(waypoints[next_checkpoint_idx])
		base_score -= clampf(dist * 0.1, 0.0, 99.0)
	return base_score

func get_speed_kmh() -> int:
	# Scale pixel velocity to arcade km/h readout
	return int(round(clampf(abs(current_speed) * 0.35, 0.0, 320.0)))
