# TrajectoryLine.gd (or whatever this script is called)
extends Line2D

@onready var enemy = get_parent().get_parent() # assuming Line2D is child of enemy node
@onready var player = get_parent().get_node("SlingShotPlayer")
var is_dragging = false
var trajectory_length = 200.0  # How far to show the trajectory
var slingshotonce = 0

func _can_use_trajectory() -> bool:
	# Check if enemy exists
	if enemy == null:
		return false
	
	# Check if enemy has is_player and it's true
	if enemy.has_method("is_player"):
		return enemy.is_player()
	elif "is_player" in enemy:
		return enemy.is_player
	else:
		return false

func _input(event: InputEvent) -> void:
	# Only proceed if this is a player enemy (check dynamically)
	if not _can_use_trajectory():
		return
		
	# Early return if slingshot already used
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
