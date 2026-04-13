extends Node2D

@onready var player = $Player
@onready var frame = $RoomManager/Frame

var current_room: Node2D
var current_room_name: String = "central_room"
const rooms = {
	"central_room": preload("res://scenes/rooms/central_room.tscn"),
	"west_room": preload("res://scenes/rooms/west_room.tscn"),
	"east_room": preload("res://scenes/rooms/east_room.tscn"),
	"north_room": preload("res://scenes/rooms/north_room.tscn"),
	"south_room": preload("res://scenes/rooms/south_room.tscn")
}
const room_bounds = Rect2(0, 0, Constants.SCREEN_WIDTH, Constants.SCREEN_HEIGHT)
var explored_rooms: Dictionary = {
	"central_room": false,
	"west_room": false,
	"east_room": false,
	"north_room": false,
	"south_room": false
}
var room_map_data: Dictionary = {}  # room_name -> {platforms: [Rect2]}
var _is_transitioning: bool = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	"""Initializes the main scene by instantiating the start room and adding it to the scene tree.
	It also sets up the player character and positions it at the start location.
	"""
	player.hide()  # Hide the player until the room is fully loaded to prevent visual glitches.

	# Instantiate start room and add it to the main scene.
	var start_room_instance = rooms[current_room_name].instantiate()
	start_room_instance.connect("room_exit", Callable(self, "_on_room_exit"))
	frame.add_child(start_room_instance)
	print("Current rooms in frame: " + str(frame.get_children()))
	current_room = start_room_instance
	explored_rooms[current_room_name] = true  # Mark the starting room as explored.
	_extract_room_data(current_room, current_room_name)

	# Add the player to the main scene and set its position to the start position.
	player.position = current_room.get_node("SpawnPoints/StartPosition").position
	player.show()  # Show the player after setting its position.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	"""This function is called every frame and can be used to handle any 
	per-frame logic or updates needed for the main scene.
	"""
	var local_x = (player.global_position.x - room_bounds.position.x) / room_bounds.size.x
	var local_y = (player.global_position.y - room_bounds.position.y) / room_bounds.size.y

	$HUD.update_minimap(current_room_name, Vector2(local_x, local_y), explored_rooms, room_map_data)


func _get_entry_spawn(from_room: String, to_room: String) -> String:
	"""Determines the appropriate spawn point name for the player when transitioning between rooms.
	The spawn point is based on the direction of entry into the new room, ensuring the player appears
	at the correct location corresponding to the exit they used in the previous room.
	"""
	if to_room == "central_room":
		match from_room:
			"east_room":
				return "EastSpawn"
			"west_room":
				return "WestSpawn"
			"north_room":
				return "NorthSpawn"
	return "StartPosition"


func _on_room_exit(direction: String) -> void:
	"""Handles the event when the player exits a room in a given direction.
	It updates the current room based on the direction of exit, marks the new room as explored,
	and updates the player's position to the corresponding spawn point in the new room.
	"""
	if _is_transitioning:
		return
	_is_transitioning = true
	player.hide()

	var source_room_name := current_room_name
	var new_room_name: String
	match direction:
		"central_room":
			new_room_name = "central_room"
		"north_room":
			new_room_name = "north_room"
		"east_room":
			new_room_name = "east_room"
		"south_room":
			new_room_name = "south_room"
		"west_room":
			new_room_name = "west_room"
		_:
			push_error("Invalid room exit direction: " + direction)
			_is_transitioning = false
			return

	if current_room:
		if current_room.is_connected("room_exit", Callable(self, "_on_room_exit")):
			current_room.disconnect("room_exit", Callable(self, "_on_room_exit"))
			print("Disconnected room_exit signal from current room before freeing it.")
		current_room.queue_free()
		await current_room.tree_exited

	var new_room_instance = rooms[new_room_name].instantiate()
	frame.add_child(new_room_instance)
	current_room = new_room_instance
	current_room_name = new_room_name
	explored_rooms[current_room_name] = true
	_extract_room_data(current_room, current_room_name)

	# Move the player to the spawn point in the new room.
	var spawn_point_name = _get_entry_spawn(source_room_name, new_room_name)
	var spawn_point = current_room.get_node_or_null("SpawnPoints/" + spawn_point_name)
	if not spawn_point:
		spawn_point = current_room.get_node_or_null("SpawnPoints/StartPosition")

	if spawn_point:
		print("Setting player position to: " + str(spawn_point.position))
		player.position = spawn_point.position
		player.velocity = Vector2.ZERO
		new_room_instance.connect("room_exit", Callable(self, "_on_room_exit"))
		player.show()
		await get_tree().create_timer(0.5).timeout
		_is_transitioning = false
	else:
		push_error("Spawn point missing in room: " + current_room_name)
		_is_transitioning = false


func _extract_room_data(room: Node2D, room_name: String) -> void:
	"""Extracts the platform data from the given room and stores it in the room_map_data dictionary.
	This data is used to represent the room's geometry on the full map and minimap.
	"""
	var data := {"platforms": []}

	var platforms_node := room.get_node_or_null("Platforms")
	if platforms_node:
		for child in platforms_node.get_children():
			# child.position is the node's origin; treat it as the center
			var rect := Rect2(
				child.position - Constants.PLATFORM_SIZE * 0.5, Constants.PLATFORM_SIZE
			)
			data["platforms"].append(rect)

	room_map_data[room_name] = data
