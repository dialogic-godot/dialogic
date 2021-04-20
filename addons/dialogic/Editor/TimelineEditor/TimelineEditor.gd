tool
extends HSplitContainer

var editor_reference
var timeline_name: String = ''
var timeline_file: String = ''
var current_timeline: Dictionary = {}

onready var master_tree = get_node('../MasterTreeContainer/MasterTree')
onready var timeline = $TimelineArea/TimeLine
onready var events_warning = $ScrollContainer/EventContainer/EventsWarning

var hovered_item = null
var selected_style : StyleBoxFlat = load("res://addons/dialogic/Editor/Events/styles/selected_styleboxflat.tres")
var selected_style_text : StyleBoxFlat = load("res://addons/dialogic/Editor/Events/styles/selected_styleboxflat_text_event.tres")
var selected_style_template : StyleBoxFlat = load("res://addons/dialogic/Editor/Events/styles/selected_styleboxflat_template.tres")
var saved_style : StyleBoxFlat
var selected_item : Node


var moving_piece = null
var piece_was_dragged = false

func _has_template(event):
	return event.event_data.has("background") or event.event_data.has("wait_seconds")


func _ready():
	var modifier = ''
	var _scale = get_constant("inspector_margin", "Editor")
	_scale = _scale * 0.125
	$ScrollContainer.rect_min_size.x = 180
	if _scale == 1.25:
		modifier = '-1.25'
		$ScrollContainer.rect_min_size.x = 200
	if _scale == 1.5:
		modifier = '-1.25'
		$ScrollContainer.rect_min_size.x = 200
	if _scale == 1.75:
		modifier = '-1.25'
		$ScrollContainer.rect_min_size.x = 390
	if _scale == 2:
		modifier = '-2'
		$ScrollContainer.rect_min_size.x = 390
	
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


func delete_event():
	# get next element
	var next = min(timeline.get_child_count() - 1, selected_item.get_index() + 1)
	var next_node = timeline.get_child(next)
	if (next_node == selected_item):
		next_node = null
		
	# remove current
	selected_item.get_parent().remove_child(selected_item)
	selected_item.queue_free()
	selected_item = null
	
	# select next
	if (next_node != null):
		_select_item(next_node)
	else:
		if (timeline.get_child_count() > 0):
			next_node = timeline.get_child(max(0, timeline.get_child_count() - 1))
			if (next_node != null):
				_select_item(next_node)
				
	indent_events()

func _input(event):
	# some shortcuts need to get handled in the common input event
	# especially CTRL-based
	# because certain godot controls swallow events (like textedit)
	# we protect this with is_visible_in_tree to not 
	# invoke a shortcut by accident
	if (event is InputEventKey and event is InputEventWithModifiers and is_visible_in_tree()):
		# CTRL UP
		if (event.pressed
			and event.alt == false
			and event.shift == false
			and event.control == true
			and event.scancode == KEY_UP
			and event.echo == false
		):
			# select previous
			if (selected_item != null):
				var prev = max(0, selected_item.get_index() - 1)
				var prev_node = timeline.get_child(prev)
				if (prev_node != selected_item):
					_select_item(prev_node)
				get_tree().set_input_as_handled()
				
			pass
			
		# CTRL DOWN
		if (event.pressed
			and event.alt == false
			and event.shift == false
			and event.control == true
			and event.scancode == KEY_DOWN
			and event.echo == false
		):
			# select next
			if (selected_item != null):
				var next = min(timeline.get_child_count() - 1, selected_item.get_index() + 1)
				var next_node = timeline.get_child(next)
				if (next_node != selected_item):
					_select_item(next_node)
				get_tree().set_input_as_handled()
				
			pass
			
		# CTRL DELETE
		if (event.pressed
			and event.alt == false
			and event.shift == false
			and event.control == true
			and event.scancode == KEY_DELETE
			and event.echo == false
		):
			if (selected_item != null):
				delete_event()
				get_tree().set_input_as_handled()
			pass
			
		# CTRL T
		if (event.pressed
			and event.alt == false
			and event.shift == false
			and event.control == true
			and event.scancode == KEY_T
			and event.echo == false
		):
			var new_text = create_event("TextBlock")
			_select_item(new_text)
			indent_events()
			get_tree().set_input_as_handled()
			pass


