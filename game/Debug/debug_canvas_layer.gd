class_name DebugTuner
extends CanvasLayer

@export var toggle_key: Key = KEY_D

var panel: PanelContainer
var container: VBoxContainer
var sliders: Dictionary = {}

# Define all tunable params here: "name": [default, min, max, step]
var params: Dictionary = {
	"gravity": [9.8, 0.1, 30.0, 0.1],
	"stone_size": [1.0, 0.1, 5.0, 0.1],
	"air_drag": [0.0, 0.0, 5.0, 0.05],
	"launch_velocity": [1.0, 0.1, 5.0, 0.1],
	"bounce": [0.5, 0.0, 1.0, 0.05],
	"friction": [0.3, 0.0, 1.0, 0.05],
	"finish_radius": [300.0, 50.0, 800.0, 10.0],
}

# Current values — read these from your game code
var values: Dictionary = {}

signal param_changed(param_name: String, value: float)

func _ready():
	# Initialize values to defaults
	for key in params:
		values[key] = params[key][0]
	
	_build_ui()
	panel.visible = false

func _unhandled_input(event: InputEvent):
	if event is InputEventKey and event.pressed and event.keycode == toggle_key:
		panel.visible = !panel.visible
		get_viewport().set_input_as_handled()

func _build_ui():
	panel = PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.anchor_top = 0.0
	panel.anchor_bottom = 1.0
	panel.offset_left = -320
	panel.offset_right = 0
	
	# Semi-transparent background
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.85)
	style.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", style)
	
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(300, 0)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(scroll)
	
	container = VBoxContainer.new()
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(container)
	
	# Title
	var title = Label.new()
	title.text = "Debug Tuner (D)"
	title.add_theme_font_size_override("font_size", 30)
	container.add_child(title)
	
	var sep = HSeparator.new()
	container.add_child(sep)
	
	# Build a slider row for each param
	for key in params:
		var config = params[key]
		_add_slider_row(key, config[0], config[1], config[2], config[3])
	
	# Reset button
	var reset_btn = Button.new()
	reset_btn.text = "Reset Params"
	reset_btn.pressed.connect(_reset_all)
	container.add_child(reset_btn)
	
	var reload_btn = Button.new()
	reload_btn.text = "Reset Scene"
	reload_btn.pressed.connect(_reload_scene)
	container.add_child(reload_btn)
	
	add_child(panel)

func _add_slider_row(param_name: String, default: float, min_val: float, max_val: float, step: float):
	var row = VBoxContainer.new()
	
	# Label showing name and current value
	var label = Label.new()
	label.text = "%s: %.2f" % [param_name, default]
	label.add_theme_font_size_override("font_size", 25)
	row.add_child(label)
	
	var slider = HSlider.new()
	slider.min_value = min_val
	slider.max_value = max_val
	slider.step = step
	slider.value = default
	slider.custom_minimum_size = Vector2(280, 20)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(slider)
	
	# Store references
	sliders[param_name] = { "slider": slider, "label": label }
	
	# Connect
	slider.value_changed.connect(func(val):
		values[param_name] = val
		label.text = "%s: %.2f" % [param_name, val]
		param_changed.emit(param_name, val)
	)
	
	container.add_child(row)

func _reset_all():
	for key in params:
		var default_val = params[key][0]
		sliders[key]["slider"].value = default_val
		values[key] = default_val
		# Add this line to trigger real-time updates when resetting:
		param_changed.emit(key, default_val)

func get_value(param_name: String) -> float:
	return values.get(param_name, 0.0)

func _reload_scene():
	get_tree().reload_current_scene()
