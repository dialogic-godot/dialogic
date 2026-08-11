@tool
@icon("node_portrait_container_icon.svg")
class_name DialogicNode_PortraitContainer
extends Control

## Node that defines a position for dialogic portraits and how to display portraits at that position.

enum PositionModes {
	POSITION, ## This container can be joined/moved to with the Character Event
	SPEAKER,  ## This container is joined/left automatically based on the speaker.
	_CHARACTER, ## This container holds a specific character. These are created at runtime and shouldn't be assigned manually.
}

@export var mode := PositionModes.POSITION

@export_subgroup("Mode: Position")
## The position names this node corresponds to.
@export var container_ids: PackedStringArray = ["1"]


@export_subgroup("Mode: Speaker")
## Can be used to use a different portrait.
## E.g. "Faces/" would mean instead of "happy" it will use portrait "Faces/happy"
@export var portrait_prefix := ""


@export_subgroup("Portrait Placement")
enum SizeModes {
	KEEP, ## The height and width of the container have no effect, only the origin.
	FIT_STRETCH, ## The portrait will be fitted into the container, ignoring its aspect ratio and the character/portrait scale.
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
		update_mirror()
		_update_debug_portrait_scene()

@export_group("Container Transform", "container")
## The containers size either in pixels or as a percentage of the parent size.
@export var container_size := DialogicFlexVector.new():
	set(siz):
		if siz == null:
			container_size = DialogicFlexVector.new()
			container_size.container_size = get_parent_control().size
			container_size.overwrite_from_vector(size)
		else:
			container_size = siz
			update_transform_from_properties.call_deferred()
		if container_size != null and not container_size.changed.is_connected(update_transform_from_properties):
			container_size.changed.connect(update_transform_from_properties)

## The containers origin position, either as an absolute position or as a percentage of the parent size.
@export var container_position := DialogicFlexVector.new():
	set(pos):
		if pos == null:
			container_position = DialogicFlexVector.new()
			container_position.container_size = get_parent_control().size
			container_position.overwrite_from_vector(position+current_settings._get_origin_position())
		else:
			container_position = pos
			update_transform_from_properties.call_deferred()
		if container_position != null and not container_position.changed.is_connected(update_transform_from_properties):
			container_position.changed.connect(update_transform_from_properties)

@export_range(-360, 360, 0.01, "degrees", "or_less", "or_greater") var container_rotation := 0.0:
	set(rot):
		container_rotation = rot
		rotation_degrees = rot
		update_transform_from_properties.call_deferred()

## The portrait will be placed relative to this point in the container.
@export var container_origin := DialogicFlexVector.from_string("x0.5y1"):
	set(ori):
		if ori == null:
			container_origin = DialogicFlexVector.new()
			container_origin.container_size = container_size.in_pixels()
			container_origin.x_value = 0.5
			container_origin.y_value = 1.0
		else:
			container_origin = ori
			update_transform_from_properties.call_deferred()
		if container_origin != null and not container_origin.changed.is_connected(update_transform_from_properties):
			container_origin.changed.connect(update_transform_from_properties)


## Can be set at runtime. Will adjust the ordering of this container and all its siblings
var container_z_index := 0:
	set(z):
		if container_z_index != z:
			container_z_index = z
			update_z_index()
		else:
			container_z_index = z

var movement_tween : Tween = null
var movement_time := 0.0


#region debug_properties
@export_group("Debug", "debug")
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
var default_portrait_scene: String = DialogicUtil.get_module_path("Character").path_join("default_portrait.tscn")
var default_debug_character := load("uid://dykf1j17ct5mo")

## If true the outline, position-name and origin icon are drawn in-game like they are in the editor.
## This value can be controlled for all containers by setting Dialogic.PortraitContainers.debug_draw
var debug_draw := false
#endregion

## Used to avoid infinitely loops when updating transforms.
var _ignore_transform_change := false

## Usually contains the containers current settings as a ContainerSettings
var current_settings: ContainerSettings
## While moving, this contains the containers target transform
var target_settings: ContainerSettings

func _ready() -> void:
	if not container_position.changed.is_connected(update_transform_from_properties):
		container_position.changed.connect(update_transform_from_properties)
	if not container_size.changed.is_connected(update_transform_from_properties):
		container_size.changed.connect(update_transform_from_properties)
	if not container_origin.changed.is_connected(update_transform_from_properties):
		container_origin.changed.connect(update_transform_from_properties)

