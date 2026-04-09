class_name Constants

const SPEED := 300.0
const JUMP_VELOCITY := -400.0
const SCREEN_WIDTH := 1100
const SCREEN_HEIGHT := 650

# Sizes for platforms and traps, used for extracting geometry data from rooms
const PLATFORM_SIZE := Vector2(107.0, 22.0)
const TRAP_SIZE := Vector2(52.0, 12.0)

# Sizes for minimap and full map indicators
const TILE_SIZE := 152.0
const TILE_STEP := 160.0
const DOT_SIZE_MINI := Vector2(4.0, 4.0)
const DOT_SIZE_FULL := Vector2(6.0, 6.0)

# Colors for minimap and full map indicators
const COLOR_UNEXPLORED := Color(0.15, 0.15, 0.15, 0.85)
const COLOR_EXPLORED := Color(0.35, 0.35, 0.45, 0.92)
const COLOR_CURRENT := Color(0.45, 0.60, 0.80, 0.95)
const COLOR_DOT := Color(1.0, 0.9, 0.2, 1.0)
const COLOR_PLATFORM := Color(0.7, 0.7, 0.7, 0.9)
const COLOR_TRAP := Color(0.9, 0.25, 0.25, 0.9)
