extends Node2D

@export var ball_scene: PackedScene
@export var black_start_spot: Node2D
@export var white_start_spot: Node2D

@export var launch_power_multiplier: float

@export var trajectory_trace_handler: Node2D


var launch_point: Vector2
var release_point: Vector2
var ball: RigidBody2D

var is_dragging: bool = false

func _process(_delta):
	if is_dragging:
		trajectory_trace_handler.update_trajectory(ball, launch_vector())

func launch_vector() -> Vector2:
	return launch_power_multiplier * (Vector2(-get_global_mouse_position().x + launch_point.x,-get_global_mouse_position().y + launch_point.y))

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("spawn_piece"):
		launch_point = get_global_mouse_position()
		ball = ball_scene.instantiate()
		ball.freeze = true
		is_dragging = true
		add_child(ball)
		if Global.is_black_turn:
			ball.global_position = black_start_spot.global_position
		else:
			ball.global_position = white_start_spot.global_position
		
	
	if event.is_action_released("spawn_piece"):
		ball.freeze = false
		ball.linear_velocity = Vector2.ZERO
		is_dragging = false
		ball.linear_velocity = launch_vector()
		trajectory_trace_handler.clear_trajectory()
