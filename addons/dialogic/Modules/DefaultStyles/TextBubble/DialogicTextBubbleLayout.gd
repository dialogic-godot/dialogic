extends CanvasLayer

## This layout won't do anything on it's own
var bubbles :Array[Dictionary] = []
var fallback_bubble :Control = null


func _ready():
	Dialogic.Text.about_to_show_text.connect(_on_dialogic_text_event)
	
	var control := Control.new()
	add_child(control)
	control.position = control.get_viewport_rect().size / 2.0
	fallback_bubble = preload("res://addons/dialogic/Modules/DefaultStyles/TextBubble/TextBubble.tscn").instantiate()
	fallback_bubble.speaker_node = control
	fallback_bubble.get_node('Tail').hide()
	fallback_bubble.safe_zone = 0
	fallback_bubble.base_direction = Vector2.ZERO
	
	add_child(fallback_bubble)


func register_character(character:DialogicCharacter, node:Node2D):
	var new_bubble := preload("res://addons/dialogic/Modules/DefaultStyles/TextBubble/TextBubble.tscn").instantiate()
	new_bubble.speaker_node = node
	add_child(new_bubble)
	bubbles.append({'node':node, 'bubble':new_bubble, 'character':character})


func _on_dialogic_text_event(info:Dictionary):
	var no_bubble_open := true
	for b in bubbles:
		if b.character == info.character:
			no_bubble_open = false
			b.bubble.open()
		else:
			b.bubble.close()
	if no_bubble_open:
		fallback_bubble.open()
