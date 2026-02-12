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
@export var finish_rate: float = 1.0

var _finish_counter: float = 0.0

func _ready():
	if (Global.is_black_turn):
		polygon_2d.self_modulate = p1_color
		team = "White"
		add_to_group("White")
	else:
		polygon_2d.self_modulate = p2_color
		team = "Black"
		add_to_group("Black")
	
	Global.is_black_turn = !Global.is_black_turn
	sleeping = false
	
	StoneManager.register_stone(self)

func _physics_process(delta: float) -> void:
	_update_finish_counter(delta)
	
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
func _update_finish_counter(delta: float) -> void:
	if (global_position.length() <= Global.finish_radius):
		_finish_counter = max(_finish_counter - finish_rate * delta, 0)
	else:
		_finish_counter = min(_finish_counter + finish_rate * delta, finish_time_limit)
	
	var _finish_magnitude: float = _finish_counter / finish_time_limit
	var swell: float = 0.5 + ((-0.5) * cos(15 * PI * _finish_magnitude * _finish_magnitude))
	
	red_indicator_polygon_2d.color.a = swell
	
	if _finish_counter >= finish_time_limit:
		print("GAME OVER!!!!")
		# TODO: signal to a game manager, show UI, etc.
