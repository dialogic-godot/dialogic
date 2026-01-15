@tool
extends DialogicLayoutLayer

# Awkward way of doing this, but we need a 'none' default to preserve compatiblity
# These enums are just copies of Viewport.DefaultCanvasItemTextureFilter
enum DefaultCanvasItemTextureFilter {
	USE_PROJECT_SETTINGS,
	NEAREST,
	LINEAR,
	LINEAR_WITH_MIPMAPS,
	NEAREST_WITH_MIPMAPS
}

# These enums are just copies of Viewport.DefaultCanvasItemTextureRepeat
enum DefaultCanvasItemTextureRepeat {
	USE_PROJECT_SETTINGS,
	DISABLED,
	ENABLED,
	REPEAT_MIRROR
}


@export var bg_texture_filter : DefaultCanvasItemTextureFilter = DefaultCanvasItemTextureFilter.USE_PROJECT_SETTINGS
@export var bg_texture_repeat : DefaultCanvasItemTextureRepeat = DefaultCanvasItemTextureRepeat.USE_PROJECT_SETTINGS


func _ready() -> void:
	# This is a work around to the style editor not accepting negative numbered enums
	# This allows the enum values to properly match the Viewport defaults
	bg_texture_filter = bg_texture_filter -1
	bg_texture_repeat = bg_texture_repeat -1
