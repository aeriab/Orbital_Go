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
var p1_score: float = 0.0 
var p2_score: float = 0.0
var p1_won: bool = false
var draw_occurred: bool = true


var black_fill_color: Color = Color.BLACK
var black_outline_color: Color = Color.DIM_GRAY

var white_fill_color: Color = Color.WHITE
var white_outline_color: Color = Color.DIM_GRAY

var neutral_fill_color: Color = Color.WEB_GRAY
var neutral_outline_color: Color = Color.DIM_GRAY

signal score_updated(p1_val: float, p2_val: float)

# ------ Round System ------
signal round_changed() # TODO call Global.next_round() after black throws their stones
var cur_round: int = 1
var final_round: int = 8

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

func reset_game_state():
	is_p1_turn = true
	p1_throws_left = 3
	#p1_total_throws_left = 18
	p2_throws_left = 3
	#p2_total_throws_left = 18
	p1_score = 0.0
	p2_score = 0.0
	game_still_going = true
	
	# Update UI: Re-enable buttons and refresh labels
	buttons_reset.emit()
	p1_throws_amount_updated.emit()
	p2_throws_amount_updated.emit()
	score_updated.emit(p1_score, p2_score)

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

# --- Methods ---

func update_score(team: String, amount: float) -> void:
	if team == "P1":
		p1_score += amount
	else:
		p2_score += amount
	score_updated.emit(p1_score, p2_score)


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


func next_round() -> void:
	cur_round += 1
	round_changed.emit()

func change_round(new_round: int) -> void:
	cur_round = new_round
	round_changed.emit()

#func check_for_game_over() -> void:
	#if (p2_total_throws_left == 0) && (p1_total_throws_left == 0):
		#tally_score()

func change_zone_radius(new_radius: float) -> void:
	zone_radius = new_radius
	zone_radius_changed.emit(zone_radius)

func tally_score() -> void:
	game_still_going = false
	draw_occurred = p1_score == p2_score
	p1_won = p1_score > p2_score
	
	game_over.emit()



# --- Utilities ---

func get_inverted_color(c: Color) -> Color:
	return Color(1.0 - c.r, 1.0 - c.g, 1.0 - c.b, c.a)
