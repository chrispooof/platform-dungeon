extends CharacterBody2D

@onready var interact_prompt = $"../HUD/InteractPrompt"
@onready var camera = $PlayerCamera

var is_on_chain: bool = false
var chain_x_position: float = 0.0
var nearby_chain = null


func _process(delta: float) -> void:
	"""This function is called every frame and can be used to handle any 
	per-frame logic or updates needed for the player character.
	"""
	if nearby_chain:
		var screen_pos = global_position - camera.global_position + get_viewport_rect().size / 2
		interact_prompt.position = screen_pos + Vector2(-35, -70)


func _physics_process(delta: float) -> void:
	"""Handles the player's movement and interaction with chains. 
	If the player is near a chain and presses the interact button, 
	they will lock to the chain's X position and can climb it. 
	If they jump while on the chain, they will exit the chain and 
	apply a jump velocity. The function also handles normal movement 
	and gravity when not on a chain.
	"""
	if not is_on_chain and nearby_chain:
		if Input.is_action_just_pressed("interact"):
			enter_chain(nearby_chain.global_position.x)

	if is_on_chain:
		# Lock player to chain X
		global_position.x = chain_x_position

		if Input.is_action_just_pressed("ui_accept"):
			exit_chain()
			velocity.y = Constants.JUMP_VELOCITY
			return

		var input = Input.get_axis("ui_up", "ui_down")
		velocity.y = input * 100  # climb speed

		# No gravity
		move_and_slide()
		return

	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = Constants.JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * Constants.SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, Constants.SPEED)

	move_and_slide()


func set_near_chain(chain):
	"""Sets the nearby chain reference when the player is within the chain's area."""
	nearby_chain = chain
	interact_prompt.visible = true


func clear_near_chain(chain):
	"""Clears the nearby chain reference when the player exits the chain's area."""
	if nearby_chain == chain:
		nearby_chain = null
		interact_prompt.visible = false
		exit_chain()


func enter_chain(x_pos):
	"""Locks the player to the chain's X position and allows them to climb it."""
	is_on_chain = true
	chain_x_position = x_pos
	velocity = Vector2.ZERO
	interact_prompt.visible = false


func exit_chain():
	"""Unlocks the player from the chain, allowing them to move freely again."""
	is_on_chain = false
