tool
extends Control

var plugin_reference

var undo_redo: UndoRedo

var editor_file_dialog # EditorFileDialog
var file_picker_data = {'method': '', 'node': self}

var version_string = "0.7"
var timeline_name = "" # The currently opened timeline name (for saving)

var current_editor_view = 'Timeline'

var WORKING_DIR = "res://dialogic"
var TIMELINE_DIR = WORKING_DIR + "/dialogs"
var CHAR_DIR = WORKING_DIR + "/characters"
var working_dialog_file = ''
var timer_duration = 200
var timer_interval = 30
var autosaving_hash
var timeline_path = "EditorTimeline/TimelineEditor/TimelineArea/TimeLine"
var dialog_list_path = "EditorTimeline/EventTools/VBoxContainer2/DialogItemList"


func _ready():
	# Adding file dialog to get used by pieces
	editor_file_dialog = EditorFileDialog.new()
	add_child(editor_file_dialog)
	
	refresh_timeline_list()
	
	$HBoxContainer/EventButton.set('self_modulate', Color('#6a9dea'))

	$EditorCharacter.editor_reference = self
	$EditorCharacter.refresh_character_list()
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


func _on_ButtonChangeTimeline_pressed():
	create_event("ChangeTimeline", {'change_timeline': ''})


func create_event(scene, data, indent_on_create = false):
	var piece = load("res://addons/dialogic/Editor/Pieces/" + scene + ".tscn").instance()
	piece.editor_reference = self
	get_node(timeline_path).add_child(piece)
	piece.load_data(data)
	$EditorTimeline/TimelineEditor/NoEventsOnTimeline.visible = false
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
	print('[!] Reloaded -----')


# Saving and loading
func _on_ButtonSave_pressed():
	save_timeline(working_dialog_file)


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
	print('Saving resource --------')
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
	
	var data = load_json(path)
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
			{'choice'}:
				create_event("Choice", i)
			{'endchoice'}:
				create_event("EndChoice", i)
			{'character', 'action'}:
				create_event("CharacterLeaveBlock", i)
			{'change_timeline'}:
				create_event("ChangeTimeline", i)
			{'condition'}:
				create_event("IfCondition", i)

	autosaving_hash = generate_save_data().hash()
	if data.size() < 1:
		$EditorTimeline/TimelineEditor/NoEventsOnTimeline.visible = true
	else:
		$EditorTimeline/TimelineEditor/NoEventsOnTimeline.visible = false
		indent_events()
		fold_all_nodes()
	
	var elapsed_time: float = (OS.get_ticks_msec() - start_time) * 0.001
	print("Elapsed time: ", elapsed_time)


func indent_events():
	var indent = 0
	var starter = false
	var event_list = get_node(timeline_path).get_children()
	if event_list.size() < 2:
		return
	# Resetting all the indents
	for event in event_list:
		var indent_node = event.get_node("Indent")
		indent_node.visible = false
	# Adding new indents
	for event in event_list:
		if event.event_data.has('choice') or event.event_data.has('condition'):
			indent += 1
			starter = true
		if event.event_data.has('endchoice'):
			indent -= 1
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
func get_timeline_list():
	var timelines = []
	for file in listdir(TIMELINE_DIR):
		if '.json' in file:
			var data = load_json(TIMELINE_DIR + '/' + file)
			var metadata = data['metadata']
			var color = Color("#ffffff")
			if metadata.has('name'):
				timelines.append({'name':metadata['name'], 'color': color, 'file': file })
			else:
				timelines.append({'name':file.split('.')[0], 'color': color, 'file': file })
	return timelines


func refresh_timeline_list():
	get_node(dialog_list_path).clear()
	var icon = load("res://addons/dialogic/Images/timeline.svg")
	var index = 0
	for c in get_timeline_list():
		get_node(dialog_list_path).add_item(c['name'], icon)
		get_node(dialog_list_path).set_item_metadata(index, {'file': c['file'], 'index': index})
		index += 1
	get_node(dialog_list_path).sort_items_by_text()
	# TODO if there are no elements on the list, show welcome screen again

func _on_DialogItemList_item_selected(index):
	var selected = get_node(dialog_list_path).get_item_text(index)
	var file = get_node(dialog_list_path).get_item_metadata(index)['file']
	clear_timeline()
	load_timeline(TIMELINE_DIR + '/' + file)


# Renaming dialogs
func _on_DialogItemList_item_rmb_selected(index, at_position):
	$TimelinePopupMenu.rect_position = get_viewport().get_mouse_position()
	$TimelinePopupMenu.popup()
	timeline_name = get_node(dialog_list_path).get_item_text(index)


func _on_TimelinePopupMenu_id_pressed(id):
	if id == 0: # rename
		popup_rename()
	if id == 1:
		OS.shell_open(ProjectSettings.globalize_path(TIMELINE_DIR))
	if id == 2:
		var current_id = get_filename_from_path(working_dialog_file)
		if current_id != '':
			OS.set_clipboard(current_id)
	if id == 3:
		$RemoveTimelineConfirmation.popup_centered()

