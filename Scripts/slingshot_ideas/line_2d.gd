extends Node2D

@onready var enemy = get_parent().get_parent()
@onready var player = get_parent().get_node("SlingShotPlayer")
@onready var camera_2d: Camera2D = $"../SlingShotPlayer/Camera2D"

@export var base_slingshot_strength: float = 3.0  # Base multiplier
@export var max_slingshot_strength: float = 3.0   # Maximum multiplier
@export var min_pull_distance: float = 50.0       # Minimum distance for any force
@export var max_pull_distance: float = 300.0      # Distance for maximum force
@export var min_x_force: float = 50            # Minimum horizontal force
@export var min_y_force: float = 300            # Minimum vertical force
@export var pullback_dot_texture: Texture2D  
@export var dot_spacing: float = 20.0
@export var max_dots: int = 20

var is_dragging = false
var slingshotonce = 0
var dot_sprites: Array[Sprite2D] = [] 

func _ready():
	ensure_texture_loaded()
	if pullback_dot_texture != null:
		create_dot_sprites()
	else:
		pass

# === TEXTURE LOADING ===
func ensure_texture_loaded():
	if pullback_dot_texture == null:
		var dot_path = "res://Sprites/Grayson/pullback_dot.png"
		if ResourceLoader.exists(dot_path):
			pullback_dot_texture = load(dot_path)
		else:
			var fallback_path = "res://Sprites/Grayson/trajectory_dot.png"
			if ResourceLoader.exists(fallback_path):
				pullback_dot_texture = load(fallback_path)
			else:
				pass

func create_dot_sprites():
	for i in range(max_dots):
		var dot = Sprite2D.new()
		dot.texture = pullback_dot_texture
		dot.visible = false
		dot.scale = Vector2(0.6, 0.6)
		dot.modulate = Color.WHITE
		add_child(dot)
		dot_sprites.append(dot)

func can_use_slingshot() -> bool:
	if enemy == null:
		return false
	
	if enemy.has_method("is_player"):
		return enemy.is_player()
	elif "is_player" in enemy:
		return enemy.is_player
	else:
		return false

func apply_minimum_forces(force_vector: Vector2) -> Vector2:
	var final_force = force_vector
	
	# Apply minimum X force (horizontal)
	if abs(final_force.x) > 0 and abs(final_force.x) < min_x_force:
		# Preserve direction but ensure minimum magnitude
		final_force.x = sign(final_force.x) * min_x_force
	
	# Apply minimum Y force (vertical) 
	if abs(final_force.y) > 0 and abs(final_force.y) < min_y_force:
		# Preserve direction but ensure minimum magnitude
		final_force.y = sign(final_force.y) * min_y_force
	
	return final_force

func calculate_slingshot_strength(pull_distance: float) -> float:
	# Don't apply force if pull is too small
	if pull_distance < min_pull_distance:
		return 0.0
	
	# Calculate strength based on pull distance
	var distance_ratio = clamp((pull_distance - min_pull_distance) / (max_pull_distance - min_pull_distance), 0.0, 1.0)
	
	# Use a curve for more natural feel - square root gives good results
	var strength = base_slingshot_strength + (max_slingshot_strength - base_slingshot_strength) * sqrt(distance_ratio)
	
	return strength

func _input(event: InputEvent) -> void:
	if not can_use_slingshot():
		return
	if slingshotonce >= 1:
		return

	if Input.is_action_just_pressed("click"):
		is_dragging = true
		update_pullback_line()
		
	elif Input.is_action_just_released("click"):
		slingshotonce += 1
		is_dragging = false
		
		var direction = player.global_position - get_global_mouse_position()
		var pull_distance = direction.length()
		
		# Calculate dynamic strength based on pull distance
		var dynamic_strength = calculate_slingshot_strength(pull_distance)
		
		# Apply the force with minimum force constraints
		var base_force = direction.normalized() * pull_distance * dynamic_strength
		var final_force = apply_minimum_forces(base_force)
		
		# Optional: Add some debug output
		print("Pull distance: ", pull_distance, " | Strength: ", dynamic_strength)
		print("Base force: ", base_force, " | Final force: ", final_force)
		
		player.dir = final_force

		var player_node = get_tree().current_scene.find_child("Player", true, false)

		if player_node and player_node.has_node("Camera2D"):
			player_node.get_node("Camera2D").enabled = false
			
		if enemy.is_player:
			var _slingshot_camera = get_node_or_null("Camera2D")
			
		if camera_2d:
			camera_2d.enabled = true
			camera_2d.make_current()
		enemy.after_possess()
		
		hide_pullback_line()
		player.enable_gravity()
		
		var head_area = get_node_or_null("../HeadArea")
		if head_area:
			head_area.queue_free()
		
		player.gravity_scale = 1.0
		player.sprite_2d.modulate.a = 1.0
		
	elif event is InputEventMouseMotion and is_dragging:
		update_pullback_line()

func update_pullback_line():
	if dot_sprites.is_empty():
		return
	
	var player_pos = player.global_position
	var mouse_pos = get_global_mouse_position()
	
	var line_vector = mouse_pos - player_pos
	var line_length = line_vector.length()
	var line_direction = line_vector.normalized()
	
	# Visual feedback: change dot color based on pull strength
	var pull_strength = calculate_slingshot_strength(line_length)
	var strength_ratio = pull_strength / max_slingshot_strength
	var line_color = Color.WHITE.lerp(Color.RED, strength_ratio)
	
	var dots_needed = int(line_length / dot_spacing)
	dots_needed = min(dots_needed, dot_sprites.size())
	
	for i in range(dots_needed):
		if i < dot_sprites.size():
			var dot_distance = (i + 1) * dot_spacing
			var dot_position = player_pos + line_direction * dot_distance
			
			dot_sprites[i].global_position = dot_position
			dot_sprites[i].visible = true
			dot_sprites[i].modulate = line_color
			
			var fade_factor = 1.0 - (float(i) / float(dots_needed))
			dot_sprites[i].modulate.a = 0.5 + (fade_factor * 0.5)
	
	for i in range(dots_needed, dot_sprites.size()):
		dot_sprites[i].visible = false

func hide_pullback_line():
	for dot in dot_sprites:
		if dot != null:
			dot.visible = false

func set_pullback_color(color: Color):
	for dot in dot_sprites:
		if dot != null:
			dot.modulate = color

func set_dot_spacing(new_spacing: float):
	dot_spacing = new_spacing

func animate_pullback_in():
	var tween = create_tween()
	for dot in dot_sprites:
		if dot != null and dot.visible:
			dot.modulate.a = 0.0
	tween.tween_method(set_pullback_opacity, 0.0, 1.0, 0.1)

func set_pullback_opacity(opacity: float):
	for dot in dot_sprites:
		if dot != null and dot.visible:
			dot.modulate.a = opacity
