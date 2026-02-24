# StoneManager.gd — Autoload Singleton
extends Node2D

@export var capture_interval: float = 0.2
var capture_polygons: Array[PackedVector2Array] = []

# --- Internal State ---
var stones: Array[Stone] = []
var capture_timer: float = 0.0

# --- Registration ---
func register_stone(stone: Stone) -> void:
	if not stones.has(stone):
		stones.append(stone)

func unregister_stone(stone: Stone) -> void:
	stones.erase(stone)



# Add this to StoneManager.gd
func _process(_delta):
	queue_redraw() # Tells Godot to call _draw()

func _draw():
	for poly_points in capture_polygons:
		# Draw a semi-transparent blue area for P1
		draw_colored_polygon(poly_points, Color(0, 0.5, 1.0, 0.3))
		# Draw the outline
		draw_polyline(poly_points, Color(0, 0.8, 1.0, 1.0), 2.0)


# --- Main Loop ---
func _physics_process(delta: float) -> void:
	capture_timer += delta
	if capture_timer >= capture_interval:
		capture_timer = 0.0
		# This is where we will eventually call the C# logic
		_run_capture_check()

func _run_capture_check() -> void:
	var active_stones = get_active_stones()
	# Filter only for P1 stones that are currently capable of capturing
	var p1_stones = active_stones.filter(func(s): return s.is_in_group("P1_Capturing"))
	
	capture_polygons.clear()
	var visited = {}
	for stone in p1_stones:
		if not visited.has(stone):
			var path = []
			_find_cycles_dfs(stone, null, visited, path, p1_stones)
	
	

func _find_cycles_dfs(current: Stone, parent: Stone, visited: Dictionary, path: Array, pool: Array):
	visited[current] = true
	path.append(current)
	
	for neighbor in current.connected_bodies:
		# Ensure the neighbor is also a P1 stone and valid
		if neighbor not in pool or not is_instance_valid(neighbor):
			continue
			
		if neighbor == parent:
			continue
			
		if neighbor in path:
			# CYCLE DETECTED!
			var cycle_points = []
			var start_index = path.find(neighbor)
			for i in range(start_index, path.size()):
				cycle_points.append(path[i].global_position)
			
			if cycle_points.size() >= 3: # Must be at least a triangle
				capture_polygons.append(PackedVector2Array(cycle_points))
		else:
			_find_cycles_dfs(neighbor, current, visited, path, pool)
	
	path.pop_back()


func get_active_stones() -> Array[Stone]:
	return stones.filter(func(s): return is_instance_valid(s))
