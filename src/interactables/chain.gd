extends Node2D


func _process(delta: float) -> void:
	"""This function is called every frame and can be used to handle any 
	per-frame logic or updates needed for the chain interactable.
	"""
	pass


func _on_area_2d_body_entered(body: Node2D) -> void:
	"""Handles the event when a body enters the chain area.
	If the body is the player, it calls the enter_chain method on 
	the player to lock them to the chain's X position and allow climbing.
	"""
	if body.is_in_group("player"):
		print("Player entered chain area")
		body.set_near_chain(self)


func _on_area_2d_body_exited(body: Node2D) -> void:
	"""Handles the event when a body exits the chain area.
	If the body is the player, it calls the exit_chain method on 
	the player to unlock them from the chain.
	"""
	if body.is_in_group("player"):
		print("Player exited chain area")
		body.clear_near_chain(self)