	current_settings = ContainerSettings.from_container(self)

	# For pre alpha 21 compatibility
	if container_size.x_value == 0 and container_size.y_value == 0:
		update_properties_from_transform()
		set_anchor(SIDE_BOTTOM, 0, true)
		set_anchor(SIDE_LEFT, 0, true)
		set_anchor(SIDE_RIGHT, 0, true)
		set_anchor(SIDE_TOP, 0, true)

	update_transform_from_properties.call_deferred()

	match mode:
		PositionModes.POSITION, PositionModes._CHARACTER:
			add_to_group("dialogic_portrait_con_position")
		PositionModes.SPEAKER:
			add_to_group("dialogic_portrait_con_speaker")

	if Engine.is_editor_hint():
		_update_debug_portrait_scene()
		if not ProjectSettings.get_setting("dialogic/portraits/default_portrait", "").is_empty():
			default_portrait_scene = ProjectSettings.get_setting("dialogic/portraits/default_portrait", "")
		item_rect_changed.connect(update_properties_from_transform)

	else:
		debug_draw = DialogicUtil.autoload().PortraitContainers.debug_draw
		item_rect_changed.connect(container_resized_during_game)
		child_entered_tree.connect(_child_entered_tree)

	connect_parent_resize()


func connect_parent_resize() -> void:
	if not get_parent().resized.is_connected(_on_parent_resized):
		get_parent().resized.connect(_on_parent_resized)


#region MAIN METHODS
################################################################################


## Tweens the containers values to [param to_settings] values.
func update_container(to_settings: ContainerSettings, time:=0.0, easing:=Tween.EASE_IN_OUT, trans:=Tween.TRANS_SINE, set_z_index:=true, set_mirror:=true) -> void:
	if movement_tween and movement_tween.is_running():
		movement_tween.kill()

	## This handles moving the container to a different parent if necessary.
	if to_settings.reference_position_id:
		var ref_con := DialogicUtil.autoload().PortraitContainers.get_container(to_settings.reference_position_id)
		if ref_con.get_parent() != get_parent():
			var global_origin: Vector2 = global_position+current_settings._get_origin_position()
			var global_size := container_size.as_pixels()
			get_parent().remove_child(self)
			ref_con.get_parent().add_child(self)
			connect_parent_resize()
			set_parent_size(get_parent_control().size)
			container_position.overwrite_from_vector(global_origin-get_parent().global_position)
			container_size.overwrite_from_vector(global_size)

	movement_tween = create_tween()
	movement_time = time
	movement_tween.set_parallel(true).set_ease(easing).set_trans(trans)

	target_settings = to_settings
	to_settings.set_parent_size(get_parent_control().size)

	movement_tween.tween_property(self, "size_mode", to_settings.size_mode, time)

	container_position.make_similar(to_settings.position)
	movement_tween.tween_property(container_position, "x_value", to_settings.position.x_value, time)
	movement_tween.tween_property(container_position, "y_value", to_settings.position.y_value, time)

	movement_tween.tween_property(self, 'container_rotation', to_settings.rotation, time)

	container_size.make_similar(to_settings.size)
	movement_tween.tween_property(container_size, "x_value", to_settings.size.x_value, time)
	movement_tween.tween_property(container_size, "y_value", to_settings.size.y_value, time)

	if set_mirror:
		mirrored = to_settings.mirrored

	container_origin.make_similar(to_settings.origin)
	movement_tween.tween_property(container_origin, "x_value", to_settings.origin.x_value, time)
	movement_tween.tween_property(container_origin, "y_value", to_settings.origin.y_value, time)

	if set_z_index:
		container_z_index = to_settings.z_index

