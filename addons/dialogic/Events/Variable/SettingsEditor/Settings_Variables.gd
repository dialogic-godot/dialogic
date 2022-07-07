tool
extends HBoxContainer

func refresh():
	$'%MainVariableFolder'.update()
	$'%MainVariableFolder'.load_data('Variables', DialogicUtil.get_project_setting('dialogic/variables', {}))
	$'%SaveVariablesButton'.icon = get_icon("Save", "EditorIcons")


func _on_SaveVariables_pressed():
	ProjectSettings.set_setting('dialogic/variables',$'%MainVariableFolder'.get_data())
