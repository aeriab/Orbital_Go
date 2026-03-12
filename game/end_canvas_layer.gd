extends CanvasLayer


@export var p1_label: Label
@export var p2_label: Label


@export var who_won_label: Label

func _ready() -> void:
	Global.game_over.connect(end_game)
	Global.score_updated.connect(score_text_update)

func end_game() -> void:
	visible = true
	who_won_label.make_winner_text()
	


func score_text_update() -> void:
	p1_label.text = "Score: " + str(Global.p1_score)
	p2_label.text = "Score: " + str(Global.p2_score)
