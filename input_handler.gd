extends Node2D

@export var ball_scene: PackedScene
@export var black_start_spot: Node2D
@export var white_start_spot: Node2D

var launch_point: Vector2
var release_point: Vector2

var ball: RigidBody2D

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("spawn_piece"):
		launch_point = DisplayServer.mouse_get_position()
		print("launch point: " + str(launch_point))
		ball = ball_scene.instantiate()
		ball.freeze = true
		add_child(ball)
		if Global.is_black_turn:
			ball.global_position = black_start_spot.global_position
		else:
			ball.global_position = white_start_spot.global_position
		
	
	if event.is_action_released("spawn_piece"):
		release_point = DisplayServer.mouse_get_position()
		print("release point: " + str(release_point))
		
		ball.freeze = false
