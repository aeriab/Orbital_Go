class_name Stone
extends RigidBody2D

@export var p1_color: Color = Color.WHITE
@export var p2_color: Color = Color.BLACK

@export var p1_outline_color: Color
@export var p2_outline_color: Color

@export var stone_polygon_2d: Polygon2D
@export var outline_polygon_2d: Polygon2D
@export var red_indicator_polygon_2d: Polygon2D

var team: String = ""

# How far (in world units) the "wall" extends beyond the stone's actual shape.
# Bigger = more forgiving enclosures. Smaller = tighter walls.
@export var paint_radius: float = 0.0

# --- Out-of-Bounds / Game Over ---
@export var finish_min_velocity: float = 10.0
@export var finish_time_limit: float = 3.0
@export var finish_rate: float = 1.0

@export var spawn_immunity_time: float = 3.0
var is_immune: bool = true

var _finish_counter: float = 0.0

func _ready():
	
	if (Global.is_black_turn):
		stone_polygon_2d.color = p1_color
		outline_polygon_2d.color = p1_outline_color
		team = "White"
		add_to_group("White")
	else:
		stone_polygon_2d.color = p2_color
		outline_polygon_2d.color = p2_outline_color
		team = "Black"
		add_to_group("Black")
	
	Global.is_black_turn = !Global.is_black_turn
	sleeping = false
	
	StoneManager.register_stone(self)

func _physics_process(delta: float) -> void:
	
	if not freeze:
		apply_central_force(stone_acceleration(global_position))
		
		if (is_immune):
			spawn_immunity_time = spawn_immunity_time - delta
			if spawn_immunity_time <= 0.0:
				is_immune = false
		else:
			_update_finish_counter(delta)
	

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
	var local_points = stone_polygon_2d.polygon
	var world_points = PackedVector2Array()
	for point in local_points:
		# Transform from Polygon2D local space → world space
		world_points.append(stone_polygon_2d.global_transform * point)
	return world_points



# --- Out-of-Bounds Timer ---
# When a stone drifts outside the play zone and slows down,
# a timer starts. If it stays out for finish_time_limit seconds,
# the game ends. The stone pulses increasingly red as a warning.
func _update_finish_counter(delta: float) -> void:
	
	if (global_position.length() <= Global.finish_radius):
		# Decrease _finish_counter, inside of zone
		_finish_counter = max(_finish_counter - finish_rate * delta, 0)
	else:
		# Increase _finish_counter, outside of zone
		_finish_counter = min(_finish_counter + finish_rate * delta, finish_time_limit)
	
	var _finish_magnitude: float = _finish_counter / finish_time_limit
	red_indicator_polygon_2d.color.a = _finish_magnitude
	#var _finish_magnitude: float = _finish_counter / finish_time_limit
	#var swell: float = 0.5 + ((-0.5) * cos(15 * PI * _finish_magnitude * _finish_magnitude))
	#
	#red_indicator_polygon_2d.color.a = swell
	
	if (_finish_counter >= finish_time_limit) && Global.game_still_going:
		Global.game_still_going = false
		ending_stone_clear()
		PointManager.tally_score()
		# TODO: signal to a game manager, show UI, etc.
	
	
	


# Executes if this stone is the 
func ending_stone_clear() -> void:
	print(self)
	pass
