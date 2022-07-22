tool
extends HSplitContainer

var editor_reference
var timeline_name: String = ''
var timeline_file: String = ''
var current_timeline: Dictionary = {}
var TimelineUndoRedo := UndoRedo.new()

onready var master_tree = get_node('../MasterTreeContainer/MasterTree')
onready var timeline = $TimelineArea/TimeLine
onready var events_warning = $ScrollContainer/EventContainer/EventsWarning
onready var custom_events_container = $ScrollContainer/EventContainer/CustomEventsContainer

var hovered_item = null
var selected_style : StyleBoxFlat = load("res://addons/dialogic/Editor/Events/styles/selected_styleboxflat.tres")
var saved_style : StyleBoxFlat
var selected_items : Array = []

var event_scenes : Dictionary = {}

var currently_draged_event_type = null
var move_start_position = null
var moving_piece = null
var piece_was_dragged = false

var custom_events = {}

var id_to_scene_name = {
	#Main events
	'dialogic_001':'TextEvent',
	'dialogic_002':'Character',
	#Logic
	'dialogic_010':'Question',
	'dialogic_011':'Choice',
	'dialogic_012':'Condition',
	'dialogic_013':'EndBranch',
	'dialogic_014':'SetValue',
	'dialogic_015':'LabelEvent',
	'dialogic_016':'GoTo Event',
	#Timeline
	'dialogic_020':'ChangeTimeline',
	'dialogic_021':'ChangeBackground',
	'dialogic_022':'CloseDialog',
	'dialogic_023':'WaitSeconds',
	'dialogic_024':'SetTheme',
	'dialogic_025':'SetGlossary',
	'dialogic_026':'SaveEvent',
	#Audio
	'dialogic_030':'AudioEvent',
	'dialogic_031':'BackgroundMusic',
	#Godot
	'dialogic_040':'EmitSignal',
	'dialogic_041':'ChangeScene',
	'dialogic_042':'CallNode',
	#Afterlife
	'dialogic_050':'NoSkipEvent',
	}

var event_data

var batches = []
var building_timeline = true
signal selection_updated
signal batch_loaded
signal timeline_loaded

func _ready():
	editor_reference = find_parent('EditorView')
	connect("batch_loaded", self, '_on_batch_loaded')
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
	
	var style = $TimelineArea.get('custom_styles/bg')
	style.set('bg_color', get_color("dark_color_1", "Editor"))
	
	update_custom_events()
	$TimelineArea.connect('resized', self, 'add_extra_scroll_area_to_timeline', [])
	
	# We create the event buttons
	event_data = _read_event_data()
	var buttonScene = load("res://addons/dialogic/Editor/TimelineEditor/SmallEventButton.tscn")
	for b in event_data:
		if typeof(b['event_data']) == TYPE_DICTIONARY:
			var button = buttonScene.instance()
			# Button properties
			button.visible_name = '       ' + b['event_name']
			button.event_id = b['event_data']['event_id']
			button.set_icon(b['event_icon'])
			button.event_color = b['event_color']
			button.event_category = b.get('event_category', 0)
			button.sorting_index = b.get('sorting_index', 9999)
			# Connecting the signal
			if button.event_id == 'dialogic_010':
				button.connect('pressed', self, "_on_ButtonQuestion_pressed", [])
			elif button.event_id == 'dialogic_012': # Condition
				button.connect('pressed', self, "_on_ButtonCondition_pressed", [])
			else:
				button.connect('pressed', self, "_create_event_button_pressed", [button.event_id])
			# Adding it to its section
			get_node("ScrollContainer/EventContainer/FlexContainer" + str(button.event_category + 1)).add_child(button)
			while button.get_index() != 0 and button.sorting_index < get_node("ScrollContainer/EventContainer/FlexContainer" + str(button.event_category + 1)).get_child(button.get_index()-1).sorting_index:
				get_node("ScrollContainer/EventContainer/FlexContainer" + str(button.event_category + 1)).move_child(button, button.get_index()-1)

# handles dragging/moving of events
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


