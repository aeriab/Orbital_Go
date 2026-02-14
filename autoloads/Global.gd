extends Node

var is_p1_turn: bool = false
var gravity: float = 9.8

# TODO: rename to zone_radius
var finish_radius: float = 150.0
signal zone_radius_changed

var game_still_going: bool = true

# SCORE
var p1_score: float = 0.0 # Black
var p2_score: float = 0.5 # White
signal p1_score_updated
signal p2_score_updated

var p1_won: bool = false
signal game_over

func _ready():
	change_zone_radius(finish_radius)
	# Check if the node exists first to prevent Nil errors
	if has_node("/root/DebugCanvasLayer"):
		DebugCanvasLayer.param_changed.connect(_on_debug_param_changed)
		gravity = DebugCanvasLayer.get_value("gravity")
		print("first")
	else:
		print("second")

func _on_debug_param_changed(param_name: String, value: float):
	if param_name == "gravity":
		gravity = value
		print("my gravity: " + str(gravity))

func _process(_delta: float) -> void:
	#gravity = DebugCanvasLayer.get_value("gravity")
	#print("my gravity: " + str(gravity))
	
	pass

func tally_score() -> void:
	p1_won = (p1_score > p2_score)
	game_over.emit()



func change_zone_radius(radius: float):
	finish_radius = radius
	zone_radius_changed.emit()

func p1_add_score(val: float) -> void:
	p1_score += val
	p1_score_updated.emit()

func p2_add_score(val: float) -> void:
	p2_score += val
	p2_score_updated.emit()


func inverted_color(c1: Color) -> Color:
	return Color(1.0 - c1.r, 1.0 - c1.g, 1.0 - c1.b, c1.a)
