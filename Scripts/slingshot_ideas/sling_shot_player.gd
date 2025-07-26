extends RigidBody2D

var dir: Vector2 = Vector2.ZERO
var gravity_enabled: bool = false
var on_floor = false
@onready var sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
var floor_ani = 0


var enemy_character = null
var player_character = null
var has_teleported = false

func _ready():
	continuous_cd = RigidBody2D.CCD_MODE_CAST_RAY
	sprite_2d.modulate.a = 0.0
	#print("Player ready - Initial gravity_scale: ", gravity_scale)
	contact_monitor = true
	max_contacts_reported = 10
	#print("Contact monitoring enabled: ", contact_monitor)
	#print("Max contacts: ", max_contacts_reported)
	
	# Method 1
	player_character = get_tree().current_scene.find_child("Player", true, false)
	if player_character != null:
		print("Found player using Method 1: find_child()") 
		pass
	else:
		print("Method 1 failed")
		pass
	"""
	# Method 2
	if player_character == null:
		var players = get_tree().get_nodes_in_group("player")
		if not players.is_empty():
			player_character = players[0]
			print("Found player using Method 2: group 'player'")
		else:
			print("Method 2 failed")
			pass
	
	# Method 3
	if player_character == null:
		player_character = get_node_or_null("../Player")  # Adjust path as needed
		if player_character:
			print("Found player using Method 3: .../Player")
			pass
		else:
			print("Method 3 failed")
			pass
	"""
	
	enemy_character = get_tree().current_scene.find_child("Enemy", true, false)
	if enemy_character != null:
		print("Found enemy using Method 1: find_child()") 
		pass
	else:
		print("Method 1 failed")
		pass

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	var floor_normal = Vector2.UP
	
	# Debug: Print contact information
	if state.get_contact_count() > 0:
		#print("Contact count: ", state.get_contact_count())
		pass
	
	
	for i in range(state.get_contact_count()):
		var contact_normal = state.get_contact_local_normal(i)
		var dot_product = contact_normal.dot(floor_normal)
		#print("Contact ", i, " normal: ", contact_normal, " dot: ", dot_product)
		
		if dot_product > 0.7:  # Allow for slopes
			on_floor = true
			#print("Floor detected!")
			break
	
	#print("Final on_floor status: ", on_floor)
	if floor_ani >= 1:
		return
	if on_floor == true :
		
		sprite_2d.play("floor")

		
func _input(_event: InputEvent) -> void:

	if enemy_character == null:
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
		if not enemy_character.has_method("is_player") and not "is_player" in enemy_character:
			#print("Enemy doesn't have is_player property!")
			return
		if not enemy_character.is_player:
			#print("Enemy is_player is false, blocking input")
			return
		#print("Enemy is_player is true, allowing input")
		
	modulate.a = 1.0

func _physics_process(_delta: float) -> void:
	if not gravity_enabled:
		# Before gravity is enabled, control velocity directly
		linear_velocity = dir
		dir = lerp(dir, Vector2.ZERO, 0.03)
	else:
		# After gravity is enabled, only apply horizontal movement
		"""
		linear_velocity.x = dir.x
		dir.x = lerp(dir.x, 0.0, 0.03)
		"""
		pass
		
func enable_gravity():
	#print("enable_gravity() function called!")
	#print("Before: gravity_scale = ", gravity_scale)
	#print("Before: linear_velocity = ", linear_velocity)
	
	# Enable gravity
	gravity_scale = 1.0
	gravity_enabled = true
	
	# Add initial impulse from slingshot direction
	linear_velocity = dir
	
	#print("After: gravity_scale = ", gravity_scale)
	#print("After: linear_velocity = ", linear_velocity)
	
	# Check project settings
	#print("Project gravity: ", ProjectSettings.get_setting("physics/2d/default_gravity"))
	#print("Project gravity vector: ", ProjectSettings.get_setting("physics/2d/default_gravity_vector"))
	
