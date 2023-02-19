@tool
extends DialogicEditor


func _register() -> void:
	editors_manager.register_simple_editor(self)
	alternative_text = "Create and edit dialogic variables and their default values"


func _ready() -> void:
	await get_tree().process_frame
	get_parent().set_tab_title(get_index(), 'Variables')
	get_parent().set_tab_icon(get_index(), load(self.get_script().get_path().get_base_dir().get_base_dir() + "/variable.svg"))

func _open(argument:Variant = null):
	%MainVariableGroup.update()
	%MainVariableGroup.load_data('Variables', DialogicUtil.get_project_setting('dialogic/variables', {}))


func _close():
	ProjectSettings.set_setting('dialogic/variables', %MainVariableGroup.get_data())
	ProjectSettings.save()
