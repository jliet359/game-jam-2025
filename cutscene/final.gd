extends Node2D

func _ready() -> void:
	# Find the enemy counter node
	var enemy_counter = get_tree().current_scene.find_child("Sling", true, false)
	if enemy_counter:
		if enemy_counter.has_variable("possessed_enemies"):
			print("possessed_enemies: ", enemy_counter.possessed_enemies)
		else:
			print("❌ 'possessed_enemies' variable not found on enemy_counter")

	# Find the timer node
	var timer = get_tree().current_scene.find_child("TimerNode", true, false)
	if timer:
		if timer.has_variable("final_time"):
			print("final_time: ", timer.final_time)
		elif timer.has_method("get_current_time"):
			print("Elapsed time: ", timer.get_current_time())
		else:
			print("❌ 'final_time' variable and 'get_current_time()' method not found on timer")
