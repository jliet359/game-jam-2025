extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const DETECTION_RANGE = 500.0
const ATTACK_COOLDOWN = 1.0

@export var is_player = false
@export var is_ai_enemy = true

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $AnimatedSprite2D/DetectionArea
@onready var attacking_area: Area2D = $AnimatedSprite2D/AttackingArea  # New attacking area

@export var patrol_speed: float = 100.0     # Speed while pacing
@export var pace_time: float = 2.0          # How long to walk in each direction

var patrol_direction: int = 1  # 1 for right, -1 for left
var pace_timer: float = 0.0
var target_player: Node2D = null
var attack_timer: float = 0.0
var state: String = "idle"
var is_in_attack_range: bool = false  # New variable to track if in attacking area

func _ready():
	pace_timer = pace_time


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	if attack_timer > 0:
		attack_timer -= delta
		
	if is_ai_enemy:
		_ai_behavior()
	else:
		pass
		
	move_and_slide()

func _ai_behavior():
	match state:
		"idle": _idle_behavior()
		"chasing": _chase_behavior()
		"attacking": _attack_behavior()

func _idle_behavior():
	velocity.x = patrol_direction * patrol_speed
	
	pace_timer -= get_process_delta_time()
	
	if pace_timer < 0:
		patrol_direction *= -1
		pace_timer = pace_time
	
	animated_sprite.flip_h = patrol_direction > 0
	animated_sprite.play("walk")
	_scan_for_players()

func _chase_behavior():
	if target_player == null or not is_instance_valid(target_player):
		state = "idle"
		return
	
	# Check if we're in the attacking area instead of distance
	if is_in_attack_range and target_player:
		state = "attacking"
		return
	
	var dist = global_position.distance_to(target_player.global_position)
	if dist > DETECTION_RANGE:
		state = "idle"
		target_player = null
	else:
		var dir = sign(target_player.global_position.x - global_position.x)
		velocity.x = dir * SPEED
		animated_sprite.play("walk")
		animated_sprite.flip_h = dir > 0
		
		if is_on_wall() and target_player.global_position.y < global_position.y and is_on_floor():
			velocity.y = JUMP_VELOCITY

func _attack_behavior():
	if target_player == null or not is_instance_valid(target_player):
		state = "idle"
		return
	
	# If no longer in attack range, go back to chasing
	if not is_in_attack_range:
		state = "chasing"
		return
	
	# Stop moving and attack
	velocity.x = move_toward(velocity.x, 0, SPEED * 2)
	animated_sprite.play("attack")
	animated_sprite.flip_h = target_player.global_position.x > global_position.x
	
	if attack_timer <= 0:
		attack_timer = ATTACK_COOLDOWN
		_perform_attack()

func _scan_for_players():
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if e != self and e.get("is_player"):
			if global_position.distance_to(e.global_position) <= DETECTION_RANGE:
				target_player = e
				state = "chasing"
				break

func _perform_attack():
	print("Enemy attacks!")
	if target_player and target_player.has_method("take_damage"):
		target_player.take_damage(10)
		_show_attack_effect()

func _show_attack_effect():
	var effect = ColorRect.new()
	effect.color = Color.RED
	effect.size = Vector2(20, 20)
	effect.position = global_position - Vector2(10, 10)
	get_parent().add_child(effect)
	var tween = create_tween()
	tween.tween_property(effect, "modulate:a", 0.0, 0.3)
	tween.tween_callback(effect.queue_free)

# Detection area signals (for spotting players)
func _on_detection_area_entered(body: Node2D):
	if is_ai_enemy and body.get("is_player"):
		target_player = body
		state = "chasing"

func _on_detection_area_exited(body: Node2D):
	if body == target_player and is_ai_enemy:
		pass  # Let chase behavior handle this

# NEW: AttackingArea signals (for triggering attacks)
func _on_attacking_area_entered(body: Node2D):
	if is_ai_enemy and body == target_player:
		is_in_attack_range = true
		print("Player entered attack range!")

func _on_attacking_area_exited(body: Node2D):
	if is_ai_enemy and body == target_player:
		is_in_attack_range = false
		print("Player left attack range!")
