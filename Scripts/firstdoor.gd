extends Area2D

@export var door_sprite_path: NodePath = "../AnimatedSprite2D"
@export var door_collision_path: NodePath = "../StaticBody2D/CollisionShape2D"  # Changed to StaticBody2D for blocking
@export var required_velocity_threshold: float = 10.0
@export var door_detection_distance: float = 100.0  # Distance ahead to check for approaching enemies
@export var enemy_collision_mask: int = 2  # Set this to match your enemy's collision layer
@export var player_name: String = "Player"  # Set this to your actual player's name

@onready var door_sprite: AnimatedSprite2D = get_node(door_sprite_path)
@onready var door_collision: CollisionShape2D = get_node(door_collision_path)

var bodies_in_area = []
var is_door_open = false
var animation_playing = false
var check_timer = 0.0
var check_interval = 1.0  # Check every 1 second

func _ready():
	# Connect the area signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Connect animation finished signal
	if door_sprite:
		door_sprite.animation_finished.connect(_on_animation_finished)
	
	# Ensure door starts closed
	if door_collision:
		door_collision.disabled = false
	
	print("Door ready. Collision shape:", door_collision)

func _process(_delta):
	# Update timer
	check_timer += _delta
	
	# Clean up invalid bodies
	for i in range(bodies_in_area.size() - 1, -1, -1):
		if not is_instance_valid(bodies_in_area[i]):
			bodies_in_area.remove_at(i)
	
	# Only check every 1 second
	if check_timer >= check_interval:
		check_timer = 0.0  # Reset timer
		
		# Debug current state
		if not bodies_in_area.is_empty():
			print("Bodies in area: ", bodies_in_area.size())
			for body in bodies_in_area:
				if is_instance_valid(body):
					print("  - ", body.name, " | Is CharacterBody2D: ", body is CharacterBody2D, " | Is Player: ", is_player(body))
		
		# Check for approaching enemies to open door early
		if not is_door_open and not animation_playing:
			print("Door closed, checking for approaching enemies...")
			check_for_approaching_enemies()
		
		# Close door if no valid enemies are in area or approaching
		elif is_door_open and not animation_playing:
			if not has_valid_enemies_in_area() and not has_approaching_enemies():
				print("No valid enemies found, closing door")
				close_door()

func check_for_approaching_enemies():
	print("=== CHECKING FOR APPROACHING ENEMIES ===")
	
	# Get all bodies in the world
	var space_state = get_world_2d().direct_space_state
	if not space_state:
		print("No space_state found!")
		return
	
	# Create a query to find nearby bodies
	var query = PhysicsShapeQueryParameters2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(door_detection_distance * 2, 200)  # Wide detection area
	query.shape = shape
	query.transform = Transform2D(0, global_position + Vector2(door_detection_distance / 2, 0))
	query.collision_mask = enemy_collision_mask  # Use the exported enemy collision mask
	query.exclude = [get_parent()]  # Exclude the door itself
	
	print("Query position: ", query.transform.origin)
	print("Query size: ", shape.size)
	print("Collision mask: ", query.collision_mask)
	
	var results = space_state.intersect_shape(query)
	print("Found ", results.size(), " bodies in detection area")
	
	for i in range(results.size()):
		var result = results[i]
		var body = result.collider
		print("Body ", i, ": ", body.name, " (", body.get_class(), ")")
		print("  Position: ", body.global_position)
		print("  Relative to door: ", body.global_position.x - global_position.x)
		
		if body is CharacterBody2D:
			var velocity = Vector2.ZERO
			if body.has_method("get_velocity"):
				velocity = body.get_velocity()
			elif "velocity" in body:
				velocity = body.velocity
			print("  Velocity: ", velocity)
			print("  Is player: ", is_player(body))
			print("  Approaching from right: ", is_enemy_approaching_from_right(body))
		
		if is_enemy_approaching_from_right(body):
			print(">>> ENEMY DETECTED - Opening door!")
			open_door()
			break
	
	print("=== END CHECK ===\n")

