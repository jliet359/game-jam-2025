extends ProgressBar

@onready var enemy_timer: Timer = $EnemyTimer
@export var enemy_total_duration: float = 2.0
var enemy_health: float = 100.0
var enemy_decay_rate: float
var enemy_tick_rate: float = 0.05

func _ready():
	init_enemy_health(enemy_health)
	
	enemy_timer.wait_time = enemy_tick_rate
	enemy_timer.one_shot = false
	enemy_timer.timeout.connect(_on_enemy_timer_timeout)
	
	calculate_enemy_decay_rate()
	
	# Don't start automatically - wait for parent to become player
	
func init_enemy_health(_health_enemy):
	enemy_health = _health_enemy
	max_value = enemy_health
	value = enemy_health
	
func calculate_enemy_decay_rate():
	enemy_decay_rate = enemy_health / (enemy_total_duration / enemy_tick_rate)

func start_decay():
	if not enemy_timer.is_stopped():
		enemy_timer.stop()
	calculate_enemy_decay_rate()
	enemy_timer.start()
	
func _on_enemy_timer_timeout():
	value -= enemy_decay_rate
	if value <= 0:
		value = 0
		enemy_timer.stop()
		enemy_died()
		
func reset_enemy_health():
	value = enemy_health
	if not enemy_timer.is_stopped():
		enemy_timer.stop()
	enemy_timer.wait_time = enemy_tick_rate
	calculate_enemy_decay_rate()
	enemy_timer.start()
	
func stop_decay():
	if not enemy_timer.is_stopped():
		enemy_timer.stop()
	
func enemy_died(): 
	get_parent().after_possess()
