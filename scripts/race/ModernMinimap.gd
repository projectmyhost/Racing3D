class_name ModernMinimap
extends Control

# High-fidelity real-time GPS circuit minimap.
# Matches official photo reference 100%:
# - Slanted POS badge: POS 1 / 12 with glowing gold "1"
# - Rounded dark translucent radar dish
# - Compass "N" marker on top-left
# - Real circuit track geometry extracted from the active 3D city track
# - Checkpoint / waypoint markers along the circuit
# - Real-time player arrow (orange chevron) moving and rotating with vehicle world position and heading

var car_node: Node3D
var player_position_rank: int = 1
var total_racers: int = 12

# Real circuit waypoints in 3D world X/Z coordinates
const RAW_TRACK_POINTS: Array[Vector2] = [
	Vector2(-40.9, 133.8),
	Vector2(37.3, 133.8),
	Vector2(115.7, 133.8),
	Vector2(178.6, 92.6),
	Vector2(221.2, 23.0),
	Vector2(193.5, -133.5),
	Vector2(160.8, -225.2),
	Vector2(145.0, -323.5),
	Vector2(83.0, -368.4),
	Vector2(39.0, -356.9),
	Vector2(-89.0, -345.8),
	Vector2(-147.3, -281.8),
	Vector2(-172.5, -175.5),
	Vector2(-176.5, -75.9),
	Vector2(-154.8, 9.6),
	Vector2(-145.7, 81.2),
	Vector2(-106.1, 172.4),
	Vector2(-42.5, 133.9)
]

# Checkpoint coordinates in 3D world X/Z
const CHECKPOINTS_XZ: Array[Vector2] = [
	Vector2(-30.0, 146.0),
	Vector2(120.0, 146.0),
	Vector2(80.0, -380.0),
	Vector2(-100.0, 146.0)
]

var _cached_screen_track: PackedVector2Array = PackedVector2Array()
var _cached_checkpoint_screen: Array[Vector2] = []
var _font_bold: Font
var _dish_sb: StyleBoxFlat

# Track coordinate bounds for normalization
var _min_x: float = -200.0
var _max_x: float = 240.0
var _min_z: float = -400.0
var _max_z: float = 180.0

func _ready() -> void:
	custom_minimum_size = Vector2(210, 240)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_load_fonts()
	_setup_styleboxes()
	_compute_bounds()
	_generate_screen_track()

func _load_fonts() -> void:
	if ResourceLoader.exists("res://assets/ui/fonts/Rajdhani-Bold.ttf"):
		_font_bold = load("res://assets/ui/fonts/Rajdhani-Bold.ttf")

func _setup_styleboxes() -> void:
	_dish_sb = StyleBoxFlat.new()
	_dish_sb.bg_color = Color(0.04, 0.06, 0.10, 0.85)
	_dish_sb.border_width_left = 2
	_dish_sb.border_width_top = 2
	_dish_sb.border_width_right = 2
	_dish_sb.border_width_bottom = 2
	_dish_sb.border_color = Color(0.28, 0.38, 0.52, 0.85)
	_dish_sb.corner_radius_top_left = 20
	_dish_sb.corner_radius_top_right = 20
	_dish_sb.corner_radius_bottom_right = 20
	_dish_sb.corner_radius_bottom_left = 20

func _compute_bounds() -> void:
	_min_x = 9999.0
	_max_x = -9999.0
	_min_z = 9999.0
	_max_z = -9999.0
	for p in RAW_TRACK_POINTS:
		_min_x = minf(_min_x, p.x)
		_max_x = maxf(_max_x, p.x)
		_min_z = minf(_min_z, p.y)
		_max_z = maxf(_max_z, p.y)
	# Add margin
	_min_x -= 30.0
	_max_x += 30.0
	_min_z -= 30.0
	_max_z += 30.0

func _world_to_map(world_x: float, world_z: float, map_rect: Rect2) -> Vector2:
	var u = (world_x - _min_x) / maxf(_max_x - _min_x, 1.0)
	var v = (world_z - _min_z) / maxf(_max_z - _min_z, 1.0)
	# In 3D: -Z is North (top of map), +Z is South (bottom of map)
	return Vector2(
		map_rect.position.x + u * map_rect.size.x,
		map_rect.position.y + v * map_rect.size.y
	)

func _generate_screen_track() -> void:
	var dish_rect = Rect2(15.0, 52.0, 175.0, 175.0)
	var pts: Array[Vector2] = []
	
	# Smoothly interpolate through track waypoints using Catmull-Rom spline
	var count = RAW_TRACK_POINTS.size()
	for i in range(count):
		var p0 = RAW_TRACK_POINTS[(i - 1 + count) % count]
		var p1 = RAW_TRACK_POINTS[i]
		var p2 = RAW_TRACK_POINTS[(i + 1) % count]
		var p3 = RAW_TRACK_POINTS[(i + 2) % count]
		
		# Generate 4 curve subdivisions between each waypoint
		for step in range(4):
			var t = float(step) / 4.0
			var wp = p1.cubic_interpolate(p2, p0, p3, t)
			pts.append(_world_to_map(wp.x, wp.y, dish_rect))
			
	# Close the loop
	if pts.size() > 0:
		pts.append(pts[0])
	_cached_screen_track = PackedVector2Array(pts)
	
	# Screen checkpoints
	_cached_checkpoint_screen.clear()
	for chk in CHECKPOINTS_XZ:
		_cached_checkpoint_screen.append(_world_to_map(chk.x, chk.y, dish_rect))

