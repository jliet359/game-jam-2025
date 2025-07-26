extends Area2D


func _on_body_entered(_body: Node2D) -> void:
	print("Power up")
	queue_free()
