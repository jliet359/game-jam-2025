extends Node2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var animation_player: AnimationPlayer = $Camera2D/AnimationPlayer
@onready var intro: AnimationPlayer = $CanvasGroup/CanvasModulate/AnimationPlayer
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var move: AnimationPlayer = $Sprite2D/AnimationPlayer
@onready var escape_player: CharacterBody2D = $EscapePlayer

var jump_count = 0


func _ready():
	sprite_2d.hide()
	escape_player.visible = false
	print("[Cutscene] Ready")
	start_cutscene()
	
	
func start_cutscene():
	pass

func _input(event):
	if event.is_action_pressed("jump"):  # Replace with your jump action
		handle_jump()

func handle_jump():
	jump_count += 1
	
	if jump_count == 1:
		# First jump: start with "second" sprite and light shake
		animated_sprite.play("second")
		animation_player.play("shake")
		
	elif jump_count == 2:
		animated_sprite.play("third")
		animation_player.play("shake")
		
	elif jump_count == 3:
		# Fourth+ jump: change to "final" sprite, extreme shake
		animated_sprite.play("last")
		animation_player.play("shake")
		move.play("new_animation")
		sprite_2d.show()
		move_player()
		
		
		
		
func move_player():
	escape_player.visible = true
	return