func popup_rename():
	$RenameDialog.register_text_enter($RenameDialog/LineEdit)
	$RenameDialog/LineEdit.text = timeline_name
	$RenameDialog.set_as_minsize()
	$RenameDialog.popup_centered()


func _on_RenameDialog_confirmed():
	timeline_name = $RenameDialog/LineEdit.text
	$RenameDialog/LineEdit.text = ''
	save_timeline(working_dialog_file)
	refresh_timeline_list()


func _on_RemoveTimelineConfirmation_confirmed():
	var dir = Directory.new()
	dir.remove(working_dialog_file)
	refresh_timeline_list()
	# TODO Handle errors if there are no more elements in the list. This should go in the refresh_timeline_list() function probably
	if $EditorTimeline/EventTools/VBoxContainer2/DialogItemList.get_item_count() != 1:
		_on_DialogItemList_item_selected(0)
		$EditorTimeline/EventTools/VBoxContainer2/DialogItemList.select(0)
		print($EditorTimeline/EventTools/VBoxContainer2/DialogItemList.get_item_count())


# Create timeline
func _on_AddTimelineButton_pressed():
	var file = create_timeline()
	refresh_timeline_list()
	clear_timeline()
	load_timeline(TIMELINE_DIR + '/' + file)


func create_timeline():
	var timeline_file = 'timeline-' + str(OS.get_unix_time()) + '.json'
	var timeline = {
		"events": [],
		"metadata":{"dialogic-version": version_string}
	}
	var directory = Directory.new()
	if not directory.dir_exists(WORKING_DIR):
		directory.make_dir(WORKING_DIR)
	if not directory.dir_exists(TIMELINE_DIR):
		directory.make_dir(TIMELINE_DIR)
	var file = File.new()
	file.open(TIMELINE_DIR + '/' + timeline_file, File.WRITE)
	file.store_line(to_json(timeline))
	file.close()
	return timeline_file


# Character Creation
func get_character_list():
	var characters = []
	for file in listdir(CHAR_DIR):
		if '.json' in file:
			var data = load_json(CHAR_DIR + '/' + file)
			var color = Color("#ffffff")
			var c_name = data['id']
			var default_speaker = 'false'
			var portraits = []
			if data.has('color'):
				color = Color('#' + data['color'])
			if data.has('name'):
				c_name = data['name']
			if data.has('default_speaker'):
				default_speaker = data['default_speaker']
			if data.has('portraits'):
				portraits = data['portraits']
			characters.append({
				'name': c_name,
				'color': color,
				'file': file,
				'default_speaker' : default_speaker,
				'portraits': portraits,
			})

	return characters


func get_character_data(file):
	var data = load_json(CHAR_DIR + '/' + file)
	return data


func get_character_color(file):
	var data = load_json(CHAR_DIR + '/' + file)
	if is_instance_valid(data):
		if data.has('color'):
			return data['color']
	else:
		return "ffffff"


func get_character_name(file):
	var data = load_json(CHAR_DIR + '/' + file)
	if data.has('name'):
		return data['name']


func get_character_portraits(file):
	var data = load_json(CHAR_DIR + '/' + file)
	if data.has('portraits'):
		return data['portraits']


# Generic functions
func listdir(path):
	# https://godotengine.org/qa/5175/how-to-get-all-the-files-inside-a-folder
	var files = []
	var dir = Directory.new()
	dir.open(path)
	dir.list_dir_begin()
	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif not file.begins_with("."):
			files.append(file)
	dir.list_dir_end()
	return files


func load_json(path):
	var file = File.new()
	if file.open(path, File.READ) != OK:
		file.close()
		return
	var data_text = file.get_as_text()
	file.close()
	var data_parse = JSON.parse(data_text)
	if data_parse.error != OK:
		return
	return data_parse.result


func get_filename_from_path(path, extension = false):
	var file_name = path.split('/')[-1]
	if extension == false:
		file_name = file_name.split('.')[0]
	return file_name


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
	print(path)


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


func change_tab(tab):
	# Hiding everything
	$HBoxContainer/EventButton.set('self_modulate', Color('#dedede'))
	$HBoxContainer/CharactersButton.set('self_modulate', Color('#dedede'))
	$HBoxContainer/FoldTools.visible = false
	$EditorTimeline.visible = false
	$EditorCharacter.visible = false
	
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
	
	current_editor_view = tab


# Auto saving
func _on_AutoSaver_timeout():
	if current_editor_view == 'Timeline':
		if autosaving_hash != generate_save_data().hash():
			save_timeline(working_dialog_file)
			print('[!] Timeline changes detected. Saving: ', autosaving_hash)
	if current_editor_view == 'Characters':
		if compare_dicts($EditorCharacter.opened_character_data, $EditorCharacter.generate_character_data_to_save()) == false:
			print('[!] Character changes detected. Saving')
			$EditorCharacter.save_current_character()


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

