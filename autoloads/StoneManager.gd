# StoneManager.gd — Autoload Singleton
class_name StoneManager
extends Node2D

var stones: Array[Stone] = []
var connected_stone_families: Dictionary = {}  # family key (instance_id) -> Array[Stone]
var family_colors: Dictionary = {}  # family key (instance_id) -> Color
var outer_connected_stones: Dictionary = {}  # family key (instance_id) -> Array[Stone]

var _outer_stone_set: Dictionary = {}

var _rebuild_timer: float = 0.0
@export var rebuild_interval: float = 0.3

func _physics_process(delta: float) -> void:
	
	_rebuild_timer += delta
	if _rebuild_timer >= rebuild_interval:
		_rebuild_timer = 0.0
		_rebuild_families()
		_find_outer_nodes()

func _find_outer_nodes() -> void:
	_outer_stone_set.clear()
	outer_connected_stones.clear()
	for key in connected_stone_families:
		var current_family: Array[Stone] = connected_stone_families[key]
		
		# This recursively chops off all "hairs" and chains
		var loop_candidates = _get_loop_core(current_family)
		
		if loop_candidates.size() >= 3:
			# FIX: Use loop_candidates here, not current_family
			var leftmost_node: Stone = _get_leftmost_node(loop_candidates)
			# FIX: Pass loop_candidates into the walk
			var outer: Array[Stone] = _get_outer_nodes(leftmost_node, loop_candidates)
			outer_connected_stones[key] = outer
			for s in outer:
				_outer_stone_set[s] = true
			
			_check_for_captures(key, outer)
			
		queue_redraw()
			#var leftmost_node: Stone = _get_leftmost_node(current_family)
			#outer_connected_stones[key] = _get_outer_nodes(leftmost_node)


func _check_for_captures(_family_key: Variant, outer_nodes: Array[Stone]) -> void:
	if outer_nodes.size() < 3: return
	
	# 1. Prepare the polygon points (Global coordinates for easy comparison)
	var poly_points: PackedVector2Array = []
	for s in outer_nodes:
		poly_points.append(s.global_position)
		
	# 2. Identify the capturing team
	# Assuming group names are "P1_Capturing" and "P2_Capturing"
	var capturing_stone = outer_nodes[0]
	var opponent_group = "P2_Capturing" if capturing_stone.is_in_group("P1_Capturing") else "P1_Capturing"
	
	# 3. Check every stone against this polygon
	for stone in stones:
		if not is_instance_valid(stone): continue
		
		# Only check stones belonging to the opponent
		if stone.is_in_group(opponent_group):
			# Geometry2D.is_point_in_polygon returns true if the position is inside
			if Geometry2D.is_point_in_polygon(stone.global_position, poly_points):
				# Trigger the capture logic on the stone
				if stone.has_method("on_captured"):
					stone.on_captured()


func _get_loop_core(family: Array[Stone]) -> Array[Stone]:
	var core = family.duplicate()
	var changed = true
	
	while changed:
		changed = false
		var to_remove = []
		
		# Find all nodes that currently have 1 or 0 connections WITHIN the core
		for stone in core:
			var active_connections_in_core = 0
			for neighbor in stone.connected_bodies:
				if neighbor in core:
					active_connections_in_core += 1
			
			if active_connections_in_core < 2:
				to_remove.append(stone)
		
		if to_remove.size() > 0:
			for stone in to_remove:
				core.erase(stone)
			changed = true # Something was removed, so we must check again
			
	return core

func _get_outer_nodes(leftmost_node: Stone, valid_nodes: Array[Stone]) -> Array[Stone]:
	var outer_nodes: Array[Stone] = [leftmost_node]
	
	# Only look at connections that are part of the pruned 'valid_nodes'
	var get_valid_conns = func(s: Stone): return s.connected_bodies.filter(func(n): return n in valid_nodes)
	
	var current_conns = get_valid_conns.call(leftmost_node)
	if current_conns.is_empty(): return outer_nodes
	
	var next_idx = _index_of_next_outer_node(current_conns, PI, leftmost_node.position)
	var prev_node: Stone = leftmost_node
	var cur_node: Stone = current_conns[next_idx]
	
	var safety = 0
	while cur_node != leftmost_node and safety < stones.size() + 2:
		outer_nodes.append(cur_node)
		var conns = get_valid_conns.call(cur_node)
		
		# Prevent immediate backtracking
		var options = conns.filter(func(s): return s != prev_node)
		if options.is_empty(): break
		
		next_idx = _index_of_next_outer_node(options, raw_angle(cur_node.position, prev_node.position) + 0.001, cur_node.position)
		prev_node = cur_node
		cur_node = options[next_idx]
		safety += 1
		
	return outer_nodes

