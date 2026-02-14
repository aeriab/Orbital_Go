extends Node

var is_black_turn: bool = false

var gravity: float = 9.8

var finish_radius: float = 350.0

var game_still_going: bool = true

func inverted_color(c1: Color) -> Color:
	return Color(1.0 - c1.r, 1.0 - c1.g, 1.0 - c1.b, c1.a)
