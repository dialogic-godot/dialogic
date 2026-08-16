extends GdUnitTestSuite
## Regression tests for dialogic-godot/dialogic#2801:
## Dialogic.Save.load() crashes when a joined character has no portrait node
## (e.g. after a scene change), because the portraits subsystem can hold a
## joined-character entry whose portrait node is gone or was never created.


var portraits


func before_test() -> void:
	DialogicResourceUtil.update()
	portraits = Dialogic.Portraits
	if portraits == null:
		push_error("test setup failed: Dialogic.Portraits subsystem not available")
		return
	# Start from a clean subsystem state.
	portraits.portraits.clear()
	portraits.character_nodes.clear()


func after_test() -> void:
	# Free any nodes the tests created.
	for node in portraits.character_nodes.values():
		if is_instance_valid(node):
			node.free()
	portraits.portraits.clear()
	portraits.character_nodes.clear()


func _test_character() -> DialogicCharacter:
	var character: DialogicCharacter = load("res://Tests/Resources/unit_test_character.dch")
	character.display_name = "unit_test_character"
	return character


## A character whose portraits entry has no live node is not joined,
## so consumers (get_character_node, highlighting, etc.) get null instead of
## a "Invalid access to property or key" error.
func test_is_character_joined_without_node() -> void:
	var character := _test_character()

	portraits.portraits[character.get_identifier()] = {'portrait': "", 'position_id': "center"}

	assert_bool(portraits.is_character_joined(character)).is_false()
	assert_object(portraits.get_character_node(character)).is_null()


## Leaving a character that lost its node cleans the leftover entry instead
## of crashing.
func test_leave_character_without_node() -> void:
	var character := _test_character()

	portraits.portraits[character.get_identifier()] = {'portrait': "", 'position_id': "center"}

	portraits.leave_character(character)

	assert_that(portraits.portraits.has(character.get_identifier())).is_false()
	assert_that(portraits.character_nodes.has(character.get_identifier())).is_false()


## A freed portrait node must not count as joined either.
func test_is_character_joined_freed_node() -> void:
	var character := _test_character()

	var node := Node.new()
	portraits.portraits[character.get_identifier()] = {'portrait': "", 'position_id': "center"}
	portraits.character_nodes[character.get_identifier()] = node
	assert_bool(portraits.is_character_joined(character)).is_true()

	node.free()
	assert_bool(portraits.is_character_joined(character)).is_false()
	assert_object(portraits.get_character_node(character)).is_null()


## Loading state when the character cannot re-join (its position container is
## not available) must not crash on the missing character_nodes entry.
func test_load_state_missing_position_container() -> void:
	var character := _test_character()

	# Simulate a save with one joined character and no containers in the tree:
	# unpack_state has restored the portraits entry, but add_character fails,
	# because load_position_container returns null.
	portraits.portraits = {character.get_identifier(): {'portrait': "", 'position_id': "center"}}

	await portraits._load_state()

	assert_bool(portraits.is_character_joined(character)).is_false()


## Clearing the subsystem while a portrait node was already freed
## (e.g. by a scene change) must not error on the freed node.
func test_clear_state_freed_node() -> void:
	var character := _test_character()

	var node := Node.new()
	portraits.portraits[character.get_identifier()] = {'portrait': "", 'position_id': "center"}
	portraits.character_nodes[character.get_identifier()] = node
	node.free()

	portraits._clear_state()

	assert_that(portraits.portraits.is_empty()).is_true()
	assert_that(portraits.character_nodes.is_empty()).is_true()
