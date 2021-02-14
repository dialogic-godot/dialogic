tool
extends HSplitContainer

var editor_reference
var timeline_name: String = "" # The currently opened timeline name (for saving)
var version_string: String = "0.9"

onready var timeline = $TimelineEditor/TimelineArea/TimeLine
onready var dialog_list = $EventTools/VBoxContainer2/DialogItemList
onready var events_warning = $TimelineEditor/ScrollContainer/EventContainer/EventsWarning


func _ready():
	$EventTools/VBoxContainer2/DialogItemList.connect('item_selected', self, '_on_DialogItemList_item_selected')
	$EventTools/VBoxContainer2/DialogItemList.connect('item_rmb_selected', self, '_on_DialogItemList_item_rmb_selected')
	
	# We connect all the event buttons to the event creation functions
	for b in $TimelineEditor/ScrollContainer/EventContainer.get_children():
		if b is Button:
			if b.name == 'ButtonQuestion':
				b.connect('pressed', self, "_on_ButtonQuestion_pressed", [])
			elif b.name == 'IfCondition':
				b.connect('pressed', self, "_on_ButtonCondition_pressed", [])
			else:
				b.connect('pressed', self, "_create_event_button_pressed", [b.name])


# Special event creation for multiple events clicking one button
func _on_ButtonQuestion_pressed() -> void:
	create_event("Question", {'no-data': true}, true)
	create_event("Choice", {'no-data': true}, true)
	create_event("Choice", {'no-data': true}, true)
	create_event("EndBranch", {'no-data': true}, true)


func _on_ButtonCondition_pressed() -> void:
	create_event("IfCondition", {'no-data': true}, true)
	create_event("EndBranch", {'no-data': true}, true)


func load_timeline(path):
	var start_time = OS.get_ticks_msec()
	editor_reference.working_dialog_file = path
	# Making editor visible
	$TimelineEditor.visible = true
	$CenterContainer.visible = false
	
	var data = DialogicUtil.load_json(path)
	if data['metadata'].has('name'):
		timeline_name = data['metadata']['name']
	data = data['events']
	for i in data:
		match i:
			{'text', 'character', 'portrait'}:
				create_event("TextBlock", i)
			{'background'}:
				create_event("SceneBlock", i)
			{'character', 'action', 'position', 'portrait'}:
				create_event("CharacterJoinBlock", i)
			{'audio', 'file'}:
				create_event("AudioBlock", i)
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
			{'condition', 'glossary', 'value'}:
				create_event("IfCondition", i)
			{'set_value', 'glossary'}:
				create_event("SetValue", i)

	editor_reference.autosaving_hash = generate_save_data().hash()
	if data.size() < 1:
		events_warning.visible = true
	else:
		events_warning.visible = false
		indent_events()
		fold_all_nodes()
	
	var elapsed_time: float = (OS.get_ticks_msec() - start_time) * 0.001
	editor_reference.dprint("Elapsed time: " + str(elapsed_time))
	
	# Preventing a bug here....
	# I'm not sure why, but some times when you load a timeline
	# and you close it, it won't save all the events. This prevents
	# it from happening for now, but I might want to revamp
	# the entire saving system sooner than later.
	editor_reference.manual_save()

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

# Event Creation signal for buttons
func _create_event_button_pressed(button_name):
	create_event(button_name)
	indent_events()


# Adding an event to the timeline
func create_event(scene: String, data: Dictionary = {'no-data': true} , indent: bool = false):
	# This function will create an event in the timeline.
	var piece = load("res://addons/dialogic/Editor/Pieces/" + scene + ".tscn").instance()
	piece.editor_reference = editor_reference
	timeline.add_child(piece)
	if data.has('no-data') == false:
		piece.load_data(data)
	events_warning.visible = false
	# Indent on create
	if indent:
		indent_events()
	return piece


# Selecting an item in the list
func _on_DialogItemList_item_selected(index):
	editor_reference.manual_save() # Making sure we save before changing tabs
	clear_timeline()
	var selected = dialog_list.get_item_text(index)
	var file = dialog_list.get_item_metadata(index)['file']
	load_timeline(DialogicUtil.get_path('TIMELINE_DIR', file))


# Popup menu with options for a timeline
func _on_DialogItemList_item_rmb_selected(index, at_position):
	editor_reference.get_node('TimelinePopupMenu').rect_position = get_viewport().get_mouse_position()
	editor_reference.get_node('TimelinePopupMenu').popup()
	timeline_name = dialog_list.get_item_text(index)


# Clear timeline
func clear_timeline():
	for event in timeline.get_children():
		event.free()


func fold_all_nodes():
	for event in timeline.get_children():
		event.get_node("PanelContainer/VBoxContainer/Header/VisibleToggle").set_pressed(false)


func unfold_all_nodes():
	for event in timeline.get_children():
		event.get_node("PanelContainer/VBoxContainer/Header/VisibleToggle").set_pressed(true)


# ordering blocks in timeline
func _move_block(block, direction):
	var block_index = block.get_index()
	if direction == 'up':
		if block_index > 0:
			timeline.move_child(block, block_index - 1)
			return true
	if direction == 'down':
		timeline.move_child(block, block_index + 1)
		return true
	return false


# Create timeline
func _on_AddTimelineButton_pressed():
	var file = create_timeline()
	refresh_timeline_list()
	clear_timeline()
	load_timeline(DialogicUtil.get_path('TIMELINE_DIR', file))


func create_timeline():
	var timeline_file = 'timeline-' + str(OS.get_unix_time()) + '.json'
	var timeline = {
		"events": [],
		"metadata":{"dialogic-version": version_string}
	}
	var directory = Directory.new()
	if not directory.dir_exists(DialogicUtil.get_path('WORKING_DIR')):
		directory.make_dir(DialogicUtil.get_path('WORKING_DIR'))
	if not directory.dir_exists(DialogicUtil.get_path('TIMELINE_DIR')):
		directory.make_dir(DialogicUtil.get_path('TIMELINE_DIR'))
	var file = File.new()
	file.open(DialogicUtil.get_path('TIMELINE_DIR') + '/' + timeline_file, File.WRITE)
	file.store_line(to_json(timeline))
	file.close()
	return timeline_file


# Conversation files
func refresh_timeline_list():
	dialog_list.clear()
	var icon = load("res://addons/dialogic/Images/timeline.svg")
	var index = 0
	for c in DialogicUtil.get_timeline_list():
		dialog_list.add_item(c['name'], icon)
		dialog_list.set_item_metadata(index, {'file': c['file'], 'index': index})
		index += 1
	dialog_list.sort_items_by_text()
	if $EventTools/VBoxContainer2/DialogItemList.get_item_count() == 0:
		editor_reference.change_tab('Timeline')

# Saving
func generate_save_data():
	var info_to_save = {
		'metadata': {
			'dialogic-version': version_string,
			'name': timeline_name,
		},
		'events': []
	}
	for event in timeline.get_children():
		info_to_save['events'].append(event.event_data)
	return info_to_save


func save_timeline(path):
	var info_to_save = generate_save_data()
	var file = File.new()
	file.open(path, File.WRITE)
	file.store_line(to_json(info_to_save))
	file.close()
	editor_reference.autosaving_hash = info_to_save.hash()