func _on_possess_area_body_entered(body: Node2D) -> void:
	if not on_floor and body.is_in_group("enemies") and body.has_method("become_player") and body.can_be_possessed:
		# ✅ Disable its camera if it exists
		if player_character and player_character.has_node("Camera2D"):
			player_character.get_node("Camera2D").enabled = true
			print("switching camera")
		#print("[_on_possess_area_body_entered] Hit body: ", body.name)
		#print("infected from slingshot")
		#print("[Possession Triggered] Possessing enemy: ", body.name)
		#print("[Possession] Killing old enemy: ", enemy_character.name)
		player_character.live.reset_health()
		
		sprite_2d.modulate.a = 0.0
		#player_character.animated_sprite_2d.modulate.a = 0.0
		#player_character.animated_sprite_2d.z_index = 0
		#enemy_character.animated_sprite_2d.z_index = 1
		
		enemy_character.after_possess()
		enemy_character.timer.stop()
		enemy_character.timer_2.stop()
		if enemy_character.timer.is_connected("timeout", Callable(enemy_character, "_on_timer_timeout")):
			enemy_character.timer.disconnect("timeout", Callable(enemy_character, "_on_timer_timeout"))
		
		# Teleport player to the new enemy's position
		if player_character != null:
			#print("player_character is not null")
			#print("Attempting to teleport to enemy position:", body.global_position)
			# Check if body (enemy) is valid
			if body != null:
				#print("body (enemy) is valid")
				# Attempt to set the global position
				if player_character.has_method("set_global_position"):
					#print("player_character has method 'set_global_position'
					player_character.global_position = body.global_position
					#print("player_character global_position set via set_global_position")
				else:
					#print("'set_global_position' not found. Using direct assignment")
					player_character.global_position = body.global_position
					#print("player_character global_position assigned directly")
				# Attempt to hide the player's AnimatedSprite2D
				if player_character.has_node("AnimatedSprite2D"):
					#print("Found 'AnimatedSprite2D' in player_character")
					var sprite = player_character.get_node("AnimatedSprite2D")
					sprite.visible = false
					#print("AnimatedSprite2D is now hidden")
				else:
					#print("AnimatedSprite2D node not found in player_character!")
					pass
				#print("Player teleported to enemy position successfully!")
			else:
				#print("body (enemy) is null – cannot teleport!")
				pass
		else:
			#print("player_character is null – cannot teleport!")\
			pass
		#print("[Possession] Setting new enemy_character to: ", body.name)
		enemy_character = body
		#print("[Possession] enemy_character assigned to: ", enemy_character.name)
		body.become_player()
		player_character.timer.wait_time = 3.0
		player_character.timer.start()
		#print("PossessArea entered by: ", body.name)
		pass # Replace with function body.
		queue_free()
		
func _on_animated_sprite_2d_animation_finished() -> void:
	# TELEPORT PLAYER TO THIS POSITION WHEN FLOOR IS DETECTED
	#print("[Animation Finished] Starting player teleport logic...")

	if player_character != null and not has_teleported:
		#print("[Animation Finished] Teleporting player to: ", global_position)
		
		if player_character.has_method("set_global_position"):
			player_character.global_position = global_position
		else:
			player_character.position = global_position

		player_character.animated_sprite_2d.modulate.a = 1.0
		has_teleported = true
		#print("[Animation Finished] Player teleported successfully.")

	else:
		if player_character == null:
			#print("[Animation Finished] Player character is null.")
			pass
		if has_teleported:
			#print("[Animation Finished] Player already teleported.")
			pass

	queue_free()
	floor_ani += 1

	if enemy_character == null:
		#print("[Animation Finished] WARNING: enemy_character is null, cannot modify is_player!")
		pass
	else:
		enemy_character.is_player = false
		#print("[Animation Finished] enemy_character.is_player set to false")

	# Re-enable camera
	if player_character and player_character.has_node("Camera2D"):
		player_character.get_node("Camera2D").enabled = true
		#print("[Animation Finished] Player camera enabled")
	else:
		#print("[Animation Finished] No Camera2D node found on player")
		pass
