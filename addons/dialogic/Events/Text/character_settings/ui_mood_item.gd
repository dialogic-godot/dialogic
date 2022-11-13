@tool
extends PanelContainer

signal duplicate
signal changed

func _ready():
	add_theme_stylebox_override('panel', get_theme_stylebox("sub_inspector_bg12", "Editor"))
	%Name.tooltip_text = "Mood name"
	%Duplicate.icon = get_theme_icon("Duplicate", "EditorIcons")
	%Duplicate.tooltip_text = "Duplicate"
	%Duplicate.button_up.connect(emit_signal.bind("duplicate"))
	%Delete.icon = get_theme_icon("Remove", "EditorIcons")
	%Delete.tooltip_text = "Delete"
	%ChangeSoundFolderButton.icon = get_theme_icon("Folder", "EditorIcons")
	%ChangeSoundFolderButton.tooltip_text = "Change sounds folder"
	%Fold.icon = get_theme_icon("GuiVisibilityVisible", "EditorIcons")
	%Fold.tooltip_text = "Fold/Unfold"
	%Play.icon = get_theme_icon("Play", "EditorIcons")
	%Play.tooltip_text = "Preview"
	_on_Fold_toggled(true)
	
	%Name.text_changed.connect(something_changed)
	%PitchBase.value_changed.connect(something_changed)
	%PitchVariance.value_changed.connect(something_changed)
	%VolumeBase.value_changed.connect(something_changed)
	%VolumeVariance.value_changed.connect(something_changed)

func load_data(dict:Dictionary):
	%Name.text = dict.get('name', '')
	%SoundFolder.text = dict.get('sound_folder', '').get_file()
	%SoundFolder.tooltip_text = dict.get('sound_folder', '')
	%PitchBase.value = dict.get('pitch_base', 1)
	%PitchVariance.value = dict.get('pitch_variance', 0)
	%VolumeBase.value = dict.get('volume_base', 0)
	%VolumeVariance.value = dict.get('volume_variance', 0)

func get_data():
	var dict = {}
	dict['name'] = %Name.text
	
	dict['sound_folder'] = %SoundFolder.tooltip_text
	dict['pitch_base'] = %PitchBase.value
	dict['pitch_variance'] = %PitchVariance.value
	dict['volume_base'] = %VolumeBase.value
	dict['volume_variance'] = %VolumeVariance.value
	return dict

func something_changed(fake_arg= ''): emit_signal("changed")

func _on_Fold_toggled(button_pressed):
	%Fold.button_pressed = button_pressed
	if button_pressed:
		%Fold.icon = get_theme_icon("GuiVisibilityHidden", "EditorIcons")
	else:
		%Fold.icon = get_theme_icon("GuiVisibilityVisible", "EditorIcons")
	%Content.visible = !button_pressed

func _on_Delete_pressed():
	emit_signal("changed")
	queue_free()

func open_file_folder_dialog():
	find_parent('EditorView').godot_file_dialog(file_folder_selected, '', EditorFileDialog.FILE_MODE_OPEN_DIR, 'Select folder with sounds')

func file_folder_selected(path):
	%SoundFolder.tooltip_text = path
	%SoundFolder.text = path.get_file()
	emit_signal("changed")

func preview():
	if %SoundFolder.tooltip_text.is_empty(): return
	$DialogicNode_TypeSounds.load_overwrite(get_data())
	var preview_timer = Timer.new()
	DialogicUtil.update_timer_process_callback(preview_timer)
	add_child(preview_timer)
	preview_timer.start(DialogicUtil.get_project_setting('text/speed', 0.01))
	for i in range(20):
		$DialogicNode_TypeSounds._on_continued_revealing_text("a")
		await preview_timer.timeout
	preview_timer.queue_free()
