tool
extends GraphNode


func _ready():
	connect("close_request", self, "_on_close_request")
	connect("resize_request", self, "_on_resize_request")
	set_slot(0, true, 0, Color(1,1,1,1), true, 0, Color(1,1,1,1))


func _on_close_request():
	queue_free()

func _on_resize_request(new_minsize):
	rect_size = new_minsize

func add_character_list(characters):
	for c in characters:
		$VBoxContainer/CharacterOption.add_item(c.name)
