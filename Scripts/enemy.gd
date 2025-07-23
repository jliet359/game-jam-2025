extends CharacterBody2D

var SPEED = 200.0
const JUMP_VELOCITY = -400.0
var is_player = false
var can_be_possessed = true

@onready var enemy: AnimatedSprite2D = $AnimatedSprite2D
@onready var timer: Timer = $Timer
@onready var possess_area: Area2D = $Area2D
@onready var collision: CollisionShape2D = $CollisionShape2D2
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var timer_2: Timer = $Timer2
@onready var head_area: Area2D = $HeadArea



func _ready():
	modulate = Color(1, 1, 1)  # Reset to default white
	
	
func become_player():
	var player = get_tree().get_first_node_in_group("player")
	print("Found player:", player)
	
	if player:
		# Get the Area2D on the head (adjust the path to your actual Area2D node)
		if has_node("HeadArea"):
			var head_area = get_node("HeadArea")
			print("Found head area at:", head_area.global_position)
			
			player.set_deferred("global_position", head_area.global_position)
			
			if player.has_method("set_linear_velocity") or "linear_velocity" in player:
				player.linear_velocity = Vector2.ZERO
				print("Player moved to head area at: ", head_area.global_position)
		else:
			print("Head area not found on: ", self.name)
	else:
		print("Player not found!")
		
		
	is_player = true
	modulate = Color(0, 1, 0)
	timer.wait_time = 3.0
	timer.start()
	can_be_possessed = false

	print("Enemy has become player!")
	
func _on_timer_timeout() -> void:
	after_possess()

func after_possess():
	enemy.play("dead")
	is_player = false
	remove_child(collision)

	# Use actual node path (adjust path as needed)
	var player = get_node("../RigidBodyPlayer")  # or whatever the actual path is
	if player:
		player.animated_sprite_2d.modulate.a = 1.0
		print("Player found and made visible!")
	else:
		print("Player not found at path!")
		
	modulate = Color(0.43,0.15,0.05)
	timer_2.wait_time = 6.0
	timer_2.start()

func _on_timer_2_timeout() -> void:
	
	animation_player.play("die")
	await animation_player.animation_finished
	queue_free() 


func _physics_process(delta: float) -> void:
	if is_player:# Add the gravity.
		if not is_on_floor():
			velocity += get_gravity() * delta
				# Handle jump.
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = JUMP_VELOCITY
		# Get the input direction and handle the movement/deceleration.
		# Gets input direction: -1,0,1
		var direction := Input.get_axis("move_left", "move_right")
		# Flip the Sprite
		if direction > 0:
			enemy.flip_h = true
		elif direction < 0:
			enemy.flip_h = false
		# Play Animations
		if is_on_floor():
			if direction == 0:
				enemy.play("idle")
			else: 
				enemy.play("walk")
		else:
			enemy.play("jump")
				
		if direction:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

		move_and_slide()
