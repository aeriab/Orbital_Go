class_name Stone
extends RigidBody2D

@export var p1_color: Color = Color.WHITE
@export var p2_color: Color = Color.BLACK

@onready var polygon_2d: Polygon2D = $Polygon2D
@onready var red_indicator_polygon_2d: Polygon2D = $RedIndicatorPolygon2D

var team: String = ""

# How far (in world units) the "wall" extends beyond the stone's actual shape.
# Bigger = more forgiving enclosures. Smaller = tighter walls.
@export var paint_radius: float = 0.0

# --- Out-of-Bounds / Game Over ---
@export var finish_min_velocity: float = 10.0
@export var finish_time_limit: float = 3.0

var _finish_timer: float = 0.0
var _base_color: Color

func _ready():
	if (Global.is_black_turn):
		polygon_2d.self_modulate = p1_color
		_base_color = p1_color
		team = "White"
		add_to_group("White")
	else:
		polygon_2d.self_modulate = p2_color
		_base_color = p2_color
		team = "Black"
		add_to_group("Black")
	
	Global.is_black_turn = !Global.is_black_turn
	sleeping = false
	
	StoneManager.register_stone(self)

func _physics_process(delta: float) -> void:
	_update_finish_timer(delta)
	
	if not freeze:
		apply_central_force(stone_acceleration(global_position))
	

func stone_acceleration(pos: Vector2) -> Vector2:
	return pos.direction_to(Vector2.ZERO) * Global.gravity * 100

func on_captured() -> void:
	StoneManager.unregister_stone(self)
	queue_free()
	# TODO
	# Other audio, particles, and points for capture

# Returns this stone's shape polygon in world-space coordinates.
# StoneManager calls this when painting onto the grid.
func get_world_polygon() -> PackedVector2Array:
	var local_points = polygon_2d.polygon
	var world_points = PackedVector2Array()
	for point in local_points:
		# Transform from Polygon2D local space → world space
		world_points.append(polygon_2d.global_transform * point)
	return world_points



# --- Out-of-Bounds Timer ---
# When a stone drifts outside the play zone and slows down,
# a timer starts. If it stays out for finish_time_limit seconds,
# the game ends. The stone pulses increasingly red as a warning.
func _update_finish_timer(delta: float) -> void:
	var is_outside = global_position.length() > Global.finish_radius
	var is_slow = linear_velocity.length() < finish_min_velocity
	if is_outside and is_slow:
		_finish_timer += delta
	elif not is_outside:
		_finish_timer = 0.0
	# Visual warning: lerp toward red based on how close to game over
	if _finish_timer > 0.0:
		var danger = clampf(_finish_timer / finish_time_limit, 0.0, 1.0)
		# Blend base color → red, and pulse using a sine wave that
		# speeds up as danger increases
		var pulse_speed = lerpf(0.5, 2.0, danger)
		var pulse = (1.0 + sin(Time.get_ticks_msec() * 0.001 * pulse_speed * TAU)) * 0.5
		var swell: float = lerpf(0.0, danger, pulse)
		red_indicator_polygon_2d.color.a = swell
		#polygon_2d.self_modulate = _base_color.lerp(Color.RED, swell)
	else:
		red_indicator_polygon_2d.color.a = 0
		#polygon_2d.self_modulate = _base_color

	if _finish_timer >= finish_time_limit:
		print("GAME OVER!!!!")
		# TODO: signal to a game manager, show UI, etc.
