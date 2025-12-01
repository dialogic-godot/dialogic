@tool
extends DialogicEditor

## Editor that allows

#region EDITOR STUFF

func _get_title() -> String:
	return "Variables"


func _get_icon() -> Texture:
	return load(self.get_script().get_path().get_base_dir().get_base_dir() + "/variable.svg")


func _register() -> void:
	editors_manager.register_simple_editor(self)
	alternative_text = "Create and edit dialogic variables and their default values"


func _open(_argument:Variant = null) -> void:
	%ReferenceInfo.hide()
	%Tree.load_info(ProjectSettings.get_setting('dialogic/variables', {}))


func _save() -> void:
	ProjectSettings.set_setting('dialogic/variables', %Tree.get_info())
	ProjectSettings.save()


func _close() -> void:
	_save()


#endregion

func _ready() -> void:
	if get_parent() is SubViewport:
		return

	%ReferenceInfo.get_node('Label').add_theme_color_override('font_color', get_theme_color("warning_color", "Editor"))
	%Search.right_icon = get_theme_icon("Search", "EditorIcons")

#region RENAMING

func variable_renamed(old_name:String, new_name:String):
	if old_name == new_name:
		return
	var count: int = editors_manager.reference_manager.get_change_count()
	editors_manager.reference_manager.add_variable_ref_change(old_name, new_name)
	var new_count: int = editors_manager.reference_manager.get_change_count()
	if count > new_count:
		%ReferenceInfo.hide()
	elif count < new_count:
		%ReferenceInfo.show()

func _on_reference_manager_pressed() -> void:
	editors_manager.reference_manager.open()
	%ReferenceInfo.hide()

#endregion


func _on_search_text_changed(new_text: String) -> void:
	%Tree.filter(new_text)
