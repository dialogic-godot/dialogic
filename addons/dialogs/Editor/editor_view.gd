tool
class_name DialogGraphEditorView
extends Control

"""
The graph editor shown in the bottom panel. When a DialogNode is selected, its DialogResource
is added as a child of the main editor view so it's editable by the user and removed (but not
deleted) when the DialogGraph is deselected.
"""

var undo_redo: UndoRedo

func _ready():
	pass # Replace with function body.

func enable_template_editor_for(node: DialogNode):
	if not node:
		return
	$GraphEdit.visible = true
	$PanelContainer.visible = false

func clear_template_editor():
	print('here')
	$GraphEdit.visible = false
	$PanelContainer.visible = true
