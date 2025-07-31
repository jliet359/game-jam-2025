extends Node



@onready var start_game: Button = $"."


func _ready():
	start_game.pressed.connect(_on_button_pressed)

func _on_button_pressed():
	var new_scene = preload("res://Scenes/main_menu.tscn")
	get_tree().change_scene_to_packed(new_scene)
