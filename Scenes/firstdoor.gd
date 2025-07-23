extends Area2D

@export var next_scene_path: String = "res://Scenes/slingshot_ideas/sling.tscn"
@export var player_path: NodePath = "../../Player"
@export var door_sprite_path: NodePath = "../AnimatedSprite2D2"

@onready var player = get_node(player_path)
@onready var door_sprite: AnimatedSprite2D = get_node(door_sprite_path)

var player_inside = false
var animation_playing = false

func _ready():
	
	print("Player node:", player)
	print("Door sprite node:", door_sprite)
	
	if door_sprite.sprite_frames:
		print("Door animations:", door_sprite.sprite_frames.get_animation_names())
	else:
		print("⚠️ Door sprite has NO SpriteFrames resource assigned!")

func _on_body_entered(body):
	if body == player:
		player_inside = true
		print("Player entered door area")

func _on_body_exited(body):
	if body == player:
		player_inside = false
		print("Player exited door area")

func _process(_delta):
	if player_inside and Input.is_action_just_pressed("interact") and not animation_playing:
		print("Interact pressed – opening door")
		animation_playing = true
		
		if door_sprite.sprite_frames and door_sprite.sprite_frames.has_animation("open"):
			door_sprite.play("open")
			
			# Wait for the animation to finish using the animation_finished signal
			await door_sprite.animation_finished
			
			# Check if we're still valid after the await
			if not is_inside_tree():
				print("⚠️ ERROR: Node is no longer in the scene tree after animation")
				return
			
			print("Animation finished, changing scene to:", next_scene_path)
			_change_scene()
		else:
			print("⚠️ Missing 'open' animation or sprite_frames on door_sprite")
			# Change scene immediately if animation missing
			_change_scene()

func _change_scene():
	# Check if the scene file exists
	if not FileAccess.file_exists(next_scene_path):
		print("⚠️ ERROR: Scene file does not exist at path:", next_scene_path)
		return
	
	print("Scene file exists, attempting to change scene...")
	
	# Check if we still have access to the scene tree
	var tree = get_tree()
	if not tree:
		print("⚠️ ERROR: Cannot access scene tree - node may have been freed")
		return
	
	print("Scene tree is valid, changing scene...")
	
	# Use call_deferred to ensure we're not in the middle of processing
	tree.call_deferred("change_scene_to_file", next_scene_path)
