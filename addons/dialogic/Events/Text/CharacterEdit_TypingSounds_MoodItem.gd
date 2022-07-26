@tool
extends PanelContainer

signal duplicate
signal changed

func _ready():
	add_stylebox_override('panel', get_stylebox("sub_inspector_bg12", "Editor"))
	$'%Name'.hint_tooltip = "Mood name"
	$'%Duplicate'.icon = get_icon("Duplicate", "EditorIcons")
	$'%Duplicate'.hint_tooltip = "Duplicate"
	$'%Duplicate'.connect("pressed", self, "emit_signal", ["duplicate"])
	$'%Delete'.icon = get_icon("Remove", "EditorIcons")
	$'%Delete'.hint_tooltip = "Delete"
	$'%ChangeSoundFolderButton'.icon = get_icon("Folder", "EditorIcons")
	$'%ChangeSoundFolderButton'.hint_tooltip = "Change sounds folder"
	$'%Fold'.icon = get_icon("GuiVisibilityVisible", "EditorIcons")
	$'%Fold'.hint_tooltip = "Fold/Unfold"
	$'%Play'.icon = get_icon("Play", "EditorIcons")
	$'%Play'.hint_tooltip = "Preview"
	_on_Fold_toggled(true)
	
	$'%Name'.connect("text_changed", self, 'something_changed')
	$'%PitchBase'.connect("value_changed", self, 'something_changed')
	$'%PitchVariance'.connect("value_changed", self, 'something_changed')
	$'%VolumeBase'.connect("value_changed", self, 'something_changed')
	$'%VolumeVariance'.connect("value_changed", self, 'something_changed')

func load_data(dict:Dictionary):
	$'%Name'.text = dict.get('name', '')
	$'%SoundFolder'.text = dict.get('sound_folder', '').get_file()
	$'%SoundFolder'.hint_tooltip = dict.get('sound_folder', '')
	$'%PitchBase'.value = dict.get('pitch_base', 1)
	$'%PitchVariance'.value = dict.get('pitch_variance', 0)
	$'%VolumeBase'.value = dict.get('volume_base', 0)
	$'%VolumeVariance'.value = dict.get('volume_variance', 0)

func get_data():
	var dict = {}
	dict['name'] = $'%Name'.text
	
	dict['sound_folder'] = $'%SoundFolder'.hint_tooltip
	dict['pitch_base'] = $'%PitchBase'.value
	dict['pitch_variance'] = $'%PitchVariance'.value
	dict['volume_base'] = $'%VolumeBase'.value
	dict['volume_variance'] = $'%VolumeVariance'.value
	return dict

func something_changed(fake_arg= ''): emit_signal("changed")

func _on_Fold_toggled(button_pressed):
	$'%Fold'.pressed = button_pressed
	if button_pressed:
		$'%Fold'.icon = get_icon("GuiVisibilityHidden", "EditorIcons")
	else:
		$'%Fold'.icon = get_icon("GuiVisibilityVisible", "EditorIcons")
	$'%Content'.visible = !button_pressed

func _on_Delete_pressed():
	emit_signal("changed")
	queue_free()

func open_file_folder_dialog():
	find_parent('EditorView').godot_file_dialog(self, 'file_folder_selected', '', EditorFileDialog.MODE_OPEN_DIR, 'Select folder with sounds')

func file_folder_selected(path):
	$'%SoundFolder'.hint_tooltip = path
	$'%SoundFolder'.text = path.get_file()
	emit_signal("changed")

func preview():
	if !$'%SoundFolder'.hint_tooltip: return
	$DialogicDisplay_TypeSounds.load_overwrite(get_data())
	var preview_timer = Timer.new()
	add_child(preview_timer)
	preview_timer.start(DialogicUtil.get_project_setting('text/speed', 0.01))
	for i in range(20):
		$DialogicDisplay_TypeSounds._on_continued_revealing_text("a")
		yield(preview_timer, "timeout")
	preview_timer.queue_free()
