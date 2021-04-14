tool
extends DialogicEditorEventNode

#base_resource:DialogicCharacterJoinEvent

export(NodePath) var ReferenceButton_path:NodePath
export(NodePath) var CharacterBtn_path:NodePath
export(NodePath) var PortraitBtn_path:NodePath
export(NodePath) var Preview_path:NodePath

var buttons:ButtonGroup

onready var character_button_node = get_node(CharacterBtn_path)
onready var portrait_button_node = get_node(PortraitBtn_path)
onready var portrait_preview_node = get_node(Preview_path)

func _ready() -> void:
	if base_resource:
		var _btn = get_node(ReferenceButton_path)
		buttons = _btn.group
		for button in buttons.get_buttons():
			button.connect("toggled", self, "_on_PositionButton_toggled")
		
		_update_node_values()
	else:
		return


func _update_node_values() -> void:
	var _base:DialogicCharacterJoinEvent = base_resource
	var _char:DialogicCharacterResource = _base.character
	
	portrait_button_node.character = _char
	
	if _char:
		var _selected_portrait:DialogicPortraitResource = _char.portraits.get_resources()[_base.selected_portrait]
		portrait_preview_node.texture = _selected_portrait.image
		portrait_button_node.select_item_by_resource(_selected_portrait)
		character_button_node.select_item_by_resource(_char)
	else:
		character_button_node.select(0)


func _on_PositionButton_toggled(button_pressed: bool) -> void:
	var _n = int(buttons.get_pressed_button().name)
	(base_resource as DialogicCharacterJoinEvent).selected_position = _n
	_save_resource()
	_update_node_values()


func _on_CharactersButton_item_selected(index: int) -> void:
	var _char_metadata = character_button_node.get_selected_metadata()
	if _char_metadata is Dictionary:
		base_resource.character = (_char_metadata as Dictionary).get("character", null)
	else:
		base_resource.character = null
	_save_resource()
	_update_node_values()


func _on_PortraitsButton_item_selected(index: int) -> void:
	var _portrait_metadata = portrait_button_node.get_selected_metadata()
	if _portrait_metadata is Dictionary:
		var _portraits:Array = base_resource.character.portraits.get_resources()
		var _selected_portrait = (_portrait_metadata as Dictionary).get("portrait")
		(base_resource as DialogicCharacterJoinEvent).selected_portrait = _portraits.find(_selected_portrait)
	else:
		base_resource.selected_portrait = 0
	
	_save_resource()
	_update_node_values()
