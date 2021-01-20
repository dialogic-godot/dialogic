tool
extends Control

var plugin_reference

var undo_redo: UndoRedo

var debug_mode = true # For printing info

var editor_file_dialog # EditorFileDialog
var file_picker_data = {'method': '', 'node': self}

var version_string = "0.9"
var timeline_name = "" # The currently opened timeline name (for saving)

var current_editor_view = 'Timeline'

var working_dialog_file = ''
var timer_duration = 200
var timer_interval = 30
var autosaving_hash
var timeline_path = "EditorTimeline/TimelineEditor/TimelineArea/TimeLine"
var dialog_list_path = "EditorTimeline/EventTools/VBoxContainer2/DialogItemList"
onready var events_warning = $EditorTimeline/TimelineEditor/ScrollContainer/EventContainer/EventsWarning

func _ready():
	# Adding file dialog to get used by pieces
	editor_file_dialog = EditorFileDialog.new()
	add_child(editor_file_dialog)
	
	refresh_timeline_list()
	
	$HBoxContainer/EventButton.set('self_modulate', Color('#6a9dea'))

	$EditorCharacter.editor_reference = self
	$EditorCharacter.refresh_character_list()
	
	$EditorTheme.editor_reference = self
	$EditorGlossary.editor_reference = self

	# Making the dialog editor the default
	change_tab('Timeline')
	_on_EventButton_pressed()


func _process(delta):
	timer_interval -= 1
	if timer_interval < 0 :
		timer_interval = timer_duration
		_on_AutoSaver_timeout()


# Creating text node
func _on_ButtonText_pressed():
	create_event("TextBlock", {'character': '', 'text': '', 'portrait': ''}, true)


func _on_ButtonBackground_pressed():
	create_event("SceneBlock", {'background': ''}, true)


func _on_ButtonCharacter_pressed():
	create_event("CharacterJoinBlock", {
			'position': {"0":false,"1":false,"2":false,"3":false,"4":false},
			'character': '',
			'action': 'join',
		}, true)


func _on_ButtonChoice_pressed():
	create_event("Choice", {'choice': ''}, true)


func _on_ButtonEndChoice_pressed():
	create_event("EndChoice", {'endchoice': ''}, true)


func _on_ButtonCondition_pressed():
	create_event("IfCondition", {'condition': ''}, true)


func _on_ButtonCharacterLeave_pressed():
	create_event("CharacterLeaveBlock", {'action': 'leaveall','character': '[All]'}, true)


func _on_ButtonAudio_pressed():
	create_event("AudioBlock", {'audio':'play', 'file': ''}, true)


func _on_ButtonCloseDialog_pressed():
	create_event("CloseDialog", {'close_dialog': ''}, true)


func _on_ButtonChangeTimeline_pressed():
	create_event("ChangeTimeline", {'change_timeline': ''})


func _on_ButtonEmitSignal_pressed():
	create_event("EmitSignal", {'emit_signal': ''})


func _on_ButtonChangeScene_pressed():
	create_event("ChangeScene", {'change_scene': ''})


func _on_ButtonEndBranch_pressed():
	pass # Replace with function body.


func _on_ButtonQuestion_pressed():
	create_event("Question", {'question': '', 'options': []}, true)
	create_event("Choice", {'choice': ''}, true)
	create_event("Choice", {'choice': ''}, true)
	create_event("EndChoice", {'endchoice': ''}, true)


func create_event(scene, data, indent_on_create = false):
	var piece = load("res://addons/dialogic/Editor/Pieces/" + scene + ".tscn").instance()
	piece.editor_reference = self
	get_node(timeline_path).add_child(piece)
	piece.load_data(data)
	events_warning.visible = false
	if indent_on_create:
		indent_events()
	return piece


# ordering blocks in timeline
func _move_block(block, direction):
	var block_index = block.get_index()
	if direction == 'up':
		if block_index > 0:
			get_node(timeline_path).move_child(block, block_index - 1)
			return true
	if direction == 'down':
		get_node(timeline_path).move_child(block, block_index + 1)
		return true
	return false


# Clear timeline
func clear_timeline():
	for event in get_node(timeline_path).get_children():
		event.free()


# Reload button
func _on_ReloadResource_pressed():
	clear_timeline()
	load_timeline(working_dialog_file)
	dprint('[!] Reloaded -----')


# Saving and loading
func generate_save_data():
	var info_to_save = {
		'metadata': {
			'dialogic-version': version_string,
			'name': timeline_name,
		},
		'events': []
	}
	for event in get_node(timeline_path).get_children():
		info_to_save['events'].append(event.event_data)
	return info_to_save


func save_timeline(path):
	dprint('Saving resource --------')
	var info_to_save = generate_save_data()
	var file = File.new()
	file.open(path, File.WRITE)
	file.store_line(to_json(info_to_save))
	file.close()
	autosaving_hash = info_to_save.hash()


