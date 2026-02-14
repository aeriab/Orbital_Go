extends Label

func _ready() -> void:
	Global.p2_score_updated.connect(p2_score_text_update)

func p2_score_text_update() -> void:
	text = "Score: " + str(Global.p2_score)