	movement_tween.finished.connect(current_settings.update_from_container.bind(self))
	movement_tween.finished.connect(set.bind("target_settings", null))

	# tween the portraits transforms towards their final transforms in to_settings.
	for character_node in get_children():
		if not character_node.has_meta("character"): continue
		movement_tween.tween_property(character_node, "position", to_settings._get_origin_position(), time)
		for portrait_node in character_node.get_children():
			if not portrait_node is DialogicPortrait: continue
			update_portrait_transform(portrait_node, to_settings, movement_tween, time)

	# if time is zero, make the movement_tween finish instantly
	if time == 0:
		movement_tween.custom_step(99)


## Tween the scale and position ofthe given [param portrait_node] to fit into [param container_settings].
func update_portrait_transform(portrait_node:DialogicPortrait, container_settings:ContainerSettings, tween:Tween=null, time:float=0.0) -> void:
	var character: DialogicCharacter = portrait_node.get_parent().get_meta("character")

	var target_pos: Vector2 = character.offset + character.get_portrait_info(portrait_node.portrait).get("offset", Vector2())
	var target_scale := container_settings.get_portrait_scale(portrait_node)
	if tween == null or time == 0:
		portrait_node.position = target_pos
		portrait_node.scale = target_scale
	else:
		tween.tween_property(portrait_node, "position", target_pos, time)
		tween.tween_property(portrait_node, "scale", target_scale, time)


## When the container is resized during the game
## make sure to reposition the character nodes at the origin and update the portrait transform.
func container_resized_during_game() -> void:
	current_settings.update_from_container(self)
	for child in get_children():
		# reposition character nodes at the origin
		if child.has_meta("character"):
			child.position = current_settings._get_origin_position()

		# update portrait transforms
		for grand_child in child.get_children():
			if grand_child is DialogicPortrait:
				update_portrait_transform(grand_child, current_settings)


## When a new character is added to this container,
## position it correctly and start listening to children (portraits) being added to it.
func _child_entered_tree(child:Node) -> void:
	if child.has_meta("character"):
		# positon character node at the origin
		current_settings.update_from_container(self)
		child.position = current_settings._get_origin_position()

		# start listening to children (portraits) being added.
		if not child.child_entered_tree.is_connected(_portrait_entered_tree):
			child.child_entered_tree.connect(_portrait_entered_tree)


## When portraits are added to a character, update their transforms and mirror.
func _portrait_entered_tree(grand_child:Node) -> void:
	if grand_child is DialogicPortrait:
		current_settings.update_from_container(self)
		update_portrait_transform(grand_child, current_settings, null, 0)
		update_mirror()


## Update the mirror of all the portraits in this container.
func update_mirror() -> void:
	if current_settings: current_settings.update_from_container(self)

	for character_node in get_children():
		if not character_node.has_meta("character"):
			continue

		for portrait_node in character_node.get_children():
			if not portrait_node is DialogicPortrait:
				continue

			var info: Dictionary = portrait_node.character.get_portrait_info(portrait_node.portrait)
			var resulting_mirror: bool = mirrored != portrait_node.character.mirror != info.get("mirror", false)

