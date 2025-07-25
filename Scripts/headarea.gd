extends Area2D

# Reference to the RigidBody2D that should stay centered
@export var target_rigidbody: RigidBody2D
# Reference to this Area2D's CollisionShape2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready():
	# Try to get the SlingShotPlayer from the scene
	if not target_rigidbody:
		target_rigidbody = get_node("../SlingShotPlayer") # Adjust path as needed
		# Alternative: target_rigidbody = get_tree().get_first_node_in_group("slingshot_player")
	
	# Initial positioning
	center_rigidbody()
	
	# Connect to position changes if needed
	connect("tree_exiting", _on_tree_exiting)

func _process(_delta):
	# Continuously keep the rigidbody centered
	# Remove this if you only want to center once
	center_rigidbody()
	

func center_rigidbody():
	if not target_rigidbody or not collision_shape:
		return
	
	# Get the center position of the Area2D's collision shape
	var shape_center = get_collision_shape_center()
	
	# Set the RigidBody2D's position to the center
	target_rigidbody.global_position = shape_center

func get_collision_shape_center() -> Vector2:
	if not collision_shape or not collision_shape.shape:
		return global_position
	
	# Calculate center based on shape type
	var shape = collision_shape.shape
	var center_offset = Vector2.ZERO
	
	center_offset = Vector2.ZERO 

		# For polygon shapes, calculate the centroid
	var points = shape.points if shape.has_method("get_points") else []
	if points.size() > 0:
		var sum = Vector2.ZERO
		for point in points:
			sum += point
		center_offset = sum / points.size()
	
	# Transform the center offset to global coordinates
	var global_center = collision_shape.global_transform * center_offset
	return global_center



# Optional: Center when the Area2D moves
func _on_tree_exiting():
	# Cleanup if needed
	pass

# Example of centering when Area2D position changes
func _on_position_changed():
	center_rigidbody()
