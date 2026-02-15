extends Node2D

@export var ball_scene: PackedScene
@export var p1_start_spot: Node2D
@export var p2_start_spot: Node2D

@export var launch_power_multiplier: float = 5.0
@export var trajectory_trace_handler: Node2D

var launch_point: Vector2
var ball: RigidBody2D
var is_dragging: bool = false

func _process(_delta):
	if is_dragging and ball:
		# Pass the vector and the current ball to the trajectory handler
		trajectory_trace_handler.update_trajectory(ball, launch_vector())

func launch_vector() -> Vector2:
	# Simplified vector math: (Start Drag - Current Mouse)
	return (launch_point - get_global_mouse_position()) * launch_power_multiplier

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("spawn_piece"):
		start_dragging()
	
	if event.is_action_released("spawn_piece") and is_dragging:
		fire_ball()

func start_dragging():
	launch_point = get_global_mouse_position()
	is_dragging = true
	
	# 1. Instantiate the ball
	ball = ball_scene.instantiate()
	ball.freeze = true
	
	# 2. add the ball to the top of the scene
	get_parent().add_child(ball)
	
	# 3. Position based on turn
	if Global.is_p1_turn:
		ball.global_position = p1_start_spot.global_position
	else:
		ball.global_position = p2_start_spot.global_position

func fire_ball():
	is_dragging = false
	
	if ball:
		ball.freeze = false
		ball.linear_velocity = launch_vector()
		
		# 4. Flip the turn ONLY after a successful launch
		Global.is_p1_turn = !Global.is_p1_turn
		
		# Clean up trajectory visuals
		trajectory_trace_handler.clear_trajectory()
		ball = null # Release reference so we don't accidentally move it later
