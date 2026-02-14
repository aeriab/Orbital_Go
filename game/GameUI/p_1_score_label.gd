extends Label

func _ready() -> void:
	Global.p1_score_updated.connect(p1_score_text_update)

func p1_score_text_update() -> void:
	text = "Score: " + str(Global.p1_score)
