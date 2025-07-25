# SlingShotPlayer.gd
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
	gravity_scale = 0.0
	#print("Player ready - Gravity set to: ", gravity_scale)
	contact_monitor = true
	max_contacts_reported = 10
	#print("Contact monitoring enabled: ", contact_monitor)
	#print("Max contacts: ", max_contacts_reported)
	player_character = get_tree().current_scene.find_child("Player", true, false)
	
	# Method 2: Find by group (if your player is in a group called "player")
	if player_character == null:
		var players = get_tree().get_nodes_in_group("player")
		if not players.is_empty():
			player_character = players[0]
	
	# Method 3: Get from a specific path (adjust path as needed)
	if player_character == null:
		player_character = get_node_or_null("../Player")  # Adjust path as needed
	
	if player_character == null:
		#print("Warning: Player character not found!")
		pass
	else:
		#print("Player character found: ", player_character.name)
		pass
		
	enemy_character = get_tree().current_scene.find_child("Enemy", true, false)
	
	# Method 2: Find by group (if your player is in a group called "player")
	if enemy_character == null:
		var enemies = get_tree().get_nodes_in_group("enemy")
		if not enemies.is_empty():
			enemy_character = enemies[0]
	
	# Method 3: Get from a specific path (adjust path as needed)
	if enemy_character == null:
		enemy_character = get_node_or_null("../Enemy")  # Adjust path as needed
	
	if enemy_character == null:
		pass
		#print("Warning: Enemy character not found!")
	else:
		pass
		#print("Enemy character found: ", enemy_character.name)
		
		
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
	if not gravity_enabled:
		# Before gravity is enabled, control velocity directly
		linear_velocity = dir
		dir = lerp(dir, Vector2.ZERO, 0.03)
	else:
		# After gravity is enabled, only apply horizontal movement
		# Let physics handle vertical movement (gravity)
		linear_velocity.x = dir.x
		dir.x = lerp(dir.x, 0.0, 0.03)
		# Don't touch linear_velocity.y - let gravity handle it

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
		print("infected from slingshot")
		queue_free()
		player_character.live.reset_health()
		sprite_2d.modulate.a = 0.0
		player_character.animated_sprite_2d.modulate.a = 0.0
		# Disable collision
		var col = player_character.get_node_or_null("CollisionShape2D")
		if col: col.disabled = true
		enemy_character.timer.stop()
		enemy_character.after_possess()
		
		# Teleport player to the new enemy's position
		if player_character != null:
			print("Teleporting player to enemy position: ", body.global_position)
			
			# Teleport to enemy's center position
			if player_character.has_method("set_global_position"):
				player_character.global_position = body.global_position
				player_character.animated_sprite_2d.modulate.a = 0.0
				player_character.animated_sprite_2d.visible = false
				player_character.z_index = self.z_index - 1
			else:
				player_character.position = body.global_position
				player_character.animated_sprite_2d.modulate.a = 0.0
				player_character.animated_sprite_2d.visible = false
			print("Player teleported to enemy successfully!")
		
		body.become_player()
		player_character.animated_sprite_2d.modulate.a = 0.0
		player_character.timer.wait_time = 3.0
		player_character.timer.start()
		#print("PossessArea entered by: ", body.name)
	pass # Replace with function body.


func _on_animated_sprite_2d_animation_finished() -> void:
	# TELEPORT PLAYER TO THIS POSITION WHEN FLOOR IS DETECTED
	if player_character != null and not has_teleported:
		#print("Teleporting player to slingshot position: ", global_position)
		# Different methods depending on your player type:
		if player_character.has_method("set_global_position"):
			player_character.global_position = global_position
			player_character.z_index = self.z_index - 1
			
		else:
			player_character.position = global_position
			player_character.z_index = self.z_index - 1
		has_teleported = true  # Prevent multiple teleports
		player_character.animated_sprite_2d.modulate.a = 1.0
			#print("Player teleported successfully!")
		pass
	queue_free()
	floor_ani += 1
	enemy_character.is_player = false
	pass # Replace with function body.
