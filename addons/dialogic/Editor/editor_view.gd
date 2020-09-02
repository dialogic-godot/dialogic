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
onready var Timeline = $Editor/ScrollContainer/TimeLine

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
	
func _on_piece_connect(from, from_slot, to, to_slot):
	$Editor/GraphEdit.connect_node(from, from_slot, to, to_slot)

func clear_template_editor():
	$Editor.visible = false
	$EmptyMessage.visible = true

# Creating text node
func _on_ButtonText_pressed():
	create_text_node()
	return true

func _on_ButtonBackground_pressed():
	create_scene_node()

func _on_ButtonCharacter_pressed():
	create_character_join_node('')

func _on_ButtonCharacterLeave_pressed():
	create_character_leave_node('')

func create_text_node(text=''):
	var piece = load("res://addons/dialogic/Editor/Pieces/TextBlock.tscn").instance()
	Timeline.add_child(piece)
	piece.load_text(text)
	piece.editor_reference = self
	return piece

func create_scene_node(path=''):
	var piece = load("res://addons/dialogic/Editor/Pieces/SceneBlock.tscn").instance()
	Timeline.add_child(piece)
	piece.load_image(path)
	piece.editor_reference = self
	return piece

func create_character_join_node(character='', action='join', joining_position = 0, clear_all=false):
	var piece = load("res://addons/dialogic/Editor/Pieces/CharacterJoinBlock.tscn").instance()
	Timeline.add_child(piece)
	piece.load_character_position(joining_position)
	piece.editor_reference = self
	return piece

func create_character_leave_node(character='', action='leave', joining_position = 0, clear_all=false):
	var piece = load("res://addons/dialogic/Editor/Pieces/CharacterLeaveBlock.tscn").instance()
	Timeline.add_child(piece)
	piece.editor_reference = self
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
	
	var file 
	file = File.new()
	file.open(path, File.WRITE)
	file.store_line(to_json(info_to_save))
	file.close()

	print(info_to_save)
	
func load_nodes(path):
	# Json
	var data_file = File.new()
	var data_file_path = path
	if data_file.open(data_file_path, File.READ) != OK:
		return
	var data_text = data_file.get_as_text()
	data_file.close()
	var data_parse = JSON.parse(data_text)
	if data_parse.error != OK:
		return
	var data = data_parse.result

	for i in data:
		match i:
			{'text'}:
				create_text_node(i['text'])
				print('text-element: ', i)
			{'text', 'character'}:
				create_text_node(i['text'])
				print('text-element: ', i)
			{'background'}:
				create_scene_node(i['background'])
				print('background-element: ', i)
				
			{'character', 'action', 'position'}:
				create_character_join_node(i['character'], i['action'],i['position'])
				print('character-join-element: ', i)
			
			{'character', 'action'}:
				create_character_leave_node(i['character'], i['action'])
				print('character-leave-block: ', i)
	fold_all_nodes()

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
