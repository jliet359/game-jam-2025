extends Node

@onready var main_character = $MainCharacter
@onready var cleaner_character = $CleanerCharacter
@onready var tank = $Tank

@onready var main_character_area: Area2D = $Tank/MainCharacterArea2d
@onready var cleaner_character_area: Area2D = $Tank/CleanerCharacterArea2d

@onready var main_target_marker: Marker2D = $Tank/MainCharacterArea2d/MainCharacterMarker
@onready var cleaner_target_marker: Marker2D = $Tank/CleanerCharacterArea2d/CleanerCharacterMarker

@onready var timer: Timer = $Tank/Timer
@onready var animation_player: AnimationPlayer = $CanvasGroup/CanvasModulate/AnimationPlayer


var movement_speed = 100.0
var is_cutscene_playing = false
var moving_main = false
var moving_cleaner = false
var timer_amount = 0


func _ready():
	print("[Cutscene] Ready")
	start_cutscene()

func start_cutscene():
	if is_cutscene_playing:
		print("[Cutscene] Already playing, skipping start.")
		return
	
	print("[Cutscene] Starting...")
	is_cutscene_playing = true
	moving_main = true
	moving_cleaner = true
	main_character.play("default")
	cleaner_character.play("default")

func _physics_process(delta):
	if moving_main:
		move_character_towards(main_character, main_target_marker.global_position, delta)
	if moving_cleaner:
		move_character_towards(cleaner_character, cleaner_target_marker.global_position, delta)

func move_character_towards(character: Node2D, target_pos: Vector2, delta: float):
	var direction = (target_pos - character.global_position).normalized()
	var distance = character.global_position.distance_to(target_pos)
	
	print("[Movement] Moving %s | Target: %s | Current: %s | Distance: %.2f" %
		[character.name, str(target_pos), str(character.global_position), distance])
	
	if distance > 5.0:
		character.global_position += direction * movement_speed * delta
	else:
		print("[Movement] %s reached destination" % character.name)
		
		if character == main_character:
			main_character.stop()
			moving_main = false
		elif character == cleaner_character:
			cleaner_character.stop()
			cleaner_character.flip_h = true
			moving_cleaner = false
		
		check_cutscene_complete()

func check_cutscene_complete():
	tank.play("default")
	timer.start()

func end_cutscene():
	main_character.modulate.a = 0.0
	tank.play("close")
	print("[Cutscene] Ending...")
	is_cutscene_playing = false

func cutscene_completed():
	animation_player.play("new_animation")
	print("[Cutscene] Cutscene completed!")

func change_scene():
	var new_scene = preload("res://cutscene/escape.tscn")
	get_tree().change_scene_to_packed(new_scene)
func _on_timer_timeout() -> void:
	timer_amount += 1
	if timer_amount == 1:
		timer.start()
		end_cutscene()
	elif timer_amount == 2:
		timer.start()
		cutscene_completed()
	elif timer_amount == 3:
		timer.start()
		change_scene()
