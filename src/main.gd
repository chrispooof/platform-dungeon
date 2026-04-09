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


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	"""Initializes the main scene by instantiating the start room and adding it to the scene tree.
	It also sets up the player character and positions it at the start location.
	"""
	player.hide()  # Hide the player until the room is fully loaded to prevent visual glitches.

	# Instantiate start room and add it to the main scene.
	var start_room_instance = rooms[current_room_name].instantiate()
	frame.add_child(start_room_instance)
	current_room = start_room_instance
	explored_rooms[current_room_name] = true  # Mark the starting room as explored.

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

	$HUD.update_minimap(current_room_name, Vector2(local_x, local_y), explored_rooms)
