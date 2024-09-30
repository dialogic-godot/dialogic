@tool
class_name DialogicNode_PortraitContainer
extends Control

## Node that defines a position for dialogic portraits and how to display portraits at that position.

enum PositionModes {
	POSITION, ## This container can be joined/moved to with the Character Event
	SPEAKER,  ## This container is joined/left automatically based on the speaker.
	}

@export var mode := PositionModes.POSITION

@export_subgroup('Mode: Position')
## The position this node corresponds to.
@export var container_ids: PackedStringArray = ["1"]


@export_subgroup('Mode: Speaker')
## Can be used to use a different portrait.
## E.g. "Faces/" would mean instead of "happy" it will use portrait "Faces/happy"
@export var portrait_prefix := ''

@export_subgroup('Portrait Placement')
enum SizeModes {
	KEEP, ## The height and width of the container have no effect, only the origin.
	FIT_STRETCH, ## The portrait will be fitted into the container, ignoring it's aspect ratio and the character/portrait scale.
	FIT_IGNORE_SCALE, ## The portrait will be fitted into the container, ignoring the character/portrait scale, but preserving the aspect ratio.
	FIT_SCALE_HEIGHT ## Recommended. The portrait will be scaled to fit the container height. A character/portrait scale of 100% means 100% container height. Aspect ratio will be preserved.
	}
## Defines how to affect the scale of the portrait
@export var size_mode: SizeModes = SizeModes.FIT_SCALE_HEIGHT :
	set(mode):
		size_mode = mode
		_update_debug_portrait_transform()

## If true, portraits will be mirrored in this position.
@export var mirrored := false :
	set(mirror):
		mirrored = mirror
		_update_debug_portrait_scene()


@export_group('Origin', 'origin')
enum OriginAnchors {TOP_LEFT, TOP_CENTER, TOP_RIGHT, LEFT_MIDDLE, CENTER, RIGHT_MIDDLE, BOTTOM_LEFT, BOTTOM_CENTER, BOTTOM_RIGHT}
## The portrait will be placed relative to this point in the container.
@export var origin_anchor: OriginAnchors = OriginAnchors.BOTTOM_CENTER :
	set(anchor):
		origin_anchor = anchor
		_update_debug_origin()

## An offset to apply to the origin. Rarely useful.
@export var origin_offset := Vector2() :
	set(offset):
		origin_offset = offset
		_update_debug_origin()

enum PivotModes {AT_ORIGIN, PERCENTAGE, PIXELS}
## Usually you want to rotate or scale around the portrait origin.
## For the moments where that is not the case, set the mode to PERCENTAGE or PIXELS and use [member pivot_value].
@export var pivot_mode: PivotModes = PivotModes.AT_ORIGIN
## Only has an effect when [member pivot_mode] is not AT_ORIGIN. Meaning depends on whether [member pivot_mode] is PERCENTAGE or PIXELS.
@export var pivot_value := Vector2()

@export_group('Debug', 'debug')
## A character that will be displayed in the editor, useful for getting the right size.
@export var debug_character: DialogicCharacter = null:
	set(character):
		debug_character = character
		_update_debug_portrait_scene()
@export var debug_character_portrait := "":
	set(portrait):
		debug_character_portrait = portrait
		_update_debug_portrait_scene()

var debug_character_holder_node: Node2D = null
var debug_character_scene_node: Node = null
var debug_origin: Sprite2D = null
var default_portrait_scene: String = DialogicUtil.get_module_path('Character').path_join("default_portrait.tscn")
# Used if no debug character is specified
var default_debug_character := load(DialogicUtil.get_module_path('Character').path_join("preview_character.tres"))

var ignore_resize := false


func _ready() -> void:
	match mode:
		PositionModes.POSITION:
			add_to_group('dialogic_portrait_con_position')
		PositionModes.SPEAKER:
			add_to_group('dialogic_portrait_con_speaker')

	if Engine.is_editor_hint():
		resized.connect(_update_debug_origin)

		if !ProjectSettings.get_setting('dialogic/portraits/default_portrait', '').is_empty():
			default_portrait_scene = ProjectSettings.get_setting('dialogic/portraits/default_portrait', '')

		debug_origin = Sprite2D.new()
		add_child(debug_origin)
		debug_origin.texture = load("res://addons/dialogic/Editor/Images/Dropdown/default.svg")

		_update_debug_origin()
		_update_debug_portrait_scene()
	else:
		resized.connect(update_portrait_transforms)


################################################################################
##						MAIN METHODS
################################################################################

func update_portrait_transforms() -> void:
	if ignore_resize:
		return

	match pivot_mode:
		PivotModes.AT_ORIGIN:
			pivot_offset = _get_origin_position()
		PivotModes.PERCENTAGE:
			pivot_offset = size*pivot_value
		PivotModes.PIXELS:
			pivot_offset = pivot_value

	for child in get_children():
		DialogicUtil.autoload().Portraits._update_character_transform(child)