func has_approaching_enemies() -> bool:
	var space_state = get_world_2d().direct_space_state
	if not space_state:
		return false
	
	var query = PhysicsShapeQueryParameters2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(door_detection_distance * 2, 200)
	query.shape = shape
	query.transform = Transform2D(0, global_position + Vector2(door_detection_distance / 2, 0))
	query.collision_mask = enemy_collision_mask
	query.exclude = [get_parent()]  # Exclude the door itself
	
	var results = space_state.intersect_shape(query)
	
	for result in results:
		if is_enemy_approaching_from_right(result.collider):
			return true
	return false

func is_enemy_approaching_from_right(body) -> bool:
	print("    Checking if enemy approaching from right:")
	print("      Body: ", body.name)
	
	# Check if it's a CharacterBody2D first
	if not body is CharacterBody2D:
		print("      Not CharacterBody2D - FALSE")
		return false
	
	# Check if it's actually an enemy (not player)
	if is_player(body):
		print("      Is player - FALSE")
		return false
	
	# Check if the body has velocity
	var velocity: Vector2
	if body.has_method("get_velocity"):
		velocity = body.get_velocity()
		print("      Got velocity via get_velocity(): ", velocity)
	elif "velocity" in body:
		velocity = body.velocity
		print("      Got velocity via property: ", velocity)
	else:
		print("      No velocity found - FALSE")
		return false
	
	# Check position relative to door
	var position_check = body.global_position.x > global_position.x
	print("      Position check (body.x > door.x): ", body.global_position.x, " > ", global_position.x, " = ", position_check)
	
	# Check velocity - moving left (right-to-left)
	var velocity_check = velocity.x < -required_velocity_threshold
	print("      Velocity check (vel.x < -threshold): ", velocity.x, " < ", -required_velocity_threshold, " = ", velocity_check)
	
	var result = velocity_check and position_check
	print("      Final result: ", result)
	return result

func _on_body_entered(body):
	print("\n=== BODY ENTERED DOOR AREA ===")
	print("Body name: ", body.name)
	print("Body type: ", body.get_class())
	print("Body position: ", body.global_position)
	print("Door position: ", global_position)
	print("Is CharacterBody2D: ", body is CharacterBody2D)
	
	if body is CharacterBody2D:
		if not body in bodies_in_area:
			bodies_in_area.append(body)
		
		var velocity = Vector2.ZERO
		if body.has_method("get_velocity"):
			velocity = body.get_velocity()
		elif "velocity" in body:
			velocity = body.velocity
		print("Velocity: ", velocity)
		print("Velocity.x: ", velocity.x)
		print("Required threshold: ", -required_velocity_threshold)
		print("Is player: ", is_player(body))
		print("Is moving right-to-left: ", is_enemy_moving_right_to_left(body))
		print("Door state - Open: ", is_door_open, " | Animation playing: ", animation_playing)
		
		# Only allow enemies through, block players
		if is_player(body):
			print(">>> PLAYER DETECTED - Keeping door closed")
			return
		
		# If it's an enemy and door isn't open, open it
		if is_enemy_moving_right_to_left(body):
			if not is_door_open and not animation_playing:
				print(">>> ENEMY QUALIFIED - Opening door!")
				open_door()
			else:
				print(">>> ENEMY QUALIFIED but door already open or animating")
		else:
			print(">>> ENEMY NOT QUALIFIED - Door stays closed")
	else:
		print(">>> NOT A CHARACTER BODY")
	
	print("=== END BODY ENTERED ===\n")

func _on_body_exited(body):
	if body in bodies_in_area:
		bodies_in_area.erase(body)
		print("Body exited door area: ", body.name)
		
		# Close door if no valid enemies are in area
		if not has_valid_enemies_in_area() and is_door_open and not animation_playing:
			close_door()

func is_player(body) -> bool:
	# First check if it's a CharacterBody2D
	if not body is CharacterBody2D:
		return false
	
	# Use the specific player name to identify the actual player
	# This way enemies with is_player property won't be confused with the real player
	return body.name == player_name or body.name.to_lower().contains("player")

