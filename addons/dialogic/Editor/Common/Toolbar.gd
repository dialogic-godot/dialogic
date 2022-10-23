@tool
extends HBoxContainer

signal toggle_editor_view(mode:String)
signal create_timeline
signal play_timeline

var editor_reference = null

func _ready():
	# Get version number
	$Version.set("custom_colors/font_color", get_theme_color("disabled_font_color", "Editor"))
	var config := ConfigFile.new()
	var err := config.load("res://addons/dialogic/plugin.cfg")
	if err == OK:
		$Version.text = "v" + config.get_value("plugin", "version")
	
	editor_reference = find_parent('EditorView')
	$PlayTimeline.icon = get_theme_icon("PlayScene", "EditorIcons")
	$PlayTimeline.button_up.connect(_on_play_timeline)
	
	$AddTimeline.icon = load("res://addons/dialogic/Editor/Images/Toolbar/add-timeline.svg")
	%ResourcePicker.get_suggestions_func = suggest_resources
	%ResourcePicker.resource_icon = get_theme_icon("GuiRadioUnchecked", "EditorIcons")
	$Settings.icon = get_theme_icon("Tools", "EditorIcons")
	
	
	$ToggleVisualEditor.button_up.connect(_on_toggle_visual_editor_clicked)
	update_toggle_button()


################################################################################
##							HELPERS
################################################################################

func set_resource_saved() -> void:
	if %ResourcePicker.current_value.ends_with(("(*)")):
		%ResourcePicker.set_value(%ResourcePicker.current_value.trim_suffix("(*)"))

func set_resource_unsaved() -> void:
	if not %ResourcePicker.current_value.ends_with(("(*)")):
		%ResourcePicker.set_value(%ResourcePicker.current_value +"(*)")

func is_current_unsaved() -> bool:
	if %ResourcePicker.current_value and %ResourcePicker.current_value.ends_with('(*)'):
		return true
	return false

################################################################################
##							BASICS
################################################################################

func _on_AddTimeline_pressed() -> void:
	emit_signal("create_timeline")


func _on_AddCharacter_pressed() -> void:
	find_parent('EditorView').godot_file_dialog(
		get_parent().get_node("CharacterEditor").new_character,
		'*.dch; DialogicCharacter',
		EditorFileDialog.FILE_MODE_SAVE_FILE,
		'Save new Character',
		'New_Character',
		true
	)


func suggest_resources(filter:String) -> Dictionary:
	var suggestions = {}
	for i in DialogicUtil.get_project_setting('dialogic/editor/last_resources', []):
		if i.ends_with('.dtl'):
			var short_name = i
			for item in editor_reference.timeline_directory:
				if editor_reference.timeline_directory[item] == i:
					short_name = item
					break
			suggestions[short_name] = {'value':i, 'tooltip':i, 'editor_icon': ["TripleBar", "EditorIcons"]}
		elif i.ends_with('.dch'):
			var short_name = i
			for item in editor_reference.character_directory:
				if editor_reference.character_directory[item]['full_path'] == i:
					short_name = item
					break
			suggestions[short_name] = {'value':i, 'tooltip':i, 'icon':load("res://addons/dialogic/Editor/Images/Resources/character.svg")}
	return suggestions


func resource_used(path:String) -> void:
	var used_resources:Array = DialogicUtil.get_project_setting('dialogic/editor/last_resources', [])
	if path in used_resources:
		used_resources.erase(path)
	used_resources.push_front(path)
	ProjectSettings.set_setting('dialogic/editor/last_resources', used_resources)
	ProjectSettings.save()


################################################################################
##							TIMELINE_MODE
################################################################################

func load_timeline(timeline_path:String) -> void:
	resource_used(timeline_path)
	var found: bool = false
	for item in editor_reference.timeline_directory:
			if editor_reference.timeline_directory[item] == timeline_path:
				found = true
				%ResourcePicker.set_value(item)
				break
	if !found:
		%ResourcePicker.set_value(timeline_path)
	%ResourcePicker.resource_icon = get_theme_icon("TripleBar", "EditorIcons")
	show_timeline_tool_buttons()


func _on_play_timeline() -> void:
	emit_signal('play_timeline')
	$PlayTimeline.release_focus()

func show_timeline_tool_buttons() -> void:
	$PlayTimeline.show()
	$ToggleVisualEditor.show()

func hide_timeline_tool_buttons() -> void:
	$PlayTimeline.hide()
	$ToggleVisualEditor.hide()
################################################################################
##							CHARACTER_MODE
################################################################################

func load_character(character_path:String) -> void:
	resource_used(character_path)
	var found: bool = false
	for item in editor_reference.character_directory:
		if editor_reference.character_directory[item]['full_path'] == character_path:
			found = true
			%ResourcePicker.set_value(item)
			break
	if !found:
		%ResourcePicker.set_value(character_path)

	%ResourcePicker.resource_icon = load("res://addons/dialogic/Editor/Images/Resources/character.svg")
	hide_timeline_tool_buttons()


func _on_ResourcePicker_value_changed(property_name, value) -> void:
	if value:
		DialogicUtil.get_dialogic_plugin().editor_interface.inspect_object(load(value))


################################################################################
##							EDITING MODE
################################################################################

func _on_toggle_visual_editor_clicked() -> void:
	var _mode := 'visual'
	if DialogicUtil.get_project_setting('dialogic/editor_mode', 'visual') == 'visual':
		_mode = 'text'
	ProjectSettings.set_setting('dialogic/editor_mode', _mode)
	ProjectSettings.save()
	emit_signal('toggle_editor_view', _mode)
	update_toggle_button()
	

func update_toggle_button() -> void:
	$ToggleVisualEditor.icon = get_theme_icon("ThemeDeselectAll", "EditorIcons")
	# Have to make this hack for the button to resize properly {
	$ToggleVisualEditor.size = Vector2(0,0)
	await get_tree().process_frame
	$ToggleVisualEditor.size = Vector2(0,0)
	# } End of hack :)
	if DialogicUtil.get_project_setting('dialogic/editor_mode', 'visual') == 'text':
		$ToggleVisualEditor.text = 'Visual Editor'
	else:
		$ToggleVisualEditor.text = 'Text Editor'
