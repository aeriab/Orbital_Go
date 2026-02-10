extends Node

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
