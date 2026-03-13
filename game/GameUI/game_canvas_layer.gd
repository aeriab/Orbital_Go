extends CanvasLayer

@export var p1_label: Label
@export var p2_label: Label

@export var p1_throws_left_label: Label
@export var p2_throws_left_label: Label

@export var p1_current_throws_label: Label
@export var p2_current_throws_label: Label

@export var p1_gain_throws_button: Button
@export var p2_gain_throws_button: Button

@onready var white_vignette_color_rect: ColorRect = $White_Vignette_ColorRect
@onready var black_vignette_color_rect: ColorRect = $Black_Vignette_ColorRect

func _ready() -> void:
	# Connect Global signals
	Global.game_over.connect(end_game)
	Global.score_updated.connect(score_text_update)
	Global.turn_passed_to_p1.connect(make_p1_vignette_visible)
	Global.turn_passed_to_p2.connect(make_p2_vignette_visible)
	
	Global.p1_throws_amount_updated.connect(update_p1_ui)
	Global.p2_throws_amount_updated.connect(update_p2_ui)
	
	# Connect Button signals
	p1_gain_throws_button.pressed.connect(_on_p1_gain_throws_pressed)
	p2_gain_throws_button.pressed.connect(_on_p2_gain_throws_pressed)
	
	# Initial UI Refresh
	update_p1_ui()
	update_p2_ui()
	update_visibility()

func end_game() -> void:
	visible = false

# --- UI Update Logic ---

func update_p1_ui():
	p1_throws_left_label.text = "Stones left: " + str(Global.p1_total_throws_left)
	p1_current_throws_label.text = "Current throws: " + str(Global.p1_throws_left)

func update_p2_ui():
	p2_throws_left_label.text = "Stones left: " + str(Global.p2_total_throws_left)
	p2_current_throws_label.text = "Current throws: " + str(Global.p2_throws_left)

func score_text_update(p1_val: float, p2_val: float) -> void:
	p1_label.text = "Score: " + str(p1_val)
	p2_label.text = "Score: " + str(p2_val)

# --- Visibility Logic ---

func update_visibility() -> void:
	# P1 Elements
	p1_current_throws_label.visible = Global.is_p1_turn
	p1_throws_left_label.visible = Global.is_p1_turn
	p1_gain_throws_button.visible = Global.is_p1_turn
	
	# P2 Elements
	p2_current_throws_label.visible = not Global.is_p1_turn
	p2_throws_left_label.visible = not Global.is_p1_turn
	p2_gain_throws_button.visible = not Global.is_p1_turn

# --- Button Handlers ---

func _on_p1_gain_throws_pressed() -> void:
	Global.p1_throws_left += 3
	p1_gain_throws_button.disabled = true
	update_p1_ui()

func _on_p2_gain_throws_pressed() -> void:
	Global.p2_throws_left += 3
	p2_gain_throws_button.disabled = true
	update_p2_ui()

# --- Visual Feedback ---

func make_p1_vignette_visible() -> void:
	white_vignette_color_rect.visible = false
	black_vignette_color_rect.visible = true
	update_visibility()

func make_p2_vignette_visible() -> void:
	black_vignette_color_rect.visible = false
	white_vignette_color_rect.visible = true
	update_visibility()
