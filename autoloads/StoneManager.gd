# StoneManager.gd — Autoload Singleton
extends Node

# --- Debug Visualization ---
var debug_enabled: bool = false
var debug_sprite: Sprite2D = null
var debug_image: Image = null
var debug_texture: ImageTexture = null

# Colors for the debug overlay
var debug_white_color: Color = Color(1, 1, 1, 0.3)
var debug_black_color: Color = Color(0, 0, 0, 0.3)
var debug_captured_color: Color = Color(1, 0, 0, 0.4)
var debug_empty_color: Color = Color(0, 0, 0, 0.0)


# --- Grid Configuration ---
const GRID_SIZE: int = 64

@export var world_radius: float = 500.0
@export var capture_interval: float = 0.4

# --- Cell Constants ---
const EMPTY: int = 0
const WHITE: int = 1
const BLACK: int = 2

# --- Internal State ---
var stones: Array[Stone] = []
var grid: PackedByteArray
var reached: PackedByteArray
var enclosed: PackedByteArray
var capture_timer: float = 0.0

# Pre-allocated BFS queue (flat indices). Sized to worst case so
# we never allocate mid-frame.
var _bfs_queue: PackedInt32Array


func _ready():
	var total_cells = GRID_SIZE * GRID_SIZE
	grid = PackedByteArray()
	grid.resize(total_cells)
	reached = PackedByteArray()
	reached.resize(total_cells)
	enclosed = PackedByteArray()
	enclosed.resize(total_cells)
	_bfs_queue = PackedInt32Array()
	_bfs_queue.resize(total_cells)

	if debug_enabled:
		_setup_debug_overlay()


func _setup_debug_overlay() -> void:
	debug_image = Image.create(GRID_SIZE, GRID_SIZE, false, Image.FORMAT_RGBA8)
	debug_texture = ImageTexture.create_from_image(debug_image)

	debug_sprite = Sprite2D.new()
	debug_sprite.texture = debug_texture
	debug_sprite.centered = true
	debug_sprite.position = Vector2.ZERO

	var scale_factor = (world_radius * 2.0) / GRID_SIZE
	debug_sprite.scale = Vector2(scale_factor, scale_factor)
	debug_sprite.z_index = 100

	add_child(debug_sprite)


func _update_debug_overlay(black_captured: PackedByteArray, white_captured: PackedByteArray) -> void:
	if not debug_enabled or debug_image == null:
		return
	for y in GRID_SIZE:
		for x in GRID_SIZE:
			var idx = _idx(x, y)
			var color: Color
			if black_captured[idx] == 1 or white_captured[idx] == 1:
				color = debug_captured_color
			elif grid[idx] == WHITE:
				color = debug_white_color
			elif grid[idx] == BLACK:
				color = debug_black_color
			else:
				color = debug_empty_color
			debug_image.set_pixel(x, y, color)
	debug_texture.update(debug_image)


# --- Registration ---
func register_stone(stone: Stone) -> void:
	stones.append(stone)


func unregister_stone(stone: Stone) -> void:
	stones.erase(stone)


# --- Main Loop ---
func _physics_process(delta: float) -> void:
	capture_timer += delta
	if capture_timer >= capture_interval:
		capture_timer = 0.0
		_run_capture_check()


# --- The Core Algorithm ---
func _run_capture_check() -> void:
	grid.fill(EMPTY)

	_paint_all_stones()

	var black_captured = _find_enclosed_cells(WHITE)
	# _find_enclosed_cells reuses `enclosed`, so we need to copy
	# the result before calling it again for the other color.
	var black_captured_copy = black_captured.duplicate()

	var white_captured = _find_enclosed_cells(BLACK)

	_update_debug_overlay(black_captured_copy, white_captured)

	var to_destroy: Array[Stone] = []

	for stone in stones:
		if not is_instance_valid(stone):
			continue
		var cell = _world_to_grid(stone.global_position)
		var idx = _idx(cell.x, cell.y)

		if stone.team == "Black" and black_captured_copy[idx]:
			to_destroy.append(stone)
		elif stone.team == "White" and white_captured[idx]:
			to_destroy.append(stone)

	for stone in to_destroy:
		#print("Captured a ", stone.team, " stone!")
		stone.on_captured()