func is_enemy_moving_right_to_left(body: CharacterBody2D) -> bool:
	# Don't allow players
	if is_player(body):
		return false
	
	# Check velocity
	var velocity: Vector2
	if body.has_method("get_velocity"):
		velocity = body.get_velocity()
	elif "velocity" in body:
		velocity = body.velocity
	else:
		return false
	
	# Check if moving left with sufficient speed
	return velocity.x < -required_velocity_threshold

func has_valid_enemies_in_area() -> bool:
	for body in bodies_in_area:
		if is_instance_valid(body) and body is CharacterBody2D:
			if not is_player(body) and is_enemy_moving_right_to_left(body):
				return true
	return false

func open_door():
	print("\n>>> OPEN_DOOR CALLED <<<")
	print("Animation playing: ", animation_playing)
	
	if animation_playing:
		print("Animation already playing - returning")
		return
		
	print("Opening door for enemy")
	print("Door sprite: ", door_sprite)
	print("Door sprite valid: ", is_instance_valid(door_sprite) if door_sprite else false)
	
	if door_sprite:
		print("Sprite frames: ", door_sprite.sprite_frames)
		if door_sprite.sprite_frames:
			print("Available animations: ", door_sprite.sprite_frames.get_animation_names())
			print("Has 'open' animation: ", door_sprite.sprite_frames.has_animation("open"))
		else:
			print("ERROR: No sprite_frames found!")
	else:
		print("ERROR: door_sprite is null - check door_sprite_path!")
	
	animation_playing = true

	if door_sprite and door_sprite.sprite_frames and door_sprite.sprite_frames.has_animation("open"):
		print("Playing 'open' animation")
		door_sprite.play("open")
	else:
		print("No animation found - calling _on_animation_finished directly")
		_on_animation_finished()

func close_door():
	if animation_playing:
		return
		
	print("Closing door")
	animation_playing = true
	
	if door_sprite and door_sprite.sprite_frames and door_sprite.sprite_frames.has_animation("open"):
		door_sprite.play_backwards("open")
	else:
		_on_animation_finished()

func _on_animation_finished():
	print("\n>>> ANIMATION FINISHED <<<")
	print("Current animation: ", door_sprite.animation if door_sprite else "No sprite")
	print("Current frame: ", door_sprite.frame if door_sprite else "No sprite")
	
	animation_playing = false
	
	# Since we're not using actual animations, just handle the door state directly
	if not door_sprite or not door_sprite.sprite_frames or not door_sprite.sprite_frames.has_animation("open"):
		print("No animation system - handling door state manually")
		# If open_door() was called, we want to open the door
		# If close_door() was called, we want to close the door
		# We can track this with a simple flag or just assume opening for now
		is_door_open = true
		if door_collision:
			door_collision.disabled = true
			print(">>> DOOR OPENED - Collision disabled (manual)")
		else:
			print(">>> DOOR OPENED - No collision shape found!")
		return
	
	# Original animation logic for when animations exist
	if door_sprite and door_sprite.animation == "open":
		var frame_count = door_sprite.sprite_frames.get_frame_count("open") if door_sprite.sprite_frames else 0
		print("Frame count: ", frame_count)
		
		if door_sprite.frame == frame_count - 1:
			# Animation played forward (door opened)
			is_door_open = true
			if door_collision:
				door_collision.disabled = true
				print(">>> DOOR OPENED - Collision disabled")
			else:
				print(">>> DOOR OPENED - No collision shape found!")
		else:
			# Animation played backward (door closed)
			is_door_open = false
			if door_collision:
				door_collision.disabled = false
				print(">>> DOOR CLOSED - Collision enabled")
			else:
				print(">>> DOOR CLOSED - No collision shape found!")
	
	# Check if we need to open/close again based on current state
	print("Checking post-animation state...")
	print("Valid enemies in area: ", has_valid_enemies_in_area())
	print("Approaching enemies: ", has_approaching_enemies())
	
	if has_valid_enemies_in_area() and not is_door_open:
		print("Need to reopen door")
		call_deferred("open_door")
	elif not has_valid_enemies_in_area() and not has_approaching_enemies() and is_door_open:
		print("Need to close door")
		call_deferred("close_door")
