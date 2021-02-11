tool
extends Control

var plugin_reference

var undo_redo: UndoRedo

var debug_mode: bool = true # For printing info

var editor_file_dialog # EditorFileDialog
var file_picker_data: Dictionary = {'method': '', 'node': self}

var current_editor_view: String = 'Timeline'

var working_dialog_file: String = ''
var timer_duration = 200
var timer_interval = 30
var autosaving_hash


func _ready():
	# Adding file dialog to get used by pieces
	editor_file_dialog = EditorFileDialog.new()
	add_child(editor_file_dialog)
	
	$ToolBar/EventButton.set('self_modulate', Color('#6a9dea'))

	$EditorCharacter.editor_reference = self
	$EditorCharacter.refresh_character_list()
	
	$EditorTimeline.editor_reference = self
	$EditorTimeline.refresh_timeline_list()
	
	$EditorTheme.editor_reference = self
	$EditorGlossary.editor_reference = self

	# Adding native icons
	$EditorTimeline/EventTools/VBoxContainer2/AddTimelineButton.icon = get_icon("Add", "EditorIcons")
	$EditorGlossary/VBoxContainer/NewEntryButton.icon = get_icon("Add", "EditorIcons")
	$EditorGlossary/CenterContainer/VBoxContainer/CenterContainer/NewEntryButton2.icon = get_icon("Add", "EditorIcons")
	$EditorCharacter/CharacterTools/Button.icon = get_icon("Add", "EditorIcons")
	
	$ToolBar/Docs.icon = get_icon("Instance", "EditorIcons")
	$ToolBar/Docs.connect('pressed', self, "_docs_button", [])
	
	# Adding custom icons. For some reason they don't load properly otherwise.
	$EditorTimeline/TimelineEditor/ScrollContainer/EventContainer/ChangeScene.icon = load("res://addons/dialogic/Images/change-scene.svg")
	
	# Making the dialog editor the default
	change_tab('Timeline')
	_on_EventButton_pressed()
	
	# Toolbar button connections
	$ToolBar/FoldTools/ButtonFold.connect('pressed', $EditorTimeline, 'fold_all_nodes')
	$ToolBar/FoldTools/ButtonUnfold.connect('pressed', $EditorTimeline, 'unfold_all_nodes')


func _process(delta):
	timer_interval -= 1
	if timer_interval < 0 :
		timer_interval = timer_duration
		_on_AutoSaver_timeout()


func _on_TimelinePopupMenu_id_pressed(id):
	if id == 0: # rename
		popup_rename()
	if id == 1:
		OS.shell_open(ProjectSettings.globalize_path(DialogicUtil.get_path('TIMELINE_DIR')))
	if id == 2:
		#var current_id = DialogicUtil.get_filename_from_path(working_dialog_file)
		#if current_id != '':
		OS.set_clipboard($EditorTimeline.timeline_name)
	if id == 3:
		$RemoveTimelineConfirmation.popup_centered()


func popup_rename():
	$RenameDialog.register_text_enter($RenameDialog/LineEdit)
	$RenameDialog/LineEdit.text = $EditorTimeline.timeline_name
	$RenameDialog.set_as_minsize()
	$RenameDialog.popup_centered()
	$RenameDialog/LineEdit.grab_focus()
	$RenameDialog/LineEdit.select_all()


func _on_RenameDialog_confirmed():
	$EditorTimeline.timeline_name = $RenameDialog/LineEdit.text
	$RenameDialog/LineEdit.text = ''
	$EditorTimeline.save_timeline(working_dialog_file)
	$EditorTimeline.refresh_timeline_list()


func _on_RemoveTimelineConfirmation_confirmed():
	var dir = Directory.new()
	dir.remove(working_dialog_file)
	working_dialog_file = ''
	$EditorTimeline.refresh_timeline_list()
	if $EditorTimeline/EventTools/VBoxContainer2/DialogItemList.get_item_count() != 0:
		$EditorTimeline._on_DialogItemList_item_selected(0)
		$EditorTimeline/EventTools/VBoxContainer2/DialogItemList.select(0)


# Character Creations
func get_character_color(file):
	var data = DialogicUtil.load_json(DialogicUtil.get_path('CHAR_DIR', file))
	if is_instance_valid(data):
		if data.has('color'):
			return data['color']
	else:
		return "ffffff"


func get_character_name(file):
	var data = DialogicUtil.get_path('CHAR_DIR', file)
	if data.has('name'):
		return data['name']


