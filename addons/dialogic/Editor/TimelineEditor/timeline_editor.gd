@tool
extends DialogicEditor

## Editor that holds both the visual and the text timeline editors.

# references
var current_editor_mode: int = 0 # 0 = visal, 1 = text
var play_timeline_button : Button = null

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
		0:
			%VisualEditor.show()
			%TextEditor.hide()
			%SwitchEditorMode.text = "Text Editor"
		1:
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
		0:
			%VisualEditor.load_timeline(current_resource)
		1:
			%TextEditor.load_timeline(current_resource)
	$NoTimelineScreen.hide()
	%TimelineName.text = DialogicResourceUtil.get_unique_identifier(current_resource.resource_path)
	play_timeline_button.disabled = false


## If this editor supports editing resources, save them here (overwrite in subclass)
func _save() -> void:
	match current_editor_mode:
		0:
			%VisualEditor.save_timeline()
		1:
			%TextEditor.save_timeline()


func _input(event: InputEvent) -> void:
	var keycode := KEY_F5
	if OS.get_name() == "macOS":
		keycode = KEY_B
	if event is InputEventKey and event.keycode == keycode and event.pressed:
		if Input.is_key_pressed(KEY_CTRL):
			play_timeline()


## Method to play the current timeline. Connected to the button in the sidebar.
func play_timeline():
	_save()

	var dialogic_plugin = DialogicUtil.get_dialogic_plugin()

	# Save the current opened timeline
	DialogicUtil.set_editor_setting('current_timeline_path', current_resource.resource_path)

	DialogicUtil.get_dialogic_plugin().get_editor_interface().play_custom_scene("res://addons/dialogic/Editor/TimelineEditor/test_timeline_scene.tscn")


## Method to switch from visual to text editor (and vice versa). Connected to the button in the sidebar.
func toggle_editor_mode():
	match current_editor_mode:
		0:
			current_editor_mode = 1
			%VisualEditor.save_timeline()
			%VisualEditor.hide()
			%TextEditor.show()
			%TextEditor.load_timeline(current_resource)
			%SwitchEditorMode.text = "Visual Editor"
		1:
			current_editor_mode = 0
			%TextEditor.save_timeline()
			%TextEditor.hide()
			%VisualEditor.load_timeline(current_resource)
			%VisualEditor.show()
			%SwitchEditorMode.text = "Text Editor"

	DialogicUtil.set_editor_setting('timeline_editor_mode', current_editor_mode)


func _on_resource_unsaved():
	if current_resource:
		current_resource.set_meta("timeline_not_saved", true)


func _on_resource_saved():
	if current_resource:
		current_resource.set_meta("timeline_not_saved", false)


func new_timeline(path:String) -> void:
	_save()
	var new_timeline := DialogicTimeline.new()
	new_timeline.resource_path = path
	new_timeline.set_meta('timeline_not_saved', true)
	var err := ResourceSaver.save(new_timeline)
	DialogicResourceUtil.update_directory('dtl')
	editors_manager.edit_resource(new_timeline)


func _ready():
	$NoTimelineScreen.add_theme_stylebox_override("panel", get_theme_stylebox("Background", "EditorStyles"))

	# switch editor mode button
	%SwitchEditorMode.text = "Text editor"
	%SwitchEditorMode.icon = get_theme_icon("ArrowRight", "EditorIcons")
	%SwitchEditorMode.pressed.connect(toggle_editor_mode)
	%SwitchEditorMode.custom_minimum_size.x = 200 * DialogicUtil.get_editor_scale()





func _on_create_timeline_button_pressed():
	editors_manager.show_add_resource_dialog(
			new_timeline,
			'*.dtl; DialogicTimeline',
			'Create new timeline',
			'timeline',
			)


func _clear():
	current_resource = null
	current_resource_state = ResourceStates.SAVED
	match current_editor_mode:
		0:
			%VisualEditor.clear_timeline_nodes()
		1:
			%TextEditor.clear_timeline()
	$NoTimelineScreen.show()
	play_timeline_button.disabled = true
