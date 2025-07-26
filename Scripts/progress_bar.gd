extends ProgressBar


@onready var live_timer: Timer = $LiveTimer
 
@export var total_duration: float = 2

var health: float = 100.0
var decay_rate: float
var tick_rate: float = .05


func _ready():
	#print("Total duration set to: ", total_duration)
	init_health(health)
	
	live_timer.wait_time = tick_rate  # e.g., 0.1 seconds
	live_timer.one_shot = false
	
	decay_rate = health / (total_duration / tick_rate)
	live_timer.start()
	
func init_health(_health):
	health = _health
	max_value = health
	value = health
	
func _on_live_timer_timeout():
	value -= decay_rate
	if value <= 0:
		value = 0
		live_timer.stop()
		player_died()
		
func reset_health():
	value = health
	if not live_timer.is_stopped():
		return
	live_timer.wait_time = 5.0
	live_timer.start()
	
func player_died(): 
	get_parent().player_died()
		
