class_name Stone
extends RigidBody2D

@export_group("Internal References")
@export var stone_polygon_2d: Polygon2D
@export var outline_polygon_2d: Polygon2D

@export var fill_color: Color = Color.WHITE
@export var outline_color: Color = Color.GRAY
@export var mass_multiplier: float = 1.0
@export var valid_teams: Array[String] = []
@export var point_value: int = 1
@export var can_be_captured: bool = true


func _ready() -> void:
	stone_polygon_2d.color = fill_color
	outline_polygon_2d.color = outline_color
	mass = mass_multiplier
	for team in valid_teams:
		add_to_group(team)
	StoneManager.register_stone(self)

func _physics_process(_delta: float) -> void:
	if not freeze:
		apply_central_force(stone_acceleration(global_position))

func stone_acceleration(pos: Vector2) -> Vector2:
	return pos.direction_to(Vector2.ZERO) * Global.gravity * 100 * mass


func on_captured() -> void:
	if not can_be_captured:
		return
	if valid_teams.size() == 1:
		var victim_team = valid_teams[0]
		var scoring_team = "P2" if victim_team == "P1" else "P1"
		Global.update_score(scoring_team, point_value)
	# Remove from team groups
	for team in valid_teams:
		remove_from_group(team)
	# Reset to neutral
	fill_color = Global.neutral_fill_color
	outline_color = Global.neutral_outline_color
	stone_polygon_2d.color = fill_color
	outline_polygon_2d.color = outline_color
	valid_teams = []
	can_be_captured = false


func assign_team(team_fill: Color, team_outline: Color, teams: Array[String], points: int = 1) -> void:
	fill_color = team_fill
	outline_color = team_outline
	valid_teams = teams
	point_value = points
	can_be_captured = true
	stone_polygon_2d.color = fill_color
	outline_polygon_2d.color = outline_color
	for team in valid_teams:
		if not is_in_group(team):
			add_to_group(team)
