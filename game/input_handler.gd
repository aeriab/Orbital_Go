extends Node2D

@export_group("Scenes")
@export var ball_scene: PackedScene

@export_group("Stone Types")
@export var p1_resource: StoneType
@export var p2_resource: StoneType
# You can add @export var neutral_resource: StoneType here later!

@export_group("Launch Settings")
@export var p1_start_spot: Node2D
@export var p2_start_spot: Node2D
@export var launch_power_multiplier: float = 5.0
@export var trajectory_trace_handler: Node2D

var launch_point: Vector2
var ball: Stone # Changed type to 'Stone' to access apply_stone_type()
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
	
	ball = ball_scene.instantiate() as Stone
	ball.freeze = true
	
	# 1. Decide which resource to use based on the turn
	var selected_type = p1_resource if Global.is_p1_turn else p2_resource
	
	# 2. Inject the data into the stone before adding it to the scene
	ball.apply_stone_type(selected_type)
	
	get_parent().add_child(ball)
	
	# 3. Position based on turn
	ball.global_position = p1_start_spot.global_position if Global.is_p1_turn else p2_start_spot.global_position

func fire_ball():
	is_dragging = false
	if ball:
		ball.freeze = false
		ball.linear_velocity = launch_vector()
		Global.is_p1_turn = !Global.is_p1_turn
		trajectory_trace_handler.clear_trajectory()
		ball = null
