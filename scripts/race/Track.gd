extends Node2D
class_name Track

signal car_crossed_checkpoint(car: RaceCar, checkpoint_idx: int)

@export var track_id: String = "sunset_circuit"

var waypoints: Array[Vector2] = []
var checkpoints: Array[Area2D] = []
var grid_positions: Array[Transform2D] = []
var road_width: float = 240.0

# Node containers
var background_layer: CanvasItem
var road_layer: Node2D
var barrier_body: StaticBody2D
var checkpoints_container: Node2D
var decorations_container: Node2D

func _ready() -> void:
	_build_track()

func setup_track(id: String) -> void:
	track_id = id
	_build_track()

func _build_track() -> void:
	# Clear existing children
	for child in get_children():
		child.queue_free()
	
	checkpoints.clear()
	grid_positions.clear()

	_load_track_waypoints()

	# Create layers
	_create_background()
	_create_road_surface()
	_create_barriers()
	_create_checkpoints()
	_create_grid_positions()
	_create_finish_line()

func _load_track_waypoints() -> void:
	waypoints.clear()
	match track_id:
		"sunset_circuit":
			# Sweeping seaside Grand Prix circuit
			waypoints = [
				Vector2(1200, 1800), # 0 - Start / Finish Line
				Vector2(1700, 1800), # 1
				Vector2(2200, 1700), # 2 - Sweeping Turn 1
				Vector2(2550, 1400), # 3
				Vector2(2650, 950),  # 4 - Hill curve
				Vector2(2450, 550),  # 5
				Vector2(1950, 420),  # 6 - Back straight
				Vector2(1350, 420),  # 7
				Vector2(850, 600),   # 8 - Chicane entry
				Vector2(650, 950),   # 9 - Chicane apex
				Vector2(880, 1250),  # 10 - Chicane exit
				Vector2(750, 1600),  # 11 - Final curve to main straight
			]
		"harbor_run":
			# Technical industrial harbor docks circuit
			waypoints = [
				Vector2(1000, 1700), # 0 - Start / Finish Line
				Vector2(1600, 1700), # 1 - Harbor pier straight
				Vector2(2200, 1650), # 2 - Dock Turn 1
				Vector2(2300, 1250), # 3
				Vector2(2300, 750),  # 4 - Crane alley
				Vector2(1850, 500),  # 5 - North warehouse 90-degree
				Vector2(1400, 500),  # 6
				Vector2(1400, 950),  # 7 - Port hairpin
				Vector2(950, 950),   # 8
				Vector2(600, 650),   # 9 - Pier chicane
				Vector2(450, 1150),  # 10 - Coast bend
				Vector2(650, 1550),  # 11 - Entry to main straight
			]
		"neon_loop":
			# High-speed futuristic illuminated speedway
			waypoints = [
				Vector2(1100, 1750), # 0 - Start / Finish Line
				Vector2(1800, 1750), # 1 - Neon main straight
				Vector2(2350, 1650), # 2 - Banked curve East
				Vector2(2700, 1350), # 3
				Vector2(2700, 850),  # 4
				Vector2(2350, 550),  # 5
				Vector2(1700, 450),  # 6 - Upper neon straight
				Vector2(1000, 450),  # 7
				Vector2(450, 600),   # 8 - Banked curve West
				Vector2(200, 950),   # 9
				Vector2(200, 1350),  # 10
				Vector2(550, 1650),  # 11 - Final high-speed transition
			]
		_:
			# Fallback circuit
			waypoints = [
				Vector2(1200, 1800), Vector2(1800, 1800), Vector2(2400, 1500),
				Vector2(2500, 800), Vector2(1800, 500), Vector2(1000, 500),
				Vector2(600, 900), Vector2(650, 1600)
			]

func _create_background() -> void:
	# Large backdrop canvas item
	var bg = Polygon2D.new()
	bg.name = "BackgroundTerrain"
	bg.polygon = PackedVector2Array([
		Vector2(-1000, -1000),
		Vector2(4000, -1000),
		Vector2(4000, 3000),
		Vector2(-1000, 3000)
	])

	match track_id:
		"sunset_circuit":
			# Warm sunset turf & tarmac runoff
			bg.color = Color(0.09, 0.10, 0.15, 1.0) # Night/Sunset infield
		"harbor_run":
			# Concrete docks and navy harbor water
			bg.color = Color(0.07, 0.08, 0.12, 1.0)
		"neon_loop":
			# Cyberpunk dark grid floor
			bg.color = Color(0.05, 0.05, 0.08, 1.0)

	add_child(bg)

