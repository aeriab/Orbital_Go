extends Node2D

@export_group("Stone Scenes")
@export var p1_stone_scene: PackedScene
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

@export_group("Pull Back Limits")
@export var max_pull_distance: float = 150.0
@export var min_pull_distance: float = 20.0
@export var rotation_lookahead: float = 50.0

@export_group("Drag Indicator")
@export var ring_color: Color = Color(1, 1, 1, 0.3)
@export var ring_armed_color: Color = Color(1, 1, 1, 0.6)
@export var ring_width: float = 1.5

var launch_point: Vector2
var ball: Stone
var is_dragging: bool = false
var pull_strength: float = 0.0
var is_armed: bool = false  # Whether pull is past min distance

func _process(_delta):
	if is_dragging and ball:
		var raw_pull = launch_point.distance_to(get_global_mouse_position())
		pull_strength = clampf(raw_pull / max_pull_distance, 0.0, 1.0)
		var is_below_min = raw_pull < min_pull_distance
		is_armed = not is_below_min

		if is_below_min:
			trajectory_trace_handler.clear_trajectory()
		else:
			trajectory_trace_handler.update_trajectory(ball, clamped_launch_vector())

		update_pull_feedback(is_below_min)

		if not is_below_min:
			var start_pos = ball.global_position
			var vel = clamped_launch_vector()
			var lookahead_point = start_pos + vel.normalized() * rotation_lookahead
			var aim_angle = start_pos.angle_to_point(lookahead_point)
			ball.rotation = lerp_angle(ball.rotation, aim_angle, 0.25)

		queue_redraw()

func _draw():
	if not is_dragging:
		return
	var local_launch = to_local(launch_point)
	var color = ring_armed_color if is_armed else ring_color
	draw_arc(local_launch, min_pull_distance, 0, TAU, 64, color, ring_width)

func raw_pull_vector() -> Vector2:
	return launch_point - get_global_mouse_position()

func clamped_launch_vector() -> Vector2:
	var pull = raw_pull_vector()
	var distance = pull.length()
	var effective_distance = clampf(distance - min_pull_distance, 0.0, max_pull_distance - min_pull_distance)
	return pull.normalized() * effective_distance * launch_power_multiplier

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("spawn_piece"):
		start_dragging()
	if event.is_action_released("spawn_piece") and is_dragging:
		fire_ball()

func start_dragging():
	launch_point = get_global_mouse_position()
	is_dragging = true
	is_armed = false
	pull_strength = 0.0

	var scene = p1_stone_scene if Global.is_p1_turn else p2_stone_scene
	ball = scene.instantiate() as Stone
	ball.freeze = true

	if Global.is_p1_turn:
		ball.assign_team(p1_fill_color, p1_outline_color, ["P1_Scoring"], ["P1_Capturing"])
	else:
		ball.assign_team(p2_fill_color, p2_outline_color, ["P2_Scoring"], ["P2_Capturing"])

	get_parent().add_child(ball)
	ball.global_position = p1_start_spot.global_position if Global.is_p1_turn else p2_start_spot.global_position

func fire_ball():
	is_dragging = false
	if not ball:
		return

	var raw_pull = launch_point.distance_to(get_global_mouse_position())
	if raw_pull < min_pull_distance:
		ball.queue_free()
		ball = null
		trajectory_trace_handler.clear_trajectory()
		queue_redraw()
		return

	ball.freeze = false
	ball.linear_velocity = clamped_launch_vector()
	Global.is_p1_turn = !Global.is_p1_turn
	trajectory_trace_handler.clear_trajectory()
	ball = null
	queue_redraw()

func update_pull_feedback(is_below_min: bool):
	if not ball:
		return
	if is_below_min:
		ball.modulate = Color(1, 1, 1, 0.3)
	else:
		ball.modulate = Color(1, 1, 1, 1.0)
