extends Node

var is_p1_turn: bool = false
var gravity: float = 9.8
var finish_radius: float = 250.0
var game_still_going: bool = true

# SCORE
var p1_score: float = 0.0 # Black
var p2_score: float = 0.5 # White
signal p1_score_updated
signal p2_score_updated


func p1_add_score(val: float) -> void:
	p1_score += val
	p1_score_updated.emit()

func p2_add_score(val: float) -> void:
	p2_score += val
	p2_score_updated.emit()


func inverted_color(c1: Color) -> Color:
	return Color(1.0 - c1.r, 1.0 - c1.g, 1.0 - c1.b, c1.a)
