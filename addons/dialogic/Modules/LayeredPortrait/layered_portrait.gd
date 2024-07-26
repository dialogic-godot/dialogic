@tool
## Layered portrait scene.
##
## The parent class has a character and portrait variable.
extends DialogicPortrait

## The term used for hiding a layer.
const _HIDE_COMMAND := "hide"
## The term used for showing a layer.
const _SHOW_COMMAND := "show"
## The term used for setting a layer to be the only visible layer.
const _SET_COMMAND := "set"

## A collection of all possible layer commands.
const _OPERATORS = [_HIDE_COMMAND, _SHOW_COMMAND, _SET_COMMAND]

static var _OPERATORS_EXPRESSION := "|".join(_OPERATORS)
static var _REGEX_STRING := "(" + _OPERATORS_EXPRESSION + ") (\\S+)"
static var _REGEX := RegEx.create_from_string(_REGEX_STRING)

var _initialized := false

var _is_coverage_rect_cached := false
var _cached_coverage_rect := Rect2(0, 0, 0, 0)


@export_group("Private")
## Attempts to fix the offset based on the first child node
@export var fix_offset := true

## Overriding [class DialogicPortrait]'s method.
##
## Load anything related to the given character and portrait
func _update_portrait(passed_character: DialogicCharacter, passed_portrait: String) -> void:
	if not _initialized:
		_apply_layer_adjustments()
		_initialized = true

	apply_character_and_portrait(passed_character, passed_portrait)


## Modifies all layers to fit the portrait preview and appear correctly in
## portrait containers.
##
## This method is not changing the scene itself and is intended for the
## Dialogic editor preview and in-game rendering only.
func _apply_layer_adjustments() -> void:
	var coverage := _find_largest_coverage_rect()
	var offset_fix := Vector2()
	if fix_offset and get_child_count():
		offset_fix = -get_child(0).position
		if "centered" in get_child(0) and get_child(0).centered:
			offset_fix += get_child(0).get_rect().size/2.0

	for node: Node in get_children():
		var node_position: Vector2 = node.position
		node_position += offset_fix
		node.position = _reposition_with_rect(coverage, node_position)


## Returns a position based on [param rect]'s size where Dialogic expects the
## scene part to be positioned at. [br]
## If the node has an offset or extra position, pass it as [param node_offset].
func _reposition_with_rect(rect: Rect2, node_offset := Vector2(0.0, 0.0)) -> Vector2:
	return rect.size  * Vector2(-0.5, -1.0) + node_offset


## Iterates over all children in [param start_node] and its children, looking
## for [class Sprite2D] nodes with a texture (not `null`).
## All found sprites are returned in an array, eventually returning all
## sprites in the scene.
func _find_sprites_recursively(start_node: Node) -> Array[Sprite2D]:
	var sprites: Array[Sprite2D] = []

	# Iterate through the children of the current node
	for child: Node in start_node.get_children():

		if child is Sprite2D:
			var sprite := child as Sprite2D

			if sprite.texture:
				sprites.append(sprite)


		var sub := _find_sprites_recursively(child)
		sprites.append_array(sub)

	return sprites


## A command will apply an effect to the layered portrait.
class LayerCommand:
	# The different types of effects.
	enum CommandType {
		## Additively Show a specific layer.
		SHOW_LAYER,
		## Subtractively hide a specific layer.
		HIDE_LAYER,
		## Exclusively show a specific layer, hiding all other sibling layers.
		## A sibling layer is a layer sharing the same parent node.
		SET_LAYER,
	}

	var _path: String
	var _type: CommandType

	## Executes the effect of the layer based on the [enum CommandType].
	func _execute(root: Node) -> void:
		var target_node := root.get_node(_path)

		if target_node == null:
			printerr("Layered Portrait had no node matching the node path: '", _path, "'.")
			return

		if not target_node is Node2D and not target_node is Sprite2D:
			printerr("Layered Portrait target path '", _path, "', is not a Sprite2D or Node2D type.")
			return

		match _type:
			CommandType.SHOW_LAYER:
				target_node.show()

			CommandType.HIDE_LAYER:
				target_node.hide()

			CommandType.SET_LAYER:
				var target_parent := target_node.get_parent()

				for child: Node in target_parent.get_children():

					if child is Sprite2D:
						var sprite_child := child as Sprite2D
						sprite_child.hide()

				target_node.show()


## Turns the input into a single [class LayerCommand] object.
## Returns `null` if the input cannot be parsed into a [class LayerCommand].
func _parse_layer_command(input: String) -> LayerCommand:
	var regex_match: RegExMatch = _REGEX.search(input)

	if regex_match == null:
		print("[Dialogic] Layered Portrait had an invalid command: ", input)
		return null

	var _path: String = regex_match.get_string(2)
	var operator: String = regex_match.get_string(1)

	var command := LayerCommand.new()

	match operator:
		_SET_COMMAND:
			command._type = LayerCommand.CommandType.SET_LAYER

		_SHOW_COMMAND:
			command._type = LayerCommand.CommandType.SHOW_LAYER

		_HIDE_COMMAND:
			command._type = LayerCommand.CommandType.HIDE_LAYER

		_SET_COMMAND:
			command._type = LayerCommand.CommandType.SET_LAYER

	## We clean escape symbols and trim the spaces.
	command._path = _path.replace("\\", "").strip_edges()

	return command


## Parses [param input] into an array of [class LayerCommand] objects.
func _parse_input_to_layer_commands(input: String) -> Array[LayerCommand]:
	var commands: Array[LayerCommand] = []
	var command_parts := input.split(",")

	for command_part: String in command_parts:

		if command_part.is_empty():
			continue

		var _command := _parse_layer_command(command_part.strip_edges())

		if not _command == null:
			commands.append(_command)

	return commands



## Overriding [class DialogicPortrait]'s method.
##
## The extra data will be turned into layer commands and then be executed.
func _set_extra_data(data: String) -> void:
	var commands := _parse_input_to_layer_commands(data)

	for _command: LayerCommand in commands:
		_command._execute(self)


## Overriding [class DialogicPortrait]'s method.
##
## Handling all layers horizontal flip state.
func _set_mirror(is_mirrored: bool) -> void:
	for child: Node in get_children():

		if is_mirrored:
			child.position.x = child.position.x * -1
			child.scale.x = -child.scale.x


## Scans all nodes in this scene and finds the largest rectangle that
## covers encloses every sprite.
func _find_largest_coverage_rect() -> Rect2:
	if _is_coverage_rect_cached:
		return _cached_coverage_rect

	var coverage_rect := Rect2(0, 0, 0, 0)

	for sprite: Sprite2D in _find_sprites_recursively(self):
		var sprite_size := sprite.get_rect().size
		var sprite_position: Vector2 = sprite.global_position-self.global_position

		if sprite.centered:
			sprite_position -= sprite_size/2

		var sprite_width := sprite_size.x * sprite.scale.x
		var sprite_height := sprite_size.y * sprite.scale.y

		var texture_rect := Rect2(
			sprite_position.x,
			sprite_position.y,
			sprite_width,
			sprite_height
		)
		coverage_rect = coverage_rect.merge(texture_rect)

	coverage_rect.position = _reposition_with_rect(coverage_rect)

	_is_coverage_rect_cached = true
	_cached_coverage_rect = coverage_rect

	return coverage_rect


## Overriding [class DialogicPortrait]'s method.
##
## Called by Dialogic when the portrait is needed to be shown.
## For instance, in the Dialogic editor or in-game.
func _get_covered_rect() -> Rect2:
	var needed_rect := _find_largest_coverage_rect()

	return needed_rect
