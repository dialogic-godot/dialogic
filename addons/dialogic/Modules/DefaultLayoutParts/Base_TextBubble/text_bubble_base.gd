@tool
extends DialogicLayoutBase

## This layout won't do anything on it's own

var bubbles: Array = []
var registered_characters: Dictionary = {}

@export_group("Main")
@export_range(1, 25, 1) var bubble_count : int = 2


func _ready():
	if Engine.is_editor_hint():
		return

	DialogicUtil.autoload().Text.about_to_show_text.connect(_on_dialogic_text_event)
	$Example/CRT.position = $Example.get_viewport_rect().size/2

	if not has_node('TextBubbleLayer'):
		return

	if len(bubbles) < bubble_count:
		add_bubble()


func register_character(character:DialogicCharacter, node:Node):
	registered_characters[character] = node
	if len(registered_characters) > len(bubbles) and len(bubbles) < bubble_count:
		add_bubble()


func add_bubble() -> void:
	if not has_node('TextBubbleLayer'):
		return

	var new_bubble: Control = get_node("TextBubbleLayer").add_bubble()
	bubbles.append(new_bubble)


func _on_dialogic_text_event(info:Dictionary):
	var bubble_to_use: Node
	for bubble in bubbles:
		if bubble.current_character == info.character:
			bubble_to_use = bubble

	if bubble_to_use == null:
		for bubble in bubbles:
			if bubble.current_character == null:
				bubble_to_use = bubble

	if bubble_to_use == null:
		bubble_to_use = bubbles[0]

	var node_to_point_at: Node
	if info.character in registered_characters:
		node_to_point_at = registered_characters[info.character]
		$Example.hide()
	else:
		node_to_point_at = $Example/CRT/Marker
		$Example.show()

	bubble_to_use.current_character = info.character
	bubble_to_use.node_to_point_at = node_to_point_at
	bubble_to_use.reset()
	if has_node('TextBubbleLayer'):
		get_node("TextBubbleLayer").bubble_apply_overrides(bubble_to_use)
	bubble_to_use.open()

	## Now close other bubbles
	for bubble in bubbles:
		if bubble != bubble_to_use:
			bubble.close()
			bubble.current_character = null
