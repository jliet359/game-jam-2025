extends Line2D
@onready var player = get_parent().get_node("SlingShotPlayer")
var is_dragging = false
var trajectory_length = 200.0  # How far to show the trajectory
var slingshotonce = 0

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
		update_direction_line()
	elif Input.is_action_just_released("click"):
		is_dragging = false
		clear_points()
		slingshotonce += 1
	elif event is InputEventMouseMotion and is_dragging:
		update_direction_line()

func update_direction_line():
	var player_pos = player.global_position
	var mouse_pos = get_global_mouse_position()
	var direction = (player_pos - mouse_pos).normalized()
	var end_pos = player_pos + (direction * trajectory_length)
	
	clear_points()
	add_point(to_local(player_pos))  # Convert global to local
	add_point(to_local(end_pos))     # Convert global to local