# SIGNAL handles input on the events mainly for selection and moving events
func _on_event_block_gui_input(event, item: Node):
	if event is InputEventMouseButton and event.button_index == 1:
		if (not event.is_pressed()):
			if (piece_was_dragged and moving_piece != null and move_start_position):
				var to_position = moving_piece.get_index()
				if move_start_position != to_position:
					# move it back so the DO action works. (Kinda stupid but whatever)
					move_block_to_index(to_position, move_start_position)
					TimelineUndoRedo.create_action("[D] Moved event (type '"+moving_piece.event_data.event_id+"').")
					TimelineUndoRedo.add_do_method(self, "move_block_to_index", move_start_position, to_position)
					TimelineUndoRedo.add_undo_method(self, "move_block_to_index", to_position, move_start_position)
					TimelineUndoRedo.commit_action()
				move_start_position = null
			else:
				select_item(item)
			if (moving_piece != null):
				
				indent_events()
			piece_was_dragged = false
			moving_piece = null
		elif event.is_pressed():
			moving_piece = item
			move_start_position = moving_piece.get_index()
			if not _is_item_selected(item):
				pass#piece_was_dragged = true
			else:
				piece_was_dragged = false


## *****************************************************************************
##					 	SHORTCUTS
## *****************************************************************************

func _input(event):
	# some shortcuts need to get handled in the common input event
	# especially CTRL-based
	# because certain godot controls swallow events (like textedit)
	# we protect this with is_visible_in_tree to not 
	# invoke a shortcut by accident
	if get_focus_owner() is TextEdit:
		return
	if (event is InputEventKey and event is InputEventWithModifiers and is_visible_in_tree()):
		# CTRL Z # UNDO
		if (event.pressed
			and event.alt == false
			and event.shift == false
			and (event.control == true or event.command == true)
			and event.scancode == KEY_Z
			and event.echo == false
		):
			TimelineUndoRedo.undo()
			indent_events()
			get_tree().set_input_as_handled()
	if (event is InputEventKey and event is InputEventWithModifiers and is_visible_in_tree()):
		# CTRL +SHIFT+ Z # REDO
		if (event.pressed
			and event.alt == false
			and event.shift == true
			and (event.control == true or event.command == true)
			and event.scancode == KEY_Z
			and event.echo == false
		) or (event.pressed
			and event.alt == false
			and event.shift == false
			and (event.control == true or event.command == true)
			and event.scancode == KEY_Y
			and event.echo == false):
			TimelineUndoRedo.redo()
			indent_events()
			get_tree().set_input_as_handled()
	if (event is InputEventKey and event is InputEventWithModifiers and is_visible_in_tree()):
		# UP
		if (event.pressed
			and event.alt == false
			and event.shift == false
			and (event.control == false or event.command == false)
			and event.scancode == KEY_UP
			and event.echo == false
		):
			# select previous
			if (len(selected_items) == 1):
				var prev = max(0, selected_items[0].get_index() - 1)
				var prev_node = timeline.get_child(prev)
				if (prev_node != selected_items[0]):
					selected_items = []
					select_item(prev_node)
				get_tree().set_input_as_handled()

			
		# DOWN
		if (event.pressed
			and event.alt == false
			and event.shift == false
			and (event.control == false or event.command == false)
			and event.scancode == KEY_DOWN
			and event.echo == false
		):
			# select next
			if (len(selected_items) == 1):
				var next = min(timeline.get_child_count() - 1, selected_items[0].get_index() + 1)
				var next_node = timeline.get_child(next)
				if (next_node != selected_items[0]):
					selected_items = []
					select_item(next_node)
				get_tree().set_input_as_handled()
			
		# DELETE
		if (event.pressed
			and event.alt == false
			and event.shift == false
			and (event.control == false or event.command == false)
			and event.scancode == KEY_DELETE
			and event.echo == false
		):
			if (len(selected_items) != 0):
				var events_indexed = get_events_indexed(selected_items)
				TimelineUndoRedo.create_action("[D] Deleting "+str(len(selected_items))+" event(s).")
				TimelineUndoRedo.add_do_method(self, "delete_events_indexed", events_indexed)
				TimelineUndoRedo.add_undo_method(self, "add_events_indexed", events_indexed)
				TimelineUndoRedo.commit_action()
				get_tree().set_input_as_handled()
			
		# CTRL T
		if (event.pressed
			and event.alt == false
			and event.shift == false
			and (event.control == true or event.command == true)
			and event.scancode == KEY_T
			and event.echo == false
		):
			var at_index = -1
			if selected_items:
				at_index = selected_items[-1].get_index()+1
			else:
				at_index = timeline.get_child_count()
			TimelineUndoRedo.create_action("[D] Add Text event.")
			TimelineUndoRedo.add_do_method(self, "create_event", "dialogic_001", {'no-data': true}, true, at_index, true)
			TimelineUndoRedo.add_undo_method(self, "remove_events_at_index", at_index, 1)
			TimelineUndoRedo.commit_action()
			get_tree().set_input_as_handled()
			
		# CTRL A
		if (event.pressed
			and event.alt == false
			and event.shift == false
			and (event.control == true or event.command == true)
			and event.scancode == KEY_A
			and event.echo == false
		):
			if (len(selected_items) != 0):
				select_all_items()
			get_tree().set_input_as_handled()
		
		# CTRL SHIFT A
		if (event.pressed
			and event.alt == false
			and event.shift == true
			and (event.control == true or event.command == true)
			and event.scancode == KEY_A
			and event.echo == false
		):
			if (len(selected_items) != 0):
				deselect_all_items()
			get_tree().set_input_as_handled()
		
		# CTRL C
		if (event.pressed
			and event.alt == false
			and event.shift == false
			and (event.control == true or event.command == true)
			and event.scancode == KEY_C
			and event.echo == false
		):
			copy_selected_events()
			get_tree().set_input_as_handled()
		
		# CTRL V
		if (event.pressed
			and event.alt == false
			and event.shift == false
			and (event.control == true or event.command == true)
			and event.scancode == KEY_V
			and event.echo == false
		):
			var events_list = paste_check()
			var paste_position = -1
			if selected_items:
				paste_position = selected_items[-1].get_index()
			else:
				paste_position = timeline.get_child_count()-1
			TimelineUndoRedo.create_action("[D] Pasting "+str(len(events_list))+" event(s).")
			TimelineUndoRedo.add_do_method(self, "add_events_at_index", events_list, paste_position)
			TimelineUndoRedo.add_undo_method(self, "remove_events_at_index", paste_position+1, len(events_list))
			TimelineUndoRedo.commit_action()
			get_tree().set_input_as_handled()
		
		# CTRL X
		if (event.pressed
			and event.alt == false
			and event.shift == false
			and (event.control == true or event.command == true)
			and event.scancode == KEY_X
			and event.echo == false
		):
			var events_indexed = get_events_indexed(selected_items)
			TimelineUndoRedo.create_action("[D] Cut "+str(len(selected_items))+" event(s).")
			TimelineUndoRedo.add_do_method(self, "cut_events_indexed", events_indexed)
			TimelineUndoRedo.add_undo_method(self, "add_events_indexed", events_indexed)
			TimelineUndoRedo.commit_action()
			get_tree().set_input_as_handled()

		# CTRL D
		if (event.pressed
			and event.alt == false
			and event.shift == false
			and (event.control == true or event.command == true)
			and event.scancode == KEY_D
			and event.echo == false
		):
			
			if len(selected_items) > 0:
				var events = get_events_indexed(selected_items).values()
				var at_index = selected_items[-1].get_index()
				TimelineUndoRedo.create_action("[D] Duplicate "+str(len(events))+" event(s).")
				TimelineUndoRedo.add_do_method(self, "add_events_at_index", events, at_index)
				TimelineUndoRedo.add_undo_method(self, "remove_events_at_index", at_index, len(events))
				TimelineUndoRedo.commit_action()
			get_tree().set_input_as_handled()