func _get_leftmost_node(current_family: Array[Stone]) -> Stone:
	var leftmost_node: Stone = current_family[0]
	for body in current_family:
		if body.global_position.x < leftmost_node.global_position.x:
			leftmost_node = body
	return leftmost_node

func _index_of_next_outer_node(connected_nodes: Array[Stone], 
				start_sweep_angle: float, my_pos: Vector2) -> int:
	
	var next_index: int = -1
	var lowest_cwd: float = 999.0
	for i in connected_nodes.size():
		var clockwise_distance: float = get_cwd(start_sweep_angle, my_pos, connected_nodes[i].global_position)
		if clockwise_distance < lowest_cwd:
			lowest_cwd = clockwise_distance
			next_index = i
	
	return next_index

func get_cwd(start_angle: float, my_pos: Vector2, end_pos: Vector2) -> float:
	var angle: float = raw_angle(my_pos, end_pos)
	var diff_angle: float = angle - start_angle
	if (start_angle > angle):
		diff_angle += 2 * PI
	return diff_angle

func raw_angle(center_pos: Vector2, outer_pos: Vector2) -> float:
	var angle = (outer_pos - center_pos).angle()
	if angle < 0:
		angle += 2 * PI
	return angle

func _build_families_for_group(group_name: String, group_color: Color) -> void:
	var visited: Dictionary = {}
	var components: Array = []
	for stone in stones:
		if not is_instance_valid(stone) or stone in visited or not stone.is_in_group(group_name):
			continue
		var component: Array[Stone] = []
		var stack: Array = [stone]
		while stack.size() > 0:
			var s = stack.pop_back()
			if s in visited:
				continue
			visited[s] = true
			component.append(s)
			for neighbor in s.connected_bodies:
				if is_instance_valid(neighbor) and neighbor not in visited and neighbor.is_in_group(group_name):
					stack.append(neighbor)
		components.append(component)
	# Save old colors before rebuilding so stable families keep their color
	var old_colors: Dictionary = family_colors.duplicate()
	for component in components:
		##Stable identity: lowest instance_id in the component
		#var min_id: int = component[0].get_instance_id()
		
		var min_id: int = component[0].get_instance_id()
		for s in component:
			min_id = min(min_id, s.get_instance_id())
		var family_key = group_name + "_" + str(min_id)
		connected_stone_families[family_key] = component
		family_colors[family_key] = group_color
		
		for s in component:
			s.current_family = component
		
		var color: Color
		if Global.debug_color_stones_on:
			# Reuse old color if this family existed before, otherwise generate one
			if old_colors.has(min_id):
				color = old_colors[min_id]
			else:
				color = Color.from_hsv(Global.rng.randf(), 0.8, 1.0)
			family_colors[min_id] = color
		
		connected_stone_families[min_id] = component
		
		for s in component:
			s.current_family = component
			if Global.debug_color_stones_on:
				s.debug_set_color(color)
	

func _rebuild_families() -> void:
	connected_stone_families.clear()
	family_colors.clear()
	_build_families_for_group("P1_Capturing", Global.black_fill_color)
	_build_families_for_group("P2_Capturing", Global.white_fill_color)
	

# --- Registration ---
func register_stone(stone: Stone) -> void:
	if not stones.has(stone):
		stones.append(stone)
		var new_family: Array[Stone] = [stone]
		stone.current_family = new_family
		var key = stone.get_instance_id()
		connected_stone_families[key] = new_family
		var new_color = Color.from_hsv(Global.rng.randf(), 0.8, 1.0)
		family_colors[key] = new_color

