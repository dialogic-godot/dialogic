@tool
extends DialogicLayoutBase

## This layout won't do anything on it's own

var bubbles: Dictionary = {}
var fallback_bubble :Control = null


func _ready():
	if Engine.is_editor_hint():
		return

	DialogicUtil.autoload().Text.about_to_show_text.connect(_on_dialogic_text_event)
	$Example/ExamplePoint.position = $Example.get_viewport_rect().size/2

	if not has_node('TextBubbleLayer'):
		return

	fallback_bubble = get_node("TextBubbleLayer").add_bubble()
	fallback_bubble.speaker_node = $Example/ExamplePoint


func register_character(character:DialogicCharacter, node:Node2D):
	if not has_node('TextBubbleLayer'):
		return

	var new_bubble: Control = get_node("TextBubbleLayer").add_bubble()
	new_bubble.speaker_node = node
	new_bubble.character = character
	new_bubble.name = character.resource_path.get_file().trim_suffix("."+character.resource_path.get_extension()) + "Bubble"
	bubbles[character] = new_bubble

func _on_dialogic_text_event(info:Dictionary):
	var no_bubble_open := true

	for character in bubbles:
		if info.character == character:
			no_bubble_open = false
			bubbles[character].open()
		else:
			bubbles[character].close()

	if no_bubble_open:
		$Example.show()
		fallback_bubble.open()
	else:
		$Example.hide()
		fallback_bubble.close()