func _unhandled_key_input(event):
	if (event is InputEventWithModifiers):
		# ALT UP
		if (event.pressed
			and event.alt == true 
			and event.shift == false 
			and (event.control == false or event.command == false)
			and event.scancode == KEY_UP
			and event.echo == false
		):
			# move selected up
			if (len(selected_items) == 1):
				move_block(selected_items[0], "up")
				indent_events()
				get_tree().set_input_as_handled()
			
		# ALT DOWN
		if (event.pressed
			and event.alt == true 
			and event.shift == false 
			and (event.control == false or event.command == false)
			and event.scancode == KEY_DOWN
			and event.echo == false
		):
			# move selected down
			if (len(selected_items) == 1):
				move_block(selected_items[0], "down")
				indent_events()
				get_tree().set_input_as_handled()

## *****************************************************************************
##					 	DELETING, COPY, PASTE
## *****************************************************************************

func get_events_indexed(events:Array) -> Dictionary:
	var indexed_dict = {}
	for event in events:
		indexed_dict[event.get_index()] = event.event_data.duplicate(true)
	return indexed_dict

func select_indexed_events(indexed_events:Dictionary) -> void:
	selected_items = []
	for event_index in indexed_events.keys():
		selected_items.append(timeline.get_child(event_index))

func add_events_indexed(indexed_events:Dictionary) -> void:
	var indexes = indexed_events.keys()
	indexes.sort()
	var events = []
	for event_idx in indexes:
		deselect_all_items()
		events.append(create_event(indexed_events[event_idx].event_id, indexed_events[event_idx]))
		timeline.move_child(events[-1], event_idx)
		
	selected_items = events
	visual_update_selection()

