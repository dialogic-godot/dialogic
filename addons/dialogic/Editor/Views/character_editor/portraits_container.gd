tool
extends PanelContainer

export(NodePath) var Confirmation_path:NodePath
export(NodePath) var AddItemBtn_path:NodePath
export(NodePath) var NameContainer_path:NodePath
export(NodePath) var PathContainer_path:NodePath
export(NodePath) var FileDialog_path:NodePath

var base_resource:DialogicCharacterResource setget _set_base_resource
var last_pressed_button = null
var file_dialog_node

onready var confirmation_node := get_node(Confirmation_path)
onready var add_item_node := get_node(AddItemBtn_path)
onready var name_container_node := get_node(NameContainer_path)
onready var path_container_node := get_node(PathContainer_path)


func _save():
	if not base_resource:
		return
	var _err = ResourceSaver.save(base_resource.resource_path, base_resource)
	assert(_err == OK)
	_update_values()


func _unload_values() -> void:
	for _child in name_container_node.get_children():
		_child.queue_free()
	for _child in path_container_node.get_children():
		_child.queue_free()


func _update_values() -> void:
	_unload_values()
	for portrait in base_resource.portraits.get_resources():
		_add_item(portrait)


func _add_item(portrait:DialogicPortraitResource) -> void:
	var _name_node = Label.new()
	var _path_node = Button.new()
	
	_name_node.size_flags_vertical = SIZE_SHRINK_CENTER | SIZE_EXPAND
	_name_node.text = portrait.name
	_path_node.text = (portrait.image.resource_path as String).get_file()
	_path_node.hint_tooltip = portrait.image.resource_path
	_path_node.icon = portrait.image
	_path_node.set_meta("portrait_resource", portrait)
	_path_node.set_script(load("res://addons/dialogic/Editor/Views/character_editor/portrait_container/portrait_button.gd"))
	var _err = _path_node.connect("pressed", self, "_on_PortraitButton_pressed")
	name_container_node.add_child(_name_node)
	path_container_node.add_child(_path_node)
	pass


func _set_base_resource(value:DialogicCharacterResource):
	base_resource = value
	if not base_resource.is_connected("changed", self, "_on_BaseResource_changed"):
		base_resource.connect("changed", self, "_on_BaseResource_changed")
	_update_values()


func _on_AddItemBtn_pressed() -> void:
	confirmation_node.popup_centered()


func _on_BaseResource_changed():
	_update_values()


func _on_NewItemPopup_confirmed() -> void:
	if not base_resource:
		return
	var _name = confirmation_node.text_node.text
	var _portrait:DialogicPortraitResource = DialogicPortraitResource.new()
	_portrait.name = _name
	_portrait.image = load("res://icon.png")
	(base_resource.portraits as ResourceArray).add(_portrait)
	_save()


func _on_PortraitButton_pressed(button:Button=null) -> void:
	if not button:
		return
	last_pressed_button = button
	if not file_dialog_node:
		var _file_dialog = get_node(FileDialog_path)
		if Engine.editor_hint:
			var _editor_interface = EditorPlugin.new().get_editor_interface()
			var _base_control = _editor_interface.get_base_control()
			file_dialog_node = _file_dialog.duplicate()
			_base_control.add_child(file_dialog_node)
		else:
			file_dialog_node = _file_dialog
			
			
	file_dialog_node.popup_centered_ratio()


func _on_FileDialog_file_selected(path: String) -> void:
	var _portrait_resource:DialogicPortraitResource = (last_pressed_button as Button).get_meta("portrait_resource")
	if not _portrait_resource:
		return
	var _selected_resource = load(path)
	
	if _selected_resource is Texture:
		_portrait_resource.image = _selected_resource
	else:
		print("Archivo no soportado ", _selected_resource.get_class())
	_save()
