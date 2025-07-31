extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const DETECTION_RANGE = 500.0
const ATTACK_COOLDOWN = 1.0

@export var is_player = false
@export var is_ai_enemy = true

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $AnimatedSprite2D/DetectionArea
@onready var attacking_area: Area2D = $AnimatedSprite2D/AttackingArea

@export var patrol_speed: float = 100.0
@export var pace_time: float = 2.0

var patrol_direction: int = 1
var pace_timer: float = 0.0
var target_player: Node2D = null
var state: String = "idle"
var is_in_attack_range: bool = false
var attack_timer: float = 0.0
var is_attacking: bool = false
var enemy_character = null

func _ready():
	pace_timer = pace_time
	#print("[READY] Enemy initialized, state: ", state)

	if detection_area:
		detection_area.body_entered.connect(_on_detection_area_entered)
		detection_area.body_exited.connect(_on_detection_area_exited)
	
	if attacking_area:
		attacking_area.body_entered.connect(_on_attacking_area_entered)
		attacking_area.body_exited.connect(_on_attacking_area_exited)
		
		
		
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
	#print("[AI] Current state: ", state, " | Target: ", target_player, " | In attack range: ", is_in_attack_range)
	match state:
		"idle": _idle_behavior()
		"chasing": _chase_behavior()
		"attacking": _attack_behavior()

func _idle_behavior():
	#print("[IDLE] Patrolling - Direction: ", patrol_direction, " | Timer: ", pace_timer)
	
	velocity.x = patrol_direction * patrol_speed
	
	pace_timer -= get_process_delta_time()
	
	if pace_timer < 0:
		patrol_direction *= -1
		pace_timer = pace_time
		#print("[IDLE] Direction changed to: ", patrol_direction)
	
	animated_sprite.flip_h = patrol_direction > 0
	animated_sprite.play("walk")
	_scan_for_players()

func _chase_behavior():
	#print("[CHASE] Target check - Target: ", target_player, " | Valid: ", is_instance_valid(target_player) if target_player else false)
	
	# Check if target is valid before accessing properties
	if target_player == null or not is_instance_valid(target_player):
		#print("[CHASE] Target invalid, switching to idle")
		state = "idle"
		target_player = null
		return
	
	# Check if we're in the attacking area
	if is_in_attack_range:
		#print("[CHASE] In attack range, switching to attacking")
		state = "attacking"
		return
	
	# Safe distance check with null validation
	var dist = global_position.distance_to(target_player.global_position)
	#print("[CHASE] Distance to target: ", dist, " | Detection range: ", DETECTION_RANGE)
	
	if dist > DETECTION_RANGE:
		#print("[CHASE] Target too far, switching to idle")
		state = "idle"
		target_player = null
	else:
		var dir = sign(target_player.global_position.x - global_position.x)
		velocity.x = dir * SPEED
		animated_sprite.play("walk")
		animated_sprite.flip_h = dir > 0
		#print("[CHASE] Chasing target - Direction: ", dir, " | Velocity: ", velocity.x)
		
		if is_on_wall() and target_player.global_position.y < global_position.y and is_on_floor():
			velocity.y = JUMP_VELOCITY
			print("[CHASE] Jumping over wall")

func _attack_behavior():
	#print("[ATTACK] Target: ", target_player, " | In range: ", is_in_attack_range, " | Timer: ", attack_timer)

	# If target becomes invalid, abort and reset
	if target_player == null or not is_instance_valid(target_player):
		#print("[ATTACK] Target invalid, switching to idle")
		state = "idle"
		is_in_attack_range = false
		is_attacking = false
		return

	# 🛑 If we are in the middle of an attack, wait for animation to finish
	if is_attacking:
		velocity.x = 0  # Stay still while attacking
		return
	
	# ✅ If not in range *and not attacking*, return to chasing
	if not is_in_attack_range:
		#print("[ATTACK] No longer in attack range, switching to chase")
		state = "idle"
		return
	
	# Start attack
	if attack_timer <= 0:
		is_attacking = true
		attack_timer = ATTACK_COOLDOWN
		animated_sprite.flip_h = target_player.global_position.x > global_position.x
		animated_sprite.play("attack")
		velocity.x = 0
		#print("[ATTACK] Attacking! Timer reset to: ", attack_timer)
		if target_player and target_player.has_method("after_possess"):
			target_player.after_possess()
	else:
		attack_timer -= get_physics_process_delta_time()


func _scan_for_players():
	#print("[SCAN] Scanning for players...")
	var enemies = get_tree().get_nodes_in_group("enemies")
	#print("[SCAN] Found ", enemies.size(), " enemies in group")
	
	for e in enemies:
		if e != self and is_instance_valid(e):
			#print("[SCAN] Checking enemy: ", e.name, " | is_player: ", e.get("is_player"))
			if e.get("is_player"):
				var dist = global_position.distance_to(e.global_position)
				#print("[SCAN] Player found at distance: ", dist)
				if dist <= DETECTION_RANGE:
					target_player = e
					state = "chasing"
					#print("[SCAN] Target acquired! Switching to chase")
					break

# Detection area signals (for spotting players)
func _on_detection_area_entered(body: Node2D):
	#print("[DETECTION] Body entered: ", body.name, " | is_player: ", body.get("is_player"))
	if is_ai_enemy and is_instance_valid(body) and body.get("is_player"):
		target_player = body
		state = "chasing"
		#print("[DETECTION] Player detected! Target set and switching to chase")

func _on_detection_area_exited(body: Node2D):
	#print("[DETECTION] Body exited: ", body.name)
	if body == target_player and is_ai_enemy:
		#print("[DETECTION] Target player left detection area")
		pass
		# Let chase behavior handle the range check

# AttackingArea signals (for triggering attacks)
func _on_attacking_area_entered(body: Node2D):
	#print("[ATTACK_AREA] Body entered: ", body.name, " | is_player: ", body.get("is_player"))
	if is_ai_enemy and is_instance_valid(body) and body.get("is_player"):
		target_player = body
		is_in_attack_range = true
		state = "attacking"
		print("[ATTACK_AREA] Player entered attack range! Switching to attack")

func _on_attacking_area_exited(body: Node2D):
	#print("[ATTACK_AREA] Body exited: ", body.name)
	if is_ai_enemy and body == target_player:
		is_in_attack_range = false
		#print("[ATTACK_AREA] Player left attack range!")


func _on_animated_finished() -> void:
	if animated_sprite.animation == "attack":
		is_attacking = false
		print("animation stopped attacking")
		# Switch back to chase animation or idle
		state = "idle"
		pass # Replace with function body.
