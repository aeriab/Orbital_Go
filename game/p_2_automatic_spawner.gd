extends Node2D

@export var ring_spawner: Node2D
@export var wait_for_p2_time: float

func _ready() -> void:
	Global.turn_passed_to_p2.connect(spawn_p2_ring)

func spawn_p2_ring() -> void:
	var types: Array[int] = []
	for i in Global.p2_start_turn_throws_amount:
		types.append(2)
	ring_spawner.spawn_rand_ring(types)
	
	await get_tree().create_timer(wait_for_p2_time).timeout
	Global.p2_throws_left = Global.p2_start_turn_throws_amount
	Global.is_p1_turn = true
	Global.turn_passed_to_p1.emit()
	
