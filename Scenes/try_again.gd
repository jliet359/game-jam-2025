extends Node


@onready var try_again: Button =  $"../TryAgain"


func _ready():
	try_again.pressed.connect(_on_button_pressed)

func _on_button_pressed():
	var new_scene = preload("res://Scenes/level_one.tscn")
	get_tree().change_scene_to_packed(new_scene)
