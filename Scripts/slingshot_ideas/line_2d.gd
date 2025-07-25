# PullbackLine.gd
extends Line2D
@onready var player = get_parent().get_node("SlingShotPlayer")
var is_dragging = false
var slingshotonce = 0

@export var slingshot_strength: float = 3.0
	
func _input(event: InputEvent) -> void:
	
	# Debug: Let's see what we can find
	#print("Searching for Enemy node...")
	
	# Try finding Enemy by name anywhere in the scene
	var enemy = get_tree().current_scene.find_child("Enemy", true, false)
	
	if enemy == null:
		#print("Enemy node not found! Trying alternative methods...")
		# Try groups approach instead
		var enemies = get_tree().get_nodes_in_group("enemies")
		if enemies.is_empty():
			pass
			#print("No enemies in group, allowing input")
			# Continue with input processing
		else:
			#print("Found enemies in group, blocking input")
			return
	else:
		#print("Found enemy node: ", enemy.name)
		if not enemy.has_method("is_player") and not "is_player" in enemy:
			#print("Enemy doesn't have is_player property!")
			return
		if not enemy.is_player:
			#print("Enemy is_player is false, blocking input")
			return
		#print("Enemy is_player is true, allowing input")
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
		slingshotonce = slingshotonce + 1
		is_dragging = false
		var direction = player.global_position - get_global_mouse_position()
		
		var powered_direction = direction * slingshot_strength
		player.dir = powered_direction
		
		print("Direction: ", direction)
		print("Powered direction: ", powered_direction)
		print("Slingshot strength: ", slingshot_strength)
		
		
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
		slingshotonce += 1
		
	elif event is InputEventMouseMotion and is_dragging:
		var player_pos = player.global_position
		var mouse_pos = get_global_mouse_position()
		
		if get_point_count() >= 2:
			set_point_position(0, to_local(player_pos))
			set_point_position(1, to_local(mouse_pos))