func get_character_portraits(file):
	var data = DialogicUtil.get_path('CHAR_DIR', file)
	if data.has('portraits'):
		return data['portraits']


# Godot dialog
func godot_dialog(filter):
	editor_file_dialog.mode = EditorFileDialog.MODE_OPEN_FILE
	editor_file_dialog.clear_filters()
	editor_file_dialog.popup_centered_ratio(0.75)
	editor_file_dialog.add_filter(filter)
	return editor_file_dialog


func godot_dialog_connect(who, method_name):
	var signal_name = "file_selected"
	# Checking if previous connection exists, if it does, disconnect it.
	if editor_file_dialog.is_connected(
		signal_name,
		file_picker_data['node'],
		file_picker_data['method']):
			editor_file_dialog.disconnect(
				signal_name,
				file_picker_data['node'],
				file_picker_data['method']
			)
	# Connect new signal
	editor_file_dialog.connect(signal_name, who, method_name, [who])
	file_picker_data['method'] = method_name
	file_picker_data['node'] = who


func _on_file_selected(path):
	dprint(path)


# Toolbar
func _on_EventButton_pressed():
	change_tab('Timeline')


func _on_CharactersButton_pressed():
	change_tab('Characters')


func _on_ThemeButton_pressed():
	change_tab('Theme')


func _on_GlossaryButton_pressed():
	change_tab('Glossary')


func change_tab(tab):
	# Hiding everything
	$ToolBar/EventButton.set('self_modulate', Color('#dedede'))
	$ToolBar/CharactersButton.set('self_modulate', Color('#dedede'))
	$ToolBar/ThemeButton.set('self_modulate', Color('#dedede'))
	$ToolBar/GlossaryButton.set('self_modulate', Color('#dedede'))
	$ToolBar/FoldTools.visible = false
	$EditorTimeline.visible = false
	$EditorCharacter.visible = false
	$EditorTheme.visible = false
	$EditorGlossary.visible = false
	
	if tab == 'Timeline':
		$ToolBar/EventButton.set('self_modulate', Color('#6a9dea'))
		$EditorTimeline.visible = true
		$ToolBar/FoldTools.visible = true
		if working_dialog_file == '':
			$EditorTimeline/TimelineEditor.visible = false
			$EditorTimeline/CenterContainer.visible = true
		else:
			$EditorTimeline/TimelineEditor.visible = true
			$EditorTimeline/CenterContainer.visible = false
		
	elif tab == 'Characters':
		$ToolBar/CharactersButton.set('self_modulate', Color('#6a9dea'))
		$EditorCharacter.visible = true
		# Select the first character in the list
		if $EditorCharacter/CharacterTools/CharacterItemList.is_anything_selected() == false:
			if $EditorCharacter/CharacterTools/CharacterItemList.get_item_count() > 0:
				$EditorCharacter._on_ItemList_item_selected(0)
				$EditorCharacter/CharacterTools/CharacterItemList.select(0)

	elif tab == 'Theme':
		$ToolBar/ThemeButton.set('self_modulate', Color('#6a9dea'))
		$EditorTheme.visible = true
	
	elif tab == 'Glossary':
		$ToolBar/GlossaryButton.set('self_modulate', Color('#6a9dea'))
		$EditorGlossary.visible = true
		
	current_editor_view = tab


# Auto saving
func _on_AutoSaver_timeout() -> void:
	if current_editor_view == 'Timeline':
		if autosaving_hash != $EditorTimeline.generate_save_data().hash():
			$EditorTimeline.save_timeline(working_dialog_file)
			dprint('[!] Timeline changes detected. Saving: ' + str(autosaving_hash))
	if current_editor_view == 'Characters':
		if $EditorCharacter.opened_character_data:
			if DialogicUtil.compare_dicts($EditorCharacter.opened_character_data, $EditorCharacter.generate_character_data_to_save()) == false:
				dprint('[!] Character changes detected. Saving')
				$EditorCharacter.save_current_character()
	# I'm trying a different approach on the glossary.


func manual_save() -> void:
	if current_editor_view == 'Timeline':
		$EditorTimeline.save_timeline(working_dialog_file)
		dprint('[!] Saving: ' + str(working_dialog_file))


func _on_Logo_gui_input(event) -> void:
	# I should probably replace this with an "About Dialogic" dialog
	if event is InputEventMouseButton and event.button_index == 1:
		OS.shell_open("https://github.com/coppolaemilio/dialogic")


func dprint(what) -> void:
	if debug_mode:
		print(what)


func _docs_button() -> void:
	OS.shell_open("https://dialogic.coppolaemilio.com")
