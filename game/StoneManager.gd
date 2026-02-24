extends Node2D

@export var capture_interval: float = 0.2

# We now store a dictionary of polygons per team
# Format: { "P1": [PackedVector2Array, ...], "P2": [...] }
var team_polygons: Dictionary = {
	"P1": [],
	"P2": []
}

var stones: Array[Stone] = []
var capture_timer: float = 0.0

func register_stone(stone: Stone) -> void:
	if not stones.has(stone):
		stones.append(stone)

func unregister_stone(stone: Stone) -> void:
	stones.erase(stone)

func _process(_delta):
	queue_redraw()

func _draw():
	# Draw P1 - Blue
	for poly in team_polygons["P1"]:
		draw_colored_polygon(poly, Color(0, 0.5, 1.0, 0.3))
		draw_polyline(poly, Color(0, 0.8, 1.0, 1.0), 2.0)
	
	# Draw P2 - Red
	for poly in team_polygons["P2"]:
		draw_colored_polygon(poly, Color(1.0, 0.0, 0.0, 0.3))
		draw_polyline(poly, Color(1.0, 0.2, 0.2, 1.0), 2.0)

func _physics_process(delta: float) -> void:
	capture_timer += delta
	if capture_timer >= capture_interval:
		capture_timer = 0.0
		_run_capture_check()

func _run_capture_check() -> void:
	var active_stones = get_active_stones()
	
	# Reset polygons for both teams
	team_polygons["P1"].clear()
	team_polygons["P2"].clear()
	
	# Run cycle detection for each team separately
	_detect_team_cycles(active_stones, "P1_Capturing", "P1")
	_detect_team_cycles(active_stones, "P2_Capturing", "P2")


func _detect_team_cycles(all_stones: Array[Stone], group_name: String, team_key: String) -> void:
	var team_stones = all_stones.filter(func(s): return s.is_in_group(group_name))
	var visited = {} # Global record for this check
	
	for stone in team_stones:
		if not visited.has(stone):
			# path stores nodes in the current branch of the search
			_find_cycles_dfs(stone, null, visited, [], team_stones, team_key)


func _find_cycles_dfs(current: Stone, parent: Stone, visited: Dictionary, path: Array, pool: Array, team_key: String):
	visited[current] = true
	path.append(current)
	
	for neighbor in current.connected_bodies:
		# 1. Basic validation
		if neighbor == parent or neighbor not in pool or not is_instance_valid(neighbor):
			continue
			
		# 2. Cycle Detection: If neighbor is in our current path, we found a loop
		if neighbor in path:
			var cycle_points = []
			var start_idx = path.find(neighbor)
			
			# Construct the polygon from the point where the loop closed
			for i in range(start_idx, path.size()):
				cycle_points.append(to_local(path[i].global_position))
			
			if cycle_points.size() >= 3:
				# Check for duplicates before adding to prevent "ghost" overlaps
				var new_poly = PackedVector2Array(cycle_points)
				if not _is_duplicate_polygon(new_poly, team_key):
					team_polygons[team_key].append(new_poly)
		
		# 3. Standard DFS: Only go deeper if we haven't visited this node at all yet
		elif not visited.has(neighbor):
			_find_cycles_dfs(neighbor, current, visited, path, pool, team_key)
	
	# CRITICAL: Remove the current node from the path as we backtrack
	path.pop_back()

# Helper to prevent drawing the same loop multiple times
func _is_duplicate_polygon(new_poly: PackedVector2Array, team_key: String) -> bool:
	for existing in team_polygons[team_key]:
		if existing.size() == new_poly.size():
			# A simple check: if the first point is the same, it's likely the same loop
			# In a complex game, you might want a more robust vertex check
			if existing[0].is_equal_approx(new_poly[0]): 
				return true
	return false



func get_active_stones() -> Array[Stone]:
	return stones.filter(func(s): return is_instance_valid(s))
