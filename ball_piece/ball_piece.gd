class_name Stone
extends RigidBody2D


@export var connecting_line:PackedScene
var connections: Dictionary = {} # Key: Stone, Value: Line2D instance

var low_velocity_timer: float = 0.0
var freeze_time: float = 1.0
var center_velocity_threshold: float = 3.0

@export var p1_color: Color = Color.WHITE
@export var p2_color: Color = Color.BLACK
@export var line_color: Color = Color.RED

@onready var connect_area_2d: Area2D = $ConnectArea2D
@onready var polygon_2d: Polygon2D = $Polygon2D


func _ready():
	connect_area_2d.body_entered.connect(_on_body_entered)
	connect_area_2d.body_exited.connect(_on_body_exited)
	
	
	if (Global.is_black_turn):
		polygon_2d.self_modulate = p1_color
		add_to_group("White")
	else:
		polygon_2d.self_modulate = p2_color
		add_to_group("Black")
	
	Global.is_black_turn = !Global.is_black_turn
	sleeping = false
	
	StoneManager.register_stone(self)

func _process(_delta: float) -> void:
	_draw_connecting_lines()
	

func _physics_process(_delta: float) -> void:
	if not freeze:
		apply_central_force(stone_acceleration(global_position))
	

func stone_acceleration(pos: Vector2) -> Vector2:
	return pos.direction_to(Vector2.ZERO) * Global.gravity * 100


func _draw_connecting_lines() -> void:
	for body in connections:
		if is_instance_valid(body):
			connections[body].points = [Vector2.ZERO, to_local(body.global_position)]
	

# --- Connection Logic ---
func _on_body_entered(body: Node2D) -> void:
	if !(body is Stone):
		return
	if !(_is_same_color(body)):
		return
	if connections.has(body):
		return
	
	var same_component: bool = StoneManager.find(self) == StoneManager.find(body)
	_create_connection(body)
	if same_component:
		StoneManager.on_capture_detected(self, body)
	else:
		StoneManager.union(self, body)
	

func _on_body_exited(body: Node2D) -> void:
	if !(connections.has(body)):
		return
	
	_remove_connection(body)
	
	StoneManager.rebuild_union_find()


func _is_same_color(other: Stone) -> bool:
	return (
		(is_in_group("White") and other.is_in_group("White"))
		or (is_in_group("Black") and other.is_in_group("Black"))
	)



func _create_connection(body: Stone) -> void:
	var line = connecting_line.instantiate()
	line.self_modulate = line_color
	add_child(line)
	connections[body] = line
	# Make it bidirectional — body also knows about this connection.
	# We reuse the same Line2D instance; body just holds a reference.
	if !(body.connections.has(self)):
		body.connections[self] = line

func _remove_connection(body: Stone) -> void:
	if connections.has(body):
		var line = connections[body]
		if is_instance_valid(line):
			line.queue_free()
		connections.erase(body)
	
	if (body is Stone) && (body.connections.has(self)):
		body.connections.erase(self)
	
