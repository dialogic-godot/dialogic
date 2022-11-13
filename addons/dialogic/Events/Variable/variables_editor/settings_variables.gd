@tool
extends HBoxContainer

func refresh():
	%MainVariableGroup.update()
	%MainVariableGroup.load_data('Variables', DialogicUtil.get_project_setting('dialogic/variables', {}))

func _about_to_close():
	ProjectSettings.set_setting('dialogic/variables', %MainVariableGroup.get_data())
	ProjectSettings.save()