			portrait_node._set_mirror(resulting_mirror)


## Update the sorting of this node and its PortraitContainer siblings based on their z-index variable.
func update_z_index() -> void:
	if current_settings: current_settings.update_from_container(self)
	var sorted_children := get_parent().get_children().filter(func(x): return x is DialogicNode_PortraitContainer)
	sorted_children.sort_custom(func(con1, con2): return con1.container_z_index < con2.container_z_index)
	var idx := 0
	for con in sorted_children:
		con.get_parent().move_child(con, idx)
		idx += 1


func _on_parent_resized() -> void:
	update_transform_from_properties()


## Updates [member container_size], [member container_position], [member container_container_origin]
## and [member container_rotation] based on the transform (position, size, rotation) of this node.
func update_properties_from_transform() -> void:
	if _ignore_transform_change:
		return
	current_settings.update_from_container(self)
	_ignore_transform_change = true
	set_parent_size(get_parent_control().size)
	container_size.overwrite_from_vector(size)
	container_origin.container_size = container_size.as_pixels()
	container_rotation = rotation_degrees
	container_position.overwrite_from_vector(position+current_settings._get_origin_position().rotated(rotation))
	_ignore_transform_change = false


## Updates size, position and rotation based on [member container_size], [member container_position],
## [member container_container_origin] and [member container_rotation].
func update_transform_from_properties() -> void:
	if _ignore_transform_change:
		return
	if not is_node_ready():
		await ready
	current_settings.update_from_container(self)
	_ignore_transform_change = true
	set_parent_size(get_parent_control().size)
	size = container_size.as_pixels()
	position = current_settings._get_top_left_position()
	_ignore_transform_change = false
	queue_redraw()


## Returns true if the given [param id] is one of the container_id's of this container.
func is_container(id:Variant) -> bool:
	return str(id) in container_ids

#endregion


#region DEBUG METHODS
################################################################################
### USE THIS TO DEBUG THE POSITIONS
var pivot_texture := load("res://addons/dialogic/Editor/Images/Resources/portrait.svg")
func _draw():
	if debug_draw or Engine.is_editor_hint():
		draw_rect(Rect2(Vector2(), size), Color(1, 0.3098039329052, 1), false, 2)
		if container_ids:
			draw_string(get_theme_default_font(),get_theme_default_font().get_string_size(container_ids[0], HORIZONTAL_ALIGNMENT_LEFT, 1, get_theme_default_font_size())+Vector2(8,0) , container_ids[0], HORIZONTAL_ALIGNMENT_CENTER)


		var pivot_draw_size := 32
		draw_texture_rect(pivot_texture, Rect2(current_settings._get_origin_position()-Vector2.ONE*pivot_draw_size*0.5, Vector2.ONE*pivot_draw_size), false, Color(1.0, 0.966, 0.997, 1.0))
		_update_debug_portrait_transform()


## Loads the debug_character with the debug_character_portrait
## Creates a holder node and applies mirror
func _update_debug_portrait_scene() -> void:
	if not Engine.is_editor_hint():
		return
	if is_instance_valid(debug_character_holder_node):
		for child in get_children():
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
	var portrait_scene_path: String = portrait_info.get("scene", default_portrait_scene)
	if portrait_scene_path.is_empty():
		portrait_scene_path = default_portrait_scene

	debug_character_scene_node = load(portrait_scene_path).instantiate()

	if not is_instance_valid(debug_character_scene_node):
		return

	# Load portrait
	DialogicUtil.apply_scene_export_overrides(debug_character_scene_node, character.portraits[debug_portrait].get("export_overrides", {}))
	debug_character_scene_node._update_portrait(character, debug_portrait)

	# Add character node
	if not is_instance_valid(debug_character_holder_node):
		debug_character_holder_node = Node2D.new()
		add_child(debug_character_holder_node)

	# Add portrait node
	debug_character_holder_node.add_child(debug_character_scene_node)
	move_child(debug_character_holder_node, 0)
	debug_character_scene_node._set_mirror(character.mirror != mirrored != portrait_info.get("mirror", false))

	_update_debug_portrait_transform()


## Set"s the size and position of the holder and scene node
## according to the size_mode
func _update_debug_portrait_transform() -> void:
	if not Engine.is_editor_hint() or not is_instance_valid(debug_character_scene_node):
		return
	if not is_node_ready():
		await ready
	var character := _get_debug_character()
	current_settings.update_from_container(self)
	var portrait_info := character.get_portrait_info(debug_character_portrait)
	debug_character_holder_node.position = current_settings._get_origin_position()
	debug_character_scene_node.position = portrait_info.get("offset", Vector2())+character.offset

