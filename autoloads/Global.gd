extends Node

# --- Game State ---
var is_p1_turn: bool = true # Typically P1 (Black) starts in Go
var game_still_going: bool = true
var gravity: float = 9.8

# --- Area / Zone ---
var zone_radius: float = 250.0
signal zone_radius_changed(new_radius: float)

# --- Scoring ---
# White (P2) often starts with 0.5 or 6.5 "Komi" points in Go to offset 
# the disadvantage of going second.
var p1_score: float = 0.0 
var p2_score: float = 0.5 

signal score_updated(p1_val: float, p2_val: float)
signal game_over(p1_won: bool)

func _ready() -> void:
	# Use a safe call to check for the Debug layer
	var debug = get_node_or_null("/root/DebugCanvasLayer")
	if debug:
		debug.param_changed.connect(_on_debug_param_changed)
		gravity = debug.get_value("gravity")

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

func change_zone_radius(new_radius: float) -> void:
	zone_radius = new_radius
	zone_radius_changed.emit(zone_radius)

func tally_score() -> void:
	game_still_going = false
	var p1_won = p1_score > p2_score
	game_over.emit(p1_won)

# --- Utilities ---

func get_inverted_color(c: Color) -> Color:
	return Color(1.0 - c.r, 1.0 - c.g, 1.0 - c.b, c.a)
