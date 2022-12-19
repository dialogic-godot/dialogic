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
	add_timeline_button.pressed.connect(editors_manager.show_add_resource_dialog.bind(
			new_timeline, 
			'*.dtl; DialogicTimeline',
			'Create new timeline',
			'timeline',
			))
	# play timeline button
	var play_timeline_button: Button = editors_manager.add_custom_button(
		"Play Timeline",
		get_theme_icon("PlayScene", "EditorIcons"),
		self)
	play_timeline_button.pressed.connect(play_timeline)
	# switch editor mode button
	editor_mode_toggle_button = editors_manager.add_custom_button(
		"Text editor",
		get_theme_icon("ArrowRight", "EditorIcons"),
		self)
	editor_mode_toggle_button.pressed.connect(toggle_editor_mode)
	
	$VisualEditor.load_event_buttons()
	
	current_editor_mode = DialogicUtil.get_project_setting('dialogic/editor/timeline_editor_mode', 0)
	
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
func _save_resource() -> void:
	match current_editor_mode:
		0:
			$VisualEditor.save_timeline()
		1:
			$TextEditor.save_timeline()



## Method to play the current timeline. Connected to the button in the sidebar.
func play_timeline():
	_save_resource()
	
	var dialogic_plugin = DialogicUtil.get_dialogic_plugin()
	
	# Save the current opened timeline
	ProjectSettings.set_setting('dialogic/editor/current_timeline_path', current_resource.resource_path)
	ProjectSettings.save()
	
	DialogicUtil.get_dialogic_plugin().editor_interface.play_custom_scene("res://addons/dialogic/Editor/TimelineEditor/test_timeline_scene.tscn")


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
	
	ProjectSettings.set_setting('dialogic/editor/timeline_editor_mode', current_editor_mode)
	ProjectSettings.save()


func _on_resource_unsaved():
	current_resource.set_meta("timeline_not_saved", true)


func _on_resource_saved():
	current_resource.set_meta("timeline_not_saved", false)


func new_timeline(path:String) -> void:
	_save_resource()
	var new_timeline := DialogicTimeline.new()
	new_timeline.resource_path = path
	_open_resource(new_timeline)


func _ready():
	$NoTimelineScreen.add_theme_stylebox_override("panel", get_theme_stylebox("Background", "EditorStyles"))


func _on_create_timeline_button_pressed():
	editors_manager.show_add_resource_dialog(
			new_timeline, 
			'*.dtl; DialogicTimeline',
			'Create new timeline',
			'timeline',
			)
