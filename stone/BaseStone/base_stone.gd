class_name BaseStone
extends Stone

@export_group("Internal References")
@export var collision_shape_2d: CollisionShape2D
@export var stone_polygon_2d: Polygon2D
@export var outline_polygon_2d: Polygon2D


var is_team_p1: bool = false
var is_tam_p2: bool = false

var center_points: Array[Vector2] = [Vector2(0,0)]

var radius: float = 23.0

func _ready() -> void:
	# Access radius properly from the actual shape
	if collision_shape_2d and collision_shape_2d.shape is CircleShape2D:
		radius = collision_shape_2d.shape.radius
	
	StoneManager.register_stone(self)

func apply_stone_type(data: StoneType) -> void:
	stone_polygon_2d.color = data.fill_color
	outline_polygon_2d.color = data.outline_color
	mass = data.mass_multiplier
	
	for team in data.valid_teams:
		add_to_group(team)

func _physics_process(_delta: float) -> void:
	# Child stones in a cluster have set_physics_process(false),
	# so this only runs for independent stones.
	if not freeze:
		apply_central_force(stone_acceleration(global_position))

func stone_acceleration(pos: Vector2) -> Vector2:
	return pos.direction_to(Vector2.ZERO) * Global.gravity * 100 * mass

func on_captured() -> void:
	if not stone_data or not stone_data.can_be_captured:
		return
		
	if stone_data.valid_teams.size() == 1:
		var victim_team = stone_data.valid_teams[0]
		var scoring_team = "P2" if victim_team == "P1" else "P1"
		Global.update_score(scoring_team, stone_data.point_value)
	
	apply_stone_type(neutral_resource)
