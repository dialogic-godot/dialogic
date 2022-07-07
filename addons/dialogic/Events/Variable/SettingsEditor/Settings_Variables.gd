tool
extends HBoxContainer

func refresh():
	$'%MainVariableGroup'.update()
	$'%MainVariableGroup'.load_data('Variables', DialogicUtil.get_project_setting('dialogic/variables', {}))
	$'%SaveVariablesButton'.icon = get_icon("Save", "EditorIcons")


func _on_SaveVariables_pressed():
	ProjectSettings.set_setting('dialogic/variables',$'%MainVariableGroup'.get_data())
