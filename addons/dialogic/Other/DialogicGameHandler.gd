extends Node

enum states {IDLE, SHOWING_TEXT, ANIMATING, AWAITING_CHOICE}

var current_timeline = null
var current_timeline_events = []


var current_state = null setget set_current_state
var current_event_idx = 0
var current_portraits = {}
var current_bg_music
var current_bg_image
var current_name
var current_text

signal state_changed(new_state)

################################################################################
## 						INPUT (WIP)
################################################################################
# This shouldn't be handled by this script I think, but for testing purposes this works.
func _input(event):
	if event is InputEventMouseButton and event.pressed:
		if current_state == states.IDLE:
			handle_next_event()

################################################################################
## 						TIMELINE+EVENT HANDLING
################################################################################
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
	hide_all_choices()
	if event_index >= len(current_timeline_events):
		return
	
	current_event_idx = event_index
	var event:DialogicEvent = current_timeline_events[event_index]
	print("[D] Handle Event ", event_index, ": ", event)
	if event.continue_at_end:
		print("    -> AUTO CONTINUE!")
		event.connect("event_finished", self, 'handle_next_event')
	event.execute(self)

################################################################################
## 						DISPLAY NODES
################################################################################
func _ready():
	reset_all_display_nodes()

func reset_all_display_nodes():
	update_dialog_text('')
	update_name_label('', Color.white)
	

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

func hide_all_choices():
	for node in get_tree().get_nodes_in_group('dialogic_choice_button'):
		node.hide()
		if node.is_connected('pressed', self, 'choice_selected'):
			node.disconnect('pressed', self, 'choice_selected')

func show_current_choices():
	hide_all_choices()
	var button_idx = 1
	for choice_index in get_current_choice_indexes():
		var choice_event = current_timeline_events[choice_index]
		show_choice(button_idx, choice_event.Text, true, choice_index)
		button_idx += 1

func show_choice(button_index, text, enabled, event_index):
	for node in get_tree().get_nodes_in_group('dialogic_choice_button'):
		if node.choice_index == button_index:
			node.show()
			node.text = text
			node.connect('pressed', self, 'choice_selected', [event_index])

func choice_selected(event_index):
	hide_all_choices()
	current_state = states.IDLE
	handle_event(event_index)


################################################################################
## 						HELPERS
################################################################################
func set_current_state(new_state):
	current_state = new_state
	emit_signal('state_changed', new_state)

func is_question(index):
	if current_timeline_events[index] is DialogicTextEvent:
		if len(current_timeline_events)-1 != index:
			if current_timeline_events[index+1] is DialogicChoiceEvent:
				return true
	return false

func get_current_choice_indexes() -> Array:
	var choices = []
	var evt_idx = current_event_idx
	var ignore = 0
	while true:
		evt_idx += 1
		if evt_idx >= len(current_timeline_events):
			break
		
		if current_timeline_events[evt_idx] is DialogicChoiceEvent:
			if ignore == 0:
				choices.append(evt_idx)
			ignore += 1
		else:
			if ignore == 0:
				break
		
		if current_timeline_events[evt_idx] is DialogicEndBranchEvent:
			ignore -= 1
	
	return choices