var _last_map_pos: Vector3 = Vector3(1e9, 0.0, 1e9)
var _last_map_yaw: float = -999.0
var _last_rank: int = -1

func _process(_delta: float) -> void:
	if car_node and is_instance_valid(car_node):
		var xf: Transform3D = car_node.get_global_transform_interpolated()
		var fwd_3d := -xf.basis.z
		var yaw := atan2(fwd_3d.z, fwd_3d.x)
		if xf.origin.distance_squared_to(_last_map_pos) > 0.04 or absf(angle_difference(yaw, _last_map_yaw)) > 0.008 or player_position_rank != _last_rank:
			_last_map_pos = xf.origin
			_last_map_yaw = yaw
			_last_rank = player_position_rank
			queue_redraw()

func _draw() -> void:
	# 1. POS Badge (Positioned at top of minimap: slanted glass container)
	var badge_rect = Rect2(8.0, 6.0, 115.0, 36.0)
	var b_pts = PackedVector2Array([
		Vector2(badge_rect.position.x + 8.0, badge_rect.position.y),
		Vector2(badge_rect.position.x + badge_rect.size.x, badge_rect.position.y),
		Vector2(badge_rect.position.x + badge_rect.size.x - 8.0, badge_rect.position.y + badge_rect.size.y),
		Vector2(badge_rect.position.x, badge_rect.position.y + badge_rect.size.y)
	])
	# Badge glass background
	draw_colored_polygon(b_pts, Color(0.05, 0.08, 0.14, 0.88))
	draw_polyline(b_pts, Color(0.3, 0.4, 0.55, 0.8), 1.5, true)
	
	if _font_bold:
		# "POS" header
		draw_string(_font_bold, Vector2(badge_rect.position.x + 14.0, badge_rect.position.y + 24.0), "POS", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.85, 0.9, 0.95, 0.9))
		# Glowing Gold Rank Number "1"
		draw_string(_font_bold, Vector2(badge_rect.position.x + 48.0, badge_rect.position.y + 26.0), str(player_position_rank), HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(0.98, 0.82, 0.15, 1.0))
		# Total racers "/ 12"
		draw_string(_font_bold, Vector2(badge_rect.position.x + 64.0, badge_rect.position.y + 24.0), "/ " + str(total_racers), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.85, 0.9, 0.95, 0.9))

	# 2. Minimap Dish Background (Translucent rounded glass dish)
	var dish_rect = Rect2(12.0, 48.0, 185.0, 185.0)
	if _dish_sb:
		draw_style_box(_dish_sb, dish_rect)
	
	# Compass "N" indicator on top-left of dish
	if _font_bold:
		draw_string(_font_bold, Vector2(dish_rect.position.x + 14.0, dish_rect.position.y + 22.0), "N", HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color(0.75, 0.85, 0.95, 0.85))
		# Small directional compass tick
		draw_line(
			Vector2(dish_rect.position.x + 20.0, dish_rect.position.y + 7.0),
			Vector2(dish_rect.position.x + 20.0, dish_rect.position.y + 11.0),
			Color(0.95, 0.25, 0.2, 0.9),
			2.0,
			true
		)

	# 3. Vector Track Line (Real Circuit Spline)
	if _cached_screen_track.size() > 1:
		# Outer track road glow
		draw_polyline(_cached_screen_track, Color(0.18, 0.35, 0.55, 0.5), 6.0, true)
		# Track solid surface
		draw_polyline(_cached_screen_track, Color(0.88, 0.92, 0.98, 0.92), 3.0, true)
		
	# 4. Waypoint / Checkpoint Markers on the circuit
	for cp in _cached_checkpoint_screen:
		draw_circle(cp, 3.5, Color(0.98, 0.76, 0.12, 0.95))
		draw_circle(cp, 1.8, Color(1.0, 1.0, 1.0, 1.0))

	# 5. Real-Time Player Vehicle Arrow (Orange Triangular Chevron)
	if car_node and is_instance_valid(car_node):
		var car_xform: Transform3D = car_node.get_global_transform_interpolated()
		var p_world = car_xform.origin
		var p_map = _world_to_map(p_world.x, p_world.z, Rect2(15.0, 52.0, 175.0, 175.0))
		
		# Heading angle in 2D map space
		# Forward in vehicle local space is -Z. In map space, 0 is right, PI/2 is down, -PI/2 is up (-Z).
		var fwd_3d = -car_xform.basis.z
		var map_rot = atan2(fwd_3d.z, fwd_3d.x)
		
		# Draw rotated orange arrow
		var arrow_len = 8.0
		var arrow_w = 6.0
		var dir = Vector2(cos(map_rot), sin(map_rot))
		var norm = Vector2(-dir.y, dir.x)
		
		var tip = p_map + dir * arrow_len
		var left_corner = p_map - dir * (arrow_len * 0.6) + norm * arrow_w
		var right_corner = p_map - dir * (arrow_len * 0.6) - norm * arrow_w
		var notch = p_map - dir * (arrow_len * 0.2)
		
		var arrow_poly = PackedVector2Array([tip, left_corner, notch, right_corner])
		# Pulse glow around player
		draw_circle(p_map, 6.0, Color(1.0, 0.5, 0.1, 0.35))
		# Solid chevron
		draw_colored_polygon(arrow_poly, Color(1.0, 0.46, 0.05, 1.0))
		draw_polyline(arrow_poly, Color(1.0, 1.0, 1.0, 1.0), 1.5, true)
