extends Node

@onready var main_character = $MainCharacter
@onready var cleaner_character = $CleanerCharacter
@onready var tank = $Tank

@onready var main_character_area: Area2D = $Tank/MainCharacterArea2d
@onready var cleaner_character_area: Area2D = $Tank/CleanerCharacterArea2d

@onready var main_target_marker: Marker2D = $Tank/MainCharacterArea2d/MainCharacterMarker
@onready var cleaner_target_marker: Marker2D = $Tank/CleanerCharacterArea2d/CleanerCharacterMarker

@onready var animation_player = $AnimationPlayer

var movement_speed = 100.0
var is_cutscene_playing = false
var moving_main = false
var moving_cleaner = false

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
	next_tank()

func next_tank():
	tank.play("final")
	main_character.modulate.a = 0.0
	end_cutscene()

func end_cutscene():
	tank.play("close")
	print("[Cutscene] Ending...")
	is_cutscene_playing = false
	cutscene_completed()

func cutscene_completed():
	print("[Cutscene] Cutscene completed!")
