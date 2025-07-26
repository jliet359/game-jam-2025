extends Node2D


@onready var enemy = get_parent().get_parent()
@onready var player = get_parent().get_node("SlingShotPlayer")


@export var slingshot_strength: float = 3.0
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
		#print("No pullback dot texture available - pullback line will not be shown")
		pass

# === TEXTURE LOADING ===
func ensure_texture_loaded():
	# Try to load pullback dot texture
	if pullback_dot_texture == null:
		var dot_path = "res://Sprites/Grayson/pullback_dot.png"
		if ResourceLoader.exists(dot_path):
			pullback_dot_texture = load(dot_path)
			#print("Loaded pullback dot texture from file")
		else:
			var fallback_path = "res://Sprites/Grayson/trajectory_dot.png"
			if ResourceLoader.exists(fallback_path):
				pullback_dot_texture = load(fallback_path)
				#print("Using trajectory dot texture for pullback line")
			else:
				#print("Pullback dot texture not found. Please add pullback_dot.png or trajectory_dot.png to res://Sprites/Grayson/")
				pass


func create_dot_sprites():
	# Create dot sprites for the pullback line
	for i in range(max_dots):
		var dot = Sprite2D.new()
		dot.texture = pullback_dot_texture
		dot.visible = false
		dot.scale = Vector2(0.6, 0.6)  # Slightly larger than trajectory dots
		dot.modulate = Color.WHITE  # Full opacity, white color
		add_child(dot)
		dot_sprites.append(dot)
	#print("Created ", dot_sprites.size(), " pullback dot sprites")


func can_use_slingshot() -> bool:
	if enemy == null:
		#print("Enemy is null!")
		return false
	
	# Check if enemy has is_player and it's true
	if enemy.has_method("is_player"):
		return enemy.is_player()
	elif "is_player" in enemy:
		return enemy.is_player
	else:
		#print("Enemy missing is_player property/method!")
		return false


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
		var powered_direction = direction * slingshot_strength
		player.dir = powered_direction

		var player_node = get_tree().current_scene.find_child("Player", true, false)

		if player_node and player_node.has_node("Camera2D"):
			player_node.get_node("Camera2D").enabled = false
			
		# Hide the pullback line
		hide_pullback_line()
		

		player.enable_gravity()
		# Free the HeadArea node when click is released
		var head_area = get_node_or_null("../HeadArea")
		if head_area:
			head_area.queue_free()
		
		# Apply gravity to player when click is released
		player.gravity_scale = 1.0
		player.sprite_2d.modulate.a = 1.0
		
	elif event is InputEventMouseMotion and is_dragging:
		update_pullback_line()


func update_pullback_line():
	# Skip if we don't have dot sprites
	if dot_sprites.is_empty():
		return
	

	var player_pos = player.global_position
	var mouse_pos = get_global_mouse_position()
	
	# Calculate the line from player to mouse
	var line_vector = mouse_pos - player_pos
	var line_length = line_vector.length()
	var line_direction = line_vector.normalized()
	
	# Calculate how many dots we need based on line length
	var dots_needed = int(line_length / dot_spacing)
	dots_needed = min(dots_needed, dot_sprites.size())  # Don't exceed available sprites
	
	# Position dots along the line
	for i in range(dots_needed):
		if i < dot_sprites.size():
			# Calculate position for this dot
			var dot_distance = (i + 1) * dot_spacing  # Start from dot_spacing, not 0
			var dot_position = player_pos + line_direction * dot_distance
			
			# Position and show the dot
			dot_sprites[i].global_position = dot_position
			dot_sprites[i].visible = true
			
			# Optional: Make dots fade out towards the mouse
			var fade_factor = 1.0 - (float(i) / float(dots_needed))
			dot_sprites[i].modulate.a = 0.5 + (fade_factor * 0.5)  # Range from 0.5 to 1.0 opacity
	
	# Hide unused dots
	for i in range(dots_needed, dot_sprites.size()):
		dot_sprites[i].visible = false


func hide_pullback_line():
	# Hide all dot sprites
	for dot in dot_sprites:
		if dot != null:
			dot.visible = false


# Change the color of all pullback dots
func set_pullback_color(color: Color):
	for dot in dot_sprites:
		if dot != null:
			dot.modulate = color

# Change the spacing between dots
func set_dot_spacing(new_spacing: float):
	dot_spacing = new_spacing

# Animate the pullback line appearing
func animate_pullback_in():
	var tween = create_tween()
	# Start invisible
	for dot in dot_sprites:
		if dot != null and dot.visible:
			dot.modulate.a = 0.0
	# Fade in over 0.1 seconds
	tween.tween_method(set_pullback_opacity, 0.0, 1.0, 0.1)

func set_pullback_opacity(opacity: float):
	for dot in dot_sprites:
		if dot != null and dot.visible:
			dot.modulate.a = opacity
