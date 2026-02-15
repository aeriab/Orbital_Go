extends CanvasLayer

@export var p1_label: Label
@export var p2_label: Label


func _ready() -> void:
	Global.score_updated.connect(score_text_update)

func score_text_update(p1_val: float, p2_val: float) -> void:
	p1_label.text = "Score: " + str(Global.p1_score)
	p2_label.text = "Score: " + str(Global.p2_score)
