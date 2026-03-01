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
	for key in connected_stone_families:
		var current_family: Array[Stone] = connected_stone_families[key]
		if current_family.size() >= 3:
			var leftmost_node: Stone = _get_leftmost_node(current_family)
			var outer: Array[Stone] = _get_outer_nodes(leftmost_node)
			outer_connected_stones[key] = outer
			for s in outer:
				_outer_stone_set[s] = true
		queue_redraw()
			#var leftmost_node: Stone = _get_leftmost_node(current_family)
			#outer_connected_stones[key] = _get_outer_nodes(leftmost_node)

func _get_outer_nodes(leftmost_node: Stone) -> Array[Stone]:
	var outer_nodes: Array[Stone] = [leftmost_node]
	var current_connected_bodies: Array[Stone] = leftmost_node.connected_bodies
	var next_outer_node_index: int = _index_of_next_outer_node(current_connected_bodies, PI, leftmost_node.position)
	var prev_node: Stone = leftmost_node
	var cur_node: Stone = leftmost_node.connected_bodies[next_outer_node_index]
	
	var safety: int = 0
	while(cur_node != leftmost_node):
		outer_nodes.append(current_connected_bodies[next_outer_node_index])
		current_connected_bodies = cur_node.connected_bodies
		next_outer_node_index = _index_of_next_outer_node(current_connected_bodies, raw_angle(cur_node.position, prev_node.position) + 0.001, cur_node.position)
		prev_node = cur_node
		cur_node = cur_node.connected_bodies[next_outer_node_index]
		
		safety += 1
		if safety > stones.size() + 2:
			print("StoneManager: outer hull walk exceeded stone count, breaking")
			break
	
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



func _rebuild_families() -> void:
	var visited: Dictionary = {}
	var components: Array = []
	for stone in stones:
		if not is_instance_valid(stone) or stone in visited:
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
				if is_instance_valid(neighbor) and neighbor not in visited:
					stack.append(neighbor)
		components.append(component)
	# Save old colors before rebuilding so stable families keep their color
	var old_colors: Dictionary = family_colors.duplicate()
	connected_stone_families.clear()
	family_colors.clear()
	for component in components:
		# Stable identity: lowest instance_id in the component
		var min_id: int = component[0].get_instance_id()
		for s in component:
			var sid = s.get_instance_id()
			if sid < min_id:
				min_id = sid
		# Reuse old color if this family existed before, otherwise generate one
		var color: Color
		if old_colors.has(min_id):
			color = old_colors[min_id]
		else:
			color = Color.from_hsv(Global.rng.randf(), 0.8, 1.0)
		connected_stone_families[min_id] = component
		family_colors[min_id] = color
		for s in component:
			s.current_family = component
			s.debug_set_color(color)

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

# --- Utilities & Drawing ---

#func debug_recolor_families() -> void:
	#for family_id in connected_stone_families:
		#var family_array = connected_stone_families[family_id]
		## Generate a random high-saturation color for visibility
		#var random_color = Color.from_hsv(Global.rng.randf(), 0.8, 1.0)
		#
		#for stone in family_array:
			#if is_instance_valid(stone):
				#stone.debug_set_color(random_color)
#
#func _input(event):
	#if event.is_action_pressed("show_color"): # Default 'Enter' or 'Space'
		#debug_recolor_families()


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
	draw_polygon(my_vertices, PackedColorArray([Color(Color.DARK_CYAN, 0.4)]))
	
	# Highlight outer stones with a bright ring
	for stone in _outer_stone_set:
		if is_instance_valid(stone):
			var local_pos: Vector2 = to_local(stone.global_position)
			draw_circle(local_pos, 18.0, Color(Color.YELLOW, 0.85))
			draw_arc(local_pos, 18.0, 0, TAU, 32, Color.WHITE, 2.0)
	
