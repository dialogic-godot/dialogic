tool
#class_name DialogGraphEditorView
extends Control

"""
The graph editor shown in the bottom panel. When a DialogNode is selected, its DialogResource
is added as a child of the main editor view so it's editable by the user and removed (but not
deleted) when the DialogGraph is deselected.
"""

var undo_redo: UndoRedo
var testing_mode = true
var dialog_selected_node
var testing = true
onready var timeline = $Editor/ScrollContainer/TimeLine

func _ready():
	if testing_mode == false:
		clear_template_editor()
	if testing == false:
		$Editor/GraphEdit.connect("connection_request", self, "_on_piece_connect")
	
func _on_piece_connect(from, from_slot, to, to_slot):
	$Editor/GraphEdit.connect_node(from, from_slot, to, to_slot)

func enable_template_editor_for(node: DialogNode):
	if not node:
		return
	dialog_selected_node = node
	$Editor.visible = true
	$EmptyMessage.visible = false

func clear_template_editor():
	print('here111')
	$Editor.visible = false
	$EmptyMessage.visible = true


# Creating text node
func _on_ButtonText_pressed():
	var piece = load("res://addons/dialogs/Editor/Pieces/TextBlock.tscn").instance()
	timeline.add_child(piece)
	piece.editor_reference = self

func _on_ButtonBackground_pressed():
	pass

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
	pass