func _create_road_surface() -> void:
	road_layer = Node2D.new()
	road_layer.name = "RoadLayer"
	add_child(road_layer)

	# Closed loop points
	var loop_points = waypoints.duplicate()
	loop_points.append(waypoints[0])

	# 1. Outer Kerb / Shoulder Line (wider than asphalt)
	var kerb_line = Line2D.new()
	kerb_line.name = "KerbShoulder"
	kerb_line.points = PackedVector2Array(loop_points)
	kerb_line.width = road_width + 48.0
	kerb_line.joint_mode = Line2D.LINE_JOINT_ROUND
	kerb_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	kerb_line.end_cap_mode = Line2D.LINE_CAP_ROUND

	match track_id:
		"sunset_circuit":
			kerb_line.default_color = Color(0.78, 0.23, 0.26, 1.0) # Red racing kerb
		"harbor_run":
			kerb_line.default_color = Color(0.85, 0.65, 0.15, 1.0) # Industrial yellow kerb
		"neon_loop":
			kerb_line.default_color = Color(0.12, 0.78, 0.88, 1.0) # Cyan neon curb

	road_layer.add_child(kerb_line)

	# 2. White inner kerb stripe
	var kerb_white = Line2D.new()
	kerb_white.name = "KerbWhiteStripe"
	kerb_white.points = PackedVector2Array(loop_points)
	kerb_white.width = road_width + 24.0
	kerb_white.joint_mode = Line2D.LINE_JOINT_ROUND
	kerb_white.begin_cap_mode = Line2D.LINE_CAP_ROUND
	kerb_white.end_cap_mode = Line2D.LINE_CAP_ROUND
	kerb_white.default_color = Color(0.92, 0.92, 0.94, 1.0)
	road_layer.add_child(kerb_white)

	# 3. Main Asphalt Road Surface
	var asphalt = Line2D.new()
	asphalt.name = "AsphaltSurface"
	asphalt.points = PackedVector2Array(loop_points)
	asphalt.width = road_width
	asphalt.joint_mode = Line2D.LINE_JOINT_ROUND
	asphalt.begin_cap_mode = Line2D.LINE_CAP_ROUND
	asphalt.end_cap_mode = Line2D.LINE_CAP_ROUND
	
	# Asphalt color
	match track_id:
		"sunset_circuit":
			asphalt.default_color = Color(0.17, 0.18, 0.22, 1.0) # Smooth dark asphalt
		"harbor_run":
			asphalt.default_color = Color(0.14, 0.15, 0.19, 1.0) # Weathered concrete/tarmac
		"neon_loop":
			asphalt.default_color = Color(0.10, 0.11, 0.16, 1.0) # Dark neon asphalt

	# Use asphalt texture if available
	var asphalt_tex_path = "res://assets/art/tracks/track_asphalt.png"
	if ResourceLoader.exists(asphalt_tex_path):
		asphalt.texture = load(asphalt_tex_path)
		asphalt.texture_mode = Line2D.LINE_TEXTURE_TILE
		asphalt.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED

	road_layer.add_child(asphalt)

	# 4. Centerline dashed markings
	var centerline = Line2D.new()
	centerline.name = "Centerline"
	centerline.points = PackedVector2Array(loop_points)
	centerline.width = 6.0
	centerline.joint_mode = Line2D.LINE_JOINT_ROUND
	centerline.default_color = Color(1.0, 0.85, 0.2, 0.75) if track_id != "neon_loop" else Color(0.95, 0.25, 0.85, 0.85)
	road_layer.add_child(centerline)

func _create_barriers() -> void:
	barrier_body = StaticBody2D.new()
	barrier_body.name = "BarrierBody"
	barrier_body.collision_layer = 1 # Wall collision layer
	barrier_body.collision_mask = 2 # Cars collide with it
	add_child(barrier_body)

	var half_w = (road_width * 0.5) + 16.0
	var n = waypoints.size()

	# Generate outer and inner boundary segments
	for i in range(n):
		var p0 = waypoints[i]
		var p1 = waypoints[(i + 1) % n]
		var dir = (p1 - p0).normalized()
		var norm = Vector2(-dir.y, dir.x) # Normal perpendicular to forward

		# Outer barrier segment
		var outer_a = p0 + norm * half_w
		var outer_b = p1 + norm * half_w
		_add_barrier_segment(outer_a, outer_b)

		# Inner barrier segment
		var inner_a = p0 - norm * half_w
		var inner_b = p1 - norm * half_w
		_add_barrier_segment(inner_a, inner_b)

