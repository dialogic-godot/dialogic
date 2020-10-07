tool
extends Control

var plugin_reference

var undo_redo: UndoRedo
var testing_mode = true

var editor_file_dialog # EditorFileDialog
var file_picker_data = {'method': '', 'node': self}

var version_string = "0.5"

var testing = true
var WORKING_DIR = "res://dialogic"
var DIALOG_DIR = WORKING_DIR + "/dialogs"
var CHAR_DIR = WORKING_DIR + "/characters"
var working_dialog_file = ''
var timer_duration = 200
var timer_interval = 30
var autosaving_hash
onready var Timeline = $Editor/TimelineEditor/TimelineArea/TimeLine
onready var DialogList = $Editor/EventTools/VBoxContainer2/DialogItemList
onready var CharacterList = $Editor/CharacterTools/CharacterItemList
onready var CharacterEditor = {
	'editor': $Editor/CharacterEditor/HBoxContainer/Container,
	'name': $Editor/CharacterEditor/HBoxContainer/Container/Name/LineEdit,
	'description': $Editor/CharacterEditor/HBoxContainer/Container/Description/TextEdit,
	'file': $Editor/CharacterEditor/HBoxContainer/Container/FileName/LineEdit,
	'color': $Editor/CharacterEditor/HBoxContainer/Container/Color/ColorPickerButton
}

func _ready():
	if testing_mode == false:
		clear_template_editor()
	if testing == false:
		$Editor/GraphEdit.connect("connection_request", self, "_on_piece_connect")
	
	# Adding file dialog to get used by pieces
	editor_file_dialog = EditorFileDialog.new()
	#plugin_reference.get_editor_interface().get_editor_viewport().add_child(editor_file_dialog)
	$Editor.visible = true
	$Editor/CharacterEditor/HBoxContainer/Container.visible = false
	
	$HBoxContainer/EventButton.set('self_modulate', Color('#6a9dea'))
	#load_nodes()
	# Refreshing the list of items
	refresh_character_list()
	refresh_dialog_list()
	# Making the dialog editor the default
	hide_editors()
	_on_EventButton_pressed()

func _process(delta):
	timer_interval -= 1
	if timer_interval < 0 :
		timer_interval = timer_duration
		_on_AutoSaver_timeout()
	
func _on_piece_connect(from, from_slot, to, to_slot):
	$Editor/GraphEdit.connect_node(from, from_slot, to, to_slot)

func clear_template_editor():
	$Editor.visible = false
	$EmptyMessage.visible = true

# Creating text node
func _on_ButtonText_pressed():
	create_text_node({'character': '', 'text': ''})
	return true

func _on_ButtonBackground_pressed():
	create_scene_node()

func _on_ButtonCharacter_pressed():
	create_character_join_node({'position': {"0":false,"1":false,"2":false,"3":false,"4":false}, 'character': '', 'action': 'join'})

func _on_ButtonCharacterLeave_pressed():
	create_character_leave_node({'action': 'leaveall','character': '[All]'})

func _on_ButtonAudio_pressed():
	create_audio_node('')

func create_text_node(data):
	var piece = load("res://addons/dialogic/Editor/Pieces/TextBlock.tscn").instance()
	piece.editor_reference = self
	Timeline.add_child(piece)
	piece.load_data(data)
	return piece

func create_scene_node(path=''):
	var piece = load("res://addons/dialogic/Editor/Pieces/SceneBlock.tscn").instance()
	piece.load_image(path)
	piece.editor_reference = self
	Timeline.add_child(piece)
	return piece

func create_character_join_node(data):
	var piece = load("res://addons/dialogic/Editor/Pieces/CharacterJoinBlock.tscn").instance()
	piece.editor_reference = self	
	Timeline.add_child(piece)
	piece.load_data(data)
	return piece

func create_character_leave_node(data):
	var piece = load("res://addons/dialogic/Editor/Pieces/CharacterLeaveBlock.tscn").instance()
	piece.editor_reference = self
	Timeline.add_child(piece)
	piece.load_data(data)
	return piece

func create_audio_node(data):
	var piece = load("res://addons/dialogic/Editor/Pieces/AudioBlock.tscn").instance()
	piece.editor_reference = self
	Timeline.add_child(piece)
	piece.load_data(data)
	return piece

# ordering blocks in timeline
func _move_block(block, direction):
	var block_index = block.get_index()
	if direction == 'up':
		if block_index > 0:	
			Timeline.move_child(block, block_index - 1)
			return true
	if direction == 'down':
		Timeline.move_child(block, block_index + 1)
		return true
	print('[!] Failed to move block ', block)
	return false

# Clear timeline
func clear_timeline():
	for event in Timeline.get_children():
		event.queue_free()

# Reload button
func _on_ReloadResource_pressed():
	clear_timeline()
	load_nodes(working_dialog_file)
	print('[!] Reloaded -----')

# Saving and loading
func _on_ButtonSave_pressed():
	save_nodes(working_dialog_file)

