extends Node2D

@export var ball_scene: PackedScene
@export var neutral_resource: StoneType

var ball: Stone

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("test_fire"):
		spawn_neutral()

func spawn_neutral() -> void:
	var spawn_pos: Vector2 = get_global_mouse_position()
	ball = ball_scene.instantiate() as Stone
	ball.apply_stone_type(neutral_resource)
	ball.global_position = spawn_pos
	get_parent().add_child(ball)
