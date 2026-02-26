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
	var active_stones = get_active_stones()
	
	# TODO: In the next step, we will call our C# CaptureManager here.
	# For now, we just ensure the list is clean.
	
	# Ignore if no stones
	if (active_stones.is_empty()):
		return
		
	var unvisited_stones = active_stones.duplicate()
	print("====================")
	while (!unvisited_stones.is_empty()):
		_findClosedLoops(unvisited_stones[0], [], unvisited_stones)
	

func _findClosedLoops(rootStone: Stone, path: Array[Stone], unvisited_stones: Array[Stone]) -> void:
	var newPath = path.duplicate()
	newPath.push_back(rootStone)
	
	unvisited_stones.erase(rootStone)
	
	print(unvisited_stones.size())

	for stone in rootStone.connected_bodies:
		
		# Ignore if not a stone
		if !(stone is Stone):
			continue
		
		# Only loops of the same color can form
		if stone.captures_with_teams != rootStone.captures_with_teams:
			continue
		
		# Ignore if connected stone is the previous stone (no loops of 2)
		if !path.is_empty() and stone == path[-1]:
			continue
		
		# Loop detected
		if stone in path:
			# TODO LOOP DETECTED, DO SMTH
			
			var loop_start_index = newPath.find(stone)
			var loop_stones = newPath.slice(loop_start_index, newPath.size())
			var color = "black" if stone.captures_with_teams[0] == "P2_Capturing" else "white"
			print("LOOP DETECTED of length %d, %s" % [loop_stones.size(), color])
			
			
			continue
		
		_findClosedLoops(stone, newPath, unvisited_stones);
		
	

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
