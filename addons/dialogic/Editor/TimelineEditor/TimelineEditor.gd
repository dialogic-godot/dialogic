tool
extends HSplitContainer

var editor_reference
var timeline_name: String = ''
var timeline_file: String = ''
var current_timeline: Dictionary = {}

onready var master_tree = get_node('../MasterTree')
onready var timeline = $TimelineArea/TimeLine
onready var events_warning = $ScrollContainer/EventContainer/EventsWarning

var hovered_item = null
var selected_style : StyleBoxFlat = load("res://addons/dialogic/Editor/Pieces/selected_styleboxflat.tres")
var selected_style_text : StyleBoxFlat = load("res://addons/dialogic/Editor/Pieces/selected_styleboxflat_text_event.tres")
var saved_style : StyleBoxFlat
var selected_item : Node

func _ready():
	# We connect all the event buttons to the event creation functions
	for b in $ScrollContainer/EventContainer.get_children():
		if b is Button:
			if b.name == 'ButtonQuestion':
				b.connect('pressed', self, "_on_ButtonQuestion_pressed", [])
			elif b.name == 'IfCondition':
				b.connect('pressed', self, "_on_ButtonCondition_pressed", [])
			else:
				b.connect('pressed', self, "_create_event_button_pressed", [b.name])
	
	var style = $TimelineArea.get('custom_styles/bg')
	style.set('bg_color', get_color("dark_color_1", "Editor"))


func _clear_selection():
	if selected_item != null and saved_style != null:
		var selected_panel: PanelContainer = selected_item.get_node("PanelContainer")
		if selected_panel != null:
			selected_panel.set('custom_styles/panel', saved_style)
	selected_item = null
	saved_style = null


func _select_item(item: Node):
	if item != selected_item:
		_clear_selection()
		var panel: PanelContainer = item.get_node("PanelContainer")
		if panel != null:
			saved_style = panel.get('custom_styles/panel')
			selected_item = item
			print(selected_item.event_data)
			if selected_item.event_data.has('text') and selected_item.event_data.has('character'):
				panel.set('custom_styles/panel', selected_style_text)
			else:
				panel.set('custom_styles/panel', selected_style)
	else:
		_clear_selection()


func _on_gui_input(event, item: Node):
	if event is InputEventMouseButton and event.button_index == 1 and event.is_pressed():
		_select_item(item)


# Event Creation signal for buttons
func _create_event_button_pressed(button_name):
	create_event(button_name)
	indent_events()


func _on_ButtonQuestion_pressed() -> void:
	if selected_item != null:
		# Events are added bellow the selected node
		# So we must reverse the adding order
		create_event("EndBranch", {'no-data': true}, true)
		create_event("Choice", {'no-data': true}, true)
		create_event("Choice", {'no-data': true}, true)
		create_event("Question", {'no-data': true}, true)
	else:
		create_event("Question", {'no-data': true}, true)
		create_event("Choice", {'no-data': true}, true)
		create_event("Choice", {'no-data': true}, true)
		create_event("EndBranch", {'no-data': true}, true)


func _on_ButtonCondition_pressed() -> void:
	if selected_item != null:
		# Events are added bellow the selected node
		# So we must reverse the adding order
		create_event("EndBranch", {'no-data': true}, true)
		create_event("IfCondition", {'no-data': true}, true)
	else:
		create_event("IfCondition", {'no-data': true}, true)
		create_event("EndBranch", {'no-data': true}, true)


# Adding an event to the timeline
func create_event(scene: String, data: Dictionary = {'no-data': true} , indent: bool = false):
	# This function will create an event in the timeline.
	var piece = load("res://addons/dialogic/Editor/Pieces/" + scene + ".tscn").instance()
	piece.editor_reference = editor_reference
	if selected_item != null:
		timeline.add_child_below_node(selected_item, piece)
	else:
		timeline.add_child(piece)
	if data.has('no-data') == false:
		piece.load_data(data)
	
	piece.connect("gui_input", self, '_on_gui_input', [piece])
	events_warning.visible = false
	# Indent on create
	if indent:
		indent_events()
	return piece


