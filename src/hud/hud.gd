extends CanvasLayer

const ROOM_GRID := {
	"north_room": Vector2i(1, 0),
	"west_room": Vector2i(0, 1),
	"central_room": Vector2i(1, 1),
	"east_room": Vector2i(2, 1),
	"south_room": Vector2i(1, 2),
}

@onready var indicator_border: Panel = $MiniMapIndicator/IndicatorBorder
@onready var geometry_layer: Control = $MiniMapIndicator/GeometryLayer
@onready var indicator_dot: ColorRect = $MiniMapIndicator/IndicatorDot
@onready var full_map: Panel = $FullMap
@onready var room_grid: Control = $FullMap/RoomGrid
@onready var full_map_dot: ColorRect = $FullMap/RoomGrid/FullMapDot

var _room_tiles: Dictionary = {}  # room_name -> Panel
var _tile_geo: Dictionary = {}  # room_name -> [ColorRect]  (geometry on full map tiles)
var _current_room_name: String = ""
var _player_norm: Vector2 = Vector2.ZERO
var _explored: Dictionary = {}
var _room_map_data: Dictionary = {}  # room_name -> {platforms:[Rect2]}


func _ready() -> void:
	"""Initializes the HUD by setting up the minimap and full map indicators,
	and building the room tiles for the full map based on the defined ROOM_GRID.
	"""
	full_map.visible = false
	build_room_tiles()
	indicator_dot.color = Constants.COLOR_DOT
	indicator_dot.size = Constants.DOT_SIZE_MINI
	full_map_dot.color = Constants.COLOR_DOT
	full_map_dot.size = Constants.DOT_SIZE_FULL


func _unhandled_input(event: InputEvent) -> void:
	"""Handles input events to toggle the visibility of the full map when the 'M' key is pressed.
	When the full map is shown, it also refreshes the map to ensure it displays the current state.
	"""
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_M:
			full_map.visible = not full_map.visible
			if full_map.visible:
				refresh_tile_colors()
				rebuild_full_map_geometry()
				refresh_full_map_dot()
			get_viewport().set_input_as_handled()


# ----- Mini Map Functions Start-----
func update_minimap(
	room_name: String, player_norm: Vector2, explored: Dictionary, room_map_data: Dictionary
) -> void:
	"""Updates the minimap and full map indicators based on the player's current room, 
	normalized position within the room, and explored rooms dictionary.
	"""
	var room_changed := room_name != _current_room_name
	_current_room_name = room_name
	_player_norm = player_norm
	_room_map_data = room_map_data
	_explored = explored

	if room_changed:
		rebuild_indicator_geometry()
		rebuild_full_map_geometry()

	refresh_indicator()
	if full_map.visible:
		refresh_tile_colors()
		refresh_full_map_dot()


func rebuild_indicator_geometry() -> void:
	"""Rebuilds the geometry for the minimap indicator based on the current room's map data.
	"""
	for child in geometry_layer.get_children():
		child.queue_free()
	var data: Dictionary = _room_map_data.get(_current_room_name, {})
	var ind_size := indicator_border.size
	_spawn_geo_rects(
		geometry_layer, data, ind_size, Vector2(Constants.SCREEN_WIDTH, Constants.SCREEN_HEIGHT)
	)


func refresh_indicator() -> void:
	"""Updates the position of the player indicator dot on the minimap based on the player's
	normalized position within the current room.
	"""
	var sz := indicator_border.size
	indicator_dot.position = Vector2(
		_player_norm.x * sz.x - Constants.DOT_SIZE_MINI.x * 0.5,
		_player_norm.y * sz.y - Constants.DOT_SIZE_MINI.y * 0.5
	)


# ----- Mini Map Functions End-----


