extends CharacterBody2D

var SPEED = 200.0
const JUMP_VELOCITY = -400.0
var is_player = false
var can_be_possessed = true
var timer_reset = 0
var has_died: bool = false

@onready var enemy_timer: Timer = $ProgressBar/EnemyTimer
@onready var enemy: AnimatedSprite2D = $AnimatedSprite2D
@onready var possess_area: Area2D = $Area2D
@onready var collision: CollisionShape2D = $CollisionShape2D2
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var timer_2: Timer = $Timer2
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var color_rect: ColorRect = $ProgressBar/ColorRect
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var sling: Node2D = $Sling
@onready var sling_shot_line: Line2D = $Sling/SlingShotLine
@onready var direction_line: Line2D = $Sling/DirectionLine

@export var patrol_speed: float = 100.0     # Speed while pacing
@export var pace_time: float = 2.0          # How long to walk in each direction

var patrol_direction: int = 1  # 1 for right, -1 for left
var pace_timer: float = 0.0

func _ready():
	modulate = Color(1, 1, 1)  # Reset to default white
	color_rect.hide()
	progress_bar.hide()
	pace_timer = pace_time  # Initialize the timer only once

func _idle_behavior():
	# Apply gravity
	if not is_on_floor():
		velocity += get_gravity() * get_physics_process_delta_time()
	
	# Handle horizontal movement
	velocity.x = patrol_direction * patrol_speed
	
	# Update pace timer (DON'T reset it every frame)
	pace_timer -= get_physics_process_delta_time()
	
	# Change direction when timer expires
	if pace_timer <= 0:
		patrol_direction *= -1
		pace_timer = pace_time
		print("Direction changed! New direction: ", patrol_direction)
	
	# Update sprite direction and animation
	enemy.flip_h = patrol_direction > 0  # flip when moving left (fixed)
	enemy.play("walk")

func become_player():
	var player = get_tree().get_first_node_in_group("player")
	#print("[become_player] Called on enemy: ", name)
	is_player = true
	enemy.modulate = Color(0, 1, 0)
	color_rect.show()
	progress_bar.show()
	enemy_timer.start()
	#print("[become_player] Timer started for enemy: ", name)
	can_be_possessed = false

func after_possess():
	sling_shot_line.hide()
	direction_line.hide()
	progress_bar.hide()
	if has_died:
		#print("[after_possess] Already died. Skipping.")
		return
		
	#print("[after_possess] Running on enemy: ", name)
	has_died = true 
	
	if enemy_timer: enemy_timer.stop()
	if timer_2: timer_2.stop()

	enemy.play("dead")
	animation_player.play("die")
	is_player = false
	remove_child(collision)
	var player = get_node("../Player")
	if player:
		#print("[after_possess] Player seen from enemy: ", name)
		player.animated_sprite_2d.visible = true
		player.animated_sprite_2d.modulate.a = 1.0
	timer_reset += 1
	timer_2.wait_time = 6.0
	timer_2.start()

func _on_timer_2_timeout() -> void:
	timer_2.stop()  # ✅ prevent further firings
	
	if has_died:
		#print("[_on_timer_2_timeout] Already processed, skipping.")
		return
		
	var sling = get_node_or_null("Sling")
	if sling:
		#print("Found Sling, about to move it")
		var scene_root = get_parent()
		#print("Scene root: ", scene_root.name)
		
		remove_child(sling)
		#print("Removed Sling from Enemy")
		
		scene_root.add_child(sling)
		#print("Added Sling to ", scene_root.name)
		#print("Moved Sling to safety")
	else:
		#print("Sling not found!")
		pass
	
	animation_player.play("die")
	await animation_player.animation_finished
	#print("About to free Enemy")
	queue_free()

func _physics_process(delta: float) -> void:
	if is_player:
		# Player control logic
		if not is_on_floor():
			velocity += get_gravity() * delta
		
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = JUMP_VELOCITY
		
		var direction := Input.get_axis("move_left", "move_right")
		
		if direction > 0:
			enemy.flip_h = true
		elif direction < 0:
			enemy.flip_h = false
		
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
	else:
		# Enemy AI behavior - only when not possessed and not dead
		if not has_died:
			_idle_behavior()
			move_and_slide()
