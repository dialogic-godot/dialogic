@tool
extends DialogicEditor


func _get_title() -> String:
	return "Variables"


func _get_icon() -> Texture:
	return load(self.get_script().get_path().get_base_dir().get_base_dir() + "/variable.svg")


func _register() -> void:
	editors_manager.register_simple_editor(self)
	alternative_text = "Create and edit dialogic variables and their default values"


func _ready() -> void:
	%ReferenceInfo.get_node('Label').add_theme_color_override('font_color', get_theme_color("warning_color", "Editor"))


func _open(argument:Variant = null):
	%ReferenceInfo.hide()
	%MainVariableGroup.update()
	%MainVariableGroup.variables_editor = self
	
	%MainVariableGroup.load_data('Variables', ProjectSettings.get_setting('dialogic/variables', {}))


func _save():
	ProjectSettings.set_setting('dialogic/variables', %MainVariableGroup.get_data())
	ProjectSettings.save()


func variable_renamed(old_name:String, new_name:String):
	editors_manager.reference_manager.add_variable_ref_change(old_name, new_name)
	%ReferenceInfo.show()


func group_renamed(old_name:String, new_name:String, group_data:Dictionary):
	for i in group_data:
		if group_data[i] is Dictionary:
			group_renamed(old_name+'.'+i, new_name+'.'+i, group_data[i])
		else:
			editors_manager.reference_manager.add_variable_ref_change(old_name+'.'+i, new_name+'.'+i)
	%ReferenceInfo.show()



func _close():
	_save()


func _on_reference_manager_pressed():
	editors_manager.reference_manager.open()
