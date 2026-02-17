extends RigidBody2D

@export var stone_scene: PackedScene
# Define the layout: [Position, StoneTypeResource]
@export var cluster_layout: Array[Dictionary] = [] 

func _ready() -> void:
	# The Master Body handles the orbit logic
	StoneManager.register_stone(self)
	setup_cluster()

func setup_cluster() -> void:
	for entry in cluster_layout:
		var pos = entry.get("position", Vector2.ZERO)
		var type = entry.get("type", null)
		
		var stone = stone_scene.instantiate() as Stone
		add_child(stone)
		
		# 1. POSITION the stone
		stone.position = pos
		
		# 2. APPLY the specific resource (Black, White, or Neutral)
		if type:
			stone.apply_stone_type(type)
		
		# 3. DISABLE child physics so they follow the Master
		# We freeze them and disable their independent processing
		stone.freeze = true
		stone.set_physics_process(false) 
		
		# Now the Master Body 'owns' the child's CollisionShape2D
		# and the child's Stone.gd script stays alive and active!

func stone_acceleration(pos: Vector2) -> Vector2:
	return pos.direction_to(Vector2.ZERO) * Global.gravity * 100 * mass
