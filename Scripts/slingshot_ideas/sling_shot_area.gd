extends Area2D
signal vector_created(vector: Vector2)
@export var maximum_length: float = 200.0
var touch_down = false
var position_start = Vector2.ZERO
var position_end = Vector2.ZERO
var vector = Vector2.ZERO
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	input_event.connect(_on_input_event)

func _draw() -> void:
	if not touch_down:
		return
	
	# Get the center of the collision shape in local coordinates
	var center: Vector2 = collision_shape.position
	
	# Draw from the center of the collision shape to the current mouse position
	# Both coordinates are now in local space
	draw_line(center, position_end, Color.BLUE, 2)
	
	# Draw the vector line
	draw_line(center, center + vector, Color.RED, 2)

func _reset() -> void:
	position_start = Vector2.ZERO
	position_end = Vector2.ZERO
	vector = Vector2.ZERO
	touch_down = false  # Make sure to reset this
	queue_redraw()

func _input(event) -> void:
	if not touch_down:
		return
		
	if event.is_action_released("click"):
		touch_down = false
		emit_signal("vector_created", vector)
		_reset()
	
	if event is InputEventMouseMotion:
		# Convert global mouse position to local coordinates relative to this Area2D
		position_end = to_local(event.global_position)
		# Calculate vector from collision shape center to mouse position
		var center = collision_shape.position
		vector = -(position_end - center).limit_length(maximum_length)
		queue_redraw()

func _on_input_event(_viewport, event, _shape_idx) -> void:
	if event.is_action_pressed("click"):
		touch_down = true
		# Set the starting position to the center of the collision shape
		position_start = event.position
		# Initialize position_end to the click position in local coordinates
		position_end = to_local(event.global_position)
		queue_redraw()
