@tool
extends DialogicEditor

## Editor that holds both the visual and the text timeline editors.

# references
enum EditorMode {VISUAL, TEXT}

var current_editor_mode := EditorMode.VISUAL
var play_timeline_button: Button = null


## Overwrite. Register to the editor manager in here.
func _register() -> void:
	resource_unsaved.connect(_on_resource_unsaved)
	resource_saved.connect(_on_resource_saved)

	# register editor
	editors_manager.register_resource_editor('dtl', self)
	# add timeline button
	var add_timeline_button: Button = editors_manager.add_icon_button(
		load("res://addons/dialogic/Editor/Images/Toolbar/add-timeline.svg"),
		"Add Timeline",
		self)
	add_timeline_button.pressed.connect(_on_create_timeline_button_pressed)
	add_timeline_button.shortcut = Shortcut.new()
	add_timeline_button.shortcut.events.append(InputEventKey.new())
	add_timeline_button.shortcut.events[0].keycode = KEY_1
	add_timeline_button.shortcut.events[0].ctrl_pressed = true
	# play timeline button
	play_timeline_button = editors_manager.add_custom_button(
		"Play Timeline",
		get_theme_icon("PlayScene", "EditorIcons"),
		self)
	play_timeline_button.pressed.connect(play_timeline)
	play_timeline_button.tooltip_text = "Play the current timeline (CTRL+F5)"
	if OS.get_name() == "macOS":
		play_timeline_button.tooltip_text = "Play the current timeline (CTRL+B)"

	%VisualEditor.load_event_buttons()

	current_editor_mode = DialogicUtil.get_editor_setting('timeline_editor_mode', 0)

	match current_editor_mode:
		EditorMode.VISUAL:
			%VisualEditor.show()
			%TextEditor.hide()
			%SwitchEditorMode.text = "Text Editor"
		EditorMode.TEXT:
			%VisualEditor.hide()
			%TextEditor.show()
			%SwitchEditorMode.text = "Visual Editor"

	$NoTimelineScreen.show()
	play_timeline_button.disabled = true


func _get_title() -> String:
	return "Timeline"


func _get_icon() -> Texture:
	return get_theme_icon("TripleBar", "EditorIcons")


## If this editor supports editing resources, load them here (overwrite in subclass)
func _open_resource(resource:Resource) -> void:
	current_resource = resource
	current_resource_state = ResourceStates.SAVED
	match current_editor_mode:
		EditorMode.VISUAL:
			%VisualEditor.load_timeline(current_resource)
		EditorMode.TEXT:
			%TextEditor.load_timeline(current_resource)
	$NoTimelineScreen.hide()
	%TimelineName.text = DialogicResourceUtil.get_unique_identifier(current_resource.resource_path)
	play_timeline_button.disabled = false


## If this editor supports editing resources, save them here (overwrite in subclass)
func _save() -> void:
	match current_editor_mode:
		EditorMode.VISUAL:
			%VisualEditor.save_timeline()
		EditorMode.TEXT:
			%TextEditor.save_timeline()


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		var keycode := KEY_F5
		if OS.get_name() == "macOS":
			keycode = KEY_B
		if event.keycode == keycode and event.pressed:
			if Input.is_key_pressed(KEY_CTRL):
				play_timeline()

		if event.keycode == KEY_F and event.pressed:
			if Input.is_key_pressed(KEY_CTRL):
				if is_ancestor_of(get_viewport().gui_get_focus_owner()):
					search_timeline()


## Method to play the current timeline. Connected to the button in the sidebar.
func play_timeline() -> void:
	_save()

	var dialogic_plugin := DialogicUtil.get_dialogic_plugin()

	# Save the current opened timeline
	DialogicUtil.set_editor_setting('current_timeline_path', current_resource.resource_path)

	DialogicUtil.get_dialogic_plugin().get_editor_interface().play_custom_scene("res://addons/dialogic/Editor/TimelineEditor/test_timeline_scene.tscn")


