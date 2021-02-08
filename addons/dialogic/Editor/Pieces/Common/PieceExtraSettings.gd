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
	if index == 0:
		# Moving this up
		current_piece.editor_reference.get_node('EditorTimeline')._move_block(current_piece, 'up')
	elif index == 1:
		# Moving piece down
		current_piece.editor_reference.get_node('EditorTimeline')._move_block(current_piece, 'down')
	elif index == 3:
		# Remove
		# TODO: Add a warning here
		current_piece.queue_free()
	current_piece.editor_reference.get_node('EditorTimeline').indent_events()