# --- Painting (Circle Stamps) ---
# Each stone stamps a filled circle onto the grid. This replaces the
# expensive polygon rasterization — capture detection only needs to
# know "is there a continuous wall", not the exact collision shape.
#
# Each Stone needs a `paint_radius` float (world units) that controls
# how large its stamp is. This replaces `paint_buffer`.
func _paint_all_stones() -> void:
	for stone in stones:
		if not is_instance_valid(stone):
			continue

		var center = _world_to_grid(stone.global_position)
		var color = WHITE if stone.team == "White" else BLACK

		# Convert the stone's paint_radius from world units to grid cells
		var radius_cells: int = ceili(stone.paint_radius / (world_radius * 2.0) * GRID_SIZE)
		var r_sq = radius_cells * radius_cells

		# Stamp a filled circle
		for dy in range(-radius_cells, radius_cells + 1):
			var gy = center.y + dy
			if gy < 0 or gy >= GRID_SIZE:
				continue
			for dx in range(-radius_cells, radius_cells + 1):
				if dx * dx + dy * dy > r_sq:
					continue
				var gx = center.x + dx
				if gx < 0 or gx >= GRID_SIZE:
					continue
				grid[gy * GRID_SIZE + gx] = color


# --- Flood Fill Capture Detection ---
# BFS from every non-wall edge cell. Anything the flood doesn't
# reach is enclosed by walls.
#
# Uses pre-allocated PackedInt32Array as the queue with head/tail
# indices — zero allocations during the BFS.
func _find_enclosed_cells(wall_color: int) -> PackedByteArray:
	reached.fill(0)
	enclosed.fill(0)

	var head: int = 0
	var tail: int = 0

	# Seed: top and bottom edges
	for x in GRID_SIZE:
		var idx_top = x  # _idx(x, 0) = 0 * GRID_SIZE + x
		if grid[idx_top] != wall_color and reached[idx_top] == 0:
			reached[idx_top] = 1
			_bfs_queue[tail] = idx_top
			tail += 1

		var idx_bot = (GRID_SIZE - 1) * GRID_SIZE + x  # _idx(x, GRID_SIZE-1)
		if grid[idx_bot] != wall_color and reached[idx_bot] == 0:
			reached[idx_bot] = 1
			_bfs_queue[tail] = idx_bot
			tail += 1

	# Seed: left and right edges (skip corners, already handled)
	for y in range(1, GRID_SIZE - 1):
		var idx_left = y * GRID_SIZE  # _idx(0, y)
		if grid[idx_left] != wall_color and reached[idx_left] == 0:
			reached[idx_left] = 1
			_bfs_queue[tail] = idx_left
			tail += 1

		var idx_right = y * GRID_SIZE + (GRID_SIZE - 1)  # _idx(GRID_SIZE-1, y)
		if grid[idx_right] != wall_color and reached[idx_right] == 0:
			reached[idx_right] = 1
			_bfs_queue[tail] = idx_right
			tail += 1

	# BFS — inlined neighbor checks (no Vector2i allocation per cell)
	while head < tail:
		var idx = _bfs_queue[head]
		head += 1

		var cx = idx % GRID_SIZE
		var cy = idx / GRID_SIZE

		# Right
		if cx + 1 < GRID_SIZE:
			var nidx = idx + 1
			if reached[nidx] == 0 and grid[nidx] != wall_color:
				reached[nidx] = 1
				_bfs_queue[tail] = nidx
				tail += 1

		# Left
		if cx - 1 >= 0:
			var nidx = idx - 1
			if reached[nidx] == 0 and grid[nidx] != wall_color:
				reached[nidx] = 1
				_bfs_queue[tail] = nidx
				tail += 1

		# Down
		if cy + 1 < GRID_SIZE:
			var nidx = idx + GRID_SIZE
			if reached[nidx] == 0 and grid[nidx] != wall_color:
				reached[nidx] = 1
				_bfs_queue[tail] = nidx
				tail += 1

		# Up
		if cy - 1 >= 0:
			var nidx = idx - GRID_SIZE
			if reached[nidx] == 0 and grid[nidx] != wall_color:
				reached[nidx] = 1
				_bfs_queue[tail] = nidx
				tail += 1

	# Invert: anything NOT reached is enclosed
	for i in reached.size():
		enclosed[i] = 1 if reached[i] == 0 else 0
	return enclosed


# --- Coordinate Conversion ---
func _world_to_grid(world_pos: Vector2) -> Vector2i:
	var normalized_x = (world_pos.x + world_radius) / (world_radius * 2.0)
	var normalized_y = (world_pos.y + world_radius) / (world_radius * 2.0)
	var gx = clampi(int(normalized_x * GRID_SIZE), 0, GRID_SIZE - 1)
	var gy = clampi(int(normalized_y * GRID_SIZE), 0, GRID_SIZE - 1)
	return Vector2i(gx, gy)


func _idx(x: int, y: int) -> int:
	return y * GRID_SIZE + x