func delete_events_indexed(indexed_events:Dictionary) -> void:
	select_indexed_events(indexed_events)
	delete_selected_events()

func delete_selected_events():
	if len(selected_items) == 0:
		return
	
	# get next element
	var next = min(timeline.get_child_count() - 1, selected_items[-1].get_index() + 1)
	var next_node = timeline.get_child(next)
	if _is_item_selected(next_node):
		next_node = null
	
	for event in selected_items:
		event.get_parent().remove_child(event)
		event.queue_free()
	
	# select next
	if (next_node != null):
		select_item(next_node, false)
	else:
		if (timeline.get_child_count() > 0):
			next_node = timeline.get_child(max(0, timeline.get_child_count() - 1))
			if (next_node != null):
				select_item(next_node, false)
		else:
			deselect_all_items()
	
	indent_events()


func cut_selected_events():
	copy_selected_events()
	delete_selected_events()


func cut_events_indexed(indexed_events:Dictionary) -> void:
	select_indexed_events(indexed_events)
	cut_selected_events()


func copy_selected_events():
	if len(selected_items) == 0:
		return
	var event_copy_array = []
	for item in selected_items:
		event_copy_array.append(item.event_data)
	
	OS.clipboard = JSON.print(
		{
			"events":event_copy_array,
			"dialogic_version": editor_reference.version_string,
			"project_name": ProjectSettings.get_setting("application/config/name")
		})

func paste_check():
	var clipboard_parse = JSON.parse(OS.clipboard).result
	
	if typeof(clipboard_parse) == TYPE_DICTIONARY:
		if clipboard_parse.has("dialogic_version"):
			if clipboard_parse['dialogic_version'] != editor_reference.version_string:
				print("[D] Be careful when copying from older versions!")
		if clipboard_parse.has("project_name"):
			if clipboard_parse['project_name'] != ProjectSettings.get_setting("application/config/name"):
				print("[D] Be careful when copying from another project!")
		if clipboard_parse.has('events'):
			return clipboard_parse['events']

func remove_events_at_index(at_index:int, amount:int = 1)-> void:
	selected_items = []
	for i in range(0, amount):
		selected_items.append(timeline.get_child(at_index + i))
	delete_selected_events()

func add_events_at_index(event_list:Array, at_index:int) -> void:
	if at_index != -1:
		event_list.invert()
		selected_items = [timeline.get_child(at_index)]
	else:
		selected_items = []
	
	var new_items = []
	for item in event_list:
		if typeof(item) == TYPE_DICTIONARY and item.has('event_id'):
			new_items.append(create_event(item['event_id'], item))
	selected_items = new_items
	sort_selection()
	visual_update_selection()
	indent_events()

