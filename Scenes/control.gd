extends Control


@onready var try_again_button: Button = $VBoxContainer/TryAgainButton
@onready var main_menu_button: Button = $VBoxContainer/MainMenuButton

func _ready():
	#print("Buttons script ready!")
	#print(try_again_button)  # Should NOT be null
	#print(main_menu_button)  # Should NOT be null
	try_again_button.pressed.connect(_on_try_again_button_pressed)
	main_menu_button.pressed.connect(_on_main_menu_button_pressed)
	
	
	
	
func _on_try_again_button_pressed():
	var path = "res://Scenes/level_one.tscn"
	if not ResourceLoader.exists(path):
		#print("Scene path invalid:", path)
		pass
	else:
		#print("Loading scene:", path)
		var level_reload_scene = load(path)
		get_tree().change_scene_to_packed(level_reload_scene)

func _on_main_menu_button_pressed():
	var main_menu_path = "res://Scenes/main_menu.tscn"
	if not ResourceLoader.exists(main_menu_path):
		#print("Scene path invalid:", main_menu_path)
		pass
	else:
		#print("Loading scene:", main_menu_path)
		var main_menu_scene = load(main_menu_path)
		get_tree().change_scene_to_packed(main_menu_scene)
