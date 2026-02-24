extends Area2D

@export var zone_collision_shape: CollisionShape2D

@export var CaptureManager: Node

func _ready() -> void:
	# Connect to the Global signal we renamed in the last step
	Global.zone_radius_changed.connect(_on_zone_radius_changed)
	
	# Initial sync with the current Global state
	_on_zone_radius_changed(Global.zone_radius)

func _on_zone_radius_changed(new_radius: float) -> void:
	if zone_collision_shape and zone_collision_shape.shape is CircleShape2D:
		# We must ensure we are modifying a UNIQUE resource so 
		# other circles in the game don't accidentally resize too.
		zone_collision_shape.shape.radius = new_radius
	else:
		push_warning("Zone collision shape is missing or not a CircleShape2D!")

# This function is now a "Query" that the C# Manager can use
# to see if a stone has drifted too far.
func is_point_inside(global_pos: Vector2) -> bool:
	return global_pos.length() <= Global.zone_radius
