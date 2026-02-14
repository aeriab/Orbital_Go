extends Area2D

@export var zone_collision_shape: CollisionShape2D

func _ready():
	area_entered.connect(_on_stone_entered)
	area_exited.connect(_on_stone_exited)


func _on_stone_entered(area):
	var stone: Stone = area.get_stone()
	var points: float = stone.point_value
	var is_p1_team: bool = stone.is_in_group("P1")
	
	if is_p1_team:
		Global.p1_add_score(points)
	else:
		Global.p2_add_score(points)
	

func _on_stone_exited(area):
	var stone: Stone = area.get_stone()
	var points: float = stone.point_value
	var is_p1_team: bool = stone.is_in_group("P1")
	
	if is_p1_team:
		Global.p1_add_score(-points)
	else:
		Global.p2_add_score(-points)
	
