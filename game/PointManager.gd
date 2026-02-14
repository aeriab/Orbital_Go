extends Node

@export var game_canvas_layer: CanvasLayer
@export var end_canvas_layer: CanvasLayer

func _ready():
	Global.game_over.connect(tally_score)

func tally_score() -> void:
	game_canvas_layer.visible = false
	end_canvas_layer.visible = true
	
	end_canvas_layer.make_winner_text()
