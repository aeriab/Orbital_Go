class_name StoneTreeGenerator
extends Node2D

# radius_step should be 2 * the radius of your stone collision shape
func generate_tree_layout(stone_type: StoneType, max_stones: int, radius_step: float) -> Array[Dictionary]:
	var layout: Array[Dictionary] = []
	var occupied_positions: Array[Vector2] = [Vector2.ZERO]
	
	# Add the center stone first
	layout.append({"position": Vector2.ZERO, "type": stone_type})
	
	# Possible directions in 60-degree increments
	var angles = [0, 60, 120, 180, 240, 300]
	
	while layout.size() < max_stones:
		# Pick an existing stone to "grow" from
		var parent_pos = occupied_positions.pick_random()
		
		# Pick a random direction
		var angle_deg = angles.pick_random()
		var direction = Vector2.RIGHT.rotated(deg_to_rad(angle_deg))
		var new_pos = (parent_pos + direction * radius_step).snapped(Vector2(0.1, 0.1))
		
		# Only add if the spot is empty
		if not _is_pos_occupied(new_pos, occupied_positions):
			occupied_positions.append(new_pos)
			layout.append({"position": new_pos, "type": stone_type})
			
	return layout

func _is_pos_occupied(pos: Vector2, occupied: Array[Vector2]) -> bool:
	for p in occupied:
		if p.distance_to(pos) < 1.0: # Small epsilon for float math
			return true
	return false
