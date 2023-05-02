@tool
extends DialogicEditor

## Editor that holds both the visual and the text timeline editors.

# references
var editor_mode_toggle_button : Button
var current_editor_mode: int = 0 # 0 = visal, 1 = text


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
	# play timeline button
	var play_timeline_button: Button = editors_manager.add_custom_button(
		"Play Timeline",
		get_theme_icon("PlayScene", "EditorIcons"),
		self)
	play_timeline_button.pressed.connect(play_timeline)
	play_timeline_button.tooltip_text = "Play the current timeline (CTRL+F5)"
	# switch editor mode button
	editor_mode_toggle_button = editors_manager.add_custom_button(
		"Text editor",
		get_theme_icon("ArrowRight", "EditorIcons"),
		self)
	editor_mode_toggle_button.pressed.connect(toggle_editor_mode)
	
	$VisualEditor.load_event_buttons()
	
	current_editor_mode = DialogicUtil.get_editor_setting('timeline_editor_mode', 0)
	
	match current_editor_mode:
		0:
			$VisualEditor.show()
			$TextEditor.hide()
			editor_mode_toggle_button.text = "Text Editor"
		1:
			$VisualEditor.hide()
			$TextEditor.show()
			editor_mode_toggle_button.text = "Visual Editor"
	$NoTimelineScreen.show()


## If this editor supports editing resources, load them here (overwrite in subclass)
func _open_resource(resource:Resource) -> void:
	current_resource = resource
	current_resource_state = ResourceStates.Saved
	match current_editor_mode:
		0:
			$VisualEditor.load_timeline(current_resource)
		1:
			$TextEditor.load_timeline(current_resource)
	$NoTimelineScreen.hide()


## If this editor supports editing resources, save them here (overwrite in subclass)
func _save() -> void:
	match current_editor_mode:
		0:
			$VisualEditor.save_timeline()
		1:
			$TextEditor.save_timeline()


func _input(event: InputEvent) -> void:
	
	if event is InputEventKey and event.keycode == KEY_F5 and event.pressed:
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
			$VisualEditor.save_timeline()
			$VisualEditor.hide()
			$TextEditor.show()
			$TextEditor.load_timeline(current_resource)
			editor_mode_toggle_button.text = "Visual Editor"
		1:
			current_editor_mode = 0
			$TextEditor.save_timeline()
			$TextEditor.hide()
			$VisualEditor.load_timeline(current_resource)
			$VisualEditor.show()
			editor_mode_toggle_button.text = "Text Editor"
	
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
	editors_manager.resource_helper.rebuild_timeline_directory()
	editors_manager.edit_resource(new_timeline)


func _ready():
	$NoTimelineScreen.add_theme_stylebox_override("panel", get_theme_stylebox("Background", "EditorStyles"))
	get_parent().set_tab_title(get_index(), 'Timeline')
	get_parent().set_tab_icon(get_index(), get_theme_icon("TripleBar", "EditorIcons"))


func _on_create_timeline_button_pressed():
	editors_manager.show_add_resource_dialog(
			new_timeline, 
			'*.dtl; DialogicTimeline',
			'Create new timeline',
			'timeline',
			)


func _clear():
	current_resource = null
	current_resource_state = ResourceStates.Saved
	match current_editor_mode:
		0:
			$VisualEditor.clear_timeline_nodes()
		1:
			$TextEditor.clear_timeline()
	$NoTimelineScreen.show()
