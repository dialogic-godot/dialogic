tool
extends HSplitContainer

var current_animation_path = ""

func _ready():
	$'%JoinDefault'.get_suggestions_func = [self, 'get_join_animation_suggestions']
	$'%LeaveDefault'.get_suggestions_func = [self, 'get_leave_animation_suggestions']

func refresh():
	$'%CustomAnimationsFolderOpener'.icon = get_icon("Folder", "EditorIcons")
	get_node('%CustomAnimationsFolder').text = DialogicUtil.get_project_setting('dialogic/animations_custom_folder', 'res://addons/dialogic_additions/Animations')
	
	$'%JoinDefault'.set_value(DialogicUtil.get_project_setting('dialogic/animations_join_default', 
	get_script().resource_path.get_base_dir().plus_file('DefaultAnimations/fade_in_up.gd')))
	$'%LeaveDefault'.set_value(DialogicUtil.get_project_setting('dialogic/animations_leave_default', 
	get_script().resource_path.get_base_dir().plus_file('DefaultAnimations/fade_out_down.gd')))
	$'%JoinDefaultLength'.set_value(DialogicUtil.get_project_setting('dialogic/animations_join_default_length', 0.5))
	$'%LeaveDefaultLength'.set_value(DialogicUtil.get_project_setting('dialogic/animations_leave_default_length', 0.5))
	$'%LeaveDefaultWait'.pressed = DialogicUtil.get_project_setting('dialogic/animations_leave_default_wait', true)
	$'%JoinDefaultWait'.pressed = DialogicUtil.get_project_setting('dialogic/animations_join_default_wait', true)


func _on_LeaveDefault_value_changed(property_name, value):
	ProjectSettings.set_setting('dialogic/animations_leave_default', value)


func _on_JoinDefault_value_changed(property_name, value):
	ProjectSettings.set_setting('dialogic/animations_join_default', value)


func _on_JoinDefaultLength_value_changed(value):
	ProjectSettings.set_setting('dialogic/animations_join_default_length', value)


func _on_LeaveDefaultLength_value_changed(value):
	ProjectSettings.set_setting('dialogic/animations_leave_default_length', value)

func _on_JoinDefaultWait_toggled(button_pressed):
	ProjectSettings.set_setting('dialogic/animations_join_default_wait', button_pressed)

func _on_LeaveDefaultWait_toggled(button_pressed):
	ProjectSettings.set_setting('dialogic/animations_leave_default_wait', button_pressed)


func get_join_animation_suggestions(search_text):
	var suggestions = {}
	for anim in list_animations():
		if search_text.to_lower() in anim.get_file().to_lower():
			if '_in' in anim.get_file():
				suggestions[DialogicUtil.pretty_name(anim)] = anim
	return suggestions

func get_leave_animation_suggestions(search_text):
	var suggestions = {}
	for anim in list_animations():
		if search_text.to_lower() in anim.get_file().to_lower():
			if '_out' in anim.get_file():
				suggestions[DialogicUtil.pretty_name(anim)] = anim
	return suggestions

func list_animations() -> Array:
	var list = DialogicUtil.listdir(get_script().resource_path.get_base_dir().plus_file('DefaultAnimations'), true, false, true)
	list.append_array(DialogicUtil.listdir(DialogicUtil.get_project_setting('dialogic/animations_custom_folder', 'res://addons/dialogic_additions/Animations'), true, false, true))
	return list


func _on_CustomAnimationsFolderOpener_pressed():
	find_parent('EditorView').godot_file_dialog(self, 'custom_anims_folder_selected', '', EditorFileDialog.MODE_OPEN_DIR, 'Select custom animation folder')

func custom_anims_folder_selected(path):
	get_node('%CustomAnimationsFolder').text = path
	ProjectSettings.set_setting('dialogic/animations_custom_folder', path)

