class_name Stone
extends RigidBody2D

@export_group("Visuals")
@export var p1_color: Color = Color.BLACK
@export var p2_color: Color = Color.WHITE
@export var p1_outline_color: Color = Color.DARK_GRAY
@export var p2_outline_color: Color = Color.GRAY

@export_group("Internal References")
@export var stone_polygon_2d: Polygon2D
@export var outline_polygon_2d: Polygon2D

var team: String = ""

func _ready() -> void:
	# Use the current turn to set team, then flip the turn
	# Note: Better to handle the turn-flip in your "Launcher" script!
	if Global.is_p1_turn:
		setup_stone("P1", p1_color, p1_outline_color)
	else:
		setup_stone("P2", p2_color, p2_outline_color)
	
	# Only register to the manager for the capture logic
	StoneManager.register_stone(self)

func setup_stone(t: String, fill: Color, stroke: Color) -> void:
	team = t
	add_to_group(t)
	stone_polygon_2d.color = fill
	outline_polygon_2d.color = stroke

func _physics_process(_delta: float) -> void:
	if not freeze:
		apply_central_force(stone_acceleration(global_position))

# Used by both the stone and your trajectory preview
func stone_acceleration(pos: Vector2) -> Vector2:
	return pos.direction_to(Vector2.ZERO) * Global.gravity * 100 * mass


func on_captured() -> void:
	# If a P1 stone is captured, P2 gets the points
	var scoring_team = "P2" if team == "P1" else "P1"
	Global.update_score(scoring_team, 1.0)

	StoneManager.unregister_stone(self)
	queue_free()
