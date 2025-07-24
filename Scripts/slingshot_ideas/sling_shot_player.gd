# SlingShotPlayer.gd
extends RigidBody2D
var dir: Vector2 = Vector2.ZERO

func _ready():
	modulate.a = 0.0
	print("Player ready - Initial gravity_scale: ", gravity_scale)
	gravity_scale = 0.0
	print("Player ready - Gravity set to: ", gravity_scale)
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
		
	modulate.a = 1.0
func _physics_process(_delta: float) -> void:
	linear_velocity = dir
	dir = lerp(dir, Vector2.ZERO, 0.03)

func enable_gravity():
	print("enable_gravity() function called!")
	print("Before: gravity_scale = ", gravity_scale)
	print("Before: linear_velocity = ", linear_velocity)
	
	# Enable gravity
	gravity_scale = 1.0
	
	# Add initial downward push
	linear_velocity += Vector2(0, 200)
	
	print("After: gravity_scale = ", gravity_scale)
	print("After: linear_velocity = ", linear_velocity)
	
	# Check project settings
	print("Project gravity: ", ProjectSettings.get_setting("physics/2d/default_gravity"))
	print("Project gravity vector: ", ProjectSettings.get_setting("physics/2d/default_gravity_vector"))