func paste_events_indexed(indexed_events):
	pass

func duplicate_events_indexed(indexed_events):
	pass

## *****************************************************************************
##					 	BLOCK SELECTION
## *****************************************************************************

func _is_item_selected(item: Node):
	return item in selected_items


func select_item(item: Node, multi_possible:bool = true):
	if item == null:
		return

	if Input.is_key_pressed(KEY_CONTROL) and multi_possible:
		# deselect the item if it is selected
		if _is_item_selected(item):
			selected_items.erase(item)
		else:
			selected_items.append(item)
	elif Input.is_key_pressed(KEY_SHIFT) and multi_possible:
		
		if len(selected_items) == 0:
			selected_items = [item]
		else:
			var index = selected_items[-1].get_index()
			var goal_idx = item.get_index()
			while true:
				if index < goal_idx: index += 1
				else: index -= 1
				if not timeline.get_child(index) in selected_items:
					selected_items.append(timeline.get_child(index))
				
				if index == goal_idx:
					break
	else:
		if len(selected_items) == 1:
			if _is_item_selected(item):
				selected_items.erase(item)
			else:
				selected_items = [item]
		else:
			selected_items = [item]
	
	sort_selection()
	
	visual_update_selection()


# checks all the events and sets their styles (selected/deselected)
func visual_update_selection():
	for item in timeline.get_children():
		item.visual_deselect()
	for item in selected_items:
		item.visual_select()


## Sorts the selection using 'custom_sort_selection'
func sort_selection():
	selected_items.sort_custom(self, 'custom_sort_selection')


## Compares two event blocks based on their position in the timeline
func custom_sort_selection(item1, item2):
	return item1.get_index() < item2.get_index()


## Helpers
func select_all_items():
	selected_items = []
	for event in timeline.get_children():
		selected_items.append(event)
	visual_update_selection()


func deselect_all_items():
	selected_items = []
	visual_update_selection()

## *****************************************************************************
##				SPECIAL BLOCK OPERATIONS
## *****************************************************************************

# SIGNAL handles the actions of the small menu on the right
func _on_event_options_action(action: String, item: Node):
	### WORK TODO
	if action == "remove":
		delete_selected_events()
	else:
		move_block(item, action)
	indent_events()


func delete_event(event):
	event.get_parent().remove_child(event)
	event.queue_free()


## *****************************************************************************
##				CREATING NEW EVENTS USING THE BUTTONS
## *****************************************************************************

# Event Creation signal for buttons
func _create_event_button_pressed(event_id):
	var at_index = -1
	if selected_items:
		at_index = selected_items[-1].get_index()+1
	else:
		at_index = timeline.get_child_count()
	TimelineUndoRedo.create_action("[D] Add event.")
	TimelineUndoRedo.add_do_method(self, "create_event", event_id, {'no-data': true}, true, at_index, true)
	TimelineUndoRedo.add_undo_method(self, "remove_events_at_index", at_index, 1)
	TimelineUndoRedo.commit_action()
	scroll_to_piece(at_index)
	indent_events()


# the Question button adds multiple blocks 
func _on_ButtonQuestion_pressed() -> void:
	var at_index = -1
	if selected_items:
		at_index = selected_items[-1].get_index()+1
	else:
		at_index = timeline.get_child_count()
	TimelineUndoRedo.create_action("[D] Add question events.")
	TimelineUndoRedo.add_do_method(self, "create_question", at_index)
	TimelineUndoRedo.add_undo_method(self, "remove_events_at_index", at_index, 4)
	TimelineUndoRedo.commit_action()

