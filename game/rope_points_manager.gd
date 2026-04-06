extends Node2D


func _ready():
	Global.update_rope_score.connect(update_rope_scores)

# --- Scoring Logic ---

func update_rope_scores() -> void:
	var p1_count: int = 0
	var p2_count: int = 0
	
	for rope in get_tree().get_nodes_in_group("rope_joint"):
		if rope.LineColor == Global.black_fill_color:
			p1_count += 1
		elif rope.LineColor == Global.white_fill_color:
			p2_count += 1
	
	Global.p1_rope_score = p1_count
	Global.p2_rope_score = p2_count