# Event Indenting
func indent_events() -> void:
	var indent: int = 0
	var starter: bool = false
	var event_list: Array = timeline.get_children()
	var question_index: int = 0
	var question_indent = {}
	if event_list.size() < 2:
		return
	# Resetting all the indents
	for event in event_list:
		var indent_node = event.get_node("Indent")
		indent_node.visible = false
	# Adding new indents
	for event in event_list:
		if event.event_data.has('question') or event.event_data.has('condition'):
			indent += 1
			starter = true
			question_index += 1
			question_indent[question_index] = indent
		if event.event_data.has('choice'):
			if question_index > 0:
				indent = question_indent[question_index] + 1
				starter = true
		if event.event_data.has('endbranch'):
			if question_indent.has(question_index):
				indent = question_indent[question_index]
				indent -= 1
				question_index -= 1
				if indent < 0:
					indent = 0

		if indent > 0:
			var indent_node = event.get_node("Indent")
			indent_node.rect_min_size = Vector2(25 * indent, 0)
			indent_node.visible = true
			if starter:
				indent_node.rect_min_size = Vector2(25 * (indent - 1), 0)
				if indent - 1 == 0:
					indent_node.visible = false
				
		starter = false


func load_timeline(filename: String):
	print('---------------------------')
	print('Loading: ', filename)
	clear_timeline()
	var start_time = OS.get_system_time_msecs()
	timeline_file = filename
	
	var data = DialogicResources.get_timeline_json(filename)
	if data['metadata'].has('name'):
		timeline_name = data['metadata']['name']
	else:
		timeline_name = data['metadata']['file']
	data = data['events']
	for i in data:
		match i:
			{'text', 'character', 'portrait'}:
				create_event("TextBlock", i)
			{'background'}:
				create_event("SceneEvent", i)
			{'character', 'action', 'position', 'portrait'}:
				create_event("CharacterJoinBlock", i)
			{'audio', 'file'}:
				create_event("AudioBlock", i)
			{'background-music', 'file'}:
				create_event("BackgroundMusic", i)
			{'question', 'options'}:
				create_event("Question", i)
			{'choice'}:
				create_event("Choice", i)
			{'endbranch'}:
				create_event("EndBranch", i)
			{'character', 'action'}:
				create_event("CharacterLeaveBlock", i)
			{'change_timeline'}:
				create_event("ChangeTimeline", i)
			{'emit_signal'}:
				create_event("EmitSignal", i)
			{'change_scene'}:
				create_event("ChangeScene", i)
			{'close_dialog'}:
				create_event("CloseDialog", i)
			{'wait_seconds'}:
				create_event("WaitSeconds", i)
			{'condition', 'definition', 'value'}:
				create_event("IfCondition", i)
			{'set_value', 'definition', ..}:
				create_event("SetValue", i)
			{'set_theme'}:
				create_event("SetTheme", i)

	if data.size() < 1:
		events_warning.visible = true
	else:
		events_warning.visible = false
		indent_events()
		#fold_all_nodes()
	
	var elapsed_time = (OS.get_system_time_msecs() - start_time) * 0.001
	editor_reference.dprint("Loading time: " + str(elapsed_time))


func clear_timeline():
	_clear_selection()
	for event in timeline.get_children():
		event.free()


# ordering blocks in timeline
func move_block(block, direction):
	var block_index = block.get_index()
	if direction == 'up':
		if block_index > 0:
			timeline.move_child(block, block_index - 1)
			return true
	if direction == 'down':
		timeline.move_child(block, block_index + 1)
		return true
	return false


func create_timeline():
	timeline_file = 'timeline-' + str(OS.get_unix_time()) + '.json'
	var timeline = {
		"events": [],
		"metadata":{
			"dialogic-version": editor_reference.version_string,
			"file": timeline_file
		}
	}
	DialogicResources.set_timeline(timeline)
	return timeline


func new_timeline():
	# This event creates and selects the new timeline
	master_tree.build_timelines(create_timeline()['metadata']['file'])


# Saving
func generate_save_data():
	var info_to_save = {
		'metadata': {
			'dialogic-version': editor_reference.version_string,
			'name': timeline_name,
			'file': timeline_file
		},
		'events': []
	}
	for event in timeline.get_children():
		if event.is_queued_for_deletion() == false: # Checking that the event is not waiting to be removed
			info_to_save['events'].append(event.event_data)
	return info_to_save


func save_timeline() -> void:
	if timeline_file != '':
		var info_to_save = generate_save_data()
		DialogicResources.set_timeline(info_to_save)
		#print('[+] Saving: ' , timeline_file)


# Utilities
func fold_all_nodes():
	for event in timeline.get_children():
		if event.has_node("PanelContainer/VBoxContainer/Header/VisibleToggle"):
			event.get_node("PanelContainer/VBoxContainer/Header/VisibleToggle").set_pressed(false)


func unfold_all_nodes():
	for event in timeline.get_children():
		if event.has_node("PanelContainer/VBoxContainer/Header/VisibleToggle"):
			event.get_node("PanelContainer/VBoxContainer/Header/VisibleToggle").set_pressed(true)
