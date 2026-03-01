class_name Stone
extends RigidBody2D

@export_group("Internal References")
@export var stone_polygon_2d: Polygon2D
@export var outline_polygon_2d: Polygon2D

@export_group("Stone Properties")
@export var fill_color: Color = Color.WHITE
@export var outline_color: Color = Color.GRAY
@export var mass_multiplier: float = 1.0
@export var point_value: int = 1
@export var can_be_captured: bool = true
@export var aero_torque_strength: float = 5.0

@export_group("Team Roles")
@export var scores_for_teams: Array[String] = []
@export var captures_with_teams: Array[String] = []

var group_name: String = ""
var radius: float = 23
var connected_bodies: Array[RigidBody2D] = []

@export_group("Rope Spring")
@export var rope_joint_scene: PackedScene
@export var spring_stiffness: float = 500.0
@export var spring_damping: float = 5.0
@export var separation: float = 0
@export var connection_buffer: float = 150.0
@export var rope_strength: float = 5.0

var stone_manager: StoneManager
var is_first_stone: bool = false
var current_family: Array[RigidBody2D] = []

# --- Lifecycle ---

func _ready() -> void:
	# 1. Get Manager First
	var managers = get_tree().get_nodes_in_group("stone_manager")
	if managers.size() > 0:
		stone_manager = managers[0]
		# 2. Register (Manager sets current_family)
		stone_manager.register_stone(self)
	
	if Global.first_stone_is_available:
		is_first_stone = true
		Global.first_stone_is_available = false
	
	# Apply Visuals
	stone_polygon_2d.color = fill_color
	outline_polygon_2d.color = outline_color
	mass = mass_multiplier
	
	for group in scores_for_teams:
		add_to_group(group)
	for group in captures_with_teams:
		add_to_group(group)

func _physics_process(_delta: float) -> void:
	if not freeze:
		apply_central_force(stone_acceleration(global_position))
		
		# Simulated aerodynamic restoring torque
		if linear_velocity.length_squared() > 1.0:
			var angle_diff = wrapf(linear_velocity.angle() - rotation, -PI, PI)
			apply_torque(angle_diff * aero_torque_strength * linear_velocity.length())

# --- Physics & Movement ---

func stone_acceleration(pos: Vector2) -> Vector2:
	return pos.direction_to(Vector2.ZERO) * Global.gravity * 100 * mass

# --- Connection Logic ---

func _on_body_entered(body: Node) -> void:
	# Ensure we only connect to other stones that are connectable
	if body is Stone and body.is_in_group("connectable"):
		# ID check prevents double-creation of joints between the same two stones
		if get_instance_id() < body.get_instance_id():
			var joint_distance: float = radius + body.radius + separation
			
			if body not in connected_bodies:
				# Mutual update of neighbor lists
				connected_bodies.append(body)
				if self not in body.connected_bodies:
					body.connected_bodies.append(self)
				
				create_rope_joint(body, joint_distance)
				
				# Update the Dictionary of Families
				if stone_manager:
					stone_manager.merge_families(self, body)

func create_rope_joint(body: Node, joint_distance: float) -> void:
	var rope_joint = rope_joint_scene.instantiate()
	get_tree().current_scene.add_child(rope_joint)
	
	# Pass initial parameters to the rope joint
	rope_joint.body1 = self
	rope_joint.body2 = body
	rope_joint.pull_back_distance = joint_distance
	rope_joint.disconnect_distance = joint_distance + rope_strength
	rope_joint.spring_stiffness = spring_stiffness
	rope_joint.spring_damping = spring_damping
	
	# Listen for the rope breaking to trigger a family split check
	rope_joint.tree_exiting.connect(_handle_break.bind(body))

func _handle_break(other_body: RigidBody2D) -> void:
	if stone_manager and is_instance_valid(other_body):
		stone_manager.break_connection(self, other_body)

# --- Team & Scoring Logic ---

func on_captured() -> void:
	if not can_be_captured:
		return
	
	# Award points to the OTHER team
	for group in scores_for_teams:
		if group == "P1_Scoring":
			Global.update_score("P2", point_value)
		elif group == "P2_Scoring":
			Global.update_score("P1", point_value)
	
	# Remove from all team groups
	for group in scores_for_teams:
		remove_from_group(group)
	for group in captures_with_teams:
		remove_from_group(group)
	
	group_name = ""
	
	# Reset to neutral
	fill_color = Global.neutral_fill_color
	outline_color = Global.neutral_outline_color
	stone_polygon_2d.color = fill_color
	outline_polygon_2d.color = outline_color
	scores_for_teams = []
	captures_with_teams = []
	can_be_captured = false

func assign_team(
	team_fill: Color,
	team_outline: Color,
	scoring_groups: Array[String],
	capturing_groups: Array[String],
	points: int = 1
) -> void:
	fill_color = team_fill
	outline_color = team_outline
	scores_for_teams = scoring_groups
	captures_with_teams = capturing_groups
	point_value = points
	can_be_captured = true
	
	stone_polygon_2d.color = fill_color
	outline_polygon_2d.color = outline_color
	
	for group in scores_for_teams:
		if not is_in_group(group):
			add_to_group(group)
			group_name = group
	for group in captures_with_teams:
		if not is_in_group(group):
			add_to_group(group)
			group_name = group

func debug_set_color(new_color: Color) -> void:
	fill_color = new_color
	if stone_polygon_2d:
		stone_polygon_2d.color = new_color