## Returns a Rect2 with the position as the position and the scale as the size.
func get_local_portrait_transform(portrait_rect:Rect2, character_scale:=1.0) -> Rect2:
	var transform := Rect2()
	transform.position = _get_origin_position()
	
	# Mode that ignores the containers size
	if size_mode == SizeModes.KEEP:
		transform.size = Vector2(1,1) * character_scale

	# Mode that makes sure neither height nor width go out of container
	elif size_mode == SizeModes.FIT_IGNORE_SCALE:
		if size.x/size.y < portrait_rect.size.x/portrait_rect.size.y:
			transform.size = Vector2(1,1) * size.x/portrait_rect.size.x
		else:
			transform.size = Vector2(1,1) * size.y/portrait_rect.size.y

	# Mode that stretches the portrait to fill the whole container
	elif size_mode == SizeModes.FIT_STRETCH:
		transform.size = size/portrait_rect.size

	# Mode that size the character so 100% size fills the height
	elif size_mode == SizeModes.FIT_SCALE_HEIGHT:
		transform.size = Vector2(1,1) * size.y / portrait_rect.size.y*character_scale

	return transform


## Returns the current origin position
func _get_origin_position(rect_size = null) -> Vector2:
	if rect_size == null:
		rect_size = size
	return rect_size * Vector2(origin_anchor%3 / 2.0, floor(origin_anchor/3.0) / 2.0) + origin_offset


func is_container(id:Variant) -> bool:
	return str(id) in container_ids

#region DEBUG METHODS
################################################################################
### USE THIS TO DEBUG THE POSITIONS
#func _draw():
	#draw_rect(Rect2(Vector2(), size), Color(1, 0.3098039329052, 1), false, 2)
	#draw_string(get_theme_default_font(),get_theme_default_font().get_string_size(container_ids[0], HORIZONTAL_ALIGNMENT_LEFT, 1, get_theme_default_font_size()) , container_ids[0], HORIZONTAL_ALIGNMENT_CENTER)
#
#func _process(delta:float) -> void:
	#queue_redraw()


## Loads the debug_character with the debug_character_portrait
## Creates a holder node and applies mirror
func _update_debug_portrait_scene() -> void:
	if !Engine.is_editor_hint():
		return
	if is_instance_valid(debug_character_holder_node):
		for child in get_children():
			if child != debug_origin:
				child.free()
	
	# Get character
	var character := _get_debug_character()
	if not character is DialogicCharacter or character.portraits.is_empty():
		return
	
	# Determine portrait
	var debug_portrait := debug_character_portrait
	if debug_portrait.is_empty():
		debug_portrait = character.default_portrait
	if mode == PositionModes.SPEAKER and !portrait_prefix.is_empty():
		if portrait_prefix+debug_portrait in character.portraits:
			debug_portrait = portrait_prefix+debug_portrait
	if not debug_portrait in character.portraits:
		debug_portrait = character.default_portrait
	
	var portrait_info: Dictionary = character.get_portrait_info(debug_portrait)
	
	# Determine scene
	var portrait_scene_path: String = portrait_info.get('scene', default_portrait_scene)
	if portrait_scene_path.is_empty(): 
		portrait_scene_path = default_portrait_scene
	
	debug_character_scene_node = load(portrait_scene_path).instantiate()
	
	if !is_instance_valid(debug_character_scene_node):
		return
	
	# Load portrait
	DialogicUtil.apply_scene_export_overrides(debug_character_scene_node, character.portraits[debug_portrait].get('export_overrides', {}))
	debug_character_scene_node._update_portrait(character, debug_portrait)
	
	# Add character node
	if !is_instance_valid(debug_character_holder_node):
		debug_character_holder_node = Node2D.new()
		add_child(debug_character_holder_node)
		print(debug_character_holder_node)
	
	# Add portrait node
	debug_character_holder_node.add_child(debug_character_scene_node)
	move_child(debug_character_holder_node, 0)
	debug_character_scene_node._set_mirror(character.mirror != mirrored != portrait_info.get('mirror', false))
	
	_update_debug_portrait_transform()


## Set's the size and position of the holder and scene node
## according to the size_mode
func _update_debug_portrait_transform() -> void:
	if !Engine.is_editor_hint() or !is_instance_valid(debug_character_scene_node) or !is_instance_valid(debug_origin):
		return
	var character := _get_debug_character()
	var portrait_info := character.get_portrait_info(debug_character_portrait)
	var transform := get_local_portrait_transform(debug_character_scene_node._get_covered_rect(), character.scale*portrait_info.get('scale', 1))
	debug_character_holder_node.position = transform.position
	debug_character_scene_node.position = portrait_info.get('offset', Vector2())+character.offset

	debug_character_holder_node.scale = transform.size


## Updates the debug origins position. Also calls _update_debug_portrait_transform()
func _update_debug_origin() -> void:
	if !Engine.is_editor_hint() or !is_instance_valid(debug_origin):
		return
	debug_origin.position = _get_origin_position()
	_update_debug_portrait_transform()



## Returns the debug character or the default debug character
func _get_debug_character() -> DialogicCharacter:
	return debug_character if debug_character != null else default_debug_character

#endregion
