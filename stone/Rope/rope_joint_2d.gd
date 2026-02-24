class_name RopeJoint2D
extends Node2D
@export var body1: RigidBody2D
@export var body2: RigidBody2D
@export var pull_back_distance: float
@export var disconnect_distance: float
@export var spring_stiffness: float = 50.0
@export var spring_damping: float = 5.0

## How strongly stones repel when compressed # 20000.0 works
@export var repulsion_strength: float = 25000.0

## The distance at which repulsion becomes near-infinite (sum of radii)
var contact_distance: float

func _ready() -> void:
	if body1 and body2:
		contact_distance = body1.radius + body2.radius

func _physics_process(delta: float) -> void:
	var diff := body2.global_position - body1.global_position
	var dist := diff.length()
	if dist > disconnect_distance:
		body1.connected_bodies.erase(body2)
		queue_free()
		return
	
	# Hard constraint — prevent stretching beyond pull_back_distance
	if dist > pull_back_distance:
		var dir := diff / dist
		var mid := (body1.global_position + body2.global_position) / 2.0
		body1.global_position = mid - dir * pull_back_distance / 2.0
		body2.global_position = mid + dir * pull_back_distance / 2.0
		dist = pull_back_distance
	
	if dist > 0.01:
		var dir := diff / dist
		
		# Soft spring — pull toward rest length when stretched
		var displacement := dist - pull_back_distance
		var relative_vel := body2.linear_velocity - body1.linear_velocity
		var vel_along := relative_vel.dot(dir)
		var spring_force := dir * (displacement * spring_stiffness + vel_along * spring_damping)
		
		# Repulsion — pushes apart when compressed below rest length
		var repulsion_force := Vector2.ZERO
		if dist < pull_back_distance:
			
			# How far into the "forbidden zone" between rest and contact
			# Goes from 0.0 (at rest length) to 1.0 (at contact)
			var compress_ratio := 1.0 - ((dist - contact_distance) / (pull_back_distance - contact_distance))
			compress_ratio = clampf(compress_ratio, 0.0, 0.99)
			
			# 1/(1-x) curve — approaches infinity as stones approach contact
			var repulsion_magnitude := repulsion_strength * (1.0 / (1.0 - compress_ratio) - 1.0)
			repulsion_force = -dir * repulsion_magnitude
			#print("repulsion force: " + str(repulsion_force))
		
		body1.apply_central_force(spring_force + repulsion_force)
		body2.apply_central_force(-spring_force - repulsion_force)
	
	queue_redraw()

func _draw() -> void:
	if body1 and body2:
		var dir: Vector2 = (body2.global_position - body1.global_position).normalized()
		var local_start := to_local(body1.global_position)
		draw_line(local_start, local_start + dir * pull_back_distance, Color(1, 1, 0, 0.4), 2.0)
