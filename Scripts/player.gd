extends CharacterBody2D

const SPEED = 200.0
const JUMP_VELOCITY = -400.0

@onready var player: CharacterBody2D = $"."
@onready var possess_area = $PossessArea
@onready var camera = $Camera2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape_2d: CollisionShape2D = $PossessArea/CollisionShape2D

func _ready():
	possess_area.body_entered.connect(_on_possess_area_body_entered)

func _physics_process(delta: float) -> void:
	# Add the gravity.
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
	
func _on_possess_area_body_entered(body):
	print("PossessArea entered by: ", body.name)
	if body.is_in_group("enemies") and body.has_method("become_player"):
		print("Possessing ", body.name)
		
		# Get the camera from the player
		"""
		var cam = get_node("Camera2D")
		# Remove the camera from the player
		remove_child(cam)
		# Add it to the enemy and reset position
		body.add_child(cam)
		cam.position = Vector2.ZERO
		cam.make_current()
		"""
		body.become_player()
		# queue_free()
		player.visible = false
		var timer = body.get_node("Timer")
		timer.connect("timeout", self, "_on_timer_timeout")
		
func player_visible():
	player.visible = true