func _unhandled_key_input(event):
	if (event is InputEventWithModifiers):
		# ALT UP
		if (event.pressed
			and event.alt == true 
			and event.shift == false 
			and event.control == false 
			and event.scancode == KEY_UP
			and event.echo == false
		):
			# move selected up
			if (selected_item != null):
				move_block(selected_item, "up")
				indent_events()
				get_tree().set_input_as_handled()
				
			pass
			
		# ALT DOWN
		if (event.pressed
			and event.alt == true 
			and event.shift == false 
			and event.control == false 
			and event.scancode == KEY_DOWN
			and event.echo == false
		):
			# move selected down
			if (selected_item != null):
				move_block(selected_item, "down")
				indent_events()
				get_tree().set_input_as_handled()
				
			pass
			
	pass
	
func _process(delta):
	if moving_piece != null:
		var current_position = get_global_mouse_position()
		var node_position = moving_piece.rect_global_position.y
		var height = get_block_height(moving_piece)
		var up_offset = get_block_height(get_block_above(moving_piece))
		var down_offset = get_block_height(get_block_below(moving_piece))
		if up_offset != null:
			up_offset = (up_offset / 2) + 5
			if current_position.y < node_position - up_offset:
				move_block(moving_piece, 'up')
				piece_was_dragged = true
		if down_offset != null:
			down_offset = height + (down_offset / 2) + 5
			if current_position.y > node_position + down_offset:
				move_block(moving_piece, 'down')
				piece_was_dragged = true


func _clear_selection():
	if selected_item != null and saved_style != null:
		if not _has_template(selected_item):
			var selected_panel: PanelContainer = selected_item.get_node("PanelContainer")
			if selected_panel != null:
				selected_panel.set('custom_styles/panel', saved_style)
		else:
			selected_item.set_event_style(saved_style)
			selected_item.on_timeline_selected(false)
	selected_item = null
	saved_style = null


func _is_item_selected(item: Node):
	return item == selected_item


func _select_item(item: Node):
	if item != null and not _is_item_selected(item):
		_clear_selection()
		selected_item = item
		if not _has_template(item):
			var panel: PanelContainer = item.get_node("PanelContainer")
			if panel != null:
				saved_style = panel.get('custom_styles/panel')
				if selected_item.event_data.has('text') and selected_item.event_data.has('character'):
					panel.set('custom_styles/panel', selected_style_text)
				else:
					panel.set('custom_styles/panel', selected_style)
				# allow event panels to do additional operation when getting selected
				if (selected_item.has_method("on_timeline_selected")):
					selected_item.on_timeline_selected()
		else:
			saved_style = item.get_event_style()
			item.set_event_style(selected_style_template)
			selected_item.on_timeline_selected(true)
	else:
		_clear_selection()


func _on_gui_input(event, item: Node):
	if event is InputEventMouseButton and event.button_index == 1:
		if (not event.is_pressed()):
			if (not piece_was_dragged and moving_piece != null):
				_clear_selection()
			if (moving_piece != null):
				indent_events()
			moving_piece = null
		elif event.is_pressed():
			moving_piece = item
			if not _is_item_selected(item):
				_select_item(item)
				piece_was_dragged = true
			else:
				piece_was_dragged = false


func _on_event_options_action(action: String, item: Node):
	if action == "remove":
		if selected_item != item:
			_select_item(item)
		delete_event()
	else:
		move_block(item, action)
	indent_events()


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


# Creates a ghost event for drag and drop
func create_drag_and_drop_event(scene: String):
	var index = get_index_under_cursor()
	var piece = create_event(scene)
	timeline.move_child(piece, index)
	moving_piece = piece
	piece_was_dragged = true
	set_event_ignore_save(piece, true)
	_select_item(piece)
	return piece


func drop_event():
	if moving_piece != null:
		set_event_ignore_save(moving_piece, false)
		moving_piece = null
		piece_was_dragged = false
		indent_events()


func cancel_drop_event():
	if moving_piece != null:
		moving_piece = null
		piece_was_dragged = false
		delete_event()
		_clear_selection()


