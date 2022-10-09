@tool
extends HBoxContainer

signal colors_changed

var color_palette = null

func _ready():
	var s = DCSS.inline({
		'padding': 5,
		'background': Color(0.545098, 0.545098, 0.545098, 0.211765)
	})
	$General/TitleLabel.add_theme_stylebox_override("normal", s)
	$General/TitleLabel2.add_theme_stylebox_override("normal", s)
	
	# Signals
	%TestingSceneButton.pressed.connect(_on_TestingSceneButton_pressed)
	%DefaultSceneButton.pressed.connect(_on_DefaultSceneButton_pressed)
	%CustomEventsFolderButton.pressed.connect(_on_CustomEventsFolderButton_pressed)
	%PhysicsTimerButton.pressed.connect(_on_physics_timer_button_toggled)
	
	# Colors
	%ResetColorsButton.button_up.connect(_on_reset_colors_button)
	
	for n in $"%Colors".get_children():
		n.color_changed.connect(_on_color_change.bind(n))

func refresh():
	%CustomEventsFolderLabel.text = DialogicUtil.get_project_setting('dialogic/custom_events_folder', 'res://addons/dialogic_additions/Events')
	%CustomEventsFolderButton.icon = get_theme_icon("Folder", "EditorIcons")
	%TestingSceneButton.icon = get_theme_icon("Folder", "EditorIcons")
	%TestingSceneLabel.text = DialogicUtil.get_project_setting('dialogic/editor/test_dialog_scene', "res://addons/dialogic/Example Assets/example-scenes/DialogicDefaultScene.tscn")
	
	%PhysicsTimerButton.button_pressed = DialogicUtil.is_physics_timer()
	
	%DefaultSceneButton.icon = get_theme_icon("Folder", "EditorIcons")
	%DefaultSceneLabel.text = DialogicUtil.get_project_setting('dialogic/editor/default_dialog_scene', "res://addons/dialogic/Example Assets/example-scenes/DialogicDefaultScene.tscn")
	
	
	# Color Palett
	color_palette = DialogicUtil.get_color_palette()
	var _scale = DialogicUtil.get_editor_scale()
	for n in %Colors.get_children():
		n.custom_minimum_size = Vector2(50 ,50)*scale
		n.color = color_palette[n.name]


func _on_CustomEventsFolderButton_pressed() -> void:
	find_parent('EditorView').godot_file_dialog(custom_events_folder_selected, '', EditorFileDialog.FILE_MODE_OPEN_DIR, 'Select custom events folder')


func custom_events_folder_selected(folder_path:String) -> void:
	%CustomEventsFolderLabel.text = folder_path
	ProjectSettings.set_setting('dialogic/custom_events_folder', folder_path)
	ProjectSettings.save()


func _on_color_change(color: Color, who) -> void:
	ProjectSettings.set_setting('dialogic/editor/' + str(who.name), color)
	ProjectSettings.save()
	emit_signal('colors_changed')


func _on_reset_colors_button() -> void:
	color_palette = DialogicUtil.get_color_palette(true)
	for n in %Colors.get_children():
		n.color = color_palette[n.name]
		# There is a bug when trying to remove existing values, so we have to
		# set/create new entries for all the colors used. 
		# If you manage to make it work using the ProjectSettings.clear() 
		# feel free to open a PR!
		ProjectSettings.set_setting('dialogic/editor/' + str(n.name), color_palette[n.name])
	ProjectSettings.save()
	emit_signal('colors_changed')


func _on_TestingSceneButton_pressed() -> void:
	find_parent('EditorView').godot_file_dialog(custom_testing_scene_selected, '*.tscn, *.scn', EditorFileDialog.FILE_MODE_OPEN_FILE, 'Select testing scene')


func custom_testing_scene_selected(path:String) -> void:
	%TestingSceneLabel.text = path
	ProjectSettings.set_setting('dialogic/editor/test_dialog_scene', path)
	ProjectSettings.save()


func _on_DefaultSceneButton_pressed() -> void:
	find_parent('EditorView').godot_file_dialog(custom_default_scene_selected, '*.tscn, *.scn', EditorFileDialog.FILE_MODE_OPEN_FILE, 'Select default scene')


func custom_default_scene_selected(path:String) -> void:
	%DefaultSceneLabel.text = path
	ProjectSettings.set_setting('dialogic/editor/default_dialog_scene', path)
	ProjectSettings.save()


func _on_physics_timer_button_toggled(button_pressed:bool) -> void:
	ProjectSettings.set_setting('dialogic/timer/process_in_physics', button_pressed)
	ProjectSettings.save()