func _add_barrier_segment(a: Vector2, b: Vector2) -> void:
	var shape_owner = barrier_body.create_shape_owner(barrier_body)
	var seg = SegmentShape2D.new()
	seg.a = a
	seg.b = b
	barrier_body.shape_owner_add_shape(shape_owner, seg)

func _create_checkpoints() -> void:
	checkpoints_container = Node2D.new()
	checkpoints_container.name = "CheckpointsContainer"
	add_child(checkpoints_container)

	var n = waypoints.size()
	for i in range(n):
		var p0 = waypoints[i]
		var p1 = waypoints[(i + 1) % n]
		var forward = (p1 - p0).normalized()
		var normal = Vector2(-forward.y, forward.x)

		var area = Area2D.new()
		area.name = "Checkpoint_%d" % i
		area.position = p0
		area.rotation = forward.angle()
		area.collision_layer = 0
		area.collision_mask = 2 # Detects cars

		var col = CollisionShape2D.new()
		var rect = RectangleShape2D.new()
		# Width spans road, height is gate depth
		rect.size = Vector2(40.0, road_width + 40.0)
		col.shape = rect
		# Rotate rectangle to be perpendicular to forward direction
		col.rotation = PI * 0.5
		area.add_child(col)

		# Connect trigger signal
		var chk_idx = i
		area.body_entered.connect(func(body):
			if body is RaceCar:
				body.notify_checkpoint(chk_idx)
				emit_signal("car_crossed_checkpoint", body, chk_idx)
		)

		checkpoints_container.add_child(area)
		checkpoints.append(area)

func _create_finish_line() -> void:
	# Visual start/finish line banner across road at waypoint 0
	var p0 = waypoints[0]
	var p1 = waypoints[1]
	var forward = (p1 - p0).normalized()
	var normal = Vector2(-forward.y, forward.x)

	var finish_node = Node2D.new()
	finish_node.name = "FinishLineVisual"
	finish_node.position = p0
	finish_node.rotation = forward.angle() + (PI * 0.5)

	# Checkered banner across road
	var banner = Line2D.new()
	banner.points = PackedVector2Array([
		Vector2(-(road_width * 0.5), 0),
		Vector2(road_width * 0.5, 0)
	])
	banner.width = 36.0
	banner.default_color = Color(1.0, 1.0, 1.0, 0.95)

	var finish_tex_path = "res://assets/art/tracks/track_finish_line.png"
	if ResourceLoader.exists(finish_tex_path):
		banner.texture = load(finish_tex_path)
		banner.texture_mode = Line2D.LINE_TEXTURE_TILE
		banner.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED

	finish_node.add_child(banner)
	add_child(finish_node)

func _create_grid_positions() -> void:
	# Compute starting grid positions lined up behind finish line
	var p0 = waypoints[0]
	var p1 = waypoints[1]
	var forward = (p1 - p0).normalized()
	var normal = Vector2(-forward.y, forward.x)
	var car_rotation = forward.angle() + (PI * 0.5) # Facing forward

	# Staggered 2x2 grid behind finish line
	# Grid 1 (Pole): left side, 120px behind finish
	var g1_pos = p0 - (forward * 120.0) + (normal * 50.0)
	# Grid 2: right side, 160px behind finish
	var g2_pos = p0 - (forward * 160.0) - (normal * 50.0)
	# Grid 3: left side, 230px behind finish
	var g3_pos = p0 - (forward * 230.0) + (normal * 50.0)
	# Grid 4 (Player): right side, 270px behind finish
	var g4_pos = p0 - (forward * 270.0) - (normal * 50.0)

	var positions = [g1_pos, g2_pos, g3_pos, g4_pos]
	for pos in positions:
		var xform = Transform2D(car_rotation, pos)
		grid_positions.append(xform)

func get_grid_transform(grid_index: int) -> Transform2D:
	if grid_index >= 0 and grid_index < grid_positions.size():
		return grid_positions[grid_index]
	if grid_positions.size() > 0:
		return grid_positions[0]
	return Transform2D.IDENTITY

func get_checkpoints_count() -> int:
	return waypoints.size()
