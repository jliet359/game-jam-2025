extends ProgressBar

@onready var linked_timer: Timer = $"../Timer"  # Reference to the shared timer
@export var total_duration: float = 6.0

func _ready():
	
	max_value = total_duration
	value = total_duration

func start_timer():
	if not linked_timer:
		push_warning("No linked_timer assigned!")
		return
	
	total_duration = linked_timer.wait_time  # Sync bar to timer length
	max_value = total_duration
	value = total_duration
	show()

func _process(delta):
	if not linked_timer or linked_timer.is_stopped():
		hide()
		return
	
	value = linked_timer.time_left
