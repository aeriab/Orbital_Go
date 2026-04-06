extends CanvasLayer

@export var p1_label: Label
@export var p2_label: Label

@export var round_label: Label

#@export var p1_throws_left_label: Label
#@export var p2_throws_left_label: Label

#@export var p1_current_throws_label: Label
#@export var p2_current_throws_label: Label

#@export var p1_gain_throws_button: Button
#@export var p2_gain_throws_button: Button

@onready var white_vignette_color_rect: ColorRect = $White_Vignette_ColorRect
@onready var black_vignette_color_rect: ColorRect = $Black_Vignette_ColorRect

func _ready() -> void:
	# Connect Global signals
	Global.game_over.connect(end_game)
	Global.turn_passed_to_p1.connect(make_p1_vignette_visible)
	Global.turn_passed_to_p2.connect(make_p2_vignette_visible)
	
	Global.round_changed.connect(change_round_text)
	
	Global.update_total_score.connect(score_text_update)

func change_round_text() -> void:
	round_label.text = "Round: " + str(Global.cur_round) + " of " + str(Global.final_round)

func end_game() -> void:
	visible = false

func score_text_update() -> void:
	print("score text updated?: " + str(Global.p1_total_score))
	p1_label.text = "Score: " + str(Global.p1_total_score)
	p2_label.text = "Score: " + str(Global.p2_total_score)

func make_p1_vignette_visible() -> void:
	white_vignette_color_rect.visible = false
	black_vignette_color_rect.visible = true
	#update_visibility()

func make_p2_vignette_visible() -> void:
	black_vignette_color_rect.visible = false
	white_vignette_color_rect.visible = true
	#update_visibility()