func create_question(at_position):
	if at_position == 0: selected_items = []
	else: selected_items = [timeline.get_child(at_position-1)]
	if len(selected_items) != 0:
		# Events are added bellow the selected node
		# So we must reverse the adding order
		create_event("dialogic_013", {'no-data': true}, true)
		create_event("dialogic_011", {'no-data': true}, true)
		create_event("dialogic_011", {'no-data': true}, true)
		create_event("dialogic_010", {'no-data': true}, true)
	else:
		create_event("dialogic_010", {'no-data': true}, true)
		create_event("dialogic_011", {'no-data': true}, true)
		create_event("dialogic_011", {'no-data': true}, true)
		create_event("dialogic_013", {'no-data': true}, true)


# the Condition button adds multiple blocks 
func _on_ButtonCondition_pressed() -> void:
	var at_index = -1
	if selected_items:
		at_index = selected_items[-1].get_index()+1
	else:
		at_index = timeline.get_child_count()
	TimelineUndoRedo.create_action("[D] Add condition events.")
	TimelineUndoRedo.add_do_method(self, "create_condition", at_index)
	TimelineUndoRedo.add_undo_method(self, "remove_events_at_index", at_index, 2)
	TimelineUndoRedo.commit_action()
	
func create_condition(at_position):
	if at_position == 0: selected_items = []
	else: selected_items = [timeline.get_child(at_position-1)]
	if len(selected_items) != 0:
		# Events are added bellow the selected node
		# So we must reverse the adding order
		create_event("dialogic_013", {'no-data': true}, true)
		create_event("dialogic_012", {'no-data': true}, true)
	else:
		create_event("dialogic_012", {'no-data': true}, true)
		create_event("dialogic_013", {'no-data': true}, true)


func update_custom_events() -> void:
	## CLEANUP
	custom_events = {}
	
	# cleaning the 'old' buttons
	for child in custom_events_container.get_children():
		child.queue_free()
	
	var path:String = "res://dialogic/custom-events"
	
	var dir = Directory.new()
	if dir.open(path) == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		# goes through all the folders in the custom events folder
		while file_name != "":
			# if it found a folder
			if dir.current_is_dir() and not file_name in ['.', '..']:
				# look through that folder
				#print("Found custom event folder: " + file_name)
				var event = load(path.plus_file(file_name).plus_file('EventBlock.tscn')).instance()
				if event:
					custom_events[event.event_data['event_id']] = {
						'event_block_scene' :path.plus_file(file_name).plus_file('EventBlock.tscn'),
						'event_name' : event.event_name,
						'event_icon' : event.event_icon
					}
					event.queue_free()
				else:
					print("[D] An error occurred when trying to access a custom event.")
				
				
			else:
				pass # files in the directory are ignored
			file_name = dir.get_next()
			
		# After we finishing checking, if any events exist, show the panel
		if custom_events.size() == 0:
			custom_events_container.hide()
			$ScrollContainer/EventContainer/CustomEventsHeadline.hide()
		else:
			custom_events_container.show()
			$ScrollContainer/EventContainer/CustomEventsHeadline.show()
	else:
		print("[D] An error occurred when trying to access the custom events folder.")
	
	## VISUAL UPDATE
	
	
	# adding new ones
	for custom_event_id in custom_events.keys():
		var button = load('res://addons/dialogic/Editor/TimelineEditor/SmallEventButton.tscn').instance()
		#button.set_script(preload("EventButton.gd"))
		button.event_id = custom_event_id
		button.visible_name = '       ' + custom_events[custom_event_id]['event_name']
		if custom_events[custom_event_id]['event_icon']:
			button.set_icon(custom_events[custom_event_id]['event_icon'])
		#button.event_color = TODO
		button.connect("pressed", self, "_create_event_button_pressed", [custom_event_id])
		custom_events_container.add_child(button)

## *****************************************************************************
##					 	DRAG AND DROP
## *****************************************************************************

# Creates a ghost event for drag and drop
func create_drag_and_drop_event(event_id: String):
	var index = get_index_under_cursor()
	var piece = create_event(event_id)
	currently_draged_event_type = event_id
	timeline.move_child(piece, index)
	moving_piece = piece
	piece_was_dragged = true
	set_event_ignore_save(piece, true)
	select_item(piece)
	return piece