# ----- Full Map Functions Start-----
func build_room_tiles() -> void:
	"""Builds the grid of room tiles for the full map based on the defined ROOM_GRID.
	Each tile is created as a Panel node, styled, and positioned according to its grid coordinates.
	"""
	for room_name in ROOM_GRID:
		var grid_pos: Vector2i = ROOM_GRID[room_name]
		var tile := Panel.new()
		tile.name = "tile_" + room_name
		tile.size = Vector2(Constants.TILE_SIZE, Constants.TILE_SIZE)
		tile.position = Vector2(
			grid_pos.x * Constants.TILE_STEP - Constants.TILE_SIZE * 0.5,
			grid_pos.y * Constants.TILE_STEP - Constants.TILE_SIZE * 0.5
		)
		room_grid.add_child(tile)
		_room_tiles[room_name] = tile
		_tile_geo[room_name] = []
	room_grid.move_child(full_map_dot, room_grid.get_child_count() - 1)


func rebuild_full_map_geometry() -> void:
	"""Rebuilds the geometry for the full map based on the current room's map data."""
	for room_name in _tile_geo:
		for child in _tile_geo[room_name]:
			child.queue_free()
		_tile_geo[room_name].clear()

	var tile_vec := Vector2(Constants.TILE_SIZE, Constants.TILE_SIZE)
	var room_vec := Vector2(Constants.SCREEN_WIDTH, Constants.SCREEN_HEIGHT)
	for room_name in _room_tiles:
		var data: Dictionary = _room_map_data.get(room_name, {})
		if data.is_empty():
			continue
		var tile: Panel = _room_tiles[room_name]
		var rects := _spawn_geo_rects(tile, data, tile_vec, room_vec)
		_tile_geo[room_name] = rects


func refresh_tile_colors() -> void:
	"""Updates the colors of the room tiles on the full map based on the current room and explored rooms."""
	for room_name in _room_tiles:
		var tile: Panel = _room_tiles[room_name]
		var sb := StyleBoxFlat.new()
		sb.set_corner_radius_all(3)
		if room_name == _current_room_name:
			sb.bg_color = Constants.COLOR_CURRENT
		elif _explored.get(room_name, false):
			sb.bg_color = Constants.COLOR_EXPLORED
		else:
			sb.bg_color = Constants.COLOR_UNEXPLORED
		tile.add_theme_stylebox_override("panel", sb)


func refresh_full_map_dot() -> void:
	"""Updates the position of the player indicator dot on the full map based on the player's
	normalized position within the current room.
	"""
	if _current_room_name in _room_tiles:
		var tile: Panel = _room_tiles[_current_room_name]
		full_map_dot.position = (
			tile.position
			+ Vector2(
				_player_norm.x * Constants.TILE_SIZE - Constants.DOT_SIZE_FULL.x * 0.5,
				_player_norm.y * Constants.TILE_SIZE - Constants.DOT_SIZE_FULL.y * 0.5
			)
		)


func _spawn_geo_rects(
	parent: Control, data: Dictionary, display_size: Vector2, room_space: Vector2
) -> Array:
	"""Spawns ColorRect nodes for platforms and traps based on the provided geometry data.
	The rectangles are scaled and positioned according to the display size and room space dimensions.
	"""
	var created := []
	var scale_x := display_size.x / room_space.x
	var scale_y := display_size.y / room_space.y
	for platform_rect: Rect2 in data.get("platforms", []):
		var cr := ColorRect.new()
		cr.color = Constants.COLOR_PLATFORM
		cr.position = Vector2(
			platform_rect.position.x * scale_x, platform_rect.position.y * scale_y
		)
		cr.size = Vector2(
			max(1.0, platform_rect.size.x * scale_x), max(1.0, platform_rect.size.y * scale_y)
		)
		parent.add_child(cr)
		created.append(cr)

	for trap_rect: Rect2 in data.get("traps", []):
		var cr := ColorRect.new()
		cr.color = Constants.COLOR_TRAP
		cr.position = Vector2(trap_rect.position.x * scale_x, trap_rect.position.y * scale_y)
		cr.size = Vector2(
			max(1.0, trap_rect.size.x * scale_x), max(1.0, trap_rect.size.y * scale_y)
		)
		parent.add_child(cr)
		created.append(cr)

	return created

# ----- Full Map Functions End-----
