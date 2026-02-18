extends Node2D

@export_group("Scenes")
@export var base_stone_type: PackedScene
@export var heavy_stone_type: PackedScene

@export_group("Stone Deck")
@export var p1_stone_deck: Array[PackedScene]
@export var p2_stone_deck: Array[PackedScene]
# Make it so that the first element in the array is used as 
# the next stone, and then that stone is pushed to the back of the array

@export_group("Launch Settings")
@export var p1_start_spot: Node2D
@export var p2_start_spot: Node2D
@export var launch_power_multiplier: float = 5.0
@export var trajectory_trace_handler: Node2D

var launch_point: Vector2
var ball: Stone # Changed type to 'Stone' to access apply_stone_type()
var is_dragging: bool = false

func _process(_delta):
	if is_dragging and ball:
		trajectory_trace_handler.update_trajectory(ball, launch_vector())

func launch_vector() -> Vector2:
	return (launch_point - get_global_mouse_position()) * launch_power_multiplier

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("spawn_piece"):
		start_dragging()
	
	if event.is_action_released("spawn_piece") and is_dragging:
		fire_ball()

func start_dragging():
	launch_point = get_global_mouse_position()
	is_dragging = true
	
	# 1. Identify the current player's deck
	var deck = p1_stone_deck if Global.is_p1_turn else p2_stone_deck
	
	if deck.is_empty():
		return
	
	# 2. Cycle the deck: take the first, move it to the end
	var next_stone_scene = deck.pop_front()
	deck.push_back(next_stone_scene)
	
	# 3. Instantiate the specific stone from the deck
	ball = next_stone_scene.instantiate() as Stone
	ball.freeze = true
	
	# 4. Position based on turn
	ball.global_position = p1_start_spot.global_position if Global.is_p1_turn else p2_start_spot.global_position
	
	get_parent().add_child(ball)

func fire_ball():
	is_dragging = false
	if ball:
		ball.freeze = false
		ball.linear_velocity = launch_vector()
		Global.is_p1_turn = !Global.is_p1_turn
		trajectory_trace_handler.clear_trajectory()
		ball = null
