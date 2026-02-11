# StoneManager.gd — Autoload Singleton
extends Node

# --- Union-Find Data ---
# parent[stone] = the stone one step "above" it in the group tree.
# When parent[stone] == stone, that stone is the root (leader) of its group.
var parent: Dictionary = {}

# rank[stone] = approximate depth of the tree beneath this stone.
# Used to keep the tree flat — we always attach the shorter tree
# under the taller one so find() stays fast.
var rank: Dictionary = {}

# --- Registration ---
# Called from Stone._ready(). Creates a new one-element group.
# The stone is its own parent (points to itself) with rank 0.
func register_stone(stone: Stone) -> void:
	parent[stone] = stone
	rank[stone] = 0

func unregister_stone(stone: Stone) -> void:
	parent.erase(stone)
	rank.erase(stone)

# --- Find (with path compression) ---
# Follow parent pointers until we hit a root (a stone whose parent is itself).
#
# PATH COMPRESSION is the trick that makes this fast:
# After we find the root, we point every stone we visited
# directly at the root. So next time, find() is instant.
#
# Before compression:  D -> C -> B -> A (root)
# After compression:   D -> A, C -> A, B -> A
#
# This is what takes Union-Find from O(log n) to effectively O(1).
func find(stone: Stone) -> Stone:
#	Base case: if stone is its own parent, it's the root
	if parent[stone] != stone:
#		Recursive call - find the true root
		parent[stone] = find(parent[stone])
	return parent[stone]


# --- Union (by rank) ---
# Merge the groups containing stone_a and stone_b.
#
# UNION BY RANK: we attach the shorter tree under the taller one.
# This keeps trees shallow, which keeps find() fast.
# If both trees are the same height, we pick one and bump its rank.
func union(stone_a: Stone, stone_b: Stone) -> void:
	var root_a = find(stone_a)
	var root_b = find(stone_b)
	
#	Safety check, shouldn't be calling if this is the case
	if root_a == root_b:
		return
	
#	Attach smaller tree under larger tree
	if rank[root_a] < rank[root_b]:
		parent[root_a] = root_b
	elif rank[root_a] > rank[root_b]:
		parent[root_b] = root_a
	else:
		parent[root_b] = root_a
		rank[root_a] += 1
	


# --- Rebuild ---
# Called when a connection BREAKS (body_exited).
# Union-Find can't split groups, so we rebuild from scratch.
#
# This sounds scary but here's what actually happens:
# 1. Reset every stone to be its own group
# 2. Walk through every existing connection
# 3. Re-union them
#
# With 200 stones and ~400 connections, this is maybe
# 800 find() calls — each nearly O(1). Sub-millisecond.
func rebuild_union_find() -> void:
	for stone in parent.keys():
		if is_instance_valid(stone):
			parent[stone] = stone
			rank[stone] = 0
		else:
			parent.erase(stone)
			rank.erase(stone)
	
	# Step 2: Walk every stone's connections and re-union
	# We track which pairs we've already processed so we
	# don't double-union (since connections are bidirectional)
	var processed: Dictionary = {}
	
	for stone in parent.keys():
		for connected_stone in stone.connections.keys():
			if !(is_instance_valid(connected_stone)):
				continue
			if !(parent.has(connected_stone)):
				continue
			
			# Create a canonical key so A-B and B-A are the same
			var key = _pair_key(stone, connected_stone)
			if processed.has(key):
				continue
			processed[key] = true
			
			union(stone, connected_stone)
			
	
	
	


# --- Capture Detection ---
# Called from Stone._on_body_entered when find(a) == find(b),
# meaning the new connection closed a loop.
#
# YOU DECIDE what happens here. Some options:
# - Delete all stones inside the loop
# - Score points for the player who made the encirclement
# - Trigger a visual effect then capture
#
# For now, this is a stub you'll fill in with your game logic.
func on_capture_detected(stone_a: Stone, stone_b: Stone) -> void:
	print("CAPTURE! Loop closed between ", stone_a, " and ", stone_b)
	
	# TODO: Your capture logic here. Some ideas:
	#
	# Option A: Find all stones in the loop and do something
	# var loop_stones = _trace_loop(stone_a, stone_b)
	#
	# Option B: Use the influence map idea on just this region
	# _flood_fill_capture(stone_a, stone_b)
	#
	# Option C: Just score points and flash the connections
	# _award_points(stone_a)
	# _flash_loop(stone_a, stone_b)
	pass

# --- Cleanup ---
# Call this when a stone is destroyed/freed
func remove_stone(stone: Stone) -> void:
	unregister_stone(stone)
	rebuild_union_find()


# --- Utility ---
# Creates a consistent key for a pair regardless of order.
# We use instance IDs because they're unique integers.
func _pair_key(a: Stone, b: Stone) -> int:
	var id_a = a.get_instance_id()
	var id_b = b.get_instance_id()
#	Cantor pairing function on sorted IDs
	var lo = mini(id_a, id_b)
	var hi = maxi(id_a, id_b)
	return (lo + hi) * (lo + hi + 1) / 2 + hi






func check_for_capture(stone: Stone) -> void:
#	find all possible loops this stone is part of
	var cycles = find_all_cycles(stone)
	if cycles.is_empty():
		return
	
	for cycle in cycles:
		process_captures(cycle)


func find_all_cycles(start_stone: Stone):
	var cycles = []
	var stack = [[start_stone, [start_stone]]]
	
	while stack.size() > 0:
		var data = stack.pop_back()
		var current = data[0]
		var path = data[1]
		
		for neighbor in current.connections.keys():
			if neighbor == path[0] and path.size() >= 3:
				cycles.append(path)
			elif neighbor not in path:
				var new_path = path.duplicate()
				new_path.append(neighbor)
				stack.append([neighbor, new_path])
	return cycles
	


func process_captures(cycle_stones: Array):
	var polygon = PackedVector2Array()
	var bounds = Rect2(cycle_stones[0].global_position, Vector2.ZERO)
	
	for s in cycle_stones:
		polygon.append(s.global_position)
		bounds = bounds.expand(s.global_position)
	
	var opponent_group = "Black" if cycle_stones[0].is_in_group("White") else "White"
	var targets = get_tree().get_nodes_in_group(opponent_group)
	for target in targets:
		if bounds.has_point(target.global_position):
			if Geometry2D.is_point_in_polygon(target.global_position, polygon):
				capture_stone(target)

func capture_stone(stone: Stone):
	# Would add animation and sound here
	stone.queue_free()
