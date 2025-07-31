extends CharacterBody2D

const SPEED = 200.0
const JUMP_VELOCITY = -400
const GRAVITY = 980.0  # Add gravity constant

@onready var camera = $Camera2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var player: CharacterBody2D = $"."
@onready var area_2d: Area2D = $"../Area2D"


var dir = Vector2.ZERO


func _physics_process(delta: float) -> void:
		# Handle jump.
		if not visible:
			return
		if not is_on_floor():
			velocity.y += GRAVITY * delta
		if Input.is_action_just_pressed("jump"):
			velocity.y = JUMP_VELOCITY
		# Get the input direction and handle the movement/deceleration.
		# Gets input direction: -1,0,1
		var direction := Input.get_axis("move_left", "move_right")
		# Flip the Sprite
		if direction > 0:
			animated_sprite_2d.flip_h = false
		elif direction < 0:
			animated_sprite_2d.flip_h = true
		# Play Animations
		if is_on_floor():
			if direction == 0:
				animated_sprite_2d.play("idle")
			else: 
				animated_sprite_2d.play("walk")
		else:
			animated_sprite_2d.play("jump")
		if direction:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
	
		move_and_slide()