	debug_character_scene_node.scale = current_settings.get_portrait_scale(debug_character_scene_node)
	update_mirror()

## Returns the debug character or the default debug character
func _get_debug_character() -> DialogicCharacter:
	return debug_character if debug_character != null else default_debug_character

func set_parent_size(parent_size:Vector2) -> void:
	container_position.container_size = parent_size
	container_size.container_size = parent_size
	container_origin.container_size = container_size.as_pixels()
	current_settings.set_parent_size(parent_size)


func _validate_property(property: Dictionary) -> void:
	if property.name in ["position", "rotation", "size", "scale"]:
		property.usage = PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_READ_ONLY


func _update_character_transform(settings:ContainerSettings, character_node: Node, tween:Tween = null, time:float = 0.0) -> void:
	var character: DialogicCharacter = character_node.get_meta("character")

	if character_node.get_child_count() == 0:
		return

	var portrait_node: DialogicPortrait = character_node.get_child(-1)
	var portrait_info: Dictionary = character.portraits.get(portrait_node.get_meta("portrait"), {})
	var transform = get_portrait_transform(settings, character, portrait_node)

	if time == 0:
		character_node.position = transform.position
	else:
		tween.tween_method(DialogicUtil.multitween.bind(character_node, "position", "base"), character_node.position, transform.position, time)

	for child in character_node.get_children():
		if not child is DialogicPortrait:
			continue

		portrait_node = (child as DialogicPortrait)
		portrait_info = character.portraits.get(portrait_node.get_meta("portrait"), {})
		transform = get_portrait_transform(settings, character, portrait_node)

		if time == 0:
			portrait_node.position = character.offset + portrait_info.get("offset", Vector2())
			portrait_node.scale = transform.size
		else:
			tween.tween_property(portrait_node, "position",character.offset + portrait_info.get("offset", Vector2()), time)
			tween.tween_property(portrait_node, "scale", transform.size, time)


func get_portrait_transform(settings:ContainerSettings, character: DialogicCharacter, portrait_node:DialogicPortrait) -> Rect2:
	var portrait_info: Dictionary = character.portraits.get(portrait_node.get_meta("portrait"), {})

	# ignore the character scale on custom portraits that have "ignore_char_scale" set to true
	var apply_character_scale: bool = not portrait_info.get("ignore_char_scale", false)

	var transform: Rect2 = settings.get_local_portrait_transform(
		portrait_node._get_covered_rect(),
		(character.scale * portrait_info.get("scale", 1))*int(apply_character_scale)+portrait_info.get("scale", 1)*int(!apply_character_scale))

	return transform

#endregion


#region CONTAINER SETTINGS
################################################################################

class ContainerSettings extends Resource:
	## A resource that allows transfering, storing and loading all settings relevant to a PortraitContainer.

	@export var position := DialogicFlexVector.new()
	@export var size := DialogicFlexVector.new()
	@export var rotation := 0.0
	@export var mirrored := false
	@export var origin := DialogicFlexVector.new()
	@export var size_mode: SizeModes = SizeModes.FIT_SCALE_HEIGHT
	@export var z_index := 0
	@export var reference_position_id := ""

	var derived_from : DialogicNode_PortraitContainer = null

	static var _transform_regex := r"(?<part>position|pos|size|siz|rotation|rot|ori|origin|mod|size_mode|mir|mirror|mirrored|sort|sor|z)\W*=(?<value>((?!(pos|siz|rot|mir|ori|mod|z|sor)).)*)"


	## Creates a new ContainerSetting and set its values from the given [param container].
	static func from_container(container:DialogicNode_PortraitContainer) -> ContainerSettings:
		var new := ContainerSettings.new()
		new.update_from_container(container)
		return new


	## Copies the settings from the given PortraitContainer node [param container] to this ContainerSetting.
	func update_from_container(container:DialogicNode_PortraitContainer) -> void:
		position = container.container_position.copy()
		size = container.container_size.copy()
		mirrored = container.mirrored
		rotation = container.container_rotation
		origin = container.container_origin
		size_mode = container.size_mode
		z_index = container.container_z_index
		if container.mode != DialogicNode_PortraitContainer.PositionModes._CHARACTER:
			derived_from = container
			reference_position_id = container.container_ids[0] if container.container_ids else ""


