extends Timer

var caller = null

func _input(event: InputEvent) -> void:
	if event.is_action_pressed(caller.next_input):
		(caller.TextNode as RichTextLabel).visible_characters = (caller.TextNode as RichTextLabel).get_total_character_count()
