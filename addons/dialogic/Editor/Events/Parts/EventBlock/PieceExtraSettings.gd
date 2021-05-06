tool
extends MenuButton

var current_piece

func _ready():
	# Gotta love the nodes system some times
	# Praise the paths (っ´ω`c)♡
	current_piece = get_parent().get_parent().get_parent().get_parent()
	var popup = get_popup()
	popup.connect("index_pressed", self, "_on_OptionSelected")


func _on_OptionSelected(index):
	var timeline_editor = current_piece.editor_reference.get_node('MainPanel/TimelineEditor')
	if index == 0:
		# Moving this up
		timeline_editor.move_block(current_piece, 'up')
	elif index == 1:
		# Moving piece down
		timeline_editor.move_block(current_piece, 'down')
	elif index == 3:
		# Removing a piece
		if timeline_editor._is_item_selected(current_piece):
			timeline_editor.select_item(current_piece)
		timeline_editor.delete_selected_events()
	timeline_editor.indent_events()
