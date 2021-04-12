tool
extends DialogicEditorEventNode

export(NodePath) var TextEdit_path:NodePath
export(NodePath) var CharacterBtn_path:NodePath

onready var text_edit_node = get_node_or_null(TextEdit_path)
onready var character_button_node = get_node_or_null(CharacterBtn_path)


func _ready() -> void:
	if base_resource:
		_update_node_values()
	else:
		return

func _update_node_values() -> void:
	text_edit_node.text = base_resource.text
	if base_resource.character:
		character_button_node.select_item_by_resource(base_resource.character)
	else:
		character_button_node.select(0)
	index_label_node.text = str(idx)


func _save_resource() -> void:
	var _res = base_resource
	emit_signal("save_item_requested", base_resource)


func _on_resource_change() -> void:
	_update_node_values()


func _on_TextEdit_text_changed() -> void:
	if text_edit_node.text != base_resource.text:
		(base_resource as DialogicTextEvent).text = text_edit_node.text


func _on_TextEdit_focus_exited() -> void:
	DialogicUtil.Logger.print(self,"Focus lost, saving things")
	_save_resource()


func _on_CharactersButton_item_selected(index: int) -> void:
	var _char_metadata = character_button_node.get_selected_metadata()
	if _char_metadata is Dictionary:
		base_resource.character = (_char_metadata as Dictionary).get("character", null)
	else:
		base_resource.character = null
	_save_resource()
