class_name Stone
extends RigidBody2D

@export var p1_color: Color = Color.WHITE
@export var p2_color: Color = Color.BLACK

@onready var polygon_2d: Polygon2D = $Polygon2D
var team: String = ""

# How far (in world units) the "wall" extends beyond the stone's actual shape.
# Bigger = more forgiving enclosures. Smaller = tighter walls.
@export var paint_radius: float = 0.0


func _ready():
	if (Global.is_black_turn):
		polygon_2d.self_modulate = p1_color
		team = "White"
		add_to_group("White")
	else:
		polygon_2d.self_modulate = p2_color
		team = "Black"
		add_to_group("Black")
	
	#Global.is_black_turn = !Global.is_black_turn
	sleeping = false
	
	StoneManager.register_stone(self)

func _physics_process(_delta: float) -> void:
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
