extends StaticBody2D

signal room_exit(direction: String)


func _on_north_exit_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		emit_signal("room_exit", "north_room")


func _on_east_exit_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		emit_signal("room_exit", "east_room")


func _on_south_exit_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		emit_signal("room_exit", "south_room")


func _on_west_exit_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		emit_signal("room_exit", "west_room")
