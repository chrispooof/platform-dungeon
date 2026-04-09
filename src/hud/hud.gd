extends CanvasLayer

const TILE_SIZE := 76.0
const TILE_STEP := 80.0
const DOT_SIZE_MINI := Vector2(4.0, 4.0)
const DOT_SIZE_FULL := Vector2(6.0, 6.0)

const ROOM_GRID := {
	"north_room": Vector2i(1, 0),
	"west_room": Vector2i(0, 1),
	"central_room": Vector2i(1, 1),
	"east_room": Vector2i(2, 1),
	"south_room": Vector2i(1, 2),
}

const COLOR_UNEXPLORED := Color(0.15, 0.15, 0.15, 0.85)
const COLOR_EXPLORED := Color(0.35, 0.35, 0.45, 0.92)
const COLOR_CURRENT := Color(0.45, 0.60, 0.80, 0.95)
const COLOR_DOT := Color(1.0, 0.9, 0.2, 1.0)

@onready var indicator_border: Panel = $MiniMapIndicator/IndicatorBorder
@onready var indicator_dot: ColorRect = $MiniMapIndicator/IndicatorDot
@onready var full_map: Panel = $FullMap
@onready var room_grid: Control = $FullMap/RoomGrid
@onready var full_map_dot: ColorRect = $FullMap/RoomGrid/FullMapDot

var room_tiles: Dictionary = {}
var current_room_name: String = ""
var _player_norm: Vector2 = Vector2(0.5, 0.5)
var _explored: Dictionary = {}


func _ready() -> void:
	"""Initializes the HUD by setting up the minimap and full map indicators,
	and building the room tiles for the full map based on the defined ROOM_GRID.
	"""
	full_map.visible = false
	buildroom_tiles()
	indicator_dot.color = COLOR_DOT
	indicator_dot.size = DOT_SIZE_MINI
	full_map_dot.color = COLOR_DOT
	full_map_dot.size = DOT_SIZE_FULL


func _unhandled_input(event: InputEvent) -> void:
	"""Handles input events to toggle the visibility of the full map when the 'M' key is pressed.
	When the full map is shown, it also refreshes the map to ensure it displays the current state.
	"""
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_M:
			full_map.visible = not full_map.visible
			if full_map.visible:
				refresh_full_map()
			get_viewport().set_input_as_handled()


func buildroom_tiles() -> void:
	"""Builds the grid of room tiles for the full map based on the defined ROOM_GRID.
	Each tile is created as a Panel node, styled, and positioned according to its grid coordinates.
	"""
	for room_name in ROOM_GRID:
		var grid_pos: Vector2i = ROOM_GRID[room_name]
		var tile := Panel.new()
		tile.name = "tile_" + room_name
		tile.size = Vector2(TILE_SIZE, TILE_SIZE)
		tile.position = Vector2(grid_pos.x * TILE_STEP, grid_pos.y * TILE_STEP)
		room_grid.add_child(tile)
		room_tiles[room_name] = tile
	room_grid.move_child(full_map_dot, room_grid.get_child_count() - 1)


func update_minimap(room_name: String, player_norm: Vector2, explored: Dictionary) -> void:
	"""Updates the minimap and full map indicators based on the player's current room, 
	normalized position within the room, and explored rooms dictionary.
	"""
	current_room_name = room_name
	_player_norm = player_norm
	_explored = explored
	refresh_indicator()
	if full_map.visible:
		refresh_full_map()


func refresh_indicator() -> void:
	"""Updates the position of the player indicator dot on the minimap based on the player's
	normalized position within the current room.
	"""
	var sz := indicator_border.size
	indicator_dot.position = Vector2(
		_player_norm.x * sz.x - DOT_SIZE_MINI.x * 0.5, _player_norm.y * sz.y - DOT_SIZE_MINI.y * 0.5
	)


func refresh_full_map() -> void:
	"""Updates the full map tiles based on the current room and explored rooms.
	"""
	for room_name in room_tiles:
		var tile: Panel = room_tiles[room_name]
		var sb := StyleBoxFlat.new()
		sb.set_corner_radius_all(3)
		if room_name == current_room_name:
			sb.bg_color = COLOR_CURRENT
		elif _explored.get(room_name, false):
			sb.bg_color = COLOR_EXPLORED
		else:
			sb.bg_color = COLOR_UNEXPLORED
		tile.add_theme_stylebox_override("panel", sb)
	if current_room_name in room_tiles:
		var tile: Panel = room_tiles[current_room_name]
		full_map_dot.position = (
			tile.position
			+ Vector2(
				_player_norm.x * TILE_SIZE - DOT_SIZE_FULL.x * 0.5,
				_player_norm.y * TILE_SIZE - DOT_SIZE_FULL.y * 0.5
			)
		)
