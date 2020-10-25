tool
extends CheckBox

var current_piece
var is_disabled = false

func _ready():
	current_piece = get_parent().get_parent().get_parent()
	connect("toggled", self, "_on_VisibleToggle_toggled")

func disabled():
	self_modulate = Color(0,0,0,0)
	is_disabled = true

func _on_VisibleToggle_toggled(button_pressed):
	if is_disabled:
		return
	var current_rect_size = current_piece.get("rect_size")
	if button_pressed:
		# TODO: Replace all this "get node" with a better way
		# to only show the header node and hide the rest of the
		# children for the main VBoxContainer
		current_piece.get_node("VBoxContainer/Header/Preview").hide()
		
		var index = 0
		for node in current_piece.get_node("VBoxContainer").get_children():
			if index > 0:
				node.show()
			index += 1
		#current_piece.get_node("VBoxContainer/TextEdit").set("rect_min_size", Vector2(0, 80))
	else:
		# TODO: Same here.
		if current_piece.has_node("VBoxContainer/Header/Preview"):
			current_piece.get_node("VBoxContainer/Header/Preview").show()
			
			var index = 0
			for node in current_piece.get_node("VBoxContainer").get_children():
				if index > 0:
					node.hide()
				index += 1
			if "preview" in current_piece:
				current_piece.get_node("VBoxContainer/Header/Preview").text = current_piece.preview
			current_piece.set("rect_size", Vector2(current_rect_size.x,0))
	release_focus()
