extends Node


var does_capturing_score: bool = false

# --- Game State ---
var is_p1_turn: bool = true # Typically P1 (Black) starts in Go

var p1_start_turn_throws_amount: int = 3
var p1_throws_left: int = p1_start_turn_throws_amount
#var p1_total_throws_left: int = 18

var p2_start_turn_throws_amount: int = 3
var p2_throws_left: int = p2_start_turn_throws_amount
#var p2_total_throws_left: int = 18

var first_stone_is_available: bool = true

signal p1_throw(amount: int)
signal p2_throw(amount: int)
signal p1_throws_amount_updated
signal p2_throws_amount_updated

signal buttons_reset()

signal player_started_dragging()
signal player_stopped_dragging()
signal turn_passed_to_p1()
signal turn_passed_to_p2()

var game_still_going: bool = true
var gravity: float = 9.8

# --- Area / Zone ---
var zone_radius: float = 250.0
signal zone_radius_changed(new_radius: float)

# --- Scoring ---
# White (P2) often starts with 0.5 or 6.5 "Komi" points in Go to offset 
# the disadvantage of going second.
var p1_total_score: float = 0.0
var p2_total_score: float = 0.0
var p1_won: bool = false
var draw_occurred: bool = true


var black_fill_color: Color = Color.BLACK
var black_outline_color: Color = Color.DIM_GRAY

var white_fill_color: Color = Color.WHITE
var white_outline_color: Color = Color.DIM_GRAY

var grey_fill_color: Color = Color(0.522, 0.522, 0.522, 0.392)
var grey_outline_color: Color = Color.DIM_GRAY

# ------ Round System ------
signal round_changed() # TODO call Global.next_round() after black throws their stones

var start_cur_round: int = 1
var cur_round: int = start_cur_round
var start_final_round: int = 8
var final_round: int = start_final_round

signal update_rope_score()
var p1_rope_score: int = 0
var p2_rope_score: int = 0

signal update_total_score()

var wait_for_game_over_time: float = 2.0
var game_is_ending: bool = false
signal game_over()


# --- Debug Settings ---
var debug_color_stones_on: bool = false
var debug_highlight_outer_on: bool = false
var debug_shade_capture_area_on: bool = false

var rng = RandomNumberGenerator.new()
func _ready() -> void:
	rng.seed = 67
	
	# Use a safe call to check for the Debug layer
	var debug = get_node_or_null("/root/DebugCanvasLayer")
	if debug:
		debug.param_changed.connect(_on_debug_param_changed)
		gravity = debug.get_value("gravity")
	
	turn_passed_to_p1.connect(_on_turn_passed_to_p1)
	update_rope_score.connect(_on_update_rope_score)
	update_total_score.connect(_on_update_total_score)
	player_started_dragging.connect(_on_player_started_dragging)
	player_stopped_dragging.connect(_on_player_stopped_dragging)

func _on_player_started_dragging() -> void:
	pass

func _on_player_stopped_dragging() -> void:
	pass

func reset_game_state():
	is_p1_turn = true
	p1_throws_left = 3
	#p1_total_throws_left = 18
	p2_throws_left = 3
	#p2_total_throws_left = 18
	cur_round = start_cur_round
	final_round = start_final_round
	
	p1_total_score = 0.0
	p2_total_score = 0.0
	
	p1_rope_score = 0
	p2_rope_score = 0
	
	game_is_ending = false
	game_still_going = true
	
	# Update UI: Re-enable buttons and refresh labels
	buttons_reset.emit()
	p1_throws_amount_updated.emit()
	p2_throws_amount_updated.emit()

func p1_gain_throws(amount: int):
	p1_throws_left += amount
	#p1_total_throws_left += amount
	p1_throws_amount_updated.emit()

func p2_gain_throws(amount: int):
	p2_throws_left += amount
	#p2_total_throws_left += amount
	p2_throws_amount_updated.emit()

func _on_debug_param_changed(param_name: String, value: float) -> void:
	if param_name == "gravity":
		gravity = value


func p1_throw_stones(amount: int):
	#if (amount <= p1_throws_left && amount <= p1_total_throws_left):
	if (amount <= p1_throws_left):
		p1_throws_left -= amount
		#p1_total_throws_left -= amount
		#check_for_game_over()
		
		if (p1_throws_left <= 0):
			p1_throws_left = p1_start_turn_throws_amount
			is_p1_turn = false
			turn_passed_to_p2.emit()
		
		p1_throw.emit(amount)
		p1_throws_amount_updated.emit()

func p2_throw_stones(amount: int):
	if (amount <= p2_throws_left):
		p2_throws_left -= amount
		
		if (p2_throws_left <= 0):
			p2_throws_left = p2_start_turn_throws_amount
			is_p1_turn = true
			turn_passed_to_p1.emit()
		
		p2_throw.emit(amount)
		p2_throws_amount_updated.emit()

func _on_update_rope_score() -> void:
	p1_total_score = p1_rope_score
	p2_total_score = p2_rope_score
	update_total_score.emit()

func _on_update_total_score() -> void:
	pass

func _on_turn_passed_to_p1() -> void:
	next_round()

func next_round() -> void:
	if cur_round >= final_round:
#		Await line of code here TODO
		game_is_ending = true
		await get_tree().create_timer(wait_for_game_over_time).timeout
		tally_score()
	else:
		cur_round += 1
		round_changed.emit()

func change_round(new_round: int) -> void:
	cur_round = new_round
	round_changed.emit()

func change_zone_radius(new_radius: float) -> void:
	zone_radius = new_radius
	zone_radius_changed.emit(zone_radius)

func tally_score() -> void:
	game_still_going = false
	draw_occurred = p1_total_score == p2_total_score
	p1_won = p1_total_score > p2_total_score
	
	game_over.emit()



# --- Utilities ---

func get_inverted_color(c: Color) -> Color:
	return Color(1.0 - c.r, 1.0 - c.g, 1.0 - c.b, c.a)
