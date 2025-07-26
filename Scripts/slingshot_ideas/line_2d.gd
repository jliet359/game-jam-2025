# PullbackLine.gd
extends Line2D

@onready var enemy = get_parent().get_parent() # assuming Line2D is child of enemy node
@onready var player = get_parent().get_node("SlingShotPlayer")
var is_dragging = false
var slingshotonce = 0
@export var slingshot_strength: float = 3.0

func _can_use_slingshot() -> bool:
	# Check if enemy exists
	if enemy == null:
		print("Enemy is null!")
		return false
	
	# Check if enemy has is_player and it's true
	if enemy.has_method("is_player"):
		return enemy.is_player()
	elif "is_player" in enemy:
		return enemy.is_player
	else:
		print("Enemy missing is_player property/method!")
		return false

func _input(event: InputEvent) -> void:
	# Only proceed if this is a player enemy (check dynamically)
	if not _can_use_slingshot():
		return
		
	# Early return if slingshot already used
	if slingshotonce >= 1:
		return
	
	# Handle click action press/release
	if Input.is_action_just_pressed("click"):
		is_dragging = true
		var player_pos = player.global_position
		var mouse_pos = get_global_mouse_position()
		
		clear_points()
		add_point(to_local(player_pos))  # Convert to local coordinates
		add_point(to_local(mouse_pos))   # Convert to local coordinates
		
	elif Input.is_action_just_released("click"):
		slingshotonce += 1
		is_dragging = false
		var direction = player.global_position - get_global_mouse_position()
		
		var powered_direction = direction * slingshot_strength
		player.dir = powered_direction
		
		clear_points()
		# Call the function to apply gravity once
		player.enable_gravity()
		# Free the HeadArea node when click is released
		var head_area = get_node_or_null("../HeadArea")
		if head_area:
			head_area.queue_free()
		
		# Apply gravity to player when click is released
		player.gravity_scale = 1.0
		player.sprite_2d.modulate.a = 1.0
		
	elif event is InputEventMouseMotion and is_dragging:
		var player_pos = player.global_position
		var mouse_pos = get_global_mouse_position()
		
		if get_point_count() >= 2:
			set_point_position(0, to_local(player_pos))
			set_point_position(1, to_local(mouse_pos))
