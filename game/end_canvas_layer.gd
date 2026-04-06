extends CanvasLayer


@export var p1_label: Label
@export var p2_label: Label


@export var who_won_label: Label

func _ready() -> void:
	Global.game_over.connect(end_game)

func end_game() -> void:
	p1_label.text = "Score: " + str(Global.p1_total_score)
	p2_label.text = "Score: " + str(Global.p2_total_score)
	visible = true
	who_won_label.make_winner_text()
	
