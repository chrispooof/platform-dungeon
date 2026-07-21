extends CharacterBody2D

@onready var interact_prompt = $"../HUD/InteractPrompt"
@onready var abilities = $"../HUD/Abilities"
@onready var camera = $PlayerCamera

var is_on_climbable: bool = false
var climbable_x_position: float = 0.0
var nearby_climbable = null
var facing_direction := 1.0  # -1 left, 1 right
var is_dashing = false
var dash_time_left = 0.0
var dash_cooldown_left = 0.0


func _process(delta: float) -> void:
	"""This function is called every frame and can be used to handle any 
	per-frame logic or updates needed for the player character.
	"""
	if nearby_climbable:
		var screen_pos = global_position - camera.global_position + get_viewport_rect().size / 2
		interact_prompt.position = screen_pos + Vector2(-35, -70)


func _physics_process(delta: float) -> void:
	"""Handles the player's movement and interaction with a climbable. 
	If the player is near a climbable and presses the interact button, 
	they will lock to the climbable's X position and can climb it. 
	If they jump while on the climbable, they will exit the climbable and 
	apply a jump velocity. The function also handles normal movement 
	and gravity when not on a climbable.
	"""
	if not is_on_climbable and nearby_climbable:
		if Input.is_action_just_pressed("interact"):
			enter_climbable(nearby_climbable.global_position.x)

	if is_on_climbable:
		# Lock player to climbable X
		global_position.x = climbable_x_position

		if Input.is_action_just_pressed("ui_accept"):
			exit_climbable()
			velocity.y = Constants.JUMP_VELOCITY
			return

		var input = Input.get_axis("ui_up", "ui_down")
		velocity.y = input * 100  # climb speed

		# No gravity
		move_and_slide()
		return

	if dash_cooldown_left > 0:
		dash_cooldown_left -= delta

	if is_dashing:
		abilities.get_node("DashIcon/TextureRect").modulate.a = 0.5
		dash_time_left -= delta

		velocity.x = facing_direction * Constants.DASH_SPEED
		move_and_slide()

		if dash_time_left <= 0:
			is_dashing = false

		return
	else:
		abilities.get_node("DashIcon/TextureRect").modulate.a = 1.0

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
		facing_direction = direction
		velocity.x = direction * Constants.SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, Constants.SPEED)

	if Input.is_action_just_pressed("dash"):
		dash()

	move_and_slide()


func dash():
	"""Initiates a dash action for the player. The player will move quickly in the direction they are facing for a short duration.
	The dash can only be performed if the player is not already dashing and if the dash cooldown
	"""
	if is_dashing:
		return

	if dash_cooldown_left > 0:
		return

	is_dashing = true
	dash_time_left = Constants.DASH_DURATION
	dash_cooldown_left = Constants.DASH_COOLDOWN


func set_near_climbable(climbable):
	"""Sets the nearby climbable reference when the player is within the climbable's area."""
	nearby_climbable = climbable
	interact_prompt.visible = true


func clear_near_climbable(climbable):
	"""Clears the nearby climbable reference when the player exits the climbable's area."""
	if nearby_climbable == climbable:
		nearby_climbable = null
		interact_prompt.visible = false
		exit_climbable()


func enter_climbable(x_pos):
	"""Locks the player to the climbable's X position and allows them to climb it."""
	is_on_climbable = true
	climbable_x_position = x_pos
	velocity = Vector2.ZERO
	interact_prompt.visible = false


func exit_climbable():
	"""Unlocks the player from the climbable, allowing them to move freely again."""
	is_on_climbable = false
