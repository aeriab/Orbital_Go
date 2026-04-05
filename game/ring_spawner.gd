extends Node2D

@export_group("Spawn Settings")
@export var radius: float = 1000
@export var rand_radius_increase: float = 100
@export var stone_count: int = 12 # Should be even for equal teams
@export var p1_stone_scene: PackedScene
@export var p2_stone_scene: PackedScene

func _ready() -> void:
	spawn_start_ring(stone_count)
	
	#Global.turn_passed_to_p2.connect(spawn_p2_ring)

#func spawn_p2_ring() -> void:
	#var types: Array[int] = []
	#for i in Global.p2_start_turn_throws_amount:
		#types.append(2)
	#spawn_ring(types)
	#
	#await get_tree().create_timer(5.0).timeout
	#function_to_call()

func spawn_start_ring(amount) -> void:
	# 1. Create a balanced list of types
	var types: Array[int] = []
	for i in amount:
		@warning_ignore("integer_division")
		types.append(1 if i < amount / 2 else 2)
	
	# 2. Randomize the order
	types.shuffle()
	
	spawn_ring(types)

# types is of format: [1,1,2,2] meaning p1 at index 0 and index 1, p2 at index 2 and index 3
func spawn_ring(types: Array[int]) -> void:
	var amount = types.size()
	# Spawn in a circle
	for i in amount:
		var angle = i * (TAU / amount)
		#var spawn_pos = Vector2(cos(angle) + randf_range(-2.0,2.0), sin(angle) + randf_range(-2.0,2.0)) * radius
		#var angle = randf_range(0, TAU)
		
		var spawn_pos = Vector2(cos(angle), sin(angle)) * (radius + randf_range(0,rand_radius_increase))
		
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

func spawn_rand_ring(types: Array[int]) -> void:
	var amount = types.size()
	# Spawn in a circle
	for i in amount:
		#var angle = i * (TAU / amount)
		#var spawn_pos = Vector2(cos(angle) + randf_range(-2.0,2.0), sin(angle) + randf_range(-2.0,2.0)) * radius
		var angle = randf_range(0, TAU)
		
		var spawn_pos = Vector2(cos(angle), sin(angle)) * (radius + randf_range(0,rand_radius_increase))
		
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