func load_timeline(path):
	var start_time = OS.get_ticks_msec()
	working_dialog_file = path
	# Making editor visible
	$EditorTimeline/TimelineEditor.visible = true
	$EditorTimeline/CenterContainer.visible = false
	
	var data = DialogicUtil.load_json(path)
	if data['metadata'].has('name'):
		timeline_name = data['metadata']['name']
	data = data['events']
	for i in data:
		match i:
			{'text', 'character', 'portrait'}:
				create_event("TextBlock", i)
			{'background'}:
				create_event("SceneBlock", i)
			{'character', 'action', 'position'}:
				create_event("CharacterJoinBlock", i)
			{'audio', 'file'}:
				create_event("AudioBlock", i)
			{'question', 'options'}:
				create_event("Question", i)
			{'choice'}:
				create_event("Choice", i)
			{'endchoice'}:
				create_event("EndChoice", i)
			{'character', 'action'}:
				create_event("CharacterLeaveBlock", i)
			{'change_timeline'}:
				create_event("ChangeTimeline", i)
			{'emit_signal'}:
				create_event("EmitSignal", i)
			{'change_scene'}:
				create_event("ChangeScene", i)
			{'close_dialog'}:
				create_event("CloseDialog", i)
			{'condition'}:
				create_event("IfCondition", i)

	autosaving_hash = generate_save_data().hash()
	if data.size() < 1:
		events_warning.visible = true
	else:
		events_warning.visible = false
		indent_events()
		fold_all_nodes()
	
	var elapsed_time: float = (OS.get_ticks_msec() - start_time) * 0.001
	dprint("Elapsed time: " + str(elapsed_time))


func indent_events() -> void:
	var indent: int = 0
	var starter: bool = false
	var event_list: Array = get_node(timeline_path).get_children()
	var question_index: int = 0
	var question_indent = {}
	if event_list.size() < 2:
		return
	# Resetting all the indents
	for event in event_list:
		var indent_node = event.get_node("Indent")
		indent_node.visible = false
	# Adding new indents
	for event in event_list:
		if event.event_data.has('question'):
			indent += 1
			starter = true
			question_index += 1
			question_indent[question_index] = indent
		if event.event_data.has('choice'):
			if question_index > 0:
				indent = question_indent[question_index] + 1
				starter = true
		if event.event_data.has('endchoice'):
			indent = question_indent[question_index]
			indent -= 1
			question_index -= 1
			if indent < 0:
				indent = 0

		if indent > 0:
			var indent_node = event.get_node("Indent")
			indent_node.rect_min_size = Vector2(25 * indent, 0)
			indent_node.visible = true
			if starter:
				indent_node.rect_min_size = Vector2(25 * (indent - 1), 0)
				if indent - 1 == 0:
					indent_node.visible = false
				
		starter = false


# Conversation files
func refresh_timeline_list():
	get_node(dialog_list_path).clear()
	var icon = load("res://addons/dialogic/Images/timeline.svg")
	var index = 0
	for c in DialogicUtil.get_timeline_list():
		get_node(dialog_list_path).add_item(c['name'], icon)
		get_node(dialog_list_path).set_item_metadata(index, {'file': c['file'], 'index': index})
		index += 1
	get_node(dialog_list_path).sort_items_by_text()
	if $EditorTimeline/EventTools/VBoxContainer2/DialogItemList.get_item_count() == 0:
		change_tab('Timeline')
		

func _on_DialogItemList_item_selected(index):
	var selected = get_node(dialog_list_path).get_item_text(index)
	var file = get_node(dialog_list_path).get_item_metadata(index)['file']
	clear_timeline()
	load_timeline(DialogicUtil.get_path('TIMELINE_DIR', file))


# Renaming dialogs
func _on_DialogItemList_item_rmb_selected(index, at_position):
	$TimelinePopupMenu.rect_position = get_viewport().get_mouse_position()
	$TimelinePopupMenu.popup()
	timeline_name = get_node(dialog_list_path).get_item_text(index)


func _on_TimelinePopupMenu_id_pressed(id):
	if id == 0: # rename
		popup_rename()
	if id == 1:
		OS.shell_open(ProjectSettings.globalize_path(DialogicUtil.get_path('TIMELINE_DIR')))
	if id == 2:
		var current_id = DialogicUtil.get_filename_from_path(working_dialog_file)
		if current_id != '':
			OS.set_clipboard(current_id)
	if id == 3:
		$RemoveTimelineConfirmation.popup_centered()

func popup_rename():
	$RenameDialog.register_text_enter($RenameDialog/LineEdit)
	$RenameDialog/LineEdit.text = timeline_name
	$RenameDialog.set_as_minsize()
	$RenameDialog.popup_centered()
	$RenameDialog/LineEdit.grab_focus()
	$RenameDialog/LineEdit.select_all()


func _on_RenameDialog_confirmed():
	timeline_name = $RenameDialog/LineEdit.text
	$RenameDialog/LineEdit.text = ''
	save_timeline(working_dialog_file)
	refresh_timeline_list()


func _on_RemoveTimelineConfirmation_confirmed():
	var dir = Directory.new()
	dir.remove(working_dialog_file)
	working_dialog_file = ''
	refresh_timeline_list()
	if $EditorTimeline/EventTools/VBoxContainer2/DialogItemList.get_item_count() != 0:
		_on_DialogItemList_item_selected(0)
		$EditorTimeline/EventTools/VBoxContainer2/DialogItemList.select(0)


