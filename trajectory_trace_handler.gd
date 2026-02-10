extends Node2D

@export var trajectory_line: Line2D

@export var line_color: Color = Color.WHITE
@export var max_alpha: float = 1.0
@export var min_alpha: float = 0.1
@export var max_width: float = 8.0
@export var min_width: float = 1.0
@export var min_speed: float = 50.0
@export var max_speed: float = 500.0

var time_step: float = 1.0 / 60.0
var max_steps: int = 300

func clear_trajectory():
	trajectory_line.clear_points()
	trajectory_line.gradient = null
	trajectory_line.width_curve = null

func update_trajectory(ball: Stone, start_velocity: Vector2):
	trajectory_line.clear_points()

	var pos = ball.global_position
	var vel = start_velocity
	var damp = ball.linear_damp

	var positions: Array[Vector2] = []
	var speeds: Array[float] = []

	for i in max_steps:
		positions.append(pos)
		speeds.append(vel.length())

		var accel = ball.stone_acceleration(pos)
		vel += accel * time_step
		vel *= max(1.0 - damp * time_step, 0.0)

		var next_pos = pos + vel * time_step

		var query = PhysicsRayQueryParameters2D.create(pos, next_pos)
		var collision = get_world_2d().direct_space_state.intersect_ray(query)

		if collision:
			positions.append(collision.position)
			speeds.append(vel.length())
			break

		pos = next_pos

	var point_count = positions.size()
	if point_count < 2:
		return

	# Build the line points
	for i in point_count:
		trajectory_line.add_point(positions[i])

	# Build gradient (alpha varies by speed)
	var gradient = Gradient.new()
	var offsets = PackedFloat32Array()
	var colors = PackedColorArray()

	# Build width curve (width varies by speed)
	var width_curve = Curve.new()

	for i in point_count:
		var t = float(i) / float(point_count - 1)
		var speed_ratio = clampf((speeds[i] - min_speed) / (max_speed - min_speed), 0.0, 1.0)

		var alpha = lerpf(min_alpha, max_alpha, speed_ratio)
		var width = lerpf(min_width, max_width, speed_ratio)

		offsets.append(t)
		colors.append(Color(line_color.r, line_color.g, line_color.b, alpha))
		width_curve.add_point(Vector2(t, width / max_width))

	gradient.offsets = offsets
	gradient.colors = colors

	trajectory_line.gradient = gradient
	trajectory_line.width_curve = width_curve
	trajectory_line.width = max_width  # curve values are a multiplier on this
