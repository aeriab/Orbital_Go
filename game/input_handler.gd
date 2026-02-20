extends Node2D

@export_group("Stone Scenes")
@export var p1_stone_scene: PackedScene  # e.g. BaseStone.tscn, LongStone.tscn
@export var p2_stone_scene: PackedScene

@export_group("Team Colors")
@export var p1_fill_color: Color = Color.BLUE
@export var p1_outline_color: Color = Color.DARK_BLUE
@export var p2_fill_color: Color = Color.RED
@export var p2_outline_color: Color = Color.DARK_RED

@export_group("Launch Settings")
@export var p1_start_spot: Node2D
@export var p2_start_spot: Node2D
@export var launch_power_multiplier: float = 5.0
@export var trajectory_trace_handler: Node2D

var launch_point: Vector2
var ball: Stone
var is_dragging: bool = false

func _process(_delta):
	if is_dragging and ball:
		trajectory_trace_handler.update_trajectory(ball, launch_vector())

func launch_vector() -> Vector2:
	return (launch_point - get_global_mouse_position()) * launch_power_multiplier

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("spawn_piece"):
		start_dragging()
	if event.is_action_released("spawn_piece") and is_dragging:
		fire_ball()

func start_dragging():
	launch_point = get_global_mouse_position()
	is_dragging = true

	# Pick the right scene based on turn
	var scene = p1_stone_scene if Global.is_p1_turn else p2_stone_scene
	ball = scene.instantiate() as Stone
	ball.freeze = true

	# Assign team identity
	if Global.is_p1_turn:
		ball.assign_team(p1_fill_color, p1_outline_color, ["P1"])
	else:
		ball.assign_team(p2_fill_color, p2_outline_color, ["P2"])

	get_parent().add_child(ball)
	ball.global_position = p1_start_spot.global_position if Global.is_p1_turn else p2_start_spot.global_position

func fire_ball():
	is_dragging = false
	if ball:
		ball.freeze = false
		ball.linear_velocity = launch_vector()
		Global.is_p1_turn = !Global.is_p1_turn
		trajectory_trace_handler.clear_trajectory()
		ball = null
