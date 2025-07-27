extends Node

@onready var main_menu_button: Button = $"MainMenuButton"

func _ready():
	main_menu_button.pressed.connect(_on_button_pressed)

func _on_button_pressed():
	var new_scene = preload("res://Scenes/main_menu.tscn")
	get_tree().change_scene_to_packed(new_scene)
