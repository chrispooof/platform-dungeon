extends Node2D


func _process(delta: float) -> void:
	"""This function is called every frame and can be used to handle any 
	per-frame logic or updates needed for the ladder interactable.
	"""
	pass


func _on_area_2d_body_entered(body: Node2D) -> void:
	"""Handles the event when a body enters the ladder area.
	If the body is the player, it calls the enter_climbable method on 
	the player to lock them to the ladder's X position and allow climbing.
	"""
	if body.is_in_group("player"):
		body.set_near_climbable(self)


func _on_area_2d_body_exited(body: Node2D) -> void:
	"""Handles the event when a body exits the ladder area.
	If the body is the player, it calls the exit_climbable method on 
	the player to unlock them from the ladder.
	"""
	if body.is_in_group("player"):
		body.clear_near_climbable(self)
