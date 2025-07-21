extends CharacterBody2D

const SPEED = 200.0
const JUMP_VELOCITY = -400.0

@onready var possess_area = $PossessArea
@onready var camera = $Camera2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var player: CharacterBody2D = $"."
@onready var timer: Timer = $Timer
@onready var live: ProgressBar = $Live
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var player_dead = false

func _ready():
	add_to_group("player")
	possess_area.body_entered.connect(_on_possess_area_body_entered)

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if player_dead == false:
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
	if body.is_in_group("enemies") and body.has_method("become_player") and body.can_be_possessed:
		live.reset_health()
		body.become_player()
		player.visible = false
		timer.wait_time = 3.0
		timer.start()
		print("PossessArea entered by: ", body.name)

func _on_timer_timeout() -> void:
	player.visible = true
	player.set_process(true)
	
func player_died():
	player_dead = true
	animated_sprite_2d.stop()
	animation_player.play("die")
