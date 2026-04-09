extends Camera2D


func _ready() -> void:
	"""Initializes the camera settings, including zoom and limits to restrict 
	the camera's movement within the defined screen dimensions.
	"""
	self.zoom = Vector2(2.0, 2.0)
	self.limit_left = 0
	self.limit_top = 0
	self.limit_right = Constants.SCREEN_WIDTH
	self.limit_bottom = Constants.SCREEN_HEIGHT


func _process(delta: float) -> void:
	pass
