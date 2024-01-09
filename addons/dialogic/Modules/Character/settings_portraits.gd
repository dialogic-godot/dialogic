@tool
extends DialogicSettingsPage


func _ready():
	%JoinDefault.get_suggestions_func = get_join_animation_suggestions
	%JoinDefault.mode = 1
	%LeaveDefault.get_suggestions_func = get_leave_animation_suggestions
	%LeaveDefault.mode = 1


func _refresh():
	%CustomPortraitScene.resource_icon = get_theme_icon("PackedScene", "EditorIcons")
	%CustomPortraitScene.set_value(ProjectSettings.get_setting('dialogic/portraits/default_portrait', ''))


	%JoinDefault.resource_icon = get_theme_icon("Animation", "EditorIcons")
	%LeaveDefault.resource_icon = get_theme_icon("Animation", "EditorIcons")
	%JoinDefault.set_value(DialogicUtil.pretty_name(ProjectSettings.get_setting('dialogic/animations/join_default',
	get_script().resource_path.get_base_dir().path_join('DefaultAnimations/fade_in_up.gd'))))
	%LeaveDefault.set_value(ProjectSettings.get_setting('dialogic/animations/leave_default',
	get_script().resource_path.get_base_dir().path_join('DefaultAnimations/fade_out_down.gd')))
	%JoinDefaultLength.set_value(ProjectSettings.get_setting('dialogic/animations/join_default_length', 0.5))
	%LeaveDefaultLength.set_value(ProjectSettings.get_setting('dialogic/animations/leave_default_length', 0.5))
	%LeaveDefaultWait.button_pressed = ProjectSettings.get_setting('dialogic/animations/leave_default_wait', true)
	%JoinDefaultWait.button_pressed = ProjectSettings.get_setting('dialogic/animations/join_default_wait', true)


func _on_custom_portrait_scene_value_changed(property_name:String, value:String) -> void:
	ProjectSettings.set_setting('dialogic/portraits/default_portrait', value)
	ProjectSettings.save()


func _on_LeaveDefault_value_changed(property_name:String, value:String) -> void:
	ProjectSettings.set_setting('dialogic/animations/leave_default', value)
	ProjectSettings.save()


func _on_JoinDefault_value_changed(property_name:String, value:String) -> void:
	ProjectSettings.set_setting('dialogic/animations/join_default', value)
	ProjectSettings.save()


func _on_JoinDefaultLength_value_changed(value:float) -> void:
	ProjectSettings.set_setting('dialogic/animations/join_default_length', value)
	ProjectSettings.save()


func _on_LeaveDefaultLength_value_changed(value:float) -> void:
	ProjectSettings.set_setting('dialogic/animations/leave_default_length', value)
	ProjectSettings.save()

func _on_JoinDefaultWait_toggled(button_pressed:bool) -> void:
	ProjectSettings.set_setting('dialogic/animations/join_default_wait', button_pressed)
	ProjectSettings.save()

func _on_LeaveDefaultWait_toggled(button_pressed:bool) -> void:
	ProjectSettings.set_setting('dialogic/animations/leave_default_wait', button_pressed)
	ProjectSettings.save()


func get_join_animation_suggestions(search_text:String) -> Dictionary:
	var suggestions = {}
	for anim in list_animations():
		if '_in' in anim.get_file():
			suggestions[DialogicUtil.pretty_name(anim)] = {'value':anim, 'icon':get_theme_icon('Animation', 'EditorIcons')}
	return suggestions

func get_leave_animation_suggestions(search_text:String) -> Dictionary:
	var suggestions = {}
	for anim in list_animations():
		if '_out' in anim.get_file():
			suggestions[DialogicUtil.pretty_name(anim)] = {'value':anim, 'icon':get_theme_icon('Animation', 'EditorIcons')}
	return suggestions

func list_animations() -> Array:
	var list = DialogicUtil.listdir(get_script().resource_path.get_base_dir().path_join('DefaultAnimations'), true, false, true)
	list.append_array(DialogicUtil.listdir(ProjectSettings.get_setting('dialogic/animations/custom_folder', 'res://addons/dialogic_additions/Animations'), true, false, true))
	return list