func drop_event():
	if moving_piece != null:
		var at_index = moving_piece.get_index()
		moving_piece.queue_free()
		TimelineUndoRedo.create_action("[D] Add event.")
		TimelineUndoRedo.add_do_method(self, "create_event", currently_draged_event_type, {'no-data': true}, true, at_index, true)
		TimelineUndoRedo.add_undo_method(self, "remove_events_at_index", at_index, 1)
		TimelineUndoRedo.commit_action()
		moving_piece = null
		piece_was_dragged = false
		indent_events()
		add_extra_scroll_area_to_timeline()
		


func cancel_drop_event():
	if moving_piece != null:
		moving_piece = null
		piece_was_dragged = false
		delete_selected_events()
		deselect_all_items()


## *****************************************************************************
##					 	CREATING THE TIMELINE
## *****************************************************************************

# Adding an event to the timeline
func create_event(event_id: String, data: Dictionary = {'no-data': true} , indent: bool = false, at_index: int = -1, auto_select: bool = false):
	var piece = null
	
	# check if it's a custom event
	if event_id in custom_events.keys():
		piece = load(custom_events[event_id]['event_block_scene']).instance()
	# check if it's a builtin event
	elif event_id in id_to_scene_name.keys():
		piece = load("res://addons/dialogic/Editor/Events/" + id_to_scene_name[event_id] + ".tscn").instance()
	# else use dummy event
	else:
		piece = load("res://addons/dialogic/Editor/Events/DummyEvent.tscn").instance()
	
	# load the piece with data
	piece.editor_reference = editor_reference
	
	if data.has('no-data') == false:
		piece.event_data = data
	
	if at_index == -1:
		if len(selected_items) != 0:
			timeline.add_child_below_node(selected_items[0], piece)
		else:
			timeline.add_child(piece)
	else:
		timeline.add_child(piece)
		timeline.move_child(piece, at_index)

	piece.connect("option_action", self, '_on_event_options_action', [piece])
	piece.connect("gui_input", self, '_on_event_block_gui_input', [piece])
	
	events_warning.visible = false
	if auto_select:
		select_item(piece, false)
	# Spacing
	add_extra_scroll_area_to_timeline()
	# Indent on create
	if indent:
		indent_events()
	
	if not building_timeline:
		piece.focus()
	
	return piece


func load_timeline(filename: String): 
	clear_timeline()
	update_custom_events()
	if timeline_file != filename:
		TimelineUndoRedo.clear_history()
	building_timeline = true
	timeline_file = filename
	
	var data = DialogicResources.get_timeline_json(filename)
	if data['metadata'].has('name'):
		timeline_name = data['metadata']['name']
	else:
		timeline_name = data['metadata']['file']
	data = data['events']
	
	var page = 1
	var batch_size = 12
	while batch_events(data, batch_size, page).size() != 0:
		batches.append(batch_events(data, batch_size, page))
		page += 1
	load_batch(batches)
	# Reset the scroll position
	$TimelineArea.scroll_vertical = 0
	


func batch_events(array, size, batch_number):
	return array.slice((batch_number - 1) * size, batch_number * size - 1)


func load_batch(data):
	#print('[D] Loading batch')
	var current_batch = batches.pop_front()
	if current_batch:
		for i in current_batch:
			create_event(i['event_id'], i, false, timeline.get_child_count())
	emit_signal("batch_loaded")


func _on_batch_loaded():
	if batches.size() > 0:
		yield(get_tree().create_timer(0.01), "timeout")
		load_batch(batches)
	else:
		events_warning.visible = false
		indent_events()
		building_timeline = false
		emit_signal("timeline_loaded")
	add_extra_scroll_area_to_timeline()
	


func clear_timeline():
	deselect_all_items()
	for event in timeline.get_children():
		event.free()


## *****************************************************************************
##					 	BLOCK GETTERS
## *****************************************************************************

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
			$TimelineArea.update()
			return true
	if direction == 'down':
		timeline.move_child(block, block_index + 1)
		$TimelineArea.update()
		return true
	return false

