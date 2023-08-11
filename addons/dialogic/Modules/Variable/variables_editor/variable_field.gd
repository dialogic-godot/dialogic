@tool
extends PanelContainer


var variables_editor :Control = null
var parent_Group :Control = null
var preview_scene = get_script().resource_path.get_base_dir().path_join("variable_drag_preview.tscn")

var previous_name :String = ""

# a flag that will be set when created with a New Group button
# prevents any changes as being counted as broken references
var actually_new :bool = false
################################################################################
##				FUNCTIONALITY
################################################################################

func get_item_name() -> String:
	return %NameEdit.text.strip_edges()


func get_data() -> String:
	return %ValueEdit.text


func load_data(var_name:String, var_value:String, _Group:Control) -> void:
	parent_Group = _Group
	%NameEdit.text = var_name
	previous_name = var_name
	%ValueEdit.text = var_value
	%NameEdit.grab_focus()
	%NameEdit.editable = true


################################################################################
##				DRAGGING
################################################################################

func _get_drag_data(position:Vector2) -> Variant:
	var data := {
		'data':{},
		'node':self
	}
	data.data[get_item_name()] = get_data()
	
	var prev :Control= load(preview_scene).instantiate()
	prev.set_text(get_item_name())
	set_drag_preview(prev)
	return data


func is_variable() -> bool:
	return true


func _can_drop_data(position:Vector2, data:Variant) -> bool:
	if typeof(data) == TYPE_DICTIONARY and data.has('data') and data.has('node'):
		return true
	return false


func _drop_data(position:Vector2, data:Variant) -> void:
	parent_Group.add_data(data.data)
	data.node.queue_free()


################################################################################
##				UI
################################################################################

func _ready() -> void:
	%DeleteButton.icon = get_theme_icon("Remove", "EditorIcons")
	%Dragger.texture = get_theme_icon("TripleBar", "EditorIcons")


func _on_DeleteButton_pressed() -> void:
	queue_free()


func _on_NameEdit_gui_input(event:InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.double_click:
		%NameEdit.editable = true
	if event is InputEventKey and event.pressed and event.keycode == KEY_ENTER and !%NameEdit.editable:
		%NameEdit.editable = true
		get_viewport().set_input_as_handled()


func _on_NameEdit_focus_exited() -> void:
	_on_name_edit_text_submitted(%NameEdit.text)


func _on_name_edit_text_submitted(new_text:String) -> void:
	%NameEdit.text = new_text.replace(' ', '_')
	%NameEdit.text = %NameEdit.text.replace('-', '_')

	if %NameEdit.text != previous_name and !actually_new:
		if parent_Group.get_group_path().is_empty():
			variables_editor.variable_renamed(previous_name, %NameEdit.text)
		else:
			variables_editor.variable_renamed(parent_Group.get_group_path()+'.'+previous_name, parent_Group.get_group_path()+'.'+%NameEdit.text)
		previous_name = %NameEdit.text
	disable_name_edit()


func disable_name_edit() -> void:
	%NameEdit.editable = false
	parent_Group.check_data()


func warning():
	modulate = get_theme_color("warning_color", "Editor")


func no_warning():
	modulate = Color(1,1,1,1)
