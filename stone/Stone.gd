class_name Stone
extends RigidBody2D

@export var stone_data: StoneType

@export_group("Internal References")
@export var stone_polygon_2d: Polygon2D
@export var outline_polygon_2d: Polygon2D

@export var neutral_resource: StoneType

func _ready() -> void:
	if stone_data:
		apply_stone_type(stone_data)
	
	StoneManager.register_stone(self)

func apply_stone_type(data: StoneType) -> void:
	stone_data = data
	
	# Set visuals
	stone_polygon_2d.color = data.fill_color
	outline_polygon_2d.color = data.outline_color
	mass = data.mass_multiplier # Adjust weight based on type
	
	# Set Teams/Groups
	for team in data.valid_teams:
		add_to_group(team)

func _physics_process(_delta: float) -> void:
	if not freeze:
		apply_central_force(stone_acceleration(global_position))

func stone_acceleration(pos: Vector2) -> Vector2:
	return pos.direction_to(Vector2.ZERO) * Global.gravity * 100 * mass

func on_captured() -> void:
	if not stone_data.can_be_captured:
		return
		
	# Scoring logic: If captured, give points to every team NOT in this stone's valid_teams
	# (For a P1 stone, P2 gets points. For a Neutral stone, no one gets points.)
	if stone_data.valid_teams.size() == 1:
		var victim_team = stone_data.valid_teams[0]
		var scoring_team = "P2" if victim_team == "P1" else "P1"
		Global.update_score(scoring_team, stone_data.point_value)
	
	apply_stone_type(neutral_resource)
	#StoneManager.unregister_stone(self)
	#queue_free()