func move_block_to_index(block_index, index):
	timeline.move_child(timeline.get_child(block_index), index)

## *****************************************************************************
##					 TIMELINE CREATION AND SAVING
## *****************************************************************************


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
	event.ignore_save = ignore
	

func get_event_ignore_save(event: Node) -> bool:
	return event.ignore_save


func save_timeline() -> void:
	if timeline_file != '' and building_timeline == false:
		var info_to_save = generate_save_data()
		DialogicResources.set_timeline(info_to_save)
		#print('[+] Saving: ' , timeline_file)


## *****************************************************************************
##					 UTILITIES/HELPERS
## *****************************************************************************

# Scrolling
func scroll_to_piece(piece_index) -> void:
	var height = 0
	for i in range(0, piece_index):
		height += $TimelineArea/TimeLine.get_child(i).rect_size.y
	if height < $TimelineArea.scroll_vertical or height > $TimelineArea.scroll_vertical+$TimelineArea.rect_size.y-(200*DialogicUtil.get_editor_scale(self)):
		$TimelineArea.scroll_vertical = height

# Event Indenting
func indent_events() -> void:
	# Now indenting
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
		
		event.set_indent(0)
		
	# Adding new indents
	for event in event_list:
		# since there are indicators now, not all elements
		# in this list have an event_data property
		if (not "event_data" in event):
			continue
		
		
		if event.event_data['event_id'] == 'dialogic_011':
			if question_index > 0:
				indent = question_indent[question_index] + 1
				starter = true
		elif event.event_data['event_id'] == 'dialogic_010' or event.event_data['event_id'] == 'dialogic_012':
			indent += 1
			starter = true
			question_index += 1
			question_indent[question_index] = indent
		elif event.event_data['event_id'] == 'dialogic_013':
			if question_indent.has(question_index):
				indent = question_indent[question_index]
				indent -= 1
				question_index -= 1
				if indent < 0:
					indent = 0
				else:
					event.remove_warning('This event is not connected to any Question or Condition but it should!')
			else:
				event.set_warning('This event is not connected to any Question or Condition but it should!')

		if indent > 0:
			# Keep old behavior for items without template
			if starter:
				event.set_indent(indent - 1)
			else:
				event.set_indent(indent)
		starter = false
	$TimelineArea.update()


# called from the toolbar
func fold_all_nodes():
	for event in timeline.get_children():
		event.set_expanded(false)
	add_extra_scroll_area_to_timeline()


# called from the toolbar
func unfold_all_nodes():
	for event in timeline.get_children():
		event.set_expanded(true)
	add_extra_scroll_area_to_timeline()

func get_current_events_anchors():
	var anchors = {}
	for event in timeline.get_children():
		if "event_data" in event:
			if event.event_data['event_id'] == 'dialogic_015':
				anchors[event.event_data['id']] = event.event_data['name']
	return anchors

func add_extra_scroll_area_to_timeline():
	if timeline.get_children().size() > 4:
		timeline.rect_min_size.y = 0
		timeline.rect_size.y = 0
		if timeline.rect_size.y + 200 > $TimelineArea.rect_size.y:
			timeline.rect_min_size = Vector2(0, timeline.rect_size.y + 200)


# Functions for reading the event data and coloring the buttons
func _read_event_data():
	var dir = 'res://addons/dialogic/Editor/Events/'
	var file = File.new()
	var config = ConfigFile.new()
	var events_data = []
	for f in DialogicUtil.list_dir(dir):
		if '.tscn' in f:
			if 'DummyEvent' in f:
				# Need to figure out what to do with this one
				pass
			else:
				var scene = load(dir + '/' + f).get_state()
				var c = {}
				for p in scene.get_node_property_count(0):
					c[scene.get_node_property_name(0,p)] = scene.get_node_property_value(0, p)
				events_data.append(c)
	return events_data


func play_timeline():
	DialogicResources.set_settings_value('QuickTimelineTest', 'timeline_file', timeline_file)
	editor_reference.editor_interface.play_custom_scene('res://addons/dialogic/Editor/TimelineEditor/TimelineTestingScene.tscn')
