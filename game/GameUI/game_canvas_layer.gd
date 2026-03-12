extends CanvasLayer

@export var p1_label: Label
@export var p2_label: Label
@onready var white_vignette_color_rect: ColorRect = $White_Vignette_ColorRect
@onready var black_vignette_color_rect: ColorRect = $Black_Vignette_ColorRect


func _ready() -> void:
	Global.score_updated.connect(score_text_update)
	Global.turn_passed_to_p1.connect(make_p1_vignette_visible)
	Global.turn_passed_to_p2.connect(make_p2_vignette_visible)


func score_text_update(p1_val: float, p2_val: float) -> void:
	p1_label.text = "Score: " + str(p1_val)
	p2_label.text = "Score: " + str(p2_val)

func make_p1_vignette_visible() -> void:
	white_vignette_color_rect.visible = false
	black_vignette_color_rect.visible = true

func make_p2_vignette_visible() -> void:
	black_vignette_color_rect.visible = false
	white_vignette_color_rect.visible = true
