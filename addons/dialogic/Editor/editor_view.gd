tool
#class_name DialogGraphEditorView
extends Control

"""
The graph editor shown in the bottom panel. When a DialogNode is selected, its DialogResource
is added as a child of the main editor view so it's editable by the user and removed (but not
deleted) when the DialogGraph is deselected.
"""
var plugin_reference

var undo_redo: UndoRedo
var testing_mode = true
var editor_file_dialog # EditorFileDialog
var testing = true
var WORKING_DIR = "res://dialogic"
var CHAR_DIR = WORKING_DIR + "/characters"
onready var Timeline = $Editor/EventEditor/TimeLine

func _ready():
	if testing_mode == false:
		clear_template_editor()
	if testing == false:
		$Editor/GraphEdit.connect("connection_request", self, "_on_piece_connect")
	
	# Adding file dialog to get used by pieces
	editor_file_dialog = EditorFileDialog.new()
	plugin_reference.get_editor_interface().get_editor_viewport().add_child(editor_file_dialog)
	$Editor.visible = true
	load_nodes("res://addons/dialogic/demo/example.json")
	refresh_character_list()
	
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
	create_character_join_node('')

func _on_ButtonCharacterLeave_pressed():
	create_character_leave_node('')

func _on_ButtonAudio_pressed():
	create_audio_node('')

func create_text_node(data):
	var piece = load("res://addons/dialogic/Editor/Pieces/TextBlock.tscn").instance()
	piece.load_data(data)
	piece.editor_reference = self
	Timeline.add_child(piece)
	return piece

func create_scene_node(path=''):
	var piece = load("res://addons/dialogic/Editor/Pieces/SceneBlock.tscn").instance()
	piece.load_image(path)
	piece.editor_reference = self
	Timeline.add_child(piece)
	return piece

func create_character_join_node(character='', action='join', joining_position = 0, clear_all=false):
	var piece = load("res://addons/dialogic/Editor/Pieces/CharacterJoinBlock.tscn").instance()
	piece.load_character_position(joining_position)
	piece.editor_reference = self
	Timeline.add_child(piece)
	return piece

func create_character_leave_node(character='', action='leave', joining_position = 0, clear_all=false):
	var piece = load("res://addons/dialogic/Editor/Pieces/CharacterLeaveBlock.tscn").instance()
	piece.editor_reference = self
	Timeline.add_child(piece)
	return piece

func create_audio_node(audio='', file=''):
	var piece = load("res://addons/dialogic/Editor/Pieces/AudioBlock.tscn").instance()
	piece.editor_reference = self
	Timeline.add_child(piece)
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
	load_nodes("res://addons/dialogic/demo/example.json")
	print('Reloaded')

# Saving and loading
func _on_ButtonSave_pressed():
	save_nodes("res://addons/dialogic/demo/example.json")

func save_nodes(path):
	print('Saving resource --------')
	var info_to_save = []
	for event in Timeline.get_children():
		info_to_save.append(event.event_data)
	
	var file = File.new()
	file.open(path, File.WRITE)
	file.store_line(to_json(info_to_save))
	file.close()

	print(info_to_save)
	
func load_nodes(path):
	var data = load_json(path)

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
				create_character_join_node(i['character'], i['action'],i['position'])
				print('character-join-element: ', i)
			
			{'audio', 'file'}:
				create_audio_node(i['audio'], i['file'])
				print('audio-block: ', i)
			
			{'character', 'action'}:
				create_character_leave_node(i['character'], i['action'])
				print('character-leave-block: ', i)
	fold_all_nodes()

# Character Creation
func _on_Button_pressed():
	create_character()
	refresh_character_list()
	
func create_character():
	var character_file = 'character-' + str(rand_range(1000,9999)) + '-' + str(OS.get_unix_time()) + '.json'
	var character = {
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

func get_character_list():
	var characters = []
	for file in listdir(CHAR_DIR):
		var data = load_json(CHAR_DIR + '/' + file)
		if data.has('name'):
			characters.append(data['name'])
		else:
			characters.append(data['id'])
	return characters

func refresh_character_list():
	var CharacterList = $Editor/CharacterTools/CharacterList/ItemList
	CharacterList.clear()
	var icon = load("res://addons/dialogic/Images/character.svg")
	for c in get_character_list():
		CharacterList.add_item(c, icon)

func _on_ItemList_item_selected(index):
	var selected = $Editor/CharacterTools/CharacterList/ItemList.get_item_text(index)
	for file in listdir(CHAR_DIR):
		var data = load_json(CHAR_DIR + '/' + file)
		if data['id'] == selected:
			load_character_editor(CHAR_DIR + '/' + file)
		else:
			if data.has('name'):
				if data['name'] == selected:
					load_character_editor(CHAR_DIR + '/' + file)

func load_character_editor(path):
	var data = load_json(path)
	print(data)
	$Editor/CharacterEditor/TimeLine/FileName/LineEdit.text = data['id']
	if data.has('name'):
		$Editor/CharacterEditor/TimeLine/Name/LineEdit.text = data['name']
	else:
		$Editor/CharacterEditor/TimeLine/Name/LineEdit.text = ''

func _on_character_SaveButton_pressed():
	var path = CHAR_DIR + '/' + $Editor/CharacterEditor/TimeLine/FileName/LineEdit.text
	var info_to_save = {
		'name': $Editor/CharacterEditor/TimeLine/Name/LineEdit.text,
		'id': $Editor/CharacterEditor/TimeLine/FileName/LineEdit.text
	}
	var file = File.new()
	file.open(path, File.WRITE)
	file.store_line(to_json(info_to_save))
	file.close()
	refresh_character_list()

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

# Godot dialog
func godot_dialog():
	editor_file_dialog.mode = EditorFileDialog.MODE_OPEN_FILE
	editor_file_dialog.clear_filters()
	editor_file_dialog.popup_centered_ratio(0.75)
	
	return editor_file_dialog

func _on_file_selected(path):
	print(path)

# Folding
func fold_all_nodes():
	for event in Timeline.get_children():
		event.get_node("VBoxContainer/Header/VisibleToggle").set_pressed(false)

func unfold_all_nodes():
	for event in Timeline.get_children():
		event.get_node("VBoxContainer/Header/VisibleToggle").set_pressed(true)
		print(event.get_node("VBoxContainer/Header/VisibleToggle"))

func _on_ButtonFold_pressed():
	fold_all_nodes()

func _on_ButtonUnfold_pressed():
	unfold_all_nodes()

func hide_editors():
	for n in $Editor.get_children():
		n.visible = false

func _on_EventButton_pressed():
	hide_editors()
	$Editor/EventTools.visible = true
	$Editor/EventEditor.visible = true

func _on_CharactersButton_pressed():
	hide_editors()
	$Editor/CharacterTools.visible = true
	$Editor/CharacterEditor.visible = true
