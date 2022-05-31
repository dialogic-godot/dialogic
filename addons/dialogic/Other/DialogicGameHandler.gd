extends Node

enum states {IDLE, SHOWING_TEXT, ANIMATING, AWAITING_CHOICE}

var current_timeline = null
var current_timeline_events = []


var current_state = null
var current_event_idx = 0
var current_portraits = {}
var current_bg_music
var current_bg_image
var current_name
var current_text


func _input(event):
	if event is InputEventMouseButton and event.pressed:
		if current_state == states.IDLE:
			handle_next_event()

func start_timeline(timeline_resource):
	# load the resource if only the path is given
	if typeof(timeline_resource) == TYPE_STRING:
		timeline_resource = load(timeline_resource)
	
	
	current_timeline = timeline_resource
	current_timeline_events = current_timeline.get_events()
	current_event_idx = -1
	
	handle_next_event()
	

func handle_next_event(ignore_argument = ""):
	handle_event(current_event_idx+1)
	
	
func handle_event(event_index):
	if event_index >= len(current_timeline_events):
		return
	
	current_event_idx = event_index
	
	var event:DialogicEvent = current_timeline_events[event_index]
	print("[D] Handle Event ", event_index, ": ", event)
	if event.continue_at_end:
		print("    -> AUTO CONTINUE!")
		event.connect("event_finished", self, 'handle_next_event')
	event.execute(self)

func update_dialog_text(text):
	for text_node in get_tree().get_nodes_in_group('dialogic_dialog_text'):
		text_node.bbcode_text = text
		text_node.reveal_text()

func update_portrait(character, portrait, position, z_index, move, animation):
	pass

func update_name_label(name, color = Color(), font = null):
	for name_label in get_tree().get_nodes_in_group('dialogic_name_label'):
		name_label.text = name
		name_label.self_modulate = color
		if font:
			name_label.font = font
