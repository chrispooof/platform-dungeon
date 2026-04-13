extends StaticBody2D

signal room_exit(direction: String)


func _on_south_exit_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		emit_signal("room_exit", "central_room")
