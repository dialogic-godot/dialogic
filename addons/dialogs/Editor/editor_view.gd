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
var dialog_selected_node
var editor_file_dialog # EditorFileDialog
var testing = true
onready var timeline = $Editor/ScrollContainer/TimeLine

func _ready():
	if testing_mode == false:
		clear_template_editor()
	if testing == false:
		$Editor/GraphEdit.connect("connection_request", self, "_on_piece_connect")
	
	# Adding file dialog to get used by pieces
	editor_file_dialog = EditorFileDialog.new()
	plugin_reference.get_editor_interface().get_editor_viewport().add_child(editor_file_dialog)
	
func _on_piece_connect(from, from_slot, to, to_slot):
	$Editor/GraphEdit.connect_node(from, from_slot, to, to_slot)

func enable_template_editor_for(node: DialogNode):
	if not node:
		return
	dialog_selected_node = node
	$Editor.visible = true
	$EmptyMessage.visible = false
	load_nodes()

func clear_template_editor():
	print('here111')
	$Editor.visible = false
	$EmptyMessage.visible = true


# Creating text node
func _on_ButtonText_pressed():
	create_text_node()
	return true

func _on_ButtonBackground_pressed():
	create_scene_node()

func _on_ButtonCharacter_pressed():
	create_character_node('', '')

func create_text_node(text=''):
	var piece = load("res://addons/dialogs/Editor/Pieces/TextBlock.tscn").instance()
	timeline.add_child(piece)
	piece.load_text(text)
	piece.editor_reference = self
	return piece

func create_scene_node(path=''):
	var piece = load("res://addons/dialogs/Editor/Pieces/SceneBlock.tscn").instance()
	timeline.add_child(piece)
	piece.load_image(path)
	piece.editor_reference = self
	return piece

func create_character_node(character, action, joining_position = 0, clear_all=false):
	var piece = load("res://addons/dialogs/Editor/Pieces/CharacterBlock.tscn").instance()
	timeline.add_child(piece)
	if action == 'join':
		piece._on_option_selected(0)
		piece.load_character_position(joining_position)
	elif action == 'leave':
		piece._on_option_selected(1)
	elif action == 'leaveall':
		piece._on_option_selected(2)
	else:
		if clear_all == true:
			piece._on_option_selected(2)
	piece.editor_reference = self
	return piece

# ordering blocks in timeline
func _move_block(block, direction):
	var block_index = block.get_index()
	if direction == 'up':
		if block_index > 0:	
			timeline.move_child(block, block_index - 1)
			return true
	if direction == 'down':
		timeline.move_child(block, block_index + 1)
		return true
	print('[!] Failed to move block ', block)
	return false

# Clear timeline
func clear_timeline():
	for event in $Editor/ScrollContainer/TimeLine.get_children():
		event.queue_free()

# Reload button
func _on_ReloadResource_pressed():
	clear_timeline()
	load_nodes()
	print('Reloaded')

# Saving and loading
func _on_ButtonSave_pressed():
	dialog_selected_node.dialog_resource.nodes = ['here']
	var resource_path = dialog_selected_node.dialog_resource.get_path()
	var resource = dialog_selected_node.dialog_resource
	print('Saving resource --------')
	print('  Resource:', resource)
	print('  Resource path: ', resource_path)
	var error : int = ResourceSaver.save(resource_path, resource)
	if error != OK:
		print('[!] Error [', error, '] when saving the resource file.')
	print('Saved resource data: ', dialog_selected_node.dialog_resource.nodes)

func load_nodes():
	# Json
	var data_file = File.new()
	var data_file_path = dialog_selected_node.dialog_resource.dialog_json
	# DEBUG OVERWRITE
	data_file_path = "res://dialogs/dialog.json"
	# END OVERWRITE
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
				create_character_node(i['character'], i['action'],i['position'])
				print('character-element: ', i)
			
			{'character', 'action'}:
				create_character_node(i['character'], i['action'])
				print('character-block: ', i)
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
	for event in $Editor/ScrollContainer/TimeLine.get_children():
		event.get_node("VBoxContainer/Header/VisibleToggle").set_pressed(false)

func unfold_all_nodes():
	for event in $Editor/ScrollContainer/TimeLine.get_children():
		event.get_node("VBoxContainer/Header/VisibleToggle").set_pressed(true)
		print(event.get_node("VBoxContainer/Header/VisibleToggle"))

func _on_ButtonFold_pressed():
	fold_all_nodes()

func _on_ButtonUnfold_pressed():
	unfold_all_nodes()