# Create timeline
func _on_AddTimelineButton_pressed():
	var file = create_timeline()
	refresh_timeline_list()
	clear_timeline()
	load_timeline(DialogicUtil.get_path('TIMELINE_DIR', file))


func create_timeline():
	var timeline_file = 'timeline-' + str(OS.get_unix_time()) + '.json'
	var timeline = {
		"events": [],
		"metadata":{"dialogic-version": version_string}
	}
	var directory = Directory.new()
	if not directory.dir_exists(DialogicUtil.get_path('WORKING_DIR')):
		directory.make_dir(DialogicUtil.get_path('WORKING_DIR'))
	if not directory.dir_exists(DialogicUtil.get_path('TIMELINE_DIR')):
		directory.make_dir(DialogicUtil.get_path('TIMELINE_DIR'))
	var file = File.new()
	file.open(DialogicUtil.get_path('TIMELINE_DIR') + '/' + timeline_file, File.WRITE)
	file.store_line(to_json(timeline))
	file.close()
	return timeline_file


# Character Creations
func get_character_data(file):
	var data = DialogicUtil.load_json(DialogicUtil.get_path('CHAR_DIR', file))
	return data


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


# Folding
func fold_all_nodes():
	for event in get_node(timeline_path).get_children():
		event.get_node("PanelContainer/VBoxContainer/Header/VisibleToggle").set_pressed(false)


func unfold_all_nodes():
	for event in get_node(timeline_path).get_children():
		event.get_node("PanelContainer/VBoxContainer/Header/VisibleToggle").set_pressed(true)


# Toolbar
func _on_ButtonFold_pressed():
	fold_all_nodes()


func _on_ButtonUnfold_pressed():
	unfold_all_nodes()


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
	$HBoxContainer/EventButton.set('self_modulate', Color('#dedede'))
	$HBoxContainer/CharactersButton.set('self_modulate', Color('#dedede'))
	$HBoxContainer/ThemeButton.set('self_modulate', Color('#dedede'))
	$HBoxContainer/GlossaryButton.set('self_modulate', Color('#dedede'))
	$HBoxContainer/FoldTools.visible = false
	$EditorTimeline.visible = false
	$EditorCharacter.visible = false
	$EditorTheme.visible = false
	$EditorGlossary.visible = false
	
	if tab == 'Timeline':
		$HBoxContainer/EventButton.set('self_modulate', Color('#6a9dea'))
		$EditorTimeline.visible = true
		$HBoxContainer/FoldTools.visible = true
		if working_dialog_file == '':
			$EditorTimeline/TimelineEditor.visible = false
			$EditorTimeline/CenterContainer.visible = true
		else:
			$EditorTimeline/TimelineEditor.visible = true
			$EditorTimeline/CenterContainer.visible = false
		
	elif tab == 'Characters':
		$HBoxContainer/CharactersButton.set('self_modulate', Color('#6a9dea'))
		$EditorCharacter.visible = true
		# Select the first character in the list
		if $EditorCharacter/CharacterTools/CharacterItemList.is_anything_selected() == false:
			if $EditorCharacter/CharacterTools/CharacterItemList.get_item_count() > 0:
				$EditorCharacter._on_ItemList_item_selected(0)
				$EditorCharacter/CharacterTools/CharacterItemList.select(0)

	elif tab == 'Theme':
		$HBoxContainer/ThemeButton.set('self_modulate', Color('#6a9dea'))
		$EditorTheme.visible = true
	
	elif tab == 'Glossary':
		$HBoxContainer/GlossaryButton.set('self_modulate', Color('#6a9dea'))
		$EditorGlossary.visible = true
		
	current_editor_view = tab


# Auto saving
func _on_AutoSaver_timeout():
	if current_editor_view == 'Timeline':
		if autosaving_hash != generate_save_data().hash():
			save_timeline(working_dialog_file)
			dprint('[!] Timeline changes detected. Saving: ' + str(autosaving_hash))
	if current_editor_view == 'Characters':
		if $EditorCharacter.opened_character_data:
			if compare_dicts($EditorCharacter.opened_character_data, $EditorCharacter.generate_character_data_to_save()) == false:
				dprint('[!] Character changes detected. Saving')
				$EditorCharacter.save_current_character()
	if current_editor_view == 'Glossary':
		$EditorGlossary.save_glossary()


func _on_Logo_gui_input(event):
	# I should probably replace this with an "About Dialogic" dialog
	if event is InputEventMouseButton and event.button_index == 1:
		OS.shell_open("https://github.com/coppolaemilio/dialogic")


func compare_dicts(dict_1, dict_2):
	# I tried using the .hash() function but it was returning different numbers
	# even when the dictionary was exactly the same.
	if str(dict_1) != "Null" and str(dict_2) != "Null":
		if str(dict_1) == str(dict_2):
			return true
	return false

func dprint(what):
	if debug_mode:
		print(what)



