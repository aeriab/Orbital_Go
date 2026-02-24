extends Node2D

@export var stone_scene: PackedScene
var stone: Stone

func _process(delta: float) -> void:
	if Input.is_action_pressed("test_fire"):
		spawn_neutral()

#func _unhandled_input(event: InputEvent) -> void:
	#if event.is_action_pressed("test_fire"):
		#spawn_neutral()

func spawn_neutral() -> void:
	stone = stone_scene.instantiate() as Stone
	
		#team_fill: Color,
	#team_outline: Color,
	#scoring_groups: Array[String],
	#capturing_groups: Array[String],
	#points: int = 1
	
	stone.assign_team(Global.neutral_fill_color, Global.neutral_outline_color, [], ["P1_Capturing", "P2_Capturing"], 1)
	
	var spawn_pos: Vector2 = get_global_mouse_position()
	stone.global_position = spawn_pos
	get_parent().add_child(stone)
	
