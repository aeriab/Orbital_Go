extends RigidBody2D

@export var stone_scene: PackedScene
@export var neutral_resource: StoneType
@export var is_procedural: bool = true
@export var tree_size: int = 7
@export var cluster_layout: Array[Dictionary] = [] 

func _ready() -> void:
	# Register this master body for capture logic and gravity
	StoneManager.register_stone(self)
	
	if is_procedural:
		_generate_procedural_layout()
	
	setup_cluster()

func _generate_procedural_layout() -> void:
	# Instantiate a temporary stone just to check its actual radius
	var temp_stone = stone_scene.instantiate() as Stone
	var detected_radius = 23.0 # Fallback
	
	# Reach into the temp stone to get the real collision radius
	if temp_stone.collision_shape_2d and temp_stone.collision_shape_2d.shape is CircleShape2D:
		detected_radius = temp_stone.collision_shape_2d.shape.radius
	
	temp_stone.free() # Delete the temp stone
	
	# Circle packing distance is 2x radius
	var radius_step = detected_radius * 2.0
	
	var generator = StoneTreeGenerator.new()
	cluster_layout = generator.generate_tree_layout(neutral_resource, tree_size, radius_step)

func setup_cluster() -> void:
	for entry in cluster_layout:
		var pos = entry.get("position", Vector2.ZERO)
		var type = entry.get("type", null)
		
		var stone = stone_scene.instantiate() as Stone
		stone.is_part_of_cluster = true 
		
		add_child(stone)
		stone.position = pos
		
		if type:
			stone.apply_stone_type(type)
		
		# Child stones are "frozen" and don't process their own physics;
		# they let this parent body handle all the movement.
		stone.freeze = true
		stone.set_physics_process(false) 

	# Recalculate total mass so gravity pulls harder on bigger clusters
	var total_mass = 0.0
	for child in get_children():
		if child is Stone:
			total_mass += child.mass
	mass = total_mass

# --- Physics & Gravity ---

func _physics_process(_delta: float) -> void:
	if not freeze:
		apply_central_force(stone_acceleration(global_position))

func stone_acceleration(pos: Vector2) -> Vector2:
	return pos.direction_to(Vector2.ZERO) * Global.gravity * 100 * mass