func generate_save_data():
	var info_to_save = {
		'metadata': {
			'dialogic-version': '0.4'
		},
		'events': []
	}
	for event in Timeline.get_children():
		info_to_save['events'].append(event.event_data)
	return info_to_save

func save_nodes(path):
	print('Saving resource --------')
	var info_to_save = generate_save_data()
	var file = File.new()
	file.open(path, File.WRITE)
	file.store_line(to_json(info_to_save))
	file.close()
	autosaving_hash = info_to_save.hash()
	
func load_nodes(path):
	working_dialog_file = path
	
	var data = load_json(path)
	data = data['events']
	for i in data:
		match i:
			{'text'}:
				create_text_node(i)
				print('text-element: ', i)
			{'text', 'character'}:
				create_text_node(i)
				print('text-element: ', i)
			
			{'background'}:
				create_scene_node(i['background'])
				print('background-element: ', i)
				
			{'character', 'action', 'position'}:
				create_character_join_node(i)
				print('character-join-element: ', i)
			
			{'audio', 'file'}:
				create_audio_node(i)
				print('audio-block: ', i)
			
			{'character', 'action'}:
				create_character_leave_node(i)
				print('character-leave-block: ', i)
	
	autosaving_hash = generate_save_data().hash()
	fold_all_nodes()

# Conversation files
func get_dialog_list():
	var dialogs = []
	for file in listdir(DIALOG_DIR):
		if '.json' in file:
			var color = Color("#ffffff")
			dialogs.append({'name':file.split('.')[0], 'color': color, 'file': file })
			#var data = load_json(DIALOG_DIR + '/' + file)
			#if data.has('color'):
			#	color = Color('#' + data['color'])
			#if data.has('name'):
			#	characters.append({'name':data['name'], 'color': color, 'file': file })
			#else:
			#	characters.append({'name':data['id'], 'color': color, 'file': file })
	return dialogs

func refresh_dialog_list():
	DialogList.clear()
	var icon = load("res://addons/dialogic/Images/timeline.svg")
	var index = 0
	for c in get_dialog_list():
		DialogList.add_item(c['name'], icon)
		DialogList.set_item_metadata(index, {'file': c['file'], 'index': index})
		index += 1

func _on_DialogItemList_item_selected(index):
	var selected = DialogList.get_item_text(index)
	var file = DialogList.get_item_metadata(index)['file']
	clear_timeline()
	load_nodes(DIALOG_DIR + '/' + file)

# Renaming dialogs

func _on_DialogItemList_item_rmb_selected(index, at_position):
	print(index)
	$RenameDialog.register_text_enter($RenameDialog/LineEdit)
	$RenameDialog/LineEdit.text = get_filename_from_path(working_dialog_file)
	$RenameDialog.set_as_minsize()
	$RenameDialog.popup_centered()

func _on_RenameDialog_confirmed():
	var new_name = $RenameDialog/LineEdit.text + '.json'
	var dir = Directory.new()
	var new_full_path = DIALOG_DIR + '/' + new_name
	dir.rename(working_dialog_file, new_full_path)
	working_dialog_file = new_full_path
	$RenameDialog/LineEdit.text = ''
	refresh_dialog_list()

# Create timeline
func _on_AddTimelineButton_pressed():
	var file = create_timeline()
	refresh_dialog_list()
	#for i in range(CharacterList.get_item_count()):
	#	if CharacterList.get_item_metadata(i)['file'] == file:
	#		CharacterList.select(i)
	#		_on_ItemList_item_selected(i)

func create_timeline():
	var timeline_file = 'timeline-' + str(OS.get_unix_time()) + '.json'
	var timeline = {
		"events": [],
		"metadata":{"dialogic-version": version_string}
	}
	var directory = Directory.new()
	if not directory.dir_exists(WORKING_DIR):
		directory.make_dir(WORKING_DIR)
	if not directory.dir_exists(DIALOG_DIR):
		directory.make_dir(DIALOG_DIR)
	var file = File.new()
	file.open(DIALOG_DIR + '/' + timeline_file, File.WRITE)
	file.store_line(to_json(timeline))
	file.close()
	return timeline_file

# Character Creation
func _on_Button_pressed():
	var file = create_character()
	refresh_character_list()
	for i in range(CharacterList.get_item_count()):
		if CharacterList.get_item_metadata(i)['file'] == file:
			CharacterList.select(i)
			_on_ItemList_item_selected(i)

func create_character():
	var character_file = 'character-' + str(OS.get_unix_time()) + '.json'
	var character = {
		'color': 'ffffff',
		'id': character_file
	}
	var directory = Directory.new()
	if not directory.dir_exists(WORKING_DIR):
		directory.make_dir(WORKING_DIR)
	if not directory.dir_exists(CHAR_DIR):
		directory.make_dir(CHAR_DIR)
	var file = File.new()
	file.open(CHAR_DIR + '/' + character_file, File.WRITE)
	file.store_line(to_json(character))
	file.close()
	return character_file

