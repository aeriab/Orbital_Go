extends Node2D

@export var stone_scene: PackedScene
var stone: Stone

var time: float = 0.0

@export var spawn_delay: float = 0.02

@export var force_strength: float = 500.0
@export var force_radius: float = 200.0

func _process(delta: float) -> void:
	time += delta
	if Input.is_action_pressed("test_fire"):
		if time >= spawn_delay:
			time = 0
			spawn_neutral()
	
	if Input.is_action_pressed("test_force"):
		#print("force testing")
		apply_radial_force(get_global_mouse_position())
	

func apply_radial_force(origin: Vector2) -> void:
	# Grab every RigidBody2D in the scene
	var bodies := get_tree().get_nodes_in_group("physics_bodies")
	
	for node in bodies:
		if node is RigidBody2D:
			var body: RigidBody2D = node
			var direction: Vector2 = body.global_position - origin
			var distance: float = direction.length()
			
			if distance < force_radius and distance > 0.01:
				# Linear falloff — full strength at center, zero at radius edge
				var strength := force_strength * (1.0 - distance / force_radius)
				body.apply_force(direction.normalized() * strength)


func spawn_neutral() -> void:
	stone = stone_scene.instantiate() as Stone
	
	#stone.assign_team(Global.neutral_fill_color, Global.neutral_outline_color, [], ["P1_Capturing", "P2_Capturing"], 1)
	stone.assign_team(Global.neutral_fill_color, Global.neutral_outline_color, [], [], 1)
	var spawn_pos: Vector2 = get_global_mouse_position()
	stone.global_position = spawn_pos
	get_parent().add_child(stone)
	