func unregister_stone(stone: Stone) -> void:
	if not is_instance_valid(stone): return
	
	var neighbors = stone.connected_bodies.duplicate()
	
	for neighbor in neighbors:
		break_connection(stone, neighbor)
		
	connected_stone_families.erase(stone.get_instance_id())
	family_colors.erase(stone.get_instance_id())
	stones.erase(stone)

# --- Connect Logic ---
func merge_families(stone_a: Stone, stone_b: Stone):
	if stone_a.current_family == stone_b.current_family:
		return
	
	var family_a = stone_a.current_family
	var family_b = stone_b.current_family
	if family_a.size() < family_b.size():
		_transfer_family(family_a, family_b)
	else:
		_transfer_family(family_b, family_a)

func _transfer_family(from_family: Array[Stone], to_family: Array[Stone]):
	# Remove the from_family entry
	for key in connected_stone_families.keys():
		if connected_stone_families[key] == from_family:
			connected_stone_families.erase(key)
			family_colors.erase(key)
			break
	
	for stone in from_family:
		stone.current_family = to_family
		to_family.append(stone)

# --- Disconnect Logic ---
func break_connection(stone_a: Stone, stone_b: Stone):
	stone_a.connected_bodies.erase(stone_b)
	stone_b.connected_bodies.erase(stone_a)

	# We check if they are still connected via another path (Breadth-First Search)
	var seen_a = []
	var family_a: Array[Stone] = []
	_flood_fill(stone_a, family_a, seen_a)
	
	if stone_b not in family_a:
		var seen_b = []
		var family_b: Array[Stone] = []
		_flood_fill(stone_b, family_b, seen_b)
		
		for s in family_b:
			s.current_family = family_b
		
		# Register the new split-off family with a fresh color
		var new_key = stone_b.get_instance_id()
		connected_stone_families[new_key] = family_b
		var new_color = Color.from_hsv(Global.rng.randf(), 0.8, 1.0)
		family_colors[new_key] = new_color

func _flood_fill(start: Stone, new_list: Array[Stone], seen: Array):
	var stack = [start]
	while stack.size() > 0:
		var s = stack.pop_back()
		if s not in seen:
			seen.append(s)
			new_list.append(s)
			for neighbor in s.connected_bodies:
				stack.append(neighbor)

func get_active_stones() -> Array[Stone]:
	return stones.filter(func(s): return is_instance_valid(s))

var my_vertices: Array[Vector2] = []

func _ready() -> void:
	for i in range(6):
		var angle: float = i * (TAU / 6.0) 
		var point := Vector2(cos(angle), sin(angle)) * 50.0
		my_vertices.append(point)
	queue_redraw()

func _draw():
	if Global.debug_shade_capture_area_on:
		# Draw the area for each family that has enough outer nodes
		for key in outer_connected_stones:
			var outer_nodes: Array[Stone] = outer_connected_stones[key]
			if outer_nodes.size() < 3:
				continue
				
			var points: PackedVector2Array = []
			for stone in outer_nodes:
				if is_instance_valid(stone):
					points.append(to_local(stone.global_position))
			
			
			if points.size() < 3:
				continue
			# If the walk went counter-clockwise, reverse the points to make them clockwise
			if not Geometry2D.is_polygon_clockwise(points):
				points.reverse()
			
			# Get the color for this family, default to gray if not found
			var fill_color = family_colors.get(key, Color.GRAY)
			fill_color.a = 0.3 # Set transparency so it looks like a "captured area"
			
			# Now that we've forced them to be clockwise, this check will always pass 
			# unless the polygon is technically "degenerate" (a straight line or zero area).
			if Geometry2D.is_polygon_clockwise(points):
				draw_polygon(points, PackedColorArray([fill_color]))
	
	# Keep your existing highlight logic for individual outer stones
	if Global.debug_highlight_outer_on:
		for stone in _outer_stone_set:
			if is_instance_valid(stone):
				var local_pos: Vector2 = to_local(stone.global_position)
				draw_circle(local_pos, 18.0, Color(Color.YELLOW, 0.85))
