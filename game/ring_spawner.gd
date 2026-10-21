extends Node2D

@export_group("Spawn Settings")
@export var radius: float = 1000
@export var rand_radius_increase: float = 100
@export var stone_scene: PackedScene

func _ready() -> void:
	spawn_start_ring()

# types is of format: [1,1,2,2] meaning p1 at index 0 and index 1, p2 at index 2 and index 3
func spawn_start_ring() -> void:
	var rand_angles = []
	for i in range(Global.black_start_stone_count):
		rand_angles.append(randf_range(-PI,PI))
	for i in range(Global.white_start_stone_count):
		rand_angles.append(randf_range(-PI,PI))
	
	# Spawn in a circle
	var counter: int = 0
	for ang in rand_angles:
		var spawn_pos = Vector2(cos(ang), sin(ang)) * (radius + randf_range(0,rand_radius_increase))
		
		if counter < Global.black_start_stone_count: # spawn a black stone
			var scene = stone_scene
			var stone = scene.instantiate() as Stone
			
			# Set position and rotation to face inward (optional)
			stone.position = spawn_pos
			stone.rotation = ang + PI
			stone.assign_team(Global.black_fill_color, Global.black_outline_color, ["P1_Scoring"], ["P1_Capturing"])
			add_child(stone)
		else: # spawn a white stone
			var scene = stone_scene
			var stone = scene.instantiate() as Stone
			
			# Set position and rotation to face inward (optional)
			stone.position = spawn_pos
			stone.rotation = ang + PI
			stone.assign_team(Global.white_fill_color, Global.white_outline_color, ["P2_Scoring"], ["P2_Capturing"])
			
			add_child(stone)
		
		counter += 1

#func spawn_rand_ring(types: Array[int]) -> void:
	#var amount = types.size()
	## Spawn in a circle
	#for i in amount:
		##var angle = i * (TAU / amount)
		##var spawn_pos = Vector2(cos(angle) + randf_range(-2.0,2.0), sin(angle) + randf_range(-2.0,2.0)) * radius
		#var angle = randf_range(0, TAU)
		#
		#var spawn_pos = Vector2(cos(angle), sin(angle)) * (radius + randf_range(0,rand_radius_increase))
		#
		#var is_p1 = types[i] == 1
		#var scene = stone_scene
		#var stone = scene.instantiate() as Stone
		#
		## Set position and rotation to face inward (optional)
		#stone.position = spawn_pos
		#stone.rotation = angle + PI
		#
		## Initialize team based on your Input Handler logic
		#if is_p1:
			#stone.assign_team(Global.black_fill_color, Global.black_outline_color, ["P1_Scoring"], ["P1_Capturing"])
		#else:
			#stone.assign_team(Global.white_fill_color, Global.white_outline_color, ["P2_Scoring"], ["P2_Capturing"])
		#
		#add_child(stone)
