extends Node2D

# Time Counter variables
var elapsed_time: float = 0.0
var counter_running: bool = true

# UI Timer display
var timer_label: Label = null

func _ready() -> void:
	print("Script loaded and ready() called")
	
	# Start the time counter
	start_counter()
	
	# Create timer display
	create_timer_display()
	
	# Find and verify Area2D exists
	var area = $Area2D  # Adjust path if needed
	if area:
		print("Area2D found: ", area.name)
		print("Area2D monitoring: ", area.monitoring)
		print("Area2D monitorable: ", area.monitorable)
		
		# Check if signal is connected
		if area.body_entered.is_connected(_on_area_2d_body_entered):
			print("Signal is connected!")
		else:
			print("WARNING: Signal is NOT connected!")
			# Connect it manually if needed
			area.body_entered.connect(_on_area_2d_body_entered)
			print("Signal connected manually")
			
		# Check collision layer/mask
		print("Area2D collision_layer: ", area.collision_layer)
		print("Area2D collision_mask: ", area.collision_mask)
		
		# Check for CollisionShape2D
		var collision_shape = area.get_child(0)
		if collision_shape is CollisionShape2D:
			print("CollisionShape2D found: ", collision_shape.name)
			if collision_shape.shape:
				print("Shape assigned: ", collision_shape.shape)
			else:
				print("ERROR: No shape assigned to CollisionShape2D!")
		else:
			print("ERROR: No CollisionShape2D found as first child!")
	else:
		print("ERROR: Area2D not found!")

# === TIME COUNTER FUNCTIONS ===
func start_counter():
	elapsed_time = 0.0
	counter_running = true
	print("Time counter started")

func stop_counter():
	counter_running = false
	print("Time counter stopped at: ", format_time_display(elapsed_time))
	return elapsed_time

func get_elapsed_time() -> float:
	return elapsed_time

func reset_counter():
	elapsed_time = 0.0
	print("Time counter reset")

# Format time as MM:SS
func format_time_display(time_seconds: float) -> String:
	var minutes = int(time_seconds) / 60
	var seconds = int(time_seconds) % 60
	return "%02d:%02d" % [minutes, seconds]

# Create on-screen timer display
func create_timer_display():
	timer_label = Label.new()
	timer_label.text = "00:00"
	timer_label.position = Vector2(10, 10)
	timer_label.z_index = 100
	timer_label.add_theme_font_size_override("font_size", 32)
	timer_label.add_theme_color_override("font_color", Color.WHITE)
	timer_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	timer_label.add_theme_constant_override("shadow_offset_x", 2)
	timer_label.add_theme_constant_override("shadow_offset_y", 2)
	add_child(timer_label)
	print("Timer display created")

func _process(delta: float) -> void:
	# Update time counter
	if counter_running:
		elapsed_time += delta
		
	# Update timer display
	if timer_label:
		timer_label.text = format_time_display(elapsed_time)

func _on_area_2d_body_entered(body: Node2D) -> void:
	#print("=== BODY ENTERED ===")
	#print("Body name: ", body.name)
	#print("Body type: ", body.get_class())
	#print("Body script: ", body.get_script())
	#print("Body groups: ", body.get_groups())
	
	# Log current time when body enters
	#print("Body entered at time: ", format_time_display(elapsed_time))
	
	# Check if body has collision properties (physics bodies only)
	if body.has_method("get_collision_layer"):
		#print("Body collision_layer: ", body.collision_layer)
		#print("Body collision_mask: ", body.collision_mask)
		pass
	else:
		#print("Body has no collision properties (not a physics body)")
		pass
	
	# Check if it's the player (adjust this condition as needed)
	if body.name == "SlingShotPlayer" or body.is_in_group("player"):
		print("Player detected! Changing scene...")
		
		# Stop the counter and get final time
		var final_time = stop_counter()
		print("FINAL TIME: ", format_time_display(final_time))
		
		var scene_path = "res://cutscene/final.tscn"
		
		if ResourceLoader.exists(scene_path):
			print("Scene file exists, changing scene...")
			get_tree().change_scene_to_file(scene_path)
		else:
			print("ERROR: Scene file not found at ", scene_path)
	else:
		print("Not the player, ignoring...")

func _on_area_2d_body_exited(body: Node2D) -> void:
	#print("Body exited: ", body.name, " at time: ", format_time_display(elapsed_time))
	pass
# Manual trigger for testing
func _input(event):
	if event.is_action_pressed("ui_accept"):  # Press Enter/Space to test
		#print("Manual trigger - Current time: ", format_time_display(elapsed_time))
		
		var area = $Area2D
		if area:
			var bodies = area.get_overlapping_bodies()
			#print("Bodies in area: ", bodies.size())
			for body in bodies:
				print("  - ", body.name, " (", body.get_class(), ")")
				_on_area_2d_body_entered(body)  # Manually trigger
	
	# Debug hotkeys
	if event.is_action_pressed("ui_cancel"):  # ESC key - stop counter
		var final_time = stop_counter()
		print("Counter stopped. Final time: ", format_time_display(final_time))
	
	if event.is_action_pressed("ui_select"):  # Space key - show current time
		print("Current time: ", format_time_display(elapsed_time))

# Public functions for other scripts
func get_current_time() -> float:
	return elapsed_time

func get_formatted_time() -> String:
	return format_time_display(elapsed_time)

func is_counter_running() -> bool:
	return counter_running

func pause_counter():
	counter_running = false
	print("Counter paused at: ", format_time_display(elapsed_time))

func resume_counter():
	counter_running = true
	print("Counter resumed at: ", format_time_display(elapsed_time))
