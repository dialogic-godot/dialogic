@tool
extends HBoxContainer

signal toggle_editor_view(mode)

func _ready():
	# Get version number
	$Version.set("custom_colors/font_color", get_theme_color("disabled_font_color", "Editor"))
	var config = ConfigFile.new()
	var err = config.load("res://addons/dialogic/plugin.cfg")
	if err == OK:
		$Version.text = "v" + config.get_value("plugin", "version")
	
	
	$PlayTimeline.icon = get_theme_icon("PlayScene", "EditorIcons")
	$PlayTimeline.button_up.connect(play_timeline)
	
	$AddTimeline.icon = load("res://addons/dialogic/Editor/Images/Toolbar/add-timeline.svg")
	%ResourcePicker.get_suggestions_func = [self, 'suggest_resources']
	%ResourcePicker.resource_icon = get_theme_icon("GuiRadioUnchecked", "EditorIcons")
	$Settings.icon = get_theme_icon("Tools", "EditorIcons")
	
	
	$ToggleVisualEditor.button_up.connect(_on_toggle_visual_editor_clicked)
	$ToggleVisualEditor.icon = get_theme_icon("ThemeDeselectAll", "EditorIcons")
	update_toggle_button()


################################################################################
##							HELPERS
################################################################################

func set_resource_saved():
	if %ResourcePicker.current_value.ends_with(("(*)")):
		%ResourcePicker.set_value(%ResourcePicker.current_value.trim_suffix("(*)"))

func set_resource_unsaved():
	if not %ResourcePicker.current_value.ends_with(("(*)")):
		%ResourcePicker.set_value(%ResourcePicker.current_value +"(*)")

func is_current_unsaved() -> bool:
	if %ResourcePicker.current_value and %ResourcePicker.current_value.ends_with('(*)'):
		return true
	return false

################################################################################
##							BASICS
################################################################################

func _on_AddTimeline_pressed():
	get_parent().get_node("%TimelineEditor").new_timeline()

func _on_AddCharacter_pressed():
	find_parent('EditorView').godot_file_dialog(
		get_parent().get_node("CharacterEditor").new_character,
		'*.dch; DialogicCharacter',
		EditorFileDialog.FILE_MODE_SAVE_FILE,
		'Save new Character',
		'New_Character',
		true
	)


func suggest_resources(filter):
	var suggestions = {}
	for i in DialogicUtil.get_project_setting('dialogic/editor/last_resources', []):
		if i.ends_with('.dtl'):
			suggestions[DialogicUtil.pretty_name(i)] = {'value':i, 'tooltip':i, 'editor_icon': ["TripleBar", "EditorIcons"]}
		elif i.ends_with('.dch'):
			suggestions[DialogicUtil.pretty_name(i)] = {'value':i, 'tooltip':i, 'icon':load("res://addons/dialogic/Editor/Images/Resources/character.svg")}
	return suggestions


func resource_used(path:String):
	var used_resources:Array = DialogicUtil.get_project_setting('dialogic/editor/last_resources', [])
	if path in used_resources:
		used_resources.erase(path)
	used_resources.push_front(path)
	ProjectSettings.set_setting('dialogic/editor/last_resources', used_resources)


################################################################################
##							TIMELINE_MODE
################################################################################

func load_timeline(timeline_path):
	resource_used(timeline_path)
	%ResourcePicker.set_value(DialogicUtil.pretty_name(timeline_path))
	%ResourcePicker.resource_icon = get_theme_icon("TripleBar", "EditorIcons")
	$PlayTimeline.show()


func play_timeline():
	if find_parent('EditorView').get_node("%TimelineEditor").current_timeline:
		var dialogic_plugin = DialogicUtil.get_dialogic_plugin()
		# Save the current opened timeline
		ProjectSettings.set_setting('dialogic/editor/current_timeline_path', find_parent('EditorView').get_node("%TimelineEditor").current_timeline.resource_path)
		ProjectSettings.save()
		dialogic_plugin._editor_interface.play_custom_scene("res://addons/dialogic/Other/TestTimelineScene.tscn")


################################################################################
##							CHARACTER_MODE
################################################################################

func load_character(character_path):
	resource_used(character_path)
	%ResourcePicker.set_value(DialogicUtil.pretty_name(character_path))
	%ResourcePicker.resource_icon = load("res://addons/dialogic/Editor/Images/Resources/character.svg")
	$PlayTimeline.hide()


func _on_ResourcePicker_value_changed(property_name, value):
	if value:
		DialogicUtil.get_dialogic_plugin()._editor_interface.inspect_object(load(value))


################################################################################
##							EDITING MODE
################################################################################

func _on_toggle_visual_editor_clicked():
	if DialogicUtil.get_project_setting('dialogic/editor_mode', 'visual') == 'visual':
		ProjectSettings.set_setting('dialogic/editor_mode', 'text')
		emit_signal('toggle_editor_view', 'text')
	else:
		ProjectSettings.set_setting('dialogic/editor_mode', 'visual')
		emit_signal('toggle_editor_view', 'visual')
	update_toggle_button()
	

func update_toggle_button():
	if DialogicUtil.get_project_setting('dialogic/editor_mode', 'visual') == 'text':
		$ToggleVisualEditor.text = 'Visual Editor'
	else:
		$ToggleVisualEditor.text = 'Text Editor'