# Adding an event to the timeline
func create_event(scene: String, data: Dictionary = {'no-data': true} , indent: bool = false):
	var piece = load("res://addons/dialogic/Editor/Events/" + scene + ".tscn").instance()
	piece.editor_reference = editor_reference
	if selected_item != null:
		timeline.add_child_below_node(selected_item, piece)
	else:
		timeline.add_child(piece)
	if data.has('no-data') == false:
		piece.load_data(data)
	
	if _has_template(piece):
		piece.connect("option_action", self, '_on_event_options_action', [piece])
	
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
		var indent_node
		# Keep old behavior for items without template
		if not _has_template(event):
			indent_node = event.get_node("Indent")
			indent_node.visible = false
		else:
			event.set_indent(0)
		
	# Adding new indents
	for event in event_list:
		# since there are indicators now, not all elements
		# in this list have an event_data property
		if (not "event_data" in event):
			continue
		
		
		if event.event_data.has('choice'):
			if question_index > 0:
				indent = question_indent[question_index] + 1
				starter = true
		elif event.event_data.has('question') or event.event_data.has('condition'):
			indent += 1
			starter = true
			question_index += 1
			question_indent[question_index] = indent
		elif event.event_data.has('endbranch'):
			if question_indent.has(question_index):
				indent = question_indent[question_index]
				indent -= 1
				question_index -= 1
				if indent < 0:
					indent = 0

		if indent > 0:
			# Keep old behavior for items without template
			if not _has_template(event):
				var indent_node = event.get_node("Indent")
				indent_node.rect_min_size = Vector2(25 * indent, 0)
				indent_node.visible = true
				if starter:
					indent_node.rect_min_size = Vector2(25 * (indent - 1), 0)
					if indent - 1 == 0:
						indent_node.visible = false
			else:
				if starter:
					event.set_indent(indent - 1)
				else:
					event.set_indent(indent)
		starter = false


func load_timeline(filename: String):
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
				create_event("ChangeBackground", i)
			{'character', 'action', 'position', 'portrait',..}:
				create_event("CharacterJoinBlock", i)
			{'audio', 'file', ..}:
				create_event("AudioBlock", i)
			{'background-music', 'file', ..}:
				create_event("BackgroundMusic", i)
			{'question', 'options', ..}:
				create_event("Question", i)
			{'choice', ..}:
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
			{'close_dialog', ..}:
				create_event("CloseDialog", i)
			{'wait_seconds'}:
				create_event("WaitSeconds", i)
			{'condition', 'definition', 'value'}:
				create_event("IfCondition", i)
			{'set_value', 'definition', ..}:
				create_event("SetValue", i)
			{'set_theme'}:
				create_event("SetTheme", i)
			{'call_node'}:
				create_event("CallNode", i)

	if data.size() < 1:
		events_warning.visible = true
	else:
		events_warning.visible = false
		indent_events()
		#fold_all_nodes()
	
	var elapsed_time = (OS.get_system_time_msecs() - start_time) * 0.001
	#editor_reference.dprint("Loading time: " + str(elapsed_time))


func clear_timeline():
	_clear_selection()
	for event in timeline.get_children():
		event.free()


func get_block_above(block):
	var block_index = block.get_index()
	var item = null
	if block_index > 0:
		item = timeline.get_child(block_index - 1)
	return item


func get_block_below(block):
	var block_index = block.get_index()
	var item = null
	if block_index < timeline.get_child_count() - 1:
		item = timeline.get_child(block_index + 1)
	return item


func get_block_height(block):
	if block != null:
		if not _has_template(block):
			return block.get_node("PanelContainer").rect_size.y
		else:
			return block.rect_size.y
	else:
		return null


func get_index_under_cursor():
	var current_position = get_global_mouse_position()
	var top_pos = 0
	for i in range(timeline.get_child_count()):
		var c = timeline.get_child(i)
		if c.rect_global_position.y < current_position.y:
			top_pos = i
	return top_pos


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
		# Checking that the event is not waiting to be removed
		# or that it is not a drag and drop placeholder
		if not get_event_ignore_save(event) and event.is_queued_for_deletion() == false:
			info_to_save['events'].append(event.event_data)
	return info_to_save


func set_event_ignore_save(event: Node, ignore: bool):
	if _has_template(event):
		event.ignore_save = ignore
	else:
		if ignore:
			event.event_data["_ignore_save"] = true
		else:
			event.event_data.erase("_ignore_save")


func get_event_ignore_save(event: Node) -> bool:
	if _has_template(event):
		return event.ignore_save
	else:
		return event.event_data.has("_ignore_save") and event.event_data["_ignore_save"]


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
		elif _has_template(event):
			event.set_expanded(false)


func unfold_all_nodes():
	for event in timeline.get_children():
		if event.has_node("PanelContainer/VBoxContainer/Header/VisibleToggle"):
			event.get_node("PanelContainer/VBoxContainer/Header/VisibleToggle").set_pressed(true)
		elif _has_template(event):
			event.set_expanded(true)
