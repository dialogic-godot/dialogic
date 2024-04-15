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


func _open(argument:Variant = null):
	%ReferenceInfo.hide()
	%Tree.load_info(ProjectSettings.get_setting('dialogic/variables', {}))


func _save():
	ProjectSettings.set_setting('dialogic/variables', %Tree.get_info())
	ProjectSettings.save()


func _close():
	_save()


#endregion

func _ready() -> void:
	%ReferenceInfo.get_node('Label').add_theme_color_override('font_color', get_theme_color("warning_color", "Editor"))
	%Search.right_icon = get_theme_icon("Search", "EditorIcons")

#region RENAMING

func variable_renamed(old_name:String, new_name:String):
	if old_name == new_name:
		return
	editors_manager.reference_manager.add_variable_ref_change(old_name, new_name)
	%ReferenceInfo.show()


func _on_reference_manager_pressed():
	editors_manager.reference_manager.open()
	%ReferenceInfo.hide()

#endregion


func _on_search_text_changed(new_text: String) -> void:
	%Tree.filter(new_text)
