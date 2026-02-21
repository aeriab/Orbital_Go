class_name Stone
extends RigidBody2D

@export_group("Internal References")
@export var stone_polygon_2d: Polygon2D
@export var outline_polygon_2d: Polygon2D

@export_group("Stone Properties")
@export var fill_color: Color = Color.WHITE
@export var outline_color: Color = Color.GRAY
@export var mass_multiplier: float = 1.0
@export var point_value: int = 1
@export var can_be_captured: bool = true

@export_group("Team Roles")
@export var scores_for_teams: Array[String] = []   # e.g. ["P1_Scoring"]
@export var captures_with_teams: Array[String] = [] # e.g. ["P1_Capturing"]

func _ready() -> void:
	stone_polygon_2d.color = fill_color
	outline_polygon_2d.color = outline_color
	mass = mass_multiplier
	for group in scores_for_teams:
		add_to_group(group)
	for group in captures_with_teams:
		add_to_group(group)
	StoneManager.register_stone(self)

func _physics_process(_delta: float) -> void:
	if not freeze:
		apply_central_force(stone_acceleration(global_position))

func stone_acceleration(pos: Vector2) -> Vector2:
	return pos.direction_to(Vector2.ZERO) * Global.gravity * 100 * mass

func on_captured() -> void:
	if not can_be_captured:
		return
	
	# Award points to the OTHER team for each scoring group this stone belongs to
	for group in scores_for_teams:
		if group == "P1_Scoring":
			Global.update_score("P2", point_value)
		elif group == "P2_Scoring":
			Global.update_score("P1", point_value)
	
	# Remove from all team groups
	for group in scores_for_teams:
		remove_from_group(group)
	for group in captures_with_teams:
		remove_from_group(group)
	
	# Reset to neutral
	fill_color = Global.neutral_fill_color
	outline_color = Global.neutral_outline_color
	stone_polygon_2d.color = fill_color
	outline_polygon_2d.color = outline_color
	scores_for_teams = []
	captures_with_teams = []
	can_be_captured = false

func assign_team(
	team_fill: Color,
	team_outline: Color,
	scoring_groups: Array[String],
	capturing_groups: Array[String],
	points: int = 1
) -> void:
	fill_color = team_fill
	outline_color = team_outline
	scores_for_teams = scoring_groups
	captures_with_teams = capturing_groups
	point_value = points
	can_be_captured = true
	stone_polygon_2d.color = fill_color
	outline_polygon_2d.color = outline_color
	for group in scores_for_teams:
		if not is_in_group(group):
			add_to_group(group)
	for group in captures_with_teams:
		if not is_in_group(group):
			add_to_group(group)
