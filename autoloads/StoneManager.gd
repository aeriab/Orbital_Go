# StoneManager.gd — Autoload Singleton
class_name StoneManager
extends Node2D

@export var capture_interval: float = 0.2

var my_vertices: PackedVector2Array = [] # Populate this with your Vector2 values

# --- Internal State ---
var stones: Array[Stone] = []
var capture_timer: float = 0.0

# --- Registration ---
func register_stone(stone: Stone) -> void:
	if not stones.has(stone):
		stones.append(stone)

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
