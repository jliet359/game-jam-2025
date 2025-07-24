extends RigidBody2D

const SPEED = 200.0
const JUMP_VELOCITY = -400.0
const GRAVITY = 980.0
const DAMPING_FACTOR = 10.0

@onready var possess_area = $PossessArea
@onready var camera = $Camera2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var timer: Timer = $Timer
@onready var live: ProgressBar = $Live
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var floor_raycast: RayCast2D = $FloorRayCast2D  # Add this node as a child

var player_dead = false
var on_floor = false
var direction = 0.0

func _ready():
	add_to_group("player")
	possess_area.body_entered.connect(_on_possess_area_body_entered)
	
	# CRITICAL: Enable contact monitoring for RigidBody2D
	contact_monitor = true
	max_contacts_reported = 10
	
	print("Contact monitoring enabled: ", contact_monitor)
	print("Max contacts: ", max_contacts_reported)

# Visual debug - shows floor status in scene
"""
func _draw():
	if on_floor:
		draw_circle(Vector2.ZERO, 10, Color.GREEN)
	else:
		draw_circle(Vector2.ZERO, 10, Color.RED)
	
	# Force redraw every frame
	queue_redraw()
"""


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	#print("_integrate_forces called! player_dead: ", player_dead)
	
	# Keep rotation locked
	rotation = 0
	angular_velocity = 0
	
	if player_dead:
		linear_velocity.x = 0
		#print("Player is dead, returning early")
		return
	
	# Improved floor detection - check all contact points
	on_floor = false
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
	
	# Apply gravity
	if not on_floor:
		linear_velocity.y += GRAVITY * state.step
	
	# Get input direction
	direction = Input.get_axis("move_left", "move_right")
	
	# Handle jump - with debug info
	if Input.is_action_just_pressed("jump"):
		print("Jump pressed! on_floor: ", on_floor, " contact_count: ", state.get_contact_count())
		if on_floor:
			linear_velocity.y = JUMP_VELOCITY
			print("Jump executed! velocity.y: ", linear_velocity.y)
	
	# Handle horizontal movement
	if direction != 0:
		linear_velocity.x = direction * SPEED
	else:
		# Improved damping - less aggressive
		linear_velocity.x = move_toward(linear_velocity.x, 0, DAMPING_FACTOR * SPEED * state.step)
	
	# Sprite flip and animation
	if direction > 0:
		animated_sprite_2d.flip_h = false
	elif direction < 0:
		animated_sprite_2d.flip_h = true
	
	# Play appropriate animation
	if on_floor:
		if direction == 0:
			animated_sprite_2d.play("idle")
		else:
			animated_sprite_2d.play("walk")
	else:
		animated_sprite_2d.play("jump")

func _on_possess_area_body_entered(body):
	if body.is_in_group("enemies") and body.has_method("become_player") and body.can_be_possessed:
		live.reset_health()
		animated_sprite_2d.modulate.a = 0.0
		body.become_player()
		timer.wait_time = 3.0
		timer.start()
		print("PossessArea entered by: ", body.name)

func _on_timer_timeout() -> void:
	pass

func player_died():
	linear_velocity.y = 0
	player_dead = true
	animated_sprite_2d.stop()
	animation_player.play("die")
