@tool
## Layered portrait scene.
##
## The parent class has a character and portrait variable.
extends DialogicPortrait

const HIDE_COMMAND := "hide"
const SHOW_COMMAND := "show"
const SET_COMMAND := "set"

const OPERATORS = [HIDE_COMMAND, SHOW_COMMAND, SET_COMMAND]
static var OPERATORS_EXPRESSION := "|".join(OPERATORS)
static var REGEX_STRING := "(" + OPERATORS_EXPRESSION + ") (\\S+)"
static var REGEX := RegEx.create_from_string(REGEX_STRING)


## Load anything related to the given character and portrait
func _update_portrait(passed_character: DialogicCharacter, passed_portrait: String) -> void:
	apply_character_and_portrait(passed_character, passed_portrait)

## Iterates over all children in [param start_node] and its children, looking
## for [class Sprite2D] nodes with a texture (not `null`).
func _find_sprites_recursively(start_node: Node) -> Array[Sprite2D]:
	var sprites: Array[Sprite2D] = []

	# Iterate through the children of the current node
	for child in start_node.get_children():

		if child is Sprite2D and child.texture:
			var sprite := child as Sprite2D
			sprites.append(sprite)
			continue

		var child_sprites := _find_sprites_recursively(child)
		sprites.append_array(child_sprites)

	return sprites


func _ready() -> void:
	for sprite: Sprite2D in _find_sprites_recursively(self):
		sprite.scale = Vector2.ONE
		sprite.centered = false
		sprite.position = (sprite.get_rect().size * Vector2(-0.5, -1)) + sprite.position


## A _command that will apply an effect to the layered portrait.
class LayerCommand:
	# The effect the command will apply.
	enum CommandType {
		SHOW_LAYER,
		HIDE_LAYER,
		SET_LAYER,
	}

	var _path: String
	var _type: CommandType

	## Executes the _command.
	func _execute(root: Node) -> void:
		var target_node := root.get_node(_path)

		if target_node == null:
			print("Layered Portrait had no node matching the node path: ", _path)
			return

		match _type:
			CommandType.SHOW_LAYER:
				target_node.show()

			CommandType.HIDE_LAYER:
				target_node.hide()

			CommandType.SET_LAYER:
				var target_parent := target_node.get_parent()

				for child in target_parent.get_children():
					child.hide()

				target_node.show()


## Turns the input into a single [class LayerCommand] object.
## Returns `null` if the input cannot be parsed into a [class LayerCommand].
func _parse_layer_command(input: String) -> LayerCommand:
	var command := LayerCommand.new()

	var regex_match: RegExMatch = REGEX.search(input)

	if regex_match == null:
		print("Layered Portrait had an invalid command: ", input)
		return null

	var _path: String = regex_match.get_string(2)
	var operator: String = regex_match.get_string(1)

	match operator:
		SET_COMMAND:
			command._type = LayerCommand.CommandType.SET_LAYER

		SHOW_COMMAND:
			command._type = LayerCommand.CommandType.SHOW_LAYER

		HIDE_COMMAND:
			command._type = LayerCommand.CommandType.HIDE_LAYER

		SET_COMMAND:
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


## The extra data will be turned into layer commands and then be executed.
func _set_extra_data(data: String) -> void:
	var commands := _parse_input_to_layer_commands(data)

	for _command: LayerCommand in commands:
		_command._execute(self)


func _set_mirror(is_mirrored: bool) -> void:
	for sprite: Sprite2D in _find_sprites_recursively(self):
		sprite.flip_h = is_mirrored


func _find_largest_coverage_rect() -> Rect2:
	var coverage_rect := Rect2(0, 0, 0, 0)

	for sprite: Sprite2D in _find_sprites_recursively(self):
		var sprite_width := sprite.texture.get_width()
		var sprite_height := sprite.texture.get_height()

		var texture_rect := Rect2(
			sprite.position.x,
			sprite.position.y,
			sprite_width,
			sprite_height
		)

		coverage_rect = coverage_rect.merge(texture_rect)

	return coverage_rect


func _get_covered_rect() -> Rect2:
	var needed_rect := _find_largest_coverage_rect()

	return needed_rect
