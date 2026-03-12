extends Node2D

@export_group("Spawn Settings")
@export var radius: float = 200.0
@export var stone_count: int = 12 # Should be even for equal teams
@export var p1_stone_scene: PackedScene
@export var p2_stone_scene: PackedScene

func _ready() -> void:
	spawn_ring()

func spawn_ring() -> void:
	# 1. Create a balanced list of types
	var types: Array[int] = []
	for i in stone_count:
		@warning_ignore("integer_division")
		types.append(1 if i < stone_count / 2 else 2)
	
	# 2. Randomize the order
	types.shuffle()
	
	# 3. Spawn in a circle
	for i in stone_count:
		var angle = i * (TAU / stone_count)
		var spawn_pos = Vector2(cos(angle), sin(angle)) * radius
		
		var is_p1 = types[i] == 1
		var scene = p1_stone_scene if is_p1 else p2_stone_scene
		var stone = scene.instantiate() as Stone
		
		# Set position and rotation to face inward (optional)
		stone.position = spawn_pos
		stone.rotation = angle + PI
		
		# Initialize team based on your Input Handler logic
		if is_p1:
			stone.assign_team(Global.black_fill_color, Global.black_outline_color, ["P1_Scoring"], ["P1_Capturing"])
		else:
			stone.assign_team(Global.white_fill_color, Global.white_outline_color, ["P2_Scoring"], ["P2_Capturing"])
		
		add_child(stone)
