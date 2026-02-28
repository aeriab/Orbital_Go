# StoneManager.gd — Autoload Singleton
class_name StoneManager
extends Node

@export var capture_interval: float = 0.2

# --- Internal State ---
var stones: Array[Stone] = []

var connected_stone_families: Dictionary = {}

func add_node_group(group_key: String):
	# Initialize a new typed array for this key
	var new_array: Array[Node] = []
	connected_stone_families[group_key] = new_array

var capture_timer: float = 0.0

# --- Registration ---
func register_stone(stone: Stone) -> void:
	if not stones.has(stone):
		stones.append(stone)
		
		var new_family: Array[RigidBody2D] = [stone]
		stone.current_family = new_family
		
		connected_stone_families[stone.get_instance_id()] = new_family

func unregister_stone(stone: Stone) -> void:
	stones.erase(stone)

# --- Main Loop ---
func _physics_process(delta: float) -> void:
	capture_timer += delta
	if capture_timer >= capture_interval:
		capture_timer = 0.0
		# This is where we will eventually call the C# logic
		_run_capture_check()

func _run_capture_check() -> void:
	# Filter out any stones that might have been queued for deletion
	var active_stones = stones.filter(func(s): return is_instance_valid(s))
	
	# TODO: In the next step, we will call our C# CaptureManager here.
	# For now, we just ensure the list is clean.
	pass

# --- Utility for C# ---
# This allows C# to easily grab the stones without managing its own list
func get_active_stones() -> Array[Stone]:
	return stones.filter(func(s): return is_instance_valid(s))
<<<<<<< Updated upstream
=======


func _ready() -> void:
#	Update my_vertices to define the captured area
#	This is an example to demonstrate a hexagon
	for i in range(6):
		var angle: float = i * (TAU / 6.0) 
		var point := Vector2(cos(angle), sin(angle)) * 50.0
		my_vertices.append(point)
	queue_redraw() # This tells Godot to refresh the canvas and trigger _draw()

# Context: In the function where your Vector2 array gets updated or changed
#my_vertices = your_new_array 
#queue_redraw() # This tells Godot to refresh the canvas and trigger _draw()

func _draw():
	# The second argument is a PackedColorArray. You can pass a single color for the whole polygon, or one color per vertex.
	draw_polygon(my_vertices, PackedColorArray([Color(Color.DARK_CYAN, 0.4)]))


func merge_families(stone_a: Stone, stone_b: Stone):
	if stone_a.current_family == stone_b.current_family:
		return # Already in the same family!
	var family_a = stone_a.current_family
	var family_b = stone_b.current_family
	# Optimization: Always move the smaller group into the larger group
	if family_a.size() < family_b.size():
		_transfer_family(family_a, family_b)
	else:
		_transfer_family(family_b, family_a)

func _transfer_family(from_family: Array[RigidBody2D], to_family: Array[RigidBody2D]):
	for stone in from_family:
		stone.current_family = to_family
		to_family.append(stone)
	# Remove the old, now empty array from your Dictionary
	connected_stone_families.erase(from_family.get_instance_id())
>>>>>>> Stashed changes