func get_character_list():
	var characters = []
	for file in listdir(CHAR_DIR):
		var data = load_json(CHAR_DIR + '/' + file)
		var color = Color("#ffffff")
		if data.has('color'):
			color = Color('#' + data['color'])
		if data.has('name'):
			characters.append({'name':data['name'], 'color': color, 'file': file })
		else:
			characters.append({'name':data['id'], 'color': color, 'file': file })
	return characters

func refresh_character_list():
	CharacterList.clear()
	var icon = load("res://addons/dialogic/Images/character.svg")
	var index = 0
	for c in get_character_list():
		CharacterList.add_item(c['name'], icon)
		CharacterList.set_item_metadata(index, {'file': c['file'], 'index': index})
		CharacterList.set_item_icon_modulate(index, c['color'])
		index += 1

func _on_ItemList_item_selected(index):
	var selected = CharacterList.get_item_text(index)
	var file = CharacterList.get_item_metadata(index)['file']
	var data = load_json(CHAR_DIR + '/' + file)
	$Editor/CharacterEditor/HBoxContainer/Container.visible = true
	load_character_editor(data)

func load_character_editor(data):
	clear_character_editor()
	CharacterEditor['file'].text = data['id']
	if data.has('name'):
		CharacterEditor['name'].text = data['name']
	if data.has('description'):
		CharacterEditor['description'].text = data['description']
	if data.has('color'):
		CharacterEditor['color'].color = Color('#' + data['color'])

func _on_character_SaveButton_pressed():
	var path = CHAR_DIR + '/' + CharacterEditor['file'].text
	var info_to_save = {
		'name': CharacterEditor['name'].text,
		'id': CharacterEditor['file'].text,
		'description': CharacterEditor['description'].text,
		'color': CharacterEditor['color'].color.to_html()
	}
	var file = File.new()
	file.open(path, File.WRITE)
	file.store_line(to_json(info_to_save))
	file.close()
	refresh_character_list()

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

func clear_character_editor():
	CharacterEditor['file'].text = ''
	CharacterEditor['name'].text = ''
	CharacterEditor['description'].text = ''
	CharacterEditor['color'].color = Color('#ffffff')

func _on_RemoveConfirmation_confirmed():
	print('remove')
	var selected = CharacterList.get_selected_items()[0]
	var file = CharacterList.get_item_metadata(selected)['file']
	print('Remove ', CharacterList.get_item_metadata(selected)['file'])
	var dir = Directory.new()
	dir.remove(CHAR_DIR + '/' + file)
	$Editor/CharacterEditor/HBoxContainer/Container.visible = false
	clear_character_editor()
	refresh_character_list()

func _on_DeleteButton_pressed():
	$RemoveConfirmation.popup_centered()

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
		return
	var data_text = file.get_as_text()
	file.close()
	var data_parse = JSON.parse(data_text)
	if data_parse.error != OK:
		return
	return data_parse.result

func get_filename_from_path(path):
	if OS.get_name() == "Windows":
		return path.split('/')[-1].replace('.json', '')
	else:
		return path.split('\\')[-1].replace('.json', '')

# Godot dialog
func godot_dialog():
	editor_file_dialog.mode = EditorFileDialog.MODE_OPEN_FILE
	editor_file_dialog.clear_filters()
	editor_file_dialog.popup_centered_ratio(0.75)
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
	for event in Timeline.get_children():
		event.get_node("VBoxContainer/Header/VisibleToggle").set_pressed(false)

func unfold_all_nodes():
	for event in Timeline.get_children():
		event.get_node("VBoxContainer/Header/VisibleToggle").set_pressed(true)

func _on_ButtonFold_pressed():
	fold_all_nodes()

func _on_ButtonUnfold_pressed():
	unfold_all_nodes()

func hide_editors():
	$HBoxContainer/EventButton.set('self_modulate', Color('#dedede'))
	$HBoxContainer/CharactersButton.set('self_modulate', Color('#dedede'))
	for n in $Editor.get_children():
		n.visible = false

func _on_EventButton_pressed():
	hide_editors()
	$Editor/EventTools.visible = true
	$Editor/TimelineEditor.visible = true
	$HBoxContainer/EventButton.set('self_modulate', Color('#6a9dea'))

func _on_CharactersButton_pressed():
	hide_editors()
	$Editor/CharacterTools.visible = true
	$Editor/CharacterEditor.visible = true
	$HBoxContainer/CharactersButton.set('self_modulate', Color('#6a9dea'))

# Auto saving

func _on_AutoSaver_timeout():
	if autosaving_hash != generate_save_data().hash():
		save_nodes(working_dialog_file)
		print('[!] Changes detected. Auto saving. ', autosaving_hash)

func _on_Logo_gui_input(event):
	# I should probably replace this with an "About Dialogic" dialog
	if event is InputEventMouseButton and event.button_index == 1:
		OS.shell_open("https://github.com/coppolaemilio/dialogic")