	## Creates a new ContainerSetting and set its values from the string. See [method update_from_string]
	static func from_string(string:="") -> ContainerSettings:
		var new := ContainerSettings.new()
		new.update_from_string(string)
		return new


	## Applies settings from the given string to this ContainerSetting.
	## The supported tags are pos/position, rot/rotation, siz/size, ori/origin, mir/mirrored, mod/size_mode.
	func update_from_string(string:="") -> void:
		var regex := RegEx.create_from_string(_transform_regex)
		for found in regex.search_all(string):
			match found.get_string("part"):
				"pos", "position":
					position.overwrite_from_string(found.get_string("value"))
				"rot", "rotation":
					rotation = float(found.get_string("value"))
				"siz", "size":
					size.overwrite_from_string(found.get_string("value"))
				"ori", "origin":
					origin.overwrite_from_string(found.get_string("value"))
				"mir", "mirror", "mirrored":
					mirrored = found.get_string("value").to_lower().strip_edges() == "true"
				"mod", "mode", "size_mode":
					size_mode = (int(found.get_string("value")) as SizeModes)
				"sor", "sort", "z":
					z_index = int(found.get_string("value"))
				"ref", "reference":
					reference_position_id = found.get_string("value").strip_edges()


	## Returns the current origin position relative to this containers top left corner.
	func _get_origin_position(rect_size = null) -> Vector2:
		if rect_size == null:
			rect_size = size
		return origin.as_pixels()


	## Returns the top left position of this container relative to its parent.
	func _get_top_left_position(rect_size = null) -> Vector2:
		if rect_size == null:
			rect_size = size
		return position.as_pixels() - _get_origin_position(rect_size).rotated(deg_to_rad(rotation))


	## Returns a scaling vector, that can be applied to the portrait node to fit it inside this container.
	func get_portrait_scale(portrait_node:DialogicPortrait) -> Vector2:
		var portrait_rect := portrait_node._get_covered_rect()
		var character := portrait_node.character
		var portrait_info := character.get_portrait_info(portrait_node.portrait)
		var apply_character_scale: bool = not portrait_info.get("ignore_char_scale", false)

		var character_scale : float =  character.scale * portrait_info.get("scale", 1) * int(apply_character_scale) + portrait_info.get("scale", 1) * int(!apply_character_scale)

		var scale_vec := Vector2()

		# Mode that ignores the containers size
		if size_mode == SizeModes.KEEP:
			scale_vec = Vector2(1,1) * character_scale

		# Mode that makes sure neither height nor width go out of container
		elif size_mode == SizeModes.FIT_IGNORE_SCALE:
			if size.as_pixels().x/size.as_pixels().y < portrait_rect.size.x/portrait_rect.size.y:
				scale_vec = Vector2(1,1) * size.as_pixels().x/portrait_rect.size.x
			else:
				scale_vec = Vector2(1,1) * size.as_pixels().y/portrait_rect.size.y

		# Mode that stretches the portrait to fill the whole container
		elif size_mode == SizeModes.FIT_STRETCH:
			scale_vec = size.as_pixels()/portrait_rect.size

		# Mode that size the character so 100% size fills the height
		elif size_mode == SizeModes.FIT_SCALE_HEIGHT:
			scale_vec = Vector2(1,1) * size.as_pixels().y / portrait_rect.size.y*character_scale

		return scale_vec


	func set_parent_size(parent_size:Vector2) -> void:
		position.container_size = parent_size
		size.container_size = parent_size
		origin.container_size = size.as_pixels()


	func _validate_property(property: Dictionary) -> void:
		if property.name in ["position", "size", "origin"]:
			property.usage = property.usage | PROPERTY_USAGE_ALWAYS_DUPLICATE


	func as_string() -> String:
		return "pos={pos} siz={siz} rot={rot} mir={mir} ori={ori} mod={mod} z={z} ref={ref}".format({
			"pos":str(position), "siz":str(size), "rot":str(rotation), "mir":str(mirrored), "ori":str(origin), "mod":str(size_mode), "z":str(z_index), "ref":reference_position_id
		})
#endregion
