# TrajectoryLine.gd - FIXED VERSION
# This script creates a visual trajectory that accurately matches the actual physics

extends Node2D

# === NODE REFERENCES ===
@onready var enemy = get_parent().get_parent()
@onready var player = get_parent().get_node("SlingShotPlayer")

# === EXPORTED VARIABLES ===
@export var trajectory_dot_texture: Texture2D
@export var arrow_head_texture: Texture2D
@export var slingshot_strength: float = 3.0

# === STATE VARIABLES ===
var is_dragging = false
var slingshotonce = 0
var trajectory_length = 200.0

# === PHYSICS VARIABLES - FIXED TO MATCH GODOT PHYSICS ===
var gravity_strength: float  # Will be set from project settings
var trajectory_points = 25
var time_step = 0.016667  # 1/60th second (60 FPS) - matches Godot's default physics
var physics_time_scale = 60.0  # Convert from per-second to per-frame

# === SPRITE STORAGE ===
var dot_sprites: Array[Sprite2D] = []
var arrow_head_sprite: Sprite2D

func _ready():
	# Get actual gravity from project settings to match real physics
	gravity_strength = ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)
	print("Using gravity: ", gravity_strength)
	
	ensure_textures_loaded()
	
	if trajectory_dot_texture != null:
		create_dot_sprites()
	else:
		print("No dot texture available - trajectory dots will not be shown")
		
	if arrow_head_texture != null:
		create_arrow_head_sprite()
	else:
		print("No arrow head texture available - arrow head will not be shown")

func ensure_textures_loaded():
	if trajectory_dot_texture == null:
		var dot_path = "res://Sprites/Grayson/trajectory_dot.png"
		if ResourceLoader.exists(dot_path):
			trajectory_dot_texture = load(dot_path)
			print("Loaded trajectory dot texture from file")
		else:
			print("Trajectory dot texture not found at: ", dot_path)

	if arrow_head_texture == null:
		var arrow_path = "res://Sprites/Grayson/arrow_head.png"
		if ResourceLoader.exists(arrow_path):
			arrow_head_texture = load(arrow_path)
			print("Loaded arrow head texture from file")
		else:
			print("Arrow head texture not found at: ", arrow_path)

func create_dot_sprites():
	for i in range(trajectory_points):
		var dot = Sprite2D.new()
		dot.texture = trajectory_dot_texture
		dot.visible = false
		dot.scale = Vector2(0.5, 0.5)
		dot.modulate.a = 0.7
		add_child(dot)
		dot_sprites.append(dot)
	print("Created ", dot_sprites.size(), " dot sprites")

func create_arrow_head_sprite():
	arrow_head_sprite = Sprite2D.new()
	arrow_head_sprite.texture = arrow_head_texture
	arrow_head_sprite.visible = false
	add_child(arrow_head_sprite)
	print("Created arrow head sprite")

func can_use_trajectory() -> bool:
	if enemy == null:
		return false
	
	if enemy.has_method("is_player"):
		return enemy.is_player()
	elif "is_player" in enemy:
		return enemy.is_player
	else:
		return false

func _input(event: InputEvent) -> void:
	if not can_use_trajectory():
		return
		
	if slingshotonce >= 1:
		return
	
	if Input.is_action_just_pressed("click"):
		is_dragging = true
		update_trajectory()
		print("Started dragging")
		
	elif Input.is_action_just_released("click"):
		is_dragging = false
		hide_trajectory()
		slingshotonce += 1
		print("Released - trajectory hidden")
		
	elif event is InputEventMouseMotion and is_dragging:
		update_trajectory()

# === FIXED TRAJECTORY CALCULATION ===
func update_trajectory():
	if dot_sprites.is_empty():
		print("No dot sprites available for trajectory")
		return
	
	var player_pos = player.global_position
	var mouse_pos = get_global_mouse_position()
	
	# EXACT same calculation as your physics code
	var direction = player_pos - mouse_pos
	var powered_direction = direction * slingshot_strength
	
	# This should match how your player applies velocity
	var initial_velocity = powered_direction
	
	var pull_distance = direction.length()
	print("Pull distance: ", pull_distance, " Initial velocity: ", initial_velocity)
	
	# Calculate dots to show based on pull strength
	var min_dots = 8
	var max_dots = trajectory_points
	var pull_strength_normalized = min(pull_distance / 150.0, 1.0)
	var dots_to_show = int(min_dots + (max_dots - min_dots) * pull_strength_normalized)
	dots_to_show = min(dots_to_show, dot_sprites.size())
	
	# PHYSICS SIMULATION - FIXED to match RigidBody2D behavior
	var points_used = 0
	for i in range(dots_to_show):
		var t = i * time_step
		
		# Standard projectile motion equations
		# But using the ACTUAL gravity value from project settings
		var pos_x = player_pos.x + initial_velocity.x * t
		var pos_y = player_pos.y + initial_velocity.y * t + 0.5 * gravity_strength * t * t
		
		var trajectory_point = Vector2(pos_x, pos_y)
		
		dot_sprites[i].global_position = trajectory_point
		dot_sprites[i].visible = true
		points_used = i + 1
		
		if i < 3:
			print("Point ", i, " at time ", t, ": ", trajectory_point)
	
	# Hide unused dots
	for i in range(points_used, dot_sprites.size()):
		dot_sprites[i].visible = false
	
	# Position arrow head
	if points_used >= 2 and arrow_head_sprite != null:
		var last_pos = dot_sprites[points_used - 1].global_position
		var second_last_pos = dot_sprites[points_used - 2].global_position
		
		arrow_head_sprite.global_position = last_pos
		arrow_head_sprite.visible = true
		
		var direction_arrow = (last_pos - second_last_pos).normalized()
		arrow_head_sprite.rotation = direction_arrow.angle()

func hide_trajectory():
	for dot in dot_sprites:
		if dot != null:
			dot.visible = false
	if arrow_head_sprite != null:
		arrow_head_sprite.visible = false

func set_trajectory_opacity(opacity: float):
	for dot in dot_sprites:
		if dot != null:
			dot.modulate.a = opacity * 0.7
	if arrow_head_sprite != null:
		arrow_head_sprite.modulate.a = opacity

func animate_trajectory_in():
	var tween = create_tween()
	set_trajectory_opacity(0.0)
	tween.tween_method(set_trajectory_opacity, 0.0, 1.0, 0.2)

# === ADDITIONAL DEBUGGING FUNCTION ===
# Call this to print physics comparison values
func debug_physics_values():
	print("=== PHYSICS DEBUG ===")
	print("Project gravity: ", ProjectSettings.get_setting("physics/2d/default_gravity"))
	print("Trajectory gravity: ", gravity_strength)
	print("Time step: ", time_step)
	print("Slingshot strength: ", slingshot_strength)
	if player:
		print("Player gravity scale: ", player.gravity_scale)
		print("Player linear velocity: ", player.linear_velocity)
