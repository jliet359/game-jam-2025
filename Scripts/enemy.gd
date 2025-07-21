extends CharacterBody2D

var SPEED = 200.0
const JUMP_VELOCITY = -400.0
var is_player = false

@onready var player: CharacterBody2D = $"."
@onready var enemy: AnimatedSprite2D = $AnimatedSprite2D
@onready var timer: Timer = $Timer
@onready var collision_shape_2d: CollisionShape2D = $Area2D/CollisionShape2D
@onready var area_2d: Area2D = $Area2D
@onready var collision_shape_2d_2: CollisionShape2D = $CollisionShape2D2


func become_player():
	is_player = true
	modulate = Color(0, 1, 0)
	timer.wait_time = 3.0
	timer.start()
	
	print("Enemy has become player!")
	
func _on_timer_timeout() -> void:
	after_possess()

func after_possess():
	enemy.play("dead")
	is_player = false
	modulate = Color(0.43,0.15,0.05)
	remove_child(area_2d)
	remove_child(collision_shape_2d_2)
	# $Area2D.disconnect("body_entered", become_player())


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
