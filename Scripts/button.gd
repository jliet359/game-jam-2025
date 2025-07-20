extends Node

@onready var button = $"."

func _ready():
	button.pressed.connect(_on_button_pressed)

func _on_button_pressed():
	var new_scene = preload("res://scenes/levelone.tscn")
	get_tree().change_scene_to_packed(new_scene)
