tool
class_name DialogGraphEditorView
extends Control

"""
The graph editor shown in the bottom panel. When a DialogNode is selected, its DialogResource
is added as a child of the main editor view so it's editable by the user and removed (but not
deleted) when the DialogGraph is deselected.
"""

var undo_redo: UndoRedo
var testing_mode = true
var dialog_selected_node

func _ready():
	if testing_mode == false:
		clear_template_editor()
	
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
	var initial_position = Vector2(40,40)
	var piece = load("res://addons/dialogs/Editor/Pieces/Text.tscn").instance()
	piece.offset += initial_position
	piece.add_character_list(dialog_selected_node.dialog_characters)
	$Editor/GraphEdit.add_child(piece)

func _on_ButtonBackground_pressed():
	var initial_position = Vector2(40,40)
	var piece = load("res://addons/dialogs/Editor/Pieces/Background.tscn").instance()
	piece.offset += initial_position
	#piece.add_character_list(dialog_selected_node.dialog_characters)
	$Editor/GraphEdit.add_child(piece)