## Method to switch from visual to text editor (and vice versa). Connected to the button in the sidebar.
func toggle_editor_mode() -> void:
	match current_editor_mode:
		EditorMode.VISUAL:
			current_editor_mode = EditorMode.TEXT
			%VisualEditor.save_timeline()
			%VisualEditor.hide()
			%TextEditor.show()
			%TextEditor.load_timeline(current_resource)
			%SwitchEditorMode.text = "Visual Editor"
		EditorMode.TEXT:
			current_editor_mode = EditorMode.VISUAL
			%TextEditor.save_timeline()
			%TextEditor.hide()
			%VisualEditor.load_timeline(current_resource)
			%VisualEditor.show()
			%SwitchEditorMode.text = "Text Editor"
	_on_search_text_changed(%Search.text)
	DialogicUtil.set_editor_setting('timeline_editor_mode', current_editor_mode)


func _on_resource_unsaved() -> void:
	if current_resource:
		current_resource.set_meta("timeline_not_saved", true)


func _on_resource_saved() -> void:
	if current_resource:
		current_resource.set_meta("timeline_not_saved", false)


func new_timeline(path:String) -> void:
	_save()
	var new_timeline := DialogicTimeline.new()
	new_timeline.resource_path = path
	new_timeline.set_meta('timeline_not_saved', true)
	var err := ResourceSaver.save(new_timeline)
	EditorInterface.get_resource_filesystem().update_file(new_timeline.resource_path)
	DialogicResourceUtil.update_directory('dtl')
	editors_manager.edit_resource(new_timeline)


func _ready() -> void:
	$NoTimelineScreen.add_theme_stylebox_override("panel", get_theme_stylebox("Background", "EditorStyles"))

	# switch editor mode button
	%SwitchEditorMode.text = "Text editor"
	%SwitchEditorMode.icon = get_theme_icon("ArrowRight", "EditorIcons")
	%SwitchEditorMode.pressed.connect(toggle_editor_mode)
	%SwitchEditorMode.custom_minimum_size.x = 200 * DialogicUtil.get_editor_scale()

	%SearchClose.icon = get_theme_icon("Close", "EditorIcons")
	%SearchUp.icon = get_theme_icon("MoveUp", "EditorIcons")
	%SearchDown.icon = get_theme_icon("MoveDown", "EditorIcons")



func _on_create_timeline_button_pressed() -> void:
	editors_manager.show_add_resource_dialog(
			new_timeline,
			'*.dtl; DialogicTimeline',
			'Create new timeline',
			'timeline',
			)


func _clear() -> void:
	current_resource = null
	current_resource_state = ResourceStates.SAVED
	match current_editor_mode:
		EditorMode.VISUAL:
			%VisualEditor.clear_timeline_nodes()
		EditorMode.TEXT:
			%TextEditor.clear_timeline()
	$NoTimelineScreen.show()
	play_timeline_button.disabled = true


func get_current_editor() -> Node:
	if current_editor_mode == 1:
		return %TextEditor
	return %VisualEditor

#region SEARCH

func search_timeline() -> void:
	%SearchSection.show()
	if get_viewport().gui_get_focus_owner() is TextEdit:
		%Search.text = get_viewport().gui_get_focus_owner().get_selected_text()
		_on_search_text_changed(%Search.text)
	else:
		%Search.text = ""
	%Search.grab_focus()


func _on_close_search_pressed() -> void:
	%SearchSection.hide()
	%Search.text = ""
	_on_search_text_changed('')


func _on_search_text_changed(new_text: String) -> void:
	var editor: Node = null
	var anything_found: bool = get_current_editor()._search_timeline(new_text)
	if anything_found or new_text.is_empty():
		%SearchLabel.hide()
		%Search.add_theme_color_override("font_color", get_theme_color("font_color", "Editor"))
	else:
		%SearchLabel.show()
		%SearchLabel.add_theme_color_override("font_color", get_theme_color("error_color", "Editor"))
		%Search.add_theme_color_override("font_color", get_theme_color("error_color", "Editor"))
		%SearchLabel.text = "No Match"


func _on_search_down_pressed() -> void:
	get_current_editor()._search_navigate_down()


func _on_search_up_pressed() -> void:
	get_current_editor()._search_navigate_up()

#endregion


