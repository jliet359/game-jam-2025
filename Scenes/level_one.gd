extends Node2D

func _ready() -> void:
	print("Script loaded and ready() called")
	
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

func _process(delta: float) -> void:
	pass

func _on_area_2d_body_entered(body: Node2D) -> void:
	print("=== BODY ENTERED ===")
	print("Body name: ", body.name)
	print("Body type: ", body.get_class())
	print("Body script: ", body.get_script())
	print("Body groups: ", body.get_groups())
	# Check if body has collision properties (physics bodies only)
	if body.has_method("get_collision_layer"):
		print("Body collision_layer: ", body.collision_layer)
		print("Body collision_mask: ", body.collision_mask)
	else:
		print("Body has no collision properties (not a physics body)")
	
	# Check if it's the player (adjust this condition as needed)
	if body.name == "SlingShotPlayer" or body.is_in_group("player"):
		print("Player detected! Changing scene...")
		
		var scene_path = "res://Scenes/main_menu.tscn"
		
		if ResourceLoader.exists(scene_path):
			print("Scene file exists, changing scene...")
			get_tree().change_scene_to_file(scene_path)
		else:
			print("ERROR: Scene file not found at ", scene_path)
	else:
		print("Not the player, ignoring...")

# Alternative debugging - check what's in the area continuously
func _on_area_2d_body_exited(body: Node2D) -> void:
	print("Body exited: ", body.name)

# Manual trigger for testing
func _input(event):
	if event.is_action_pressed("ui_accept"):  # Press Enter/Space to test
		print("Manual trigger - bodies in area:")
		var area = $Area2D
		if area:
			var bodies = area.get_overlapping_bodies()
			print("Bodies in area: ", bodies.size())
			for body in bodies:
				print("  - ", body.name, " (", body.get_class(), ")")
				_on_area_2d_body_entered(body)  # Manually trigger
